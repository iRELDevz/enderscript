import json
import os
import shutil
import statistics
import subprocess
import sys
import time

ender = os.path.abspath(sys.argv[1])
label = sys.argv[2]
langs = sys.argv[3].split(",")
runs = int(os.environ.get("BENCH_RUNS", "5"))
compile_timeout = int(os.environ.get("BENCH_COMPILE_TIMEOUT", "120"))
luajit = os.environ.get("LUAJIT", "luajit")
work = os.path.abspath(os.environ.get("BENCH_DIR", "benchwork"))
os.makedirs(work, exist_ok=True)
win = os.name == "nt"
exe = ".exe" if win else ""
N = int(os.environ.get("BENCH_N", "2000"))
NL = chr(92) + "n"


def write(name, text):
    with open(os.path.join(work, name), "w", newline="\n") as f:
        f.write(text)


def sources():
    write("hello.es", 'print>>"Hello World"\n')
    write("hello.c", '#include <stdio.h>\nint main(void){puts("Hello World");return 0;}\n')
    write("hello.cpp", '#include <iostream>\nint main(){std::cout<<"Hello World' + NL + '";return 0;}\n')
    write("hello.rs", 'fn main(){println!("Hello World");}\n')
    write("hello.py", 'print("Hello World")\n')
    write("hello.js", 'console.log("Hello World")\n')
    write("hello.lua", 'io.write("Hello World' + NL + '")\n')

    write("print.es", 'a.int = 12345\nb.str = "DATA"\nc.bool = true\n' + 'print>>"n="{a}" s="{b}" b="{c}\n' * N)
    write("print.c", '#include <stdio.h>\nint main(void){int a=12345;const char*b="DATA";int c=1;\n'
          + ('printf("n=%d s=%s b=%s' + NL + '",a,b,c?"true":"false");\n') * N + 'return 0;}\n')
    write("print.cpp", '#include <iostream>\nint main(){std::ios::sync_with_stdio(false);int a=12345;const char*b="DATA";bool c=true;\n'
          + ('std::cout<<"n="<<a<<" s="<<b<<" b="<<(c?"true":"false")<<"' + NL + '";\n') * N + 'return 0;}\n')
    write("print.rs", 'use std::io::Write;\nfn main(){let a=12345;let b="DATA";let c=true;let o=std::io::stdout();let mut o=std::io::BufWriter::new(o.lock());\n'
          + ('writeln!(o,"n={} s={} b={}",a,b,c).unwrap();\n') * N + '}\n')
    write("print.py", 'a=12345\nb="DATA"\nc=True\n' + 'print(f"n={a} s={b} b={str(c).lower()}")\n' * N)
    write("print.js", 'const a=12345,b="DATA",c=true;\n' + 'console.log(`n=${a} s=${b} b=${c}`);\n' * N)
    write("print.lua", 'local a=12345 local b="DATA" local c=true\n' + ('io.write("n=",a," s=",b," b=",tostring(c),"' + NL + '")\n') * N)

    half = N // 2
    write("arith.es", "x.int = 1\ny.int = 7\n" + "x = (x * 31 + y) % 1000003\ny = y + x / 7 - 3\n" * half + 'print>>{x}" "{y}\n')
    write("arith.c", "#include <stdio.h>\nint main(void){int x=1,y=7;\n" + "x=(x*31+y)%1000003;y=y+x/7-3;\n" * half + 'printf("%d %d' + NL + '",x,y);return 0;}\n')
    write("arith.cpp", "#include <cstdio>\nint main(){int x=1,y=7;\n" + "x=(x*31+y)%1000003;y=y+x/7-3;\n" * half + 'std::printf("%d %d' + NL + '",x,y);return 0;}\n')
    write("arith.rs", "fn main(){let mut x:i32=1;let mut y:i32=7;\n" + "x=(x*31+y)%1000003;y=y+x/7-3;\n" * half + 'println!("{} {}",x,y);}\n')
    write("arith.py", "x=1\ny=7\n" + "x=(x*31+y)%1000003\ny=y+x//7-3\n" * half + "print(x,y)\n")
    write("arith.js", "let x=1,y=7;\n" + "x=(x*31+y)%1000003;y=y+Math.trunc(x/7)-3;\n" * half + 'console.log(x+" "+y);\n')
    write("arith.lua", "local x=1 local y=7\n" + "x=(x*31+y)%1000003 y=y+math.floor(x/7)-3\n" * half + 'io.write(x," ",y,"' + NL + '")\n')


def timed(cmd, timeout=None):
    t = time.perf_counter()
    r = subprocess.run(cmd, cwd=work, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    return time.perf_counter() - t, r


def median_ms(cmd, n):
    timed(cmd)
    return statistics.median(timed(cmd)[0] for _ in range(n)) * 1000


def builder(lang, prog):
    out = os.path.join(work, "%s_%s%s" % (prog, lang, exe))
    src = os.path.join(work, prog + "." + {"es": "es", "c": "c", "cpp": "cpp", "rust": "rs"}[lang])
    if lang == "es":
        return [ender, "build", src, "-o", out], out
    if lang == "c":
        return ["gcc", "-O2", "-s", "-o", out, src], out
    if lang == "cpp":
        return ["g++", "-O2", "-s"] + (["-static"] if win else []) + ["-o", out, src], out
    return ["rustc", "-O", "-C", "strip=symbols", "-o", out, src], out


def runner(lang, prog):
    src = os.path.join(work, prog + "." + {"python": "py", "node": "js", "luajit": "lua"}[lang])
    tool = {"python": sys.executable, "node": shutil.which("node") or "node", "luajit": luajit}[lang]
    return [tool, src]


sources()
results = {"label": label, "langs": {}}
for lang in langs:
    entry = {}
    for prog in ["hello", "print", "arith"]:
        rec = {}
        try:
            if lang in ("es", "c", "cpp", "rust"):
                cmd, out = builder(lang, prog)
                if lang == "es":
                    rec["compile_ms"] = median_ms(cmd, 5)
                else:
                    t, r = timed(cmd, compile_timeout)
                    if r.returncode != 0:
                        raise RuntimeError(r.stderr.decode(errors="replace")[:300])
                    rec["compile_ms"] = t * 1000
                rec["size"] = os.path.getsize(out)
                run_cmd = [out]
            else:
                run_cmd = runner(lang, prog)
            _, r = timed(run_cmd)
            rec["output"] = r.stdout.decode(errors="replace").replace("\r\n", "\n")
            rec["run_ms"] = median_ms(run_cmd, runs)
        except subprocess.TimeoutExpired:
            rec["error"] = "compile timeout"
        except Exception as e:
            rec["error"] = str(e)[:300]
        entry[prog] = rec
        print(label, lang, prog, {k: (round(v, 2) if isinstance(v, float) else v) for k, v in rec.items() if k != "output"}, flush=True)
    results["langs"][lang] = entry

ref = results["langs"].get("es", {})
for lang, entry in results["langs"].items():
    for prog, rec in entry.items():
        if "output" in rec and "output" in ref.get(prog, {}):
            rec["same_output_as_es"] = rec["output"] == ref[prog]["output"]
        rec.pop("output", None)
with open(os.path.join(work, "result_%s.json" % label), "w") as f:
    json.dump(results, f, indent=1)
print("saved", os.path.join(work, "result_%s.json" % label))
