import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzja")
os.makedirs(work, exist_ok=True)


def wrap(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def tdiv(a, b):
    q = abs(a) // abs(b)
    return wrap(q if (a < 0) == (b < 0) else -q)


def lit(v):
    return "(%d)" % v if v < 0 else str(v)


lines = ["x.int = 1", "c.int = 0", "s.int = 7", "y.int = 0", "i.int = 0", "k.int = 0"]
env = {"x": 1, "c": 0, "s": 7, "y": 0, "i": 0, "k": 0}
out = []


def leaf(lv):
    r = rng.random()
    if r < 0.4:
        return "x < 0", lambda e: e["x"] < 0
    if r < 0.55:
        return "0 > x", lambda e: e["x"] < 0
    if r < 0.75:
        d = rng.choice([3, 7, 16])
        return "x %% %d is 0" % d, lambda e, d=d: wrap(e["x"] - tdiv(e["x"], d) * d) == 0
    if r < 0.9 and lv:
        v = rng.choice([2, 5, 30])
        return "%s > %d" % (lv, v), lambda e, v=v: e[lv] > v
    v = rng.choice([1000, -1000, 0])
    return "x > %s" % lit(v), lambda e, v=v: e["x"] > v


force = seed % 3 == 0


def rest(lv):
    if force:
        cond = rng.choice(["x < 0", "0 > x"])
        t = rng.choice(["c", "s"])
        k = rng.choice([1, -1])
        body = "%s = %s %s 1" % (t, t, "+" if k > 0 else "-")
        return [("if %s:" % cond, body, lambda e, t=t, k=k: e.__setitem__(t, wrap(e[t] + k)) if e["x"] < 0 else None)]
    items = []
    for _ in range(rng.randint(1, 3)):
        r = rng.random()
        if r < 0.65:
            leaves = [leaf(lv) for _ in range(rng.choice([1, 1, 2]))]
            t = rng.choice(["c", "s"])
            k = rng.choice([1, 1, -1, 3, -2])
            text = "if %s:" % " or ".join(a for a, _ in leaves)
            body = "%s = %s %s %d" % (t, t, "+" if k > 0 else "-", abs(k))
            items.append((text, body, lambda e, leaves=leaves, t=t, k=k: e.__setitem__(t, wrap(e[t] + k)) if any(f(e) for _, f in leaves) else None))
        elif r < 0.85:
            items.append(("y = x / 3", None, lambda e: e.__setitem__("y", tdiv(e["x"], 3))))
        elif lv:
            items.append(("y = x + %s" % lv, None, lambda e: e.__setitem__("y", wrap(e["x"] + e[lv]))))
        else:
            items.append(("y = x * 2", None, lambda e: e.__setitem__("y", wrap(e["x"] * 2))))
    return items


for _ in range(rng.randint(2, 5)):
    a = rng.choice([1103515245, 3, -3, 5, 2, -1, 0, 1664525, 69069, 214013])
    b = rng.choice([12345, 0, 1, -7, 1013904223, 2531011])
    n = rng.choice([8, 16, 24, 40, 64, 4, 12, 1000, 4096]) if force else rng.choice([8, 16, 24, 40, 64, 5, 15, 25, 6, 18, 3, 9, 2, 14, 7, 11, 13, 1000, 999, 0, 1])
    form = rng.random()
    if b == 0:
        stmt = "x = x * %s" % lit(a)
    elif form < 0.5:
        stmt = "x = x * %s + %s" % (lit(a), lit(b))
    elif form < 0.75:
        stmt = "x = %s + x * %s" % (lit(b), lit(a))
    else:
        stmt = "x = x * %s - %s" % (lit(a), lit(-b))
    use_for = rng.random() < 0.6
    lv = "i" if use_for else None
    body = rest(lv)
    nested = rng.random() < 0.3
    ind = ""
    if nested:
        lines.append("loops(2):")
        ind = "  "
    lines.append(ind + ("for i in range(%d):" % n if use_for else "loops(%d):" % n))
    lines.append(ind + "  " + stmt)
    for text, bd, _ in body:
        lines.append(ind + "  " + text)
        if bd:
            lines.append(ind + "    " + bd)
    for _ in range(2 if nested else 1):
        for it in range(n):
            if use_for:
                env["i"] = it
            env["x"] = wrap(wrap(env["x"] * a) + b)
            for _, _, f in body:
                f(env)
    lines.append('print>>{x}" "{c}" "{s}" "{y}" "{i}')
    out.append("%d %d %d %d %d" % (env["x"], env["c"], env["s"], env["y"], env["i"]))

src = os.path.join(work, "j%d.es" % seed)
open(src, "w", newline="\n").write("\n".join(lines) + "\n")
exe = os.path.join(work, "j%d.exe" % seed)
r = subprocess.run([ender, "build", src, "-o", exe], capture_output=True)
if r.returncode:
    print("BUILD FAILED", seed, r.stderr.decode(errors="replace")[:300])
    sys.exit(1)
got = subprocess.run([exe], capture_output=True).stdout.decode().replace("\r\n", "\n").split("\n")[:-1]
if got != out:
    print("MISMATCH seed", seed)
    for i, (p, q) in enumerate(zip(out, got)):
        if p != q:
            print("  line", i, "expected", p, "got", q)
            break
    print("  lengths", len(out), len(got))
    sys.exit(1)
print("ok", seed)
