import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzarr")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def tdiv(a, b):
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q


def tmod(a, b):
    return a - tdiv(a, b) * b


class RunErr(Exception):
    def __init__(self, line):
        self.line = line


SCAL = ["x", "y", "z"]
LOOPV = ["i", "j", "k"]
WORDS = ["a", "bc", "", "halo", "x y", "bc"]
ARR = {}
CTX = []
LINE = [0]
ERR = [rng.random() < 0.2]


def lit(w):
    return '"%s"' % w


def int_atom():
    r = rng.random()
    vs = SCAL + [f[1] for f in CTX]
    if r < 0.4:
        n = rng.choice(vs)
        return n, lambda e, n=n: e[n]
    if r < 0.6:
        t, f = elem("A")
        return t, f
    if r < 0.67:
        return "A.len", lambda e: len(e["A"])
    v = rng.choice([0, 1, 2, 3, 5, 7, 10, 100, -4])
    return str(v), lambda e, v=v: v


def int_expr():
    a, fa = int_atom()
    if rng.random() < 0.35:
        return a, fa
    b, fb = int_atom()
    op = rng.choice(["+", "-", "*", "%", "/"])
    if op in "%/":
        d = rng.choice([3, 7, 8, 10])
        f = (lambda e: tmod(fa(e), d)) if op == "%" else (lambda e: tdiv(fa(e), d))
        return "%s %s %d" % (a, op, d), f
    g = {"+": lambda e: wrap(fa(e) + fb(e)), "-": lambda e: wrap(fa(e) - fb(e)),
         "*": lambda e: wrap(fa(e) * fb(e))}[op]
    return "%s %s %s" % (a, op, b), g


def index(name):
    n = ARR[name][1]
    r = rng.random()
    fors = [f for f in CTX if f[0] == "for" and f[2] <= n]
    if ERR[0] and n > 1 and rng.random() < 0.05:
        ERR[0] = False
        v = rng.choice(SCAL)
        return "(%s %% %d + %d) %% %d + %d" % (v, n, n, n, n + 1), \
            lambda e, v=v: tmod(tmod(e[v], n) + n, n) + n + 1
    if r < 0.3:
        c = rng.randint(1, n)
        return str(c), lambda e, c=c: c
    if r < 0.65 and fors:
        f = rng.choice(fors)
        c = rng.randint(1, n - f[2] + 1)
        return "%s + %d" % (f[1], c), lambda e, v=f[1], c=c: e[v] + c
    v = rng.choice(SCAL + [f[1] for f in CTX])
    return "(%s %% %d + %d) %% %d + 1" % (v, n, n, n), lambda e, v=v: tmod(tmod(e[v], n) + n, n) + 1


def check(e, name, i):
    if i < 1 or i > len(e[name]):
        raise RunErr(LINE[0])
    return i


def elem(name):
    t, f = index(name)
    ln = [None]

    def get(e, f=f, name=name):
        return e[name][check(e, name, f(e)) - 1]
    return "%s[%s]" % (name, t), get


def str_val():
    r = rng.random()
    if r < 0.4:
        w = rng.choice(WORDS)
        return lit(w), lambda e, w=w: w
    if r < 0.5:
        return "null", lambda e: None
    return elem("S")


def bool_val():
    r = rng.random()
    if r < 0.4:
        b = rng.random() < 0.5
        return ("true" if b else "false"), lambda e, b=b: b
    return elem("B")


def cond():
    r = rng.random()
    if r < 0.5:
        a, fa = int_expr()
        v = rng.choice([0, 1, 3, 7, 50, 500])
        op = rng.choice(["is", "isnot", "<", ">", ">=", "<="])
        f = {"is": lambda x: x == v, "isnot": lambda x: x != v, "<": lambda x: x < v, ">": lambda x: x > v,
             ">=": lambda x: x >= v, "<=": lambda x: x <= v}[op]
        return "%s %s %d" % (a, op, v), lambda e: f(fa(e))
    if r < 0.75:
        a, fa = str_val()
        b, fb = str_val()
        op = rng.choice(["is", "isnot"])
        if op == "is":
            return "%s is %s" % (a, b), lambda e: fa(e) == fb(e)
        return "%s isnot %s" % (a, b), lambda e: fa(e) != fb(e)
    a, fa = bool_val()
    b, fb = bool_val()
    op = rng.choice(["is", "isnot"])
    if op == "is":
        return "%s is %s" % (a, b), lambda e: fa(e) == fb(e)
    return "%s isnot %s" % (a, b), lambda e: fa(e) != fb(e)


def stmt(depth, ind):
    r = rng.random()
    if r < 0.2:
        t, ft = index("A")
        v, fv = int_expr()
        return ("aset", ind + "A[%s] = %s" % (t, v), "A", ft, fv)
    if r < 0.3:
        t, ft = index("S")
        v, fv = str_val()
        return ("aset", ind + "S[%s] = %s" % (t, v), "S", ft, fv)
    if r < 0.38:
        t, ft = index("B")
        v, fv = bool_val()
        return ("aset", ind + "B[%s] = %s" % (t, v), "B", ft, fv)
    if r < 0.42:
        name = rng.choice(["A", "S", "B"])
        t, ft = index(name)
        z = {"A": 0, "S": None, "B": False}[name]
        return ("aset", ind + "%s[%s] =" % (name, t), name, ft, lambda e, z=z: z)
    if r < 0.6:
        v = rng.choice(SCAL)
        t, f = int_expr()
        if rng.random() < 0.5:
            return ("set", ind + "%s = %s + %s" % (v, v, t), v, lambda e, v=v, f=f: wrap(e[v] + f(e)))
        return ("set", ind + "%s = %s" % (v, t), v, f)
    if r < 0.72:
        t, f = cond()
        sub = [stmt(depth, ind + "  ") for _ in range(rng.randint(1, 2))]
        els = None
        if rng.random() < 0.3:
            els = [stmt(depth, ind + "  ")]
        return ("if", ind + "if " + t + ":", f, sub, els, ind)
    if r < 0.8 and depth < 3:
        return loop(depth + 1, ind)
    k = rng.random()
    if k < 0.4:
        t, f = elem("A")
        return ("print", ind + 'print>>"v="{%s}' % t, lambda e, f=f: "v=%d" % f(e))
    if k < 0.7:
        t, f = elem("S")
        return ("print", ind + 'print>>"s="{%s}' % t,
                lambda e, f=f: "s=" + ("null" if f(e) is None else f(e)))
    t, f = elem("B")
    return ("print", ind + 'print>>"b="{%s}' % t, lambda e, f=f: "b=" + ("true" if f(e) else "false"))


def loop(depth, ind):
    n = rng.choice([1, 3, 5, 8, 16, 64, 100])
    used = [f[1] for f in CTX]
    free = [v for v in LOOPV if v not in used]
    if rng.random() < 0.7 and free:
        v = rng.choice(free)
        CTX.append(("for", v, n))
        b = [stmt(depth, ind + "  ") for _ in range(rng.randint(1, 4))]
        CTX.pop()
        return ("for", ind + "for %s in range(%d):" % (v, n), v, n, b)
    b = [stmt(depth, ind + "  ") for _ in range(rng.randint(1, 4))]
    return ("loops", ind + "loops(%d):" % n, n, b)


def render(items, lines, owners):
    for it in items:
        lines.append(it[1])
        owners.append(it)
        if it[0] == "if":
            render(it[3], lines, owners)
            if it[4]:
                lines.append(it[5] + "else:")
                owners.append(None)
                render(it[4], lines, owners)
        elif it[0] == "for":
            render(it[4], lines, owners)
        elif it[0] == "loops":
            render(it[3], lines, owners)


steps = [0]
LINEOF = {}


def run(items, e, out):
    for it in items:
        steps[0] += 1
        if steps[0] > 3000000:
            print("skip seed %d (too many steps)" % seed)
            sys.exit(0)
        LINE[0] = LINEOF[id(it)]
        k = it[0]
        if k == "set":
            e[it[2]] = it[3](e)
        elif k == "aset":
            i = check(e, it[2], it[3](e))
            v = it[4](e)
            e[it[2]][i - 1] = v
        elif k == "print":
            out.append(it[2](e))
        elif k == "if":
            if it[2](e):
                run(it[3], e, out)
            elif it[4]:
                run(it[4], e, out)
        elif k == "for":
            for c in range(it[3]):
                e[it[2]] = c
                run(it[4], e, out)
        elif k == "loops":
            for _ in range(it[2]):
                run(it[3], e, out)


na = rng.choice([1, 3, 10, 64, 100])
ns = rng.choice([1, 4, 9])
nb = rng.choice([1, 5, 16])
ARR["A"] = ("int", na)
ARR["S"] = ("str", ns)
ARR["B"] = ("bool", nb)


def decl(name):
    typ, n = ARR[name]
    r = rng.random()
    if typ == "int":
        if r < 0.3:
            v = rng.choice([0, 7, -3])
            return "A.int[%d] = %d.all" % (n, v), [v] * n
        vals = [rng.randint(-50, 50) for _ in range(rng.randint(0, n))]
        src = "A.int[%d] =" % n + ("" if not vals else " " + ", ".join(map(str, vals)))
        return src, vals + [0] * (n - len(vals))
    if typ == "str":
        if r < 0.3:
            w = rng.choice(WORDS)
            return "S.str[%d] = %s.all" % (n, lit(w)), [w] * n
        vals = [rng.choice(WORDS) for _ in range(rng.randint(0, n))]
        src = "S.str[%d] =" % n + ("" if not vals else " " + ", ".join(map(lit, vals)))
        return src, vals + [None] * (n - len(vals))
    if r < 0.3:
        b = rng.random() < 0.5
        return "B.bool[%d] = %s.all" % (n, "true" if b else "false"), [b] * n
    vals = [rng.random() < 0.5 for _ in range(rng.randint(0, n))]
    src = "B.bool[%d] =" % n + ("" if not vals else " " + ", ".join("true" if v else "false" for v in vals))
    return src, vals + [False] * (n - len(vals))


lines = ["x.int = 0", "y.int = 1", "z.int = 2", "i.int = 0", "j.int = 0", "k.int = 0"]
e = {"x": 0, "y": 1, "z": 2, "i": 0, "j": 0, "k": 0}
top = []
for name in ["A", "S", "B"]:
    src, vals = decl(name)
    top.append(("decl", src, name, vals))
for _ in range(rng.randint(1, 3)):
    top.append(loop(1, ""))
    if rng.random() < 0.3:
        name = rng.choice(["A", "S", "B"])
        src, vals = decl(name)
        top.append(("decl", src, name, vals))
owners = []
base = len(lines)
for it in top:
    if it[0] == "decl":
        lines.append(it[1])
        owners.append(it)
    else:
        render([it], lines, owners)
for n, it in enumerate(owners):
    if it is not None:
        LINEOF[id(it)] = base + n + 1
tail = ['print>>"x="{x}', 'print>>"y="{y}', 'print>>"z="{z}', 'print>>{A[1]}" "{A[A.len]}']
lines += tail

expected = []
code = 0
try:
    for it in top:
        if it[0] == "decl":
            e[it[2]] = list(it[3])
        else:
            run([it], e, expected)
    for v in ["x", "y", "z"]:
        expected.append("%s=%d" % (v, e[v]))
    expected.append("%d %d" % (e["A"][0], e["A"][-1]))
except RunErr as x:
    code = 1
    errline = "runtime error: array index out of range on line %d" % x.line
if len(expected) > 200000:
    print("skip seed %d (output too large)" % seed)
    sys.exit(0)
src = os.path.join(work, "a%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "a%d.exe" % seed)
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode:
    print("BUILD FAILED seed", seed, r.stderr.decode(errors="replace")[:400])
    sys.exit(1)
p = subprocess.run([exe], capture_output=True)
got = p.stdout.decode().replace("\r\n", "\n").split("\n")[:-1]
bad = got != expected or p.returncode != code
if code and not bad:
    bad = p.stderr.decode().strip() != errline
if bad:
    print("MISMATCH seed", seed, "exit", p.returncode, "expected exit", code)
    if code:
        print("  stderr", p.stderr.decode().strip(), "| expected", errline)
    for i, (a, b) in enumerate(zip(expected, got)):
        if a != b:
            print("  line", i, "expected", a, "got", b)
            break
    print("  lengths", len(expected), len(got))
    sys.exit(1)
print("ok seed %d (%d lines, %d prints%s)" % (seed, len(lines), len(expected), ", runtime error" if code else ""))
