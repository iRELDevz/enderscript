import os
import random
import subprocess
import sys

here = os.path.dirname(os.path.abspath(__file__))
ender = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(here, "..", "ender.exe")
work = os.path.join(here, "build", "fuzz")
os.makedirs(work, exist_ok=True)
seed = int(sys.argv[2]) if len(sys.argv) > 2 else 1
rng = random.Random(seed)
exe_suffix = ".exe" if os.name == "nt" else ""


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def cdiv(a, b):
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q


VALUES = [0, 1, -1, 2, 3, 7, 10, 16, 100, 255, 1024, 65536, 2147483647, -2147483648, -7, -16, 123456789]
names = ["a", "b", "c", "d"]


class DivZero(Exception):
    pass


def gen(depth, env):
    if depth == 0 or rng.random() < 0.3:
        if rng.random() < 0.5:
            v = rng.choice(VALUES + [rng.randint(-1000, 1000)])
            text = str(v) if v >= 0 else "(" + str(v) + ")"
            return text, v
        n = rng.choice(names)
        return n, env[n]
    if rng.random() < 0.1:
        t, v = gen(depth - 1, env)
        return "-(" + t + ")", wrap(-v)
    op = rng.choice("+-*/%")
    lt, lv = gen(depth - 1, env)
    rt, rv = gen(depth - 1, env)
    if op in "/%" and rv == 0:
        raise DivZero()
    if op == "+":
        v = wrap(lv + rv)
    elif op == "-":
        v = wrap(lv - rv)
    elif op == "*":
        v = wrap(lv * rv)
    elif op == "/":
        v = wrap(cdiv(lv, rv))
    else:
        v = wrap(lv - cdiv(lv, rv) * rv)
    return "(" + lt + " " + op + " " + rt + ")", v


lines = []
expected = []
env = {n: rng.choice(VALUES) for n in names}
for n in names:
    lines.append("%s.int = %d" % (n, env[n]))
count = 0
while count < int(sys.argv[3]) if len(sys.argv) > 3 else count < 400:
    try:
        text, v = gen(rng.randint(1, 5), env)
    except DivZero:
        continue
    count += 1
    kind = rng.random()
    if kind < 0.4:
        lines.append("print>>" + text)
    elif kind < 0.7:
        lines.append("print>>\"r=\"{" + text + "}")
        v = "r=" + str(v)
    else:
        target = rng.choice(names)
        lines.append("%s = %s" % (target, text))
        env[target] = v
        lines.append("print>>" + target)
    expected.append(str(v))

src = os.path.join(work, "fuzz%d.es" % seed)
with open(src, "w", newline="\n") as f:
    f.write("\n".join(lines) + "\n")
exe = os.path.join(work, "fuzz%d%s" % (seed, exe_suffix))
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode != 0:
    print("BUILD FAILED", r.stderr.decode(errors="replace")[:500])
    sys.exit(1)
r = subprocess.run([exe], capture_output=True)
got = r.stdout.decode().replace("\r\n", "\n").split("\n")[:-1]
bad = [(i, e, g) for i, (e, g) in enumerate(zip(expected, got)) if e != g]
if r.returncode != 0 or len(got) != len(expected) or bad:
    print("MISMATCH seed", seed, "exit", r.returncode, "lines", len(got), "/", len(expected))
    for i, e, g in bad[:5]:
        print("  line", i, "expected", e, "got", g)
    sys.exit(1)
print("ok seed %d: %d expressions" % (seed, len(expected)))
