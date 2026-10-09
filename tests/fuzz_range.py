import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzrange")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def tdiv(a, b):
    q = abs(a) // abs(b)
    return wrap(q if (a < 0) == (b < 0) else -q)


def tmod(a, b):
    return wrap(a - tdiv(a, b) * b)


def lit(v):
    return "(%d)" % v if v < 0 else str(v)


names = ["a", "b", "c", "w"]
DIVS = [7, 8, 16, 1000003, 1000, 3, -8, -7, 2, 64, 65536, 2147483647]
MULS = [2, 3, 5, 7, 9, 15, 17, 31, 33, 63, -3, 1103515245]


def term(lv):
    r = rng.random()
    if r < 0.4:
        n = rng.choice(names + lv)
        return n, lambda e, n=n: e[n]
    if r < 0.6:
        v = rng.choice([0, 1, 5, 100, 2147483647, -1, -100])
        return lit(v), lambda e, v=v: v
    n = rng.choice(names)
    m = rng.choice(MULS)
    k = rng.choice(lv + ["1", "0"]) if lv else "1"
    if k in lv:
        return "%s * %s + %s" % (n, lit(m), k), lambda e, n=n, m=m, k=k: wrap(wrap(e[n] * m) + e[k])
    return "%s * %s" % (n, lit(m)), lambda e, n=n, m=m: wrap(e[n] * m)


def expr(lv):
    r = rng.random()
    a = term(lv)
    if r < 0.5:
        d = rng.choice(DIVS)
        return "(%s) %% %s" % (a[0], lit(d)), lambda e, a=a, d=d: tmod(a[1](e), d)
    if r < 0.7:
        d = rng.choice(DIVS)
        return "(%s) / %s" % (a[0], lit(d)), lambda e, a=a, d=d: tdiv(a[1](e), d)
    if r < 0.85:
        b = term(lv)
        return "%s - (%s)" % (a[0], b[0]), lambda e, a=a, b=b: wrap(a[1](e) - b[1](e))
    b = term(lv)
    return "%s + %s" % (a[0], b[0]), lambda e, a=a, b=b: wrap(a[1](e) + b[1](e))


def block(depth, ind, lv):
    out = []
    for _ in range(rng.randint(1, 4)):
        r = rng.random()
        if r < 0.2 and depth < 2 and len(lv) < 2:
            v = ["i", "j"][len(lv)]
            n = rng.choice([0, 1, 7, 50, 333])
            out.append(("for", "%sfor %s in range(%d):" % (ind, v, n), v, n, block(depth + 1, ind + "  ", lv + [v])))
        elif r < 0.3:
            t = rng.choice(names)
            d = rng.choice([3, 7, 10])
            out.append(("if", "%sif %s %% %d is 0:" % (ind, t, d), t, d, block(depth + 1, ind + "  ", lv)))
        elif r < 0.85:
            t = rng.choice(names)
            text, f = expr(lv)
            out.append(("set", "%s%s = %s" % (ind, t, text), t, f))
        else:
            t = rng.choice(names + lv)
            out.append(("print", "%sprint>>{%s}" % (ind, t), t))
    return out


lines = ["i.int = 0", "j.int = 0"]
env = {"i": 0, "j": 0}
for n in names:
    v = rng.choice([0, 1, 5, 999, -3, 2147483647, -2147483647, rng.randint(-1000, 1000)])
    lines.append("%s.int = %s" % (n, lit(v) if v >= 0 else "0 - %d" % -v))
    env[n] = v
prog = []
for _ in range(rng.randint(2, 5)):
    if rng.random() < 0.5:
        t = rng.choice(names)
        v = rng.choice([1, 0, 7, -5, 123456])
        prog.append(("set", "%s = %s" % (t, lit(v)), t, lambda e, v=v: v))
    prog.extend(block(0, "", []))


def render(items):
    for it in items:
        lines.append(it[1])
        if it[0] == "for":
            render(it[4])
        elif it[0] == "if":
            render(it[4])


out = []


def run(items):
    for it in items:
        if len(out) > 200000:
            return
        if it[0] == "for":
            for x in range(it[3]):
                env[it[2]] = x
                run(it[4])
        elif it[0] == "if":
            if tmod(env[it[2]], it[3]) == 0:
                run(it[4])
        elif it[0] == "set":
            env[it[2]] = it[3](env)
        else:
            out.append(str(env[it[2]]))


render(prog)
run(prog)
if len(out) > 200000:
    print("skip", seed)
    sys.exit(0)
for n in names:
    lines.append("print>>{%s}" % n)
    out.append(str(env[n]))
src = os.path.join(work, "r%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "r%d.exe" % seed)
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode:
    print("BUILD FAILED", seed, r.stderr.decode(errors="replace")[:300])
    sys.exit(1)
got = subprocess.run([exe], capture_output=True).stdout.decode().replace("\r\n", "\n").split("\n")[:-1]
if got != out:
    print("MISMATCH seed", seed, len(out), len(got))
    for i, (x, y) in enumerate(zip(out, got)):
        if x != y:
            print("  line", i, "expected", x, "got", y)
            break
    sys.exit(1)
print("ok", seed)
