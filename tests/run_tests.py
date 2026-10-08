import os
import subprocess
import sys

here = os.path.dirname(os.path.abspath(__file__))
compiler = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(here, "ender")
tests = here
out_dir = os.path.join(here, "out")
os.makedirs(out_dir, exist_ok=True)
passed = 0
failed = 0


def run(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return r.returncode, r.stdout.decode(errors="replace"), r.stderr.decode(errors="replace")


def result(label, ok, details=()):
    global passed, failed
    if ok:
        passed += 1
        print("PASS " + label)
    else:
        failed += 1
        print("FAIL " + label)
        for d in details:
            print("    " + d)


def cases(group):
    d = os.path.join(tests, group)
    if not os.path.isdir(d):
        return []
    return sorted(f for f in os.listdir(d) if f.endswith(".es")), d


def read(path):
    with open(path, "rb") as f:
        return f.read().decode().replace("\r\n", "\n")


for group, mode in [("check/ok", "ok"), ("check/err", "err"), ("check/warn", "warn")]:
    found = cases(group)
    if not found:
        continue
    names, d = found
    for name in names:
        base = name[:-3]
        code, out, err = run([compiler, "check", name], d)
        label = group + "/" + base
        if mode == "ok":
            result(label, code == 0 and err == "", ["exit %d" % code, "stderr: " + err.strip()])
        elif mode == "err":
            expect = read(os.path.join(d, base + ".expect")).strip()
            first = err.strip().split("\n")[0] if err.strip() else ""
            result(label, code == 1 and first == expect, ["expected: " + expect, "actual:   " + first, "exit %d" % code])
        else:
            expect = read(os.path.join(d, base + ".expect")).strip()
            result(label, code == 0 and err.strip() == expect, ["expected: " + expect, "actual:   " + err.strip(), "exit %d" % code])

found = cases("run")
if found:
    names, d = found
    for name in names:
        base = name[:-3]
        exe = os.path.join(out_dir, base)
        label = "run/" + base
        code, out, err = run([compiler, "build", name, "-o", exe], d)
        if code != 0:
            result(label, False, ["build exit %d: %s" % (code, err.strip())])
            continue
        code, out, err = run([exe], d)
        expect = read(os.path.join(d, base + ".out"))
        result(label, code == 0 and out == expect, ["expected: %r" % expect, "actual:   %r" % out, "exit %d" % code])

print("%d passed, %d failed" % (passed, failed))
sys.exit(1 if failed else 0)
