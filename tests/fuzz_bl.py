import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzbl")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def tdiv(a, b):
    q = abs(a) // abs(b)
    return wrap(q if (a < 0) == (b < 0) else -q)


names = ["a", "b", "c", "d"]
loopv = ["i", "j"]
p_bool = ["p", "q"]


def operand(lv):
    r = rng.random()
    pool = names + lv
    if r < 0.45:
        n = rng.choice(pool)
        return n, lambda e, n=n: e[n]
    if r < 0.65:
        v = rng.choice([0, 1, 3, 5, 7, 100, 2147483647, -7, -2147483648])
        return ("(%d)" % v if v < 0 else str(v)), lambda e, v=v: v
    n = rng.choice(pool)
    d = rng.choice([2, 3, 5, 6, 7, 8, 10, -3, 1000003, 64])
    op = rng.choice(["%", "/", "+", "*"])
    dt = "(%d)" % d if d < 0 else str(d)
    if op == "%":
        return "%s %% %s" % (n, dt), lambda e, n=n, d=d: wrap(e[n] - tdiv(e[n], d) * d)
    if op == "/":
        return "%s / %s" % (n, dt), lambda e, n=n, d=d: tdiv(e[n], d)
    if op == "+":
        return "%s + %s" % (n, dt), lambda e, n=n, d=d: wrap(e[n] + d)
    return "%s * %s" % (n, dt), lambda e, n=n, d=d: wrap(e[n] * d)


def cond(lv):
    parts = []
    for _ in range(rng.choice([1, 1, 2, 3, 4])):
        if rng.random() < 0.15:
            a = rng.choice(p_bool)
            v = rng.choice(["true", "false", rng.choice(p_bool)])
            op = rng.choice(["is", "isnot"])
            parts.append(("%s %s %s" % (a, op, v), lambda e, a=a, v=v, op=op: (e[a] == (e[v] if v in e else v == "true")) == (op == "is")))
            continue
        l = operand(lv)
        r = operand(lv) if rng.random() < 0.4 else (lambda v: ("(%d)" % v if v < 0 else str(v), lambda e: v))(rng.choice([0, 0, 1, 3, -1, 50]))
        op = rng.choice(["is", "isnot", "<", ">"])
        shown = "==" if op == "is" and rng.random() < 0.4 else op
        def ev(e, l=l, r=r, op=op):
            a, b = l[1](e), r[1](e)
            return {"is": a == b, "isnot": a != b, "<": a < b, ">": a > b}[op]
        parts.append(("%s %s %s" % (l[0], shown, r[0]), ev))
    if rng.random() < 0.7:
        return " or ".join(t for t, _ in parts), lambda e: any(f(e) for _, f in parts)
    return join(parts)


def join(items):
    conns = [rng.choice(["or", "or", "and"]) for _ in items[1:]]
    text = items[0][0]
    for c, (t, _) in zip(conns, items[1:]):
        text += " " + c + " " + t
    fs = [f for _, f in items]

    def ev(e):
        terms = []
        cur = [fs[0]]
        for c, f in zip(conns, fs[1:]):
            if c == "and":
                cur.append(f)
            else:
                terms.append(cur)
                cur = [f]
        terms.append(cur)
        return any(all(f(e) for f in t) for t in terms)
    return text, ev


def body(depth, ind, lv):
    out = []
    for _ in range(rng.randint(1, 4)):
        r = rng.random()
        if r < 0.25 and depth < 3 and len(lv) < 2:
            v = loopv[len(lv)]
            n = rng.choice([0, 1, 5, 13, 40])
            out.append(("for", "%sfor %s in range(%d):" % (ind, v, n), v, n, body(depth + 1, ind + "  ", lv + [v])))
        elif r < 0.75:
            ct, cf = cond(lv)
            t = rng.choice(names)
            k = rng.choice([1, -1, 1, 2, -5, 1000])
            sign = "+" if k > 0 else "-"
            if rng.random() < 0.3 and k > 0:
                text = "%s = %d + %s" % (t, k, t)
            else:
                text = "%s = %s %s %d" % (t, t, sign, abs(k))
            ek = rng.choice([None, None, 3, -2])
            out.append(("if", "%sif %s:" % (ind, ct), cf, t, k, "%s  %s" % (ind, text), ek, "%selse:" % ind, "%s  %s = %s + %d" % (ind, t, t, ek or 0)))
        elif r < 0.9:
            t = rng.choice(names)
            m = rng.choice([3, 7, 1103515245, -1])
            a = rng.choice([1, 12345, 0])
            out.append(("set", "%s%s = %s * %d + %d" % (ind, t, t, m, a) if m > 0 else "%s%s = 0 - %s" % (ind, t, t), t, m, a))
        else:
            n = rng.choice(names + lv)
            out.append(("print", '%sprint>>{%s}' % (ind, n), n))
    return out


prog = body(0, "", [])
lines = ["a.int = 1", "b.int = -5", "c.int = 77", "d.int = 2147483647", "i.int = 0", "j.int = 0", "p.bool = true", "q.bool = false"]


def render(items):
    for it in items:
        lines.append(it[1])
        if it[0] == "for":
            render(it[4])
        elif it[0] == "if":
            lines.append(it[5])
            if it[6] is not None:
                lines.append(it[7])
                lines.append(it[8])


render(prog)
env = {"a": 1, "b": -5, "c": 77, "d": 2147483647, "i": 0, "j": 0, "p": True, "q": False}
out = []


def run(items):
    for it in items:
        if it[0] == "for":
            for x in range(it[3]):
                env[it[2]] = x
                run(it[4])
        elif it[0] == "if":
            if it[2](env):
                env[it[3]] = wrap(env[it[3]] + it[4])
            elif it[6] is not None:
                env[it[3]] = wrap(env[it[3]] + it[6])
        elif it[0] == "set":
            env[it[2]] = wrap(env[it[2]] * it[3] + it[4]) if it[3] > 0 else wrap(-env[it[2]])
        else:
            out.append(str(env[it[2]]))


run(prog)
for n in names:
    lines.append("print>>{%s}" % n)
    out.append(str(env[n]))
src = os.path.join(work, "b%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "b%d.exe" % seed)
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
