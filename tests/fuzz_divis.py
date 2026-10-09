import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzdiv")
os.makedirs(work, exist_ok=True)

EDGE = [0, 1, -1, 2, -2, 3, -3, 2147483647, -2147483648, -2147483647, 1000003, 6, 15, 30, 64, -64]
DIVS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 16, 31, 64, 100, 255, 256, 641, 1000, 1024, 65536, 1000003,
        2147483647, 2147483646, 1073741824, -2, -3, -4, -5, -7, -16, -641, -2147483647, -1073741824]
names = ["a", "b", "c", "d", "e"]
lines = []
expected = []
for n in names:
    v = rng.choice(EDGE + [rng.randint(-2**31, 2**31 - 1) for _ in range(4)])
    lines.append("%s.int = %d" % (n, v) if v >= 0 else "%s.int = 0 - %d" % (n, -v) if v != -2**31 else "%s.int = 0 - 2147483647 - 1" % n)
env = {}
for l in lines:
    n = l.split(".")[0]
    expr = l.split("= ", 1)[1]
    env[n] = eval(expr)


def tmod(a, b):
    q = abs(a) // abs(b)
    q = q if (a < 0) == (b < 0) else -q
    return a - q * b


for i in range(300):
    if rng.random() < 0.3:
        n = rng.choice(names)
        v = rng.choice(EDGE + [rng.randint(-2**31, 2**31 - 1)])
        d = rng.choice(DIVS)
        v = v - tmod(v, d) if rng.random() < 0.5 else v
        if not (-2**31 < v < 2**31):
            v = d
        lines.append("%s = %d" % (n, v) if v >= 0 else "%s = 0 - %d" % (n, -v))
        env[n] = v
    n = rng.choice(names)
    d = rng.choice(DIVS)
    op = rng.choice(["is", "isnot"])
    dt = str(d) if d > 0 else "(%d)" % d
    form = rng.random()
    if form < 0.5:
        cond = "%s %% %s %s 0" % (n, dt, op)
    else:
        cond = "0 %s %s %% %s" % (op, n, dt)
    hit = (tmod(env[n], d) == 0) == (op == "is")
    lines.append("if %s:" % cond)
    lines.append('  print>>"%d"' % i)
    if hit:
        expected.append(str(i))
    lines.append('print>>{%s / %s}" "{%s %% %s}' % (n, dt, n, dt))
    q = abs(env[n]) // abs(d)
    q = q if (env[n] < 0) == (d < 0) else -q
    if q == 2**31:
        q = -2**31
    expected.append("%d %d" % (q, tmod(env[n], d)))
if seed % 2:
    lines = lines[:len(names)] + ["loops(1):"] + ["  " + l for l in lines[len(names):]]
src = os.path.join(work, "d%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "d%d.exe" % seed)
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode:
    print("BUILD FAILED", seed, r.stderr.decode(errors="replace")[:400])
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
print("ok", seed)
