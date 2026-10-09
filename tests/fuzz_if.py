import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzif")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


ints = ["i", "j", "k"]
strs = ["s", "t"]
bools = ["p", "q"]
env = {"i": 3, "j": -7, "k": 100, "s": "ka", "t": None, "p": True, "q": False}
STRS = ["ka", "a", "Hellowin", "", "x y"]


def int_operand():
    r = rng.random()
    if r < 0.4:
        n = rng.choice(ints)
        return n, lambda e, n=n: e[n]
    if r < 0.7:
        v = rng.choice([0, 1, -1, 3, 5, 100, -7, 2147483647, -2147483648])
        return ("(%d)" % v if v < 0 else str(v)), lambda e, v=v: v
    a = rng.choice(ints)
    v = rng.randint(1, 9)
    return "%s + %d" % (a, v), lambda e, a=a, v=v: wrap(e[a] + v)


def str_operand():
    r = rng.random()
    if r < 0.5:
        n = rng.choice(strs)
        return n, lambda e, n=n: e[n]
    if r < 0.85:
        v = rng.choice(STRS)
        return '"%s"' % v, lambda e, v=v: v
    return "null", lambda e: None


def bool_operand():
    if rng.random() < 0.6:
        n = rng.choice(bools)
        return n, lambda e, n=n: e[n]
    v = rng.choice([True, False])
    return ("true" if v else "false"), lambda e, v=v: v


def group():
    kind = rng.choice(["int", "int", "str", "bool"])
    gen = {"int": int_operand, "str": str_operand, "bool": bool_operand}[kind]
    ops = ["is", "isnot"] + (["<", ">"] if kind == "int" else [])
    op = rng.choice(ops)
    left = [gen() for _ in range(rng.choice([1, 1, 1, 2, 3]))]
    right = gen()
    text = " or ".join(t for t, _ in left) + " " + op + " " + right[0]

    def ev(e):
        rv = right[1](e)
        for _, f in left:
            lv = f(e)
            if op == "is" and lv == rv:
                return True
            if op == "isnot" and lv != rv:
                return True
            if op == "<" and lv < rv:
                return True
            if op == ">" and lv > rv:
                return True
        return False
    return text, ev


def cond():
    gs = [group() for _ in range(rng.choice([1, 1, 2, 3]))]
    return " or ".join(t for t, _ in gs), lambda e: any(f(e) for _, f in gs)


def show(v):
    if v is True:
        return "true"
    if v is False:
        return "false"
    if v is None:
        return "null"
    return str(v)


def block(depth, indent):
    out = []
    for _ in range(rng.randint(1, 5)):
        r = rng.random()
        if r < 0.25 and depth < 5:
            text, ev = cond()
            sub = block(depth + 1, indent + rng.choice(["  ", "    ", "\t"]))
            out.append(("if", indent + "if " + text + ":", ev, sub))
        elif r < 0.5:
            n = rng.choice(ints)
            v = rng.choice([1, -1, 2, 10])
            if rng.random() < 0.5 and depth > 0:
                out.append(("set", indent + "%s.int = %s + %d" % (n, n, v), n, lambda e, n=n, v=v: wrap(e[n] + v)))
            else:
                out.append(("set", indent + "%s = %s * %d" % (n, n, v), n, lambda e, n=n, v=v: wrap(e[n] * v)))
        elif r < 0.6:
            n = rng.choice(strs)
            v = rng.choice(STRS + [None])
            out.append(("set", indent + "%s = %s" % (n, '"%s"' % v if v is not None else "null"), n, lambda e, v=v: v))
        elif r < 0.7:
            n = rng.choice(bools)
            v = rng.choice([True, False])
            out.append(("set", indent + "%s = %s" % (n, "true" if v else "false"), n, lambda e, v=v: v))
        else:
            n = rng.choice(ints + strs + bools)
            out.append(("print", indent + 'print>>"%s="{%s}' % (n, n), n))
    return out


prog = [x for _ in range(6) for x in block(0, "")]


def render(items, lines):
    for it in items:
        lines.append(it[1])
        if it[0] == "if":
            render(it[3], lines)


def run(items, e, out):
    for it in items:
        if it[0] == "if":
            if it[2](e):
                run(it[3], e, out)
        elif it[0] == "set":
            e[it[2]] = it[3](e)
        else:
            out.append("%s=%s" % (it[2], show(e[it[2]])))


lines = ['i.int = 3', 'j.int = -7', 'k.int = 100', 's.str = "ka"', 't.str =', 'p.bool = true', 'q.bool = false']
render(prog, lines)
expected = []
run(prog, dict(env), expected)
src = os.path.join(work, "if%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "if%d.exe" % seed)
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
