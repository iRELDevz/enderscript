import os
import random
import subprocess
import sys

ender = os.path.abspath(sys.argv[1])
seed = int(sys.argv[2])
rng = random.Random(seed)
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "build", "fuzzloop")
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


def group():
    kind = rng.choice(["int", "int", "str", "bool"])
    gen = {"int": int_operand, "str": str_operand, "bool": bool_operand}[kind]
    ops = ["is", "isnot"] + (["<", ">", "<=", ">="] if kind == "int" else [])
    op = rng.choice(ops)
    left = [gen() for _ in range(rng.choice([1, 1, 1, 2, 3]))]
    right = gen()
    shown = "==" if op == "is" and rng.random() < 0.4 else ("!=" if op == "isnot" and rng.random() < 0.4 else op)

    def one(f):
        def ev(e):
            rv = right[1](e)
            lv = f(e)
            if op == "is":
                return lv == rv
            if op == "isnot":
                return lv != rv
            if op == "<=":
                return lv <= rv
            if op == ">=":
                return lv >= rv
            return lv < rv if op == "<" else lv > rv
        return ev
    text, ev = join([(t, one(f)) for t, f in left])
    return text + " " + shown + " " + right[0], ev


def cond():
    gs = [group() for _ in range(rng.choice([1, 1, 2, 3, 4]))]
    return join(gs)


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
        if r < 0.15 and depth < 5:
            text, ev = cond()
            step = rng.choice(["  ", "    ", "\t"])
            sub = block(depth + 1, indent + step)
            elifs = []
            for _ in range(rng.choice([0, 0, 0, 1, 2, 3])):
                et, ee = cond()
                elifs.append((indent + "elif " + et + rng.choice([":", " :"]), ee, block(depth + 1, indent + step)))
            els = block(depth + 1, indent + step) if rng.random() < 0.4 else None
            out.append(("if", indent + "if " + text + rng.choice([":", " :"]), ev, sub, els, indent + rng.choice(["else:", "else :"]), elifs))
        elif r < 0.3 and depth < 4:
            sub = block(depth + 1, indent + rng.choice(["  ", "    ", "\t"]))
            cnt_text, cnt = rng.choice([
                ("3", lambda e: 3),
                ("0", lambda e: 0),
                ("(-2)", lambda e: -2),
                ("2", lambda e: 2),
                ("i % 4", lambda e: e["i"] - int(e["i"] / 4) * 4),
                ("k / 50", lambda e: int(e["k"] / 50)),
            ])
            kind = rng.random()
            if kind < 0.35:
                v = rng.choice(ints)
                out.append(("for", indent + "for %s in range(%s):" % (v, cnt_text), v, cnt, sub))
            elif kind < 0.7:
                out.append(("loops", indent + "loops(%s):" % cnt_text, cnt, sub))
            else:
                name = "g%d" % rng.randint(0, 99)
                step = rng.choice(["", "  ", "\t"])
                inner = indent + step + rng.choice(["", "  ", "    "])
                parts = []
                for _ in range(rng.randint(1, 3)):
                    ct, cf = rng.choice([
                        ("3", lambda e: 3),
                        ("0", lambda e: 0),
                        ("(-2)", lambda e: -2),
                        ("2", lambda e: 2),
                        ("i % 4", lambda e: e["i"] - int(e["i"] / 4) * 4),
                    ])
                    parts.append((indent + step + ct + "(", cf, block(depth + 1, inner), indent + step + ")"))
                out.append(("group", indent + "loops(%s," % name, indent + step + "start." + name, parts, indent + step + "stop." + name, indent + ")"))
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
            for et, _, eb in it[6]:
                lines.append(et)
                render(eb, lines)
            if it[4] is not None:
                lines.append(it[5])
                render(it[4], lines)
        elif it[0] == "for":
            render(it[4], lines)
        elif it[0] == "loops":
            render(it[3], lines)
        elif it[0] == "group":
            lines.append(it[2])
            for head, _, body, close in it[3]:
                lines.append(head)
                render(body, lines)
                lines.append(close)
            lines.append(it[4])
            lines.append(it[5])


steps = [0]


def run(items, e, out):
    for it in items:
        steps[0] += 1
        if steps[0] > 3000000:
            print("skip seed %d (too many steps)" % seed)
            sys.exit(0)
        if len(out) > 300000:
            return
        if it[0] == "if":
            if it[2](e):
                run(it[3], e, out)
            else:
                for _, ee, eb in it[6]:
                    if ee(e):
                        run(eb, e, out)
                        break
                else:
                    if it[4] is not None:
                        run(it[4], e, out)
        elif it[0] == "for":
            n = it[3](e)
            for c in range(n):
                e[it[2]] = c
                run(it[4], e, out)
        elif it[0] == "loops":
            n = it[2](e)
            for _ in range(max(n, 0)):
                run(it[3], e, out)
        elif it[0] == "group":
            for _, cf, body, _ in it[3]:
                for _ in range(max(cf(e), 0)):
                    run(body, e, out)
        elif it[0] == "set":
            e[it[2]] = it[3](e)
        else:
            out.append("%s=%s" % (it[2], show(e[it[2]])))


lines = ['i.int = 3', 'j.int = -7', 'k.int = 100', 's.str = "ka"', 't.str =', 'p.bool = true', 'q.bool = false']
render(prog, lines)
expected = []
run(prog, dict(env), expected)
if len(expected) > 300000:
    print("skip seed %d (output too large)" % seed)
    sys.exit(0)
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
