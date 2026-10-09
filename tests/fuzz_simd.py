import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzsimd")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def lit(v):
    return "(%d)" % v if v < 0 else str(v)


def leaf(v):
    side = rng.random()
    c = rng.choice([0, 0, 1, 2, 3, -1, 7, 50, 1000])
    op = rng.choice(["is", "isnot", "<", ">", "<=", ">="])
    if side < 0.6:
        d = rng.choice([1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 16, 100, 1000003, -3, -7, 1073741824])
        text = "%s %% %s" % (v, lit(d))
        f = lambda i, d=d: i % abs(d)
    else:
        text = v
        f = lambda i: i
    cmpf = {"is": lambda a, b: a == b, "isnot": lambda a, b: a != b, "<": lambda a, b: a < b, ">": lambda a, b: a > b, "<=": lambda a, b: a <= b, ">=": lambda a, b: a >= b}
    if rng.random() < 0.3:
        mir = {"is": "is", "isnot": "isnot", "<": ">", ">": "<", "<=": ">=", ">=": "<="}[op]
        return "%s %s %s" % (lit(c), mir, text), lambda i, f=f, c=c, op=op: cmpf[op](f(i), c)
    return "%s %s %s" % (text, op, lit(c)), lambda i, f=f, c=c, op=op: cmpf[op](f(i), c)


lines = ["c.int = 5", "s.int = -3", "i.int = 9", "o.int = 0"]
env = {"c": 5, "s": -3, "i": 9, "o": 0}
out = []
for _ in range(rng.randint(3, 8)):
    n = rng.choice([0, 1, 7, 8, 9, 10, 11, 12, 13, 16, 31, 64, 100, 1001, 4099, 100000])
    t = rng.choice(["c", "s"])
    term = rng.choice(["1", "1", "i", "2", "1000", "(-1)", "-5"])
    if term == "-5":
        stmt = "%s = %s - 5" % (t, t)
        tf = lambda e, i: -5
    elif term == "i" and rng.random() < 0.3:
        stmt = "%s = %s - i" % (t, t)
        tf = lambda e, i: -i
    elif rng.random() < 0.3 and term != "(-1)":
        stmt = "%s = %s + %s" % (t, term, t)
        tf = (lambda e, i: i) if term == "i" else (lambda e, i, k=int(term): k)
    else:
        stmt = "%s = %s + %s" % (t, t, term)
        tf = (lambda e, i: i) if term == "i" else (lambda e, i, k=int(term.strip("()")): k)
    nested = rng.random() < 0.25
    ind = "  " if nested else ""
    if nested:
        lines.append("loops(2):")
    lines.append("%sfor i in range(%d):" % (ind, n))
    if rng.random() < 0.8:
        leaves = [leaf("i") for _ in range(rng.randint(1, 4))]
        lines.append("%s  if %s:" % (ind, " or ".join(x for x, _ in leaves)))
        lines.append("%s    %s" % (ind, stmt))
        cond = lambda i, leaves=leaves: any(f(i) for _, f in leaves)
    else:
        lines.append("%s  %s" % (ind, stmt))
        cond = lambda i: True
    for _ in range(2 if nested else 1):
        for i in range(n):
            env["i"] = i
            if cond(i):
                env[t] = wrap(env[t] + tf(env, i))
    lines.append("print>>{c}\" \"{s}\" \"{i}")
    out.append("%d %d %d" % (env["c"], env["s"], env["i"]))
src = os.path.join(work, "s%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "s%d.exe" % seed)
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode:
    print("BUILD FAILED", seed, r.stderr.decode(errors="replace")[:300])
    sys.exit(1)
got = subprocess.run([exe], capture_output=True).stdout.decode().replace("\r\n", "\n").split("\n")[:-1]
if got != out:
    print("MISMATCH seed", seed)
    for i, (x, y) in enumerate(zip(out, got)):
        if x != y:
            print("  line", i, "expected", x, "got", y)
            break
    print("  lengths", len(out), len(got))
    sys.exit(1)
print("ok", seed)
