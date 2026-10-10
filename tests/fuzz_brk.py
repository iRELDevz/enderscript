import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzbrk")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def tdiv(a, b):
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q


def tmod(a, b):
    return a - tdiv(a, b) * b


class Brk(Exception):
    def __init__(self, t):
        self.t = t


class Cont(Exception):
    def __init__(self, t):
        self.t = t


VARS = ["x", "y", "z"]
LOOPV = ["i", "j", "k"]
CTX = []
NID = [0]


def nid():
    NID[0] += 1
    return NID[0]


def atom():
    r = rng.random()
    vs = VARS + [f[2] for f in CTX if f[0] == "for"]
    if r < 0.5:
        n = rng.choice(vs)
        return n, lambda e, n=n: e[n]
    if r < 0.6:
        g = [f for f in CTX if f[0] == "group"]
        if g:
            f = rng.choice(g)
            key = [h for h in g if h[2] == f[2]][-1][1]
            return f[2] + ".takedata", lambda e, key=key: e.get(key, 0)
    v = rng.choice([1, 2, 3, 5, 7, 10, 100])
    return str(v), lambda e, v=v: v


def expr():
    a, fa = atom()
    r = rng.random()
    if r < 0.3:
        return a, fa
    b, fb = atom()
    op = rng.choice(["+", "-", "*", "%", "/"])
    if op in "%/":
        d = rng.choice([3, 7, 8, 10])
        f = (lambda e: tmod(fa(e), d)) if op == "%" else (lambda e: tdiv(fa(e), d))
        return "%s %s %d" % (a, op, d), f
    g = {"+": lambda e: wrap(fa(e) + fb(e)), "-": lambda e: wrap(fa(e) - fb(e)), "*": lambda e: wrap(fa(e) * fb(e))}[op]
    return "%s %s %s" % (a, op, b), g


def cond():
    a, fa = expr()
    v = rng.choice([0, 1, 3, 7, 50, 500, 5000])
    op = rng.choice(["is", "isnot", "<", ">", ">=", "<="])
    f = {"is": lambda x: x == v, "isnot": lambda x: x != v, "<": lambda x: x < v, ">": lambda x: x > v,
         ">=": lambda x: x >= v, "<=": lambda x: x <= v}[op]
    return "%s %s %d" % (a, op, v), lambda e: f(fa(e))


def jump(ind):
    loops = [f for f in CTX if f[0] in ("for", "loops", "blk")]
    groups = [f for f in CTX if f[0] == "group"]
    r = rng.random()
    if groups and r < 0.25:
        g = rng.choice(groups)
        gid = [h for h in groups if h[2] == g[2]][-1][1]
        return ("brk", ind + "break." + g[2], gid)
    lid = loops[-1][1]
    if r < 0.6:
        return ("brk", ind + "break", lid)
    return ("cont", ind + "continue", lid)


def body(depth, ind):
    out = []
    for _ in range(rng.randint(1, 4)):
        r = rng.random()
        inloop = any(f[0] in ("for", "loops", "blk") for f in CTX)
        if r < 0.35:
            v = rng.choice(VARS)
            t, f = expr()
            if rng.random() < 0.5:
                out.append(("set", ind + "%s = %s + %s" % (v, v, t), v, lambda e, v=v, f=f: wrap(e[v] + f(e))))
            else:
                out.append(("set", ind + "%s = %s" % (v, t), v, f))
        elif r < 0.6 and inloop:
            t, f = cond()
            sub = [jump(ind + "  ")]
            if rng.random() < 0.3:
                v = rng.choice(VARS)
                sub.insert(0, ("set", ind + "  %s = %s + 1" % (v, v), v, lambda e, v=v: wrap(e[v] + 1)))
            out.append(("if", ind + "if " + t + ":", f, sub))
        elif r < 0.8 and depth < 3:
            out.append(loop(depth + 1, ind))
        elif r < 0.85 and inloop:
            out.append(jump(ind))
        else:
            v = rng.choice(VARS)
            out.append(("print", ind + 'print>>"%s="{%s}' % (v, v), v))
    return out


def loop(depth, ind):
    n = rng.choice([1, 3, 8, 16, 64, 100, 1000, 4096])
    r = rng.random()
    used = [f[2] for f in CTX if f[0] == "for"]
    free = [v for v in LOOPV if v not in used]
    if r < 0.45 and free:
        v = rng.choice(free)
        lid = nid()
        CTX.append(("for", lid, v))
        b = body(depth, ind + "  ")
        CTX.pop()
        return ("for", ind + "for %s in range(%d):" % (v, n), v, n, b, lid)
    if r < 0.75:
        lid = nid()
        CTX.append(("loops", lid))
        b = body(depth, ind + "  ")
        CTX.pop()
        return ("loops", ind + "loops(%d):" % n, n, b, lid)
    name = rng.choice(["g", "h"])
    gid = nid()
    CTX.append(("group", gid, name))
    parts = []
    for _ in range(rng.randint(1, 3)):
        m = rng.choice([1, 2, 5, 8, 100])
        bid = nid()
        CTX.append(("blk", bid))
        b = body(depth, ind + "  ")
        CTX.pop()
        parts.append((m, b, bid))
    CTX.pop()
    return ("group", ind, name, parts, gid)


def render(items, lines):
    for it in items:
        if it[0] == "group":
            ind, name = it[1], it[2]
            lines.append(ind + "loops(%s," % name)
            lines.append(ind + "start." + name)
            for m, b, _ in it[3]:
                lines.append(ind + "%d(" % m)
                render(b, lines)
                lines.append(ind + ")")
            lines.append(ind + "stop." + name)
            lines.append(ind + ")")
            continue
        lines.append(it[1])
        if it[0] in ("if",):
            render(it[3], lines)
        elif it[0] == "for":
            render(it[4], lines)
        elif it[0] == "loops":
            render(it[3], lines)


steps = [0]


def run_body(b, e, out, lid):
    try:
        run(b, e, out)
    except Brk as x:
        if x.t != lid:
            raise
        return True
    except Cont as x:
        if x.t != lid:
            raise
    return False


def run(items, e, out):
    for it in items:
        steps[0] += 1
        if steps[0] > 4000000:
            print("skip seed %d (too many steps)" % seed)
            sys.exit(0)
        k = it[0]
        if k == "set":
            e[it[2]] = it[3](e)
        elif k == "print":
            out.append("%s=%d" % (it[2], e[it[2]]))
        elif k == "if":
            if it[2](e):
                run(it[3], e, out)
        elif k == "brk":
            raise Brk(it[2])
        elif k == "cont":
            raise Cont(it[2])
        elif k == "for":
            for c in range(it[3]):
                e[it[2]] = c
                if run_body(it[4], e, out, it[5]):
                    break
        elif k == "loops":
            for _ in range(it[2]):
                if run_body(it[3], e, out, it[4]):
                    break
        elif k == "group":
            gid = it[4]
            try:
                for m, b, bid in it[3]:
                    e[gid] = m
                    for _ in range(m):
                        if run_body(b, e, out, bid):
                            break
                    e[gid] = 0
            except Brk as x:
                if x.t != gid:
                    raise
            e[gid] = 0


prog = [loop(1, "") for _ in range(rng.randint(1, 3))]
lines = ["x.int = 0", "y.int = 1", "z.int = 2", "i.int = 0", "j.int = 0", "k.int = 0"]
render(prog, lines)
lines += ['print>>"x="{x}', 'print>>"y="{y}', 'print>>"z="{z}', 'print>>"i="{i}', 'print>>"j="{j}', 'print>>"k="{k}']
e = {"x": 0, "y": 1, "z": 2, "i": 0, "j": 0, "k": 0}
expected = []
run(prog, e, expected)
for v in ["x", "y", "z", "i", "j", "k"]:
    expected.append("%s=%d" % (v, e[v]))
if len(expected) > 200000:
    print("skip seed %d (output too large)" % seed)
    sys.exit(0)
src = os.path.join(work, "b%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "b%d.exe" % seed)
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode:
    print("BUILD FAILED seed", seed, r.stderr.decode(errors="replace")[:400])
    sys.exit(1)
got = subprocess.run([exe], capture_output=True).stdout.decode().replace("\r\n", "\n").split("\n")[:-1]
if got != expected:
    print("MISMATCH seed", seed)
    for i, (a, b) in enumerate(zip(expected, got)):
        if a != b:
            print("  line", i, "expected", a, "got", b)
            break
    print("  lengths", len(expected), len(got))
    sys.exit(1)
print("ok seed %d (%d lines, %d prints)" % (seed, len(lines), len(expected)))
