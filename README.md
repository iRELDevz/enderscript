# EnderScript 1.2.1

English · Bahasa Indonesia · 日本語 · 简体中文

<details open>
<summary><b>English</b></summary>

This repository is the original and first repository of the EnderScript project. Other repositories are supporting repositories only and cannot be claimed as the original EnderScript project repository.

EnderScript compiles straight to machine code, with no interpreter, VM, garbage collector, or large runtime. The compiler itself is written entirely in assembly and writes the exe file on its own, so building a program needs no assembler, linker, or other toolchain.

> **Note:** `range(n)` runs from **1 to n inclusive**, unlike Python. `for i in range(3):` gives `i` = 1, 2, 3. Arrays are numbered from 1 too.

## Why EnderScript

### Fast

The compiler applies optimizations aimed at loops and arithmetic. Not every architecture has all of them yet:

| Optimization | x86 | x64 | ARM64 |
|---|---|---|---|
| Constant division without `idiv` | yes | yes | yes |
| Loop counters in registers | yes | yes | yes |
| Branchless conditions | yes | yes | yes |
| Array index check skipped when provably in range | yes | yes | yes |
| Variables promoted to registers in hot loops | yes | yes | - |
| Unsigned division when a value is provably non-negative | yes | yes | - |
| Array fill with `rep stosd` | yes | yes | - |
| Sieve mark loop with one hoisted range check | yes | yes | - |
| Zero count with SSE | yes | yes | - |
| LCG loops run several iterations per pass | yes | yes | - |
| General loop unrolling and SIMD | - | yes | - |
| Loops computed with a closed formula | - | yes | - |

ARM64 currently has only the basic optimizations, so ARM64 programs are slower than x86 and x64.

### Honest numbers

EnderScript wins on the benchmarks below because the compiler has dedicated optimizations for exactly these loop patterns (array fill, sieve, counting, LCG, print/read loops). On ordinary code it is still clearly slower than C, C++, Rust, and Zig. These three programs were never tuned for:

- `gcd`: Euclid's algorithm over every pair from 1 to 3000
- `collatz`: Collatz step counts for 1 to 100000, 20 times
- `matrix`: 200x200 integer matrix multiply with nested loops over arrays, 30 times

Windows 32-bit (ms, fastest run):

| Benchmark | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| gcd | 691.3 | 391.0 | 395.3 | 352.5 |
| collatz | 669.2 | 319.3 | 315.5 | 348.3 |
| matrix | 280.3 | 61.9 | 58.8 | 90.8 |

Windows x64 (ms, fastest run; Python measured once):

| Benchmark | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| gcd | 436.7 | 330.7 | 330.6 | 310.6 | 254.6 | 22900 |
| collatz | 445.6 | 315.7 | 316.9 | 306.9 | 287.2 | 31100 |
| matrix | 238.8 | 58.3 | 57.6 | 59.6 | 56.7 | 39000 |

EnderScript is 1.3 to 4.5 times slower than C here. General code generation (register allocation, instruction selection, array indexing in nested loops) is the next thing to improve.

Benchmarks where the dedicated optimizations apply:

Benchmark results on Windows 32-bit (ms, fastest run, every language produces exactly the same output):

| Benchmark | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| hello | 4.2 | 5.2 | 5.4 | 4.6 |
| lcg | 110.7 | 142.4 | 139.5 | 219.2 |
| fizz | 197.6 | 306.9 | 306.2 | 303.7 |
| modchain | 274.8 | 360.6 | 357.3 | 356.3 |
| sieve | 50.5 | 52.9 | 53.1 | 56.4 |
| print | 20.9 | 95.4 | 102.0 | 23.3 |
| pipe | 30.9 | 243.3 | 1460.2 | 31.4 |

Benchmark results on Windows x64 (ms, fastest run, every language produces exactly the same output):

| Benchmark | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| hello | 3.2 | 3.9 | 3.9 | 4.3 | 3.5 | 16.8 |
| lcg | 151.9 | 177.5 | 176.1 | 175.0 | 172.9 | 30571.9 |
| fizz | 175.7 | 264.8 | 263.3 | 260.5 | 277.1 | 17061.0 |
| modchain | 235.8 | 388.4 | 384.3 | 393.0 | 416.5 | 12392.2 |
| sieve | 50.7 | 51.7 | 51.2 | 51.2 | 53.2 | 2629.8 |
| print | 11.3 | 69.4 | 83.4 | 21.6 | 12.0 | 583.4 |
| pipe | 16.6 | 162.8 | 1081.6 | 34.3 | 20.3 | 352.2 |

C and C++ are built with clang (`zig cc -O2`), Rust with `rustc -C opt-level=3`, and Zig with `-O ReleaseFast`. The source of every benchmark, the exact flags, and a script to rerun them are in [enderscript-bench](https://github.com/iRELDevz/enderscript-bench). ARM64 benchmarks are not available yet.

### Small

- The Windows x64 compiler is only 59 KB, x86 is 61 KB, and ARM64 is 58 KB.
- The program `print>>"halo"` becomes a 3.5 KB exe.

### Easy to remember

- The type is attached to the name: `umur.int = 17`.
- Readable words: `is`, `isnot`, `and`, `or`, `elif`. `==` and `!=` also work.
- Short form: `if a or b is 3:` means `a is 3 or b is 3`.
- `print>>` and `show>>` for output, with values inserted through `{ }`.
- `loops(n):` repeats n times without a variable, and staged loops run several blocks in order.
- No `main`, `import`, or semicolons.

### Safe and clear

- Types are checked before the program runs.
- Error messages give the file, line, and column.
- Int overflow always wraps, and division by zero is reported with its line number.
- Source files saved with a UTF-8 BOM (Notepad, PowerShell 5.1) are accepted.
- `input` has no total size limit. Each line can be up to 65535 bytes.

### Not available yet

Functions and decimal numbers.

## Target

| Folder | Target | Output |
|---|---|---|
| `windows/x86` | Windows x86 (32-bit) | PE32 |
| `windows/x64` | Windows x64 | PE32+ |
| `windows/arm64` | Windows ARM64 | PE32+ ARM64 |

Linux is coming later.

## Download

Get the `ender.exe` for your machine from the [releases](https://github.com/iRELDevz/enderscript/releases) page. Nothing to install. Releases currently ship x86 and x64. ARM64 builds but has not been run on real ARM hardware yet, so it is not released.

## Build it yourself

Requirements:
- x86: NASM, MinGW binutils (`ld`, `dlltool`)
- x64: NASM, GCC MinGW-w64
- ARM64: LLVM (`clang`, `lld-link`, `llvm-dlltool`)

```
.\build.ps1 -Arch x86
.\build.ps1 -Arch x64
.\build.ps1 -Arch arm64
```

The result is at `build\windows-<arch>\ender.exe`.

## Usage

```
ender <file.es>
ender examine <file.es>
ender run <file.es>
ender --version
ender --help
```

`ender <file.es>` builds the program into the `.ender` folder and runs it. `examine` checks syntax, semantics, and types and runs code generation without writing a file. `run` runs the program built earlier in `.ender` without building it again.

## Example program

Save as `main.es`:

```
nama.str = "Ender"
umur.int = 17
aktif.bool = true

print>>"halo "{nama}", umur "{umur}

if umur >= 17 and aktif is true:
  print>>"dewasa"
elif umur > 12:
  print>>"remaja"
else :
  print>>"anak"

jumlah.int = 0
for i in range(5):
  jumlah = jumlah + i
print>>"jumlah "{jumlah}
```

Run it with `ender main.es`. Output:

```
halo Ender, umur 17
dewasa
jumlah 15
```

## Syntax

### Variables

A variable is declared with `name.type = value`. There are three types:

| Type | Contents | Default when empty |
|---|---|---|
| `int` | Signed 32-bit integer, -2147483648 to 2147483647 | `0` |
| `str` | Text up to 65535 bytes | `null` |
| `bool` | `true` or `false` | `false` |

```
a.str = "DATA"
a2.str = 'DATA'
a3.str = `DATA`
b.int = 12
c.int = -7
d.bool = true
z.int =
```

An existing variable is reassigned without writing its type:

```
b = 30
b =
k.int = b
```

`b =` resets `b` to its default value. `k.int = b` copies the value of another variable of the same type. Declaring a variable again with the same type only gives a warning, and the last declaration wins. Declaring it again with a different type is an error.

A variable name starts with a letter or `_`, followed by letters, digits, or `_`, up to 64 characters. Keywords cannot be used as names.

### Printing

| Command | Newline at the end |
|---|---|
| `print>>` | Yes |
| `print.s>>` | Yes, same as `print>>` |
| `show>>` | No |

```
print>>"Hello World"
print.s>>'Hello World'
show>>`Hello World`
print>>10
print>>true
print>>b
print>>"umur : "{b}" tahun"
print>>""
```

- Strings can be written with `"..."`, `'...'`, or `` `...` ``. All three are the same and support the escapes `\n \t \r \0 \\ \" \' \``.
- To combine text and values, write the parts in order and wrap values in `{ }`. `print>>"a" b` is an error; the correct form is `print>>"a"{b}`.
- An empty `str` prints as `null`. An empty line is printed with `print>>""`.

### Arithmetic

```
a.int = 1 + 2 * 3
b.int = (a - 4) * -2
a = a + 1
c.int = a / 2 % 3
print>>"hasil : "{a * b}
```

- Operators `+ - * / %`, unary minus, and parentheses. `* / %` are evaluated before `+ -`.
- All operands must be `int`. Results beyond the 32-bit range wrap around.
- `/` and `%` truncate toward zero: `-10 / 3` is `-3` and `-10 % 3` is `-1`.
- Division by zero found at compile time is an error. If it happens while the program runs, the program prints `runtime error: division by zero on line N` and exits with code 1.
- Decimal numbers are not supported yet.

### if, elif, else

```
if a is "ka":
  print>>"satu"
elif a == "kb" or a == "kc":
  print>>"dua"
else :
  print>>"lain"

if x > 3 and y <= 10:
  print>>"masuk"

if a or b is "Hellowin":
  print>>"salah satu"
```

| Operator | Meaning | Types |
|---|---|---|
| `is`, `==` | equal | int, str, bool |
| `isnot`, `!=` | not equal | int, str, bool |
| `<`, `>`, `<=`, `>=` | comparison | int |
| `and` | both sides are true | conditions |
| `or` | one or both sides are true | conditions |

- `and` binds tighter than `or`. Evaluation stops as soon as the result is known.
- Short form: `x or y is Z` means `x is Z or y is Z`, and `x and y is Z` means `x is Z and y is Z`.
- Strings are compared by content and can be compared with `null`.
- `if`, `elif`, and `else` lines end with `:`. The block body is indented deeper. Any number of spaces works as long as it is the same within one block, and tabs cannot be mixed with spaces.
- `elif` and `else` are written at the same indentation as their `if`, right after the previous block.
- Inside a block, `int` and `bool` variables can only be reassigned if they were declared before the block. Declaring a new `str` inside a block is not allowed.

### Loops

```
for i in range(10):
  print>>i

loops(3):
  print>>"ulang"
```

- `for v in range(n):` runs the block with `v` = 1, 2, up to n. When the loop finishes, `v` holds n. At the top level, `v` is created as an `int` automatically.
- `loops(n):` runs the block n times without a variable.
- `n` is evaluated once at the start. If n ≤ 0, the block does not run.
- Loops and `if` can be nested.

### Staged loops

```
loops(adv,
start.adv
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.adv
)
```

- `loops(name,` opens a staged loop, followed by `start.name`. The loop is closed with `stop.name` and then `)`. `name` is only a label.
- Between `start` and `stop` only `N(` to `)` blocks are allowed. Each block runs N times, in order from the top. The example above prints `halo` 100 times and then `hello` 200 times.
- Block bodies are delimited by parentheses, so indentation is not required.

### break and continue

```
for i in range(100):
  if i is 5:
    break
  print>>i

for j in range(10):
  if j % 2 is 0:
    continue
  print>>j
```

- `break` stops the innermost loop, and `continue` jumps straight to the next iteration. Both work in `for`, `loops`, and `N(` blocks.
- After `break` in a `for` loop, the loop variable holds the value it had when the loop stopped.
- In a staged loop, `break` only stops the running `N(` block. `break.name` stops the whole staged loop `name`.

### takedata

```
loops(adv,
start.adv
3(
print>>adv.takedata
)
2(
print>>"b"{adv.takedata}
break.adv
)
stop.adv
)
```

- `name.takedata` holds the N of the `N(` block that is running in the staged loop `name`. The example above prints `3` three times, then `b2` once before `break.adv`.
- Outside a block, its value is 0.

### Input

```
nama.str = input>>"Siapa namamu? "
umur.int = input>>"Umur: "
print>>"Halo "{nama}", tahun depan umurmu "{umur + 1}
```

- `x.str = input>>"text"` prints the text without a newline, then reads one line from the keyboard or stdin. `x = input>>"text"` reassigns an existing variable, and `x.str = input` reads without a prompt.
- The prompt is written like `show>>`, so it can contain values in `{ }`.
- For an `int` variable, the number is read from the start of the line (spaces and a `-` or `+` sign are allowed). If there is no number, the result is 0.
- An empty line gives `""`. When the input has ended, a `str` gets `null` and an `int` gets 0.
- A `bool` variable cannot be read from input.

### Arrays

```
nilai.int[5] = 10, 20, 30
nama.str[3] = "Andi", "Budi"
aktif.bool[4] = true.all
print>>nilai[1]
print>>"jumlah elemen: "{nilai.len}
nilai[4] = 40
total.int = 0
for i in range(nilai.len):
  total = total + nilai[i]
print>>"total "{total}
nama[3] = input>>"Nama ketiga? "
print>>nama[3]
```

- `name.type[N] = values` declares an array with N elements. N is a whole number from 1 to 1048576 and must be written, so `a.int[] =` is an error.
- Elements are numbered from 1: `nilai[1]` is the first element and `nilai[nilai.len]` is the last.
- Values are separated by commas and fill the array from the first element. Elements without a value get the default of the type (`0`, `null`, or `false`). More values than elements is an error.
- A single value followed by `.all`, such as `true.all`, goes into every element. `aktif.bool[4] = true` only sets the first element.
- `name[index] = value` changes one element, and `name[index] =` resets it to the default. `name[index] = input>>"..."` reads one element of type `int` or `str`.
- An element can be used anywhere a value of its type is allowed: in arithmetic, in conditions, inside `{ }` in `print>>`, and as the value of another variable.
- `name.len` is the number of elements. It is known at compile time.
- An index written as a number is checked by the compiler, for example `index 6 is outside 1..5 of array 'nilai'`. An index computed while the program runs is checked at run time. If it is out of range, the program prints `runtime error: array index out of range on line N` to stderr and exits with code 1.
- Arrays are declared at the top level, not inside `if` or a loop. Declaring the same array again with the same type and size gives a warning and resets every element.
- Inside a `for` loop, an index such as `i` that the compiler can prove is in range is used without the run-time check.

### General rules

- One statement per line. Empty lines are ignored.
- Comments start with `//` and run to the end of the line.
- The program runs from the first line to the last, without a `main` function.
- Keywords: `print show int str bool true false null if elif else is isnot and or for in range loops break continue input`.

### Error messages

The compiler stops at the first error with the format `file:line:col: kind error: message`. Example:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

Warnings do not stop the build and use the format `file:line:col: warning: message`.

## Contributing

Read `CONTRIBUTOR.md` before sending a PR.

## License

Apache License 2.0. See `LICENSE`.

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>Bahasa Indonesia</b></summary>

ini repo asli dan pertama dari project EnderScript. repo lain cuma pendukung, ga bisa ngaku-ngaku jadi repo utama EnderScript.

EnderScript itu bahasa yang langsung di-compile jadi machine code. ga ada interpreter, ga ada VM, ga ada garbage collector, ga ada runtime gede. compilernya sendiri ditulis full pake assembly, terus nulis file exe-nya sendiri juga, jadi pas build program lo ga butuh assembler, linker, atau toolchain lain.

> **catatan:** `range(n)` jalan dari **1 sampe n**, beda sama python. `for i in range(3):` ngasih `i` = 1, 2, 3. array juga mulai dari 1.

## kenapa EnderScript

### kenceng

compilernya punya optimasi khusus buat loop sama aritmetika. belom semua arch punya semuanya:

| optimasi | x86 | x64 | arm64 |
|---|---|---|---|
| bagi konstanta tanpa `idiv` | ada | ada | ada |
| counter loop di register | ada | ada | ada |
| kondisi tanpa cabang | ada | ada | ada |
| cek index array dilewatin kalo kebukti aman | ada | ada | ada |
| variabel di loop panas dipindah ke register | ada | ada | - |
| bagi unsigned kalo nilainya kebukti ga negatif | ada | ada | - |
| isi array pake `rep stosd` | ada | ada | - |
| loop tandain sieve dengan cek batas sekali di depan | ada | ada | - |
| ngitung nol pake SSE | ada | ada | - |
| loop lcg jalan beberapa iterasi sekaligus | ada | ada | - |
| unroll loop umum sama SIMD | - | ada | - |
| loop yang diitung langsung pake rumus | - | ada | - |

arm64 sekarang baru punya optimasi dasar, jadi program arm64 masih lebih lambat dari x86 sama x64.

### angka yang jujur

EnderScript menang di bench bawah karena compilernya punya optimasi khusus buat pola loop itu (isi array, sieve, hitung, lcg, loop print/baca). buat kode biasa, EnderScript masih jelas lebih lambat dari C, C++, Rust, sama Zig. tiga program ini ga pernah di-tuning sama sekali:

- `gcd`: algoritma euclid buat semua pasangan 1 sampe 3000
- `collatz`: ngitung langkah collatz buat 1 sampe 100000, diulang 20 kali
- `matrix`: perkalian matriks int 200x200 pake loop nested di array, diulang 30 kali

windows 32-bit (ms, ambil yang paling cepet):

| bench | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| gcd | 691.3 | 391.0 | 395.3 | 352.5 |
| collatz | 669.2 | 319.3 | 315.5 | 348.3 |
| matrix | 280.3 | 61.9 | 58.8 | 90.8 |

windows x64 (ms, ambil yang paling cepet, python cuma sekali jalan):

| bench | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| gcd | 436.7 | 330.7 | 330.6 | 310.6 | 254.6 | 22900 |
| collatz | 445.6 | 315.7 | 316.9 | 306.9 | 287.2 | 31100 |
| matrix | 238.8 | 58.3 | 57.6 | 59.6 | 56.7 | 39000 |

di sini EnderScript 1.3 sampe 4.5 kali lebih lambat dari C. codegen umum (alokasi register, pemilihan instruksi, index array di loop nested) itu yang bakal dibenerin berikutnya.

bench yang kena optimasi khusus:

hasil bench di windows 32-bit (ms, ambil yang paling cepet, output semua bahasa sama persis):

| bench | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| hello | 4.2 | 5.2 | 5.4 | 4.6 |
| lcg | 110.7 | 142.4 | 139.5 | 219.2 |
| fizz | 197.6 | 306.9 | 306.2 | 303.7 |
| modchain | 274.8 | 360.6 | 357.3 | 356.3 |
| sieve | 50.5 | 52.9 | 53.1 | 56.4 |
| print | 20.9 | 95.4 | 102.0 | 23.3 |
| pipe | 30.9 | 243.3 | 1460.2 | 31.4 |

hasil bench di windows x64 (ms, ambil yang paling cepet, output semua bahasa sama persis):

| bench | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| hello | 3.2 | 3.9 | 3.9 | 4.3 | 3.5 | 16.8 |
| lcg | 151.9 | 177.5 | 176.1 | 175.0 | 172.9 | 30571.9 |
| fizz | 175.7 | 264.8 | 263.3 | 260.5 | 277.1 | 17061.0 |
| modchain | 235.8 | 388.4 | 384.3 | 393.0 | 416.5 | 12392.2 |
| sieve | 50.7 | 51.7 | 51.2 | 51.2 | 53.2 | 2629.8 |
| print | 11.3 | 69.4 | 83.4 | 21.6 | 12.0 | 583.4 |
| pipe | 16.6 | 162.8 | 1081.6 | 34.3 | 20.3 | 352.2 |

C sama C++ di-build pake clang (`zig cc -O2`), Rust pake `rustc -C opt-level=3`, Zig pake `-O ReleaseFast`. source tiap bench, flag lengkap, sama script buat ngulang bench-nya ada di [enderscript-bench](https://github.com/iRELDevz/enderscript-bench). bench arm64 belom ada.

### kecil

- compiler windows x64 cuma 59 KB, x86 61 KB, arm64 58 KB.
- program `print>>"halo"` jadinya exe 3.5 KB.

### gampang diinget

- tipe nempel di nama: `umur.int = 17`.
- pake kata yang kebaca: `is`, `isnot`, `and`, `or`, `elif`. `==` sama `!=` juga bisa.
- bentuk singkat: `if a or b is 3:` artinya `a is 3 or b is 3`.
- `print>>` sama `show>>` buat output, nilai disisipin pake `{ }`.
- `loops(n):` ngulang n kali tanpa variabel, loop bertahap jalanin beberapa blok berurutan.
- ga ada `main`, `import`, atau titik koma.

### aman dan jelas

- tipe dicek sebelum program jalan.
- pesan error ngasih tau file, baris, sama kolomnya.
- int yang overflow selalu wrap, bagi nol dilaporin lengkap sama nomor barisnya.
- file yang disimpen pake BOM UTF-8 (notepad, powershell 5.1) bisa dibaca.
- `input` ga ada batas total ukurannya. satu baris maksimal 65535 byte.

### yang belom ada

fungsi sama bilangan pecahan.

## target

| folder | target | output |
|---|---|---|
| `windows/x86` | windows x86 (32-bit) | PE32 |
| `windows/x64` | windows x64 | PE32+ |
| `windows/arm64` | windows arm64 | PE32+ arm64 |

linux nyusul.

## download

ambil `ender.exe` yang sesuai mesin lo dari halaman [releases](https://github.com/iRELDevz/enderscript/releases), ga perlu install apa-apa. rilis sekarang baru ada x86 sama x64. arm64 udah bisa di-build tapi belom pernah dijalanin di mesin arm beneran, jadi belom dirilis.

## build sendiri

butuhnya:
- x86: NASM, binutils MinGW (`ld`, `dlltool`)
- x64: NASM, GCC MinGW-w64
- arm64: LLVM (`clang`, `lld-link`, `llvm-dlltool`)

```
.\build.ps1 -Arch x86
.\build.ps1 -Arch x64
.\build.ps1 -Arch arm64
```

hasilnya ada di `build\windows-<arch>\ender.exe`.

## cara pake

```
ender <file.es>
ender examine <file.es>
ender run <file.es>
ender --version
ender --help
```

`ender <file.es>` nge-build program ke folder `.ender` terus langsung jalanin. `examine` ngecek sintaks, semantik, tipe, sama ngejalanin code generation tanpa nulis file. `run` jalanin program yang udah di-build sebelumnya di `.ender` tanpa build ulang.

## contoh program

simpen jadi `main.es`:

```
nama.str = "Ender"
umur.int = 17
aktif.bool = true

print>>"halo "{nama}", umur "{umur}

if umur >= 17 and aktif is true:
  print>>"dewasa"
elif umur > 12:
  print>>"remaja"
else :
  print>>"anak"

jumlah.int = 0
for i in range(5):
  jumlah = jumlah + i
print>>"jumlah "{jumlah}
```

jalanin pake `ender main.es`, outputnya:

```
halo Ender, umur 17
dewasa
jumlah 15
```

## Sintaks

### Variabel

Variabel dideklarasikan dengan `nama.tipe = nilai`. Ada tiga tipe:

| Tipe | Isi | Default kalau kosong |
|---|---|---|
| `int` | Integer 32-bit bertanda, -2147483648 sampai 2147483647 | `0` |
| `str` | Teks sampai 65535 byte | `null` |
| `bool` | `true` atau `false` | `false` |

```
a.str = "DATA"
a2.str = 'DATA'
a3.str = `DATA`
b.int = 12
c.int = -7
d.bool = true
z.int =
```

Variabel yang sudah ada diisi ulang tanpa menulis tipenya:

```
b = 30
b =
k.int = b
```

`b =` mengembalikan `b` ke nilai default. `k.int = b` menyalin nilai dari variabel lain yang tipenya sama. Deklarasi ulang dengan tipe yang sama hanya memberi warning, dan deklarasi terakhir yang dipakai. Deklarasi ulang dengan tipe berbeda adalah error.

Nama variabel diawali huruf atau `_`, lalu boleh diikuti huruf, angka, atau `_`, maksimal 64 karakter. Keyword tidak bisa dipakai sebagai nama.

### Menampilkan teks

| Perintah | Baris baru di akhir |
|---|---|
| `print>>` | Ya |
| `print.s>>` | Ya, sama dengan `print>>` |
| `show>>` | Tidak |

```
print>>"Hello World"
print.s>>'Hello World'
show>>`Hello World`
print>>10
print>>true
print>>b
print>>"umur : "{b}" tahun"
print>>""
```

- String boleh ditulis dengan `"..."`, `'...'`, atau `` `...` ``. Ketiganya sama dan mendukung escape `\n \t \r \0 \\ \" \' \``.
- Untuk menggabungkan teks dan nilai, tulis bagian-bagiannya berurutan dan bungkus nilai dengan `{ }`. `print>>"a" b` adalah error, yang benar `print>>"a"{b}`.
- `str` yang kosong dicetak sebagai `null`. Baris kosong dicetak dengan `print>>""`.

### Aritmetika

```
a.int = 1 + 2 * 3
b.int = (a - 4) * -2
a = a + 1
c.int = a / 2 % 3
print>>"hasil : "{a * b}
```

- Operator `+ - * / %`, minus unary, dan kurung. `* / %` dihitung lebih dulu daripada `+ -`.
- Semua operand harus `int`. Hasil yang melewati batas 32-bit akan wrap.
- `/` dan `%` memotong ke arah nol: `-10 / 3` adalah `-3` dan `-10 % 3` adalah `-1`.
- Pembagian dengan nol yang ketahuan saat compile adalah error. Kalau terjadi saat program jalan, program mencetak `runtime error: division by zero on line N` lalu keluar dengan exit code 1.
- Bilangan pecahan belum didukung.

### if, elif, else

```
if a is "ka":
  print>>"satu"
elif a == "kb" or a == "kc":
  print>>"dua"
else :
  print>>"lain"

if x > 3 and y <= 10:
  print>>"masuk"

if a or b is "Hellowin":
  print>>"salah satu"
```

| Operator | Arti | Tipe |
|---|---|---|
| `is`, `==` | sama | int, str, bool |
| `isnot`, `!=` | tidak sama | int, str, bool |
| `<`, `>`, `<=`, `>=` | perbandingan | int |
| `and` | kedua sisi benar | kondisi |
| `or` | salah satu atau kedua sisi benar | kondisi |

- `and` lebih kuat dari `or`. Pengecekan berhenti begitu hasilnya sudah pasti.
- Bentuk singkat: `x or y is Z` artinya `x is Z or y is Z`, dan `x and y is Z` artinya `x is Z and y is Z`.
- Str dibandingkan isinya, dan boleh dibandingkan dengan `null`.
- Baris `if`, `elif`, dan `else` diakhiri `:`. Isi blok ditulis menjorok lebih dalam. Jumlah spasinya bebas asal sama dalam satu blok, dan tab tidak boleh dicampur dengan spasi.
- `elif` dan `else` ditulis sejajar dengan `if` pasangannya, tepat setelah blok sebelumnya.
- Di dalam blok, variabel `int` dan `bool` hanya boleh diisi ulang kalau sudah dideklarasikan sebelum blok. Deklarasi `str` baru di dalam blok tidak boleh.

### Loop

```
for i in range(10):
  print>>i

loops(3):
  print>>"ulang"
```

- `for v in range(n):` menjalankan blok dengan `v` = 1, 2, sampai n. Setelah loop selesai, `v` berisi n. Di tingkat atas, `v` otomatis dibuat sebagai `int`.
- `loops(n):` menjalankan blok n kali tanpa variabel.
- `n` dihitung sekali di awal. Kalau n ≤ 0, blok tidak dijalankan.
- Loop dan `if` boleh bersarang.

### Loop bertahap

```
loops(adv,
start.adv
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.adv
)
```

- `loops(nama,` membuka loop bertahap, lalu diikuti `start.nama`. Loop ditutup dengan `stop.nama` lalu `)`. `nama` hanya label.
- Di antara `start` dan `stop` hanya boleh ada blok `N(` sampai `)`. Setiap blok dijalankan N kali, berurutan dari atas. Contoh di atas mencetak `halo` 100 kali lalu `hello` 200 kali.
- Isi blok dibatasi kurung, jadi tidak wajib menjorok.

### break dan continue

```
for i in range(100):
  if i is 5:
    break
  print>>i

for j in range(10):
  if j % 2 is 0:
    continue
  print>>j
```

- `break` menghentikan loop terdalam, sedangkan `continue` langsung lompat ke putaran berikutnya. Keduanya berlaku untuk `for`, `loops`, dan blok `N(`.
- Setelah `break` di `for`, variabel loop berisi nilai saat loop dihentikan.
- Di loop bertahap, `break` hanya menghentikan blok `N(` yang sedang jalan. `break.nama` menghentikan seluruh loop bertahap `nama`.

### takedata

```
loops(adv,
start.adv
3(
print>>adv.takedata
)
2(
print>>"b"{adv.takedata}
break.adv
)
stop.adv
)
```

- `nama.takedata` berisi N dari blok `N(` yang sedang jalan di loop bertahap `nama`. Contoh di atas mencetak `3` tiga kali, lalu `b2` sekali sebelum `break.adv`.
- Di luar blok, nilainya 0.

### Input

```
nama.str = input>>"Siapa namamu? "
umur.int = input>>"Umur: "
print>>"Halo "{nama}", tahun depan umurmu "{umur + 1}
```

- `x.str = input>>"teks"` mencetak teks tanpa baris baru, lalu membaca satu baris dari keyboard atau stdin. `x = input>>"teks"` mengisi ulang variabel yang sudah ada, dan `x.str = input` membaca tanpa teks.
- Teks pertanyaan ditulis seperti `show>>`, jadi boleh berisi nilai dalam `{ }`.
- Untuk variabel `int`, angka dibaca dari awal baris (spasi dan tanda `-` atau `+` boleh). Kalau tidak ada angka, hasilnya 0.
- Baris kosong menghasilkan `""`. Kalau input sudah habis, `str` berisi `null` dan `int` berisi 0.
- Variabel `bool` tidak bisa diisi dari input.

### Array

```
nilai.int[5] = 10, 20, 30
nama.str[3] = "Andi", "Budi"
aktif.bool[4] = true.all
print>>nilai[1]
print>>"jumlah elemen: "{nilai.len}
nilai[4] = 40
total.int = 0
for i in range(nilai.len):
  total = total + nilai[i]
print>>"total "{total}
nama[3] = input>>"Nama ketiga? "
print>>nama[3]
```

- `nama.tipe[N] = nilai` membuat array berisi N elemen. N adalah bilangan bulat 1 sampai 1048576 dan wajib ditulis, jadi `a.int[] =` adalah error.
- Elemen dinomori mulai dari 1: `nilai[1]` adalah elemen pertama dan `nilai[nilai.len]` elemen terakhir.
- Nilai dipisah koma dan mengisi array mulai dari elemen pertama. Elemen yang tidak diberi nilai berisi default tipenya (`0`, `null`, atau `false`). Nilai yang lebih banyak dari jumlah elemen adalah error.
- Satu nilai yang diikuti `.all`, misalnya `true.all`, mengisi semua elemen. `aktif.bool[4] = true` hanya mengisi elemen pertama.
- `nama[index] = nilai` mengubah satu elemen, dan `nama[index] =` mengembalikannya ke default. `nama[index] = input>>"..."` membaca satu elemen bertipe `int` atau `str`.
- Elemen boleh dipakai di mana pun nilai bertipe sama boleh dipakai: di aritmetika, di kondisi, di dalam `{ }` pada `print>>`, dan sebagai isi variabel lain.
- `nama.len` adalah jumlah elemen. Nilainya sudah diketahui saat compile.
- Index yang ditulis sebagai angka dicek oleh compiler, misalnya `index 6 is outside 1..5 of array 'nilai'`. Index yang dihitung saat program jalan dicek saat program jalan. Kalau di luar batas, program mencetak `runtime error: array index out of range on line N` ke stderr lalu keluar dengan exit code 1.
- Array dideklarasikan di tingkat atas, tidak di dalam `if` atau loop. Deklarasi ulang array yang sama dengan tipe dan ukuran sama memberi warning dan mengosongkan semua elemen.
- Di dalam loop `for`, index seperti `i` yang bisa dibuktikan compiler masih dalam batas dipakai tanpa pengecekan saat program jalan.

### Aturan umum

- Satu statement per baris. Baris kosong diabaikan.
- Komentar diawali `//` sampai akhir baris.
- Program berjalan dari baris pertama sampai terakhir, tanpa fungsi `main`.
- Keyword: `print show int str bool true false null if elif else is isnot and or for in range loops break continue input`.

### Pesan error

Compiler berhenti di error pertama dengan format `file:line:col: jenis error: pesan`. Contoh:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

Warning tidak menghentikan build dan ditulis dengan format `file:line:col: warning: pesan`.

## kontribusi

baca `CONTRIBUTOR.md` dulu sebelum ngirim PR.

## lisensi

Apache License 2.0. liat `LICENSE`.

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>日本語</b></summary>

このリポジトリは EnderScript プロジェクトのオリジナルかつ最初のリポジトリです。他のリポジトリはサポート用のリポジトリにすぎず、EnderScript プロジェクトのオリジナルリポジトリであると主張することはできません。

EnderScript はインタプリタ、VM、ガベージコレクタ、大きなランタイムなしで、直接機械語にコンパイルされます。コンパイラ自体はすべてアセンブリで書かれており、exe ファイルも自分で書き出すため、プログラムのビルドにアセンブラ、リンカ、その他のツールチェーンは不要です。

> **注意:** `range(n)` は Python と違い **1 から n まで** (n を含む) 進みます。`for i in range(3):` では `i` は 1、2、3 になります。配列も 1 から始まります。

## なぜ EnderScript か

### 速い

コンパイラはループと算術に特化した最適化を行います。すべてのアーキテクチャにすべてがあるわけではありません:

| 最適化 | x86 | x64 | ARM64 |
|---|---|---|---|
| `idiv` を使わない定数除算 | あり | あり | あり |
| レジスタに置かれるループカウンタ | あり | あり | あり |
| 分岐のない条件 | あり | あり | あり |
| 範囲内と証明できる配列インデックスのチェック省略 | あり | あり | あり |
| ホットループ内の変数のレジスタ割り当て | あり | あり | - |
| 非負と証明できる値の符号なし除算 | あり | あり | - |
| `rep stosd` による配列の埋め込み | あり | あり | - |
| 範囲チェックを 1 回にまとめた sieve の印付けループ | あり | あり | - |
| SSE によるゼロのカウント | あり | あり | - |
| 複数の反復をまとめて実行する LCG ループ | あり | あり | - |
| 一般的なループ展開と SIMD | - | あり | - |
| 公式で直接計算されるループ | - | あり | - |

ARM64 は現在基本的な最適化のみのため、ARM64 のプログラムは x86 や x64 より遅くなります。

### 正直な数字

以下のベンチマークで EnderScript が勝っているのは、コンパイラがまさにそのループパターン (配列の埋め込み、sieve、カウント、LCG、出力/入力ループ) 専用の最適化を持っているためです。一般的なコードでは、EnderScript はまだ C、C++、Rust、Zig より明らかに遅いです。次の 3 つのプログラムは一切チューニングしていません:

- `gcd`: 1 から 3000 までのすべての組に対するユークリッドの互除法
- `collatz`: 1 から 100000 までのコラッツの手順数を 20 回
- `matrix`: 配列上の多重ループによる 200x200 の整数行列積を 30 回

Windows 32-bit (ms、最速の実行):

| ベンチマーク | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| gcd | 691.3 | 391.0 | 395.3 | 352.5 |
| collatz | 669.2 | 319.3 | 315.5 | 348.3 |
| matrix | 280.3 | 61.9 | 58.8 | 90.8 |

Windows x64 (ms、最速の実行、Python は 1 回のみ計測):

| ベンチマーク | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| gcd | 436.7 | 330.7 | 330.6 | 310.6 | 254.6 | 22900 |
| collatz | 445.6 | 315.7 | 316.9 | 306.9 | 287.2 | 31100 |
| matrix | 238.8 | 58.3 | 57.6 | 59.6 | 56.7 | 39000 |

ここでは EnderScript は C より 1.3 倍から 4.5 倍遅くなります。一般的なコード生成 (レジスタ割り当て、命令選択、多重ループでの配列インデックス) が次の改善対象です。

専用の最適化が効くベンチマーク:

Windows 32-bit でのベンチマーク結果 (ms、最速の実行、すべての言語で出力は完全に同じ):

| ベンチマーク | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| hello | 4.2 | 5.2 | 5.4 | 4.6 |
| lcg | 110.7 | 142.4 | 139.5 | 219.2 |
| fizz | 197.6 | 306.9 | 306.2 | 303.7 |
| modchain | 274.8 | 360.6 | 357.3 | 356.3 |
| sieve | 50.5 | 52.9 | 53.1 | 56.4 |
| print | 20.9 | 95.4 | 102.0 | 23.3 |
| pipe | 30.9 | 243.3 | 1460.2 | 31.4 |

Windows x64 でのベンチマーク結果 (ms、最速の実行、すべての言語で出力は完全に同じ):

| ベンチマーク | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| hello | 3.2 | 3.9 | 3.9 | 4.3 | 3.5 | 16.8 |
| lcg | 151.9 | 177.5 | 176.1 | 175.0 | 172.9 | 30571.9 |
| fizz | 175.7 | 264.8 | 263.3 | 260.5 | 277.1 | 17061.0 |
| modchain | 235.8 | 388.4 | 384.3 | 393.0 | 416.5 | 12392.2 |
| sieve | 50.7 | 51.7 | 51.2 | 51.2 | 53.2 | 2629.8 |
| print | 11.3 | 69.4 | 83.4 | 21.6 | 12.0 | 583.4 |
| pipe | 16.6 | 162.8 | 1081.6 | 34.3 | 20.3 | 352.2 |

C と C++ は clang (`zig cc -O2`)、Rust は `rustc -C opt-level=3`、Zig は `-O ReleaseFast` でビルドしています。各ベンチマークのソース、正確なフラグ、再実行用のスクリプトは [enderscript-bench](https://github.com/iRELDevz/enderscript-bench) にあります。ARM64 のベンチマークはまだありません。

### 小さい

- Windows x64 版コンパイラはわずか 59 KB、x86 版は 61 KB、ARM64 版は 58 KB です。
- `print>>"halo"` のプログラムは 3.5 KB の exe になります。

### 覚えやすい構文

- 型は名前に付けて書きます: `umur.int = 17`。
- 読みやすい単語: `is`、`isnot`、`and`、`or`、`elif`。`==` と `!=` も使えます。
- 省略形: `if a or b is 3:` は `a is 3 or b is 3` を意味します。
- 出力は `print>>` と `show>>` で、値は `{ }` で埋め込みます。
- `loops(n):` は変数なしで n 回繰り返し、段階ループは複数のブロックを順番に実行します。
- `main`、`import`、セミコロンは不要です。

### 安全でわかりやすい

- 型はプログラムの実行前にチェックされます。
- エラーメッセージはファイル、行、列を示します。
- int のオーバーフローは常にラップし、ゼロ除算は行番号付きで報告されます。
- UTF-8 BOM 付きで保存されたファイル (メモ帳、PowerShell 5.1) も読み込めます。
- `input` に合計サイズの上限はありません。1 行は最大 65535 バイトです。

### まだないもの

関数と小数。

## ターゲット

| フォルダ | ターゲット | 出力 |
|---|---|---|
| `windows/x86` | Windows x86 (32-bit) | PE32 |
| `windows/x64` | Windows x64 | PE32+ |
| `windows/arm64` | Windows ARM64 | PE32+ ARM64 |

Linux は後日対応します。

## ダウンロード

[releases](https://github.com/iRELDevz/enderscript/releases) ページから、お使いのマシンに合った `ender.exe` を入手してください。インストールは不要です。リリースは現在 x86 と x64 のみです。ARM64 はビルドできますが、まだ実機の ARM で実行していないためリリースしていません。

## 自分でビルドする

必要なもの:
- x86: NASM、MinGW binutils (`ld`、`dlltool`)
- x64: NASM、GCC MinGW-w64
- ARM64: LLVM (`clang`、`lld-link`、`llvm-dlltool`)

```
.\build.ps1 -Arch x86
.\build.ps1 -Arch x64
.\build.ps1 -Arch arm64
```

結果は `build\windows-<arch>\ender.exe` に生成されます。

## 使い方

```
ender <file.es>
ender examine <file.es>
ender run <file.es>
ender --version
ender --help
```

`ender <file.es>` はプログラムを `.ender` フォルダにビルドしてから実行します。`examine` は構文、意味、型をチェックし、ファイルを書かずにコード生成まで行います。`run` は `.ender` にビルド済みのプログラムを再ビルドせずに実行します。

## サンプルプログラム

`main.es` として保存します:

```
nama.str = "Ender"
umur.int = 17
aktif.bool = true

print>>"halo "{nama}", umur "{umur}

if umur >= 17 and aktif is true:
  print>>"dewasa"
elif umur > 12:
  print>>"remaja"
else :
  print>>"anak"

jumlah.int = 0
for i in range(5):
  jumlah = jumlah + i
print>>"jumlah "{jumlah}
```

`ender main.es` で実行します。出力:

```
halo Ender, umur 17
dewasa
jumlah 15
```

## 構文

### 変数

変数は `名前.型 = 値` で宣言します。型は 3 種類あります:

| 型 | 内容 | 空のときのデフォルト |
|---|---|---|
| `int` | 符号付き 32 ビット整数、-2147483648 から 2147483647 | `0` |
| `str` | 最大 65535 バイトのテキスト | `null` |
| `bool` | `true` または `false` | `false` |

```
a.str = "DATA"
a2.str = 'DATA'
a3.str = `DATA`
b.int = 12
c.int = -7
d.bool = true
z.int =
```

既存の変数は型を書かずに再代入できます:

```
b = 30
b =
k.int = b
```

`b =` は `b` をデフォルト値に戻します。`k.int = b` は同じ型の別の変数の値をコピーします。同じ型で再宣言すると警告のみで、最後の宣言が使われます。異なる型で再宣言するとエラーになります。

変数名は英字または `_` で始まり、その後に英字、数字、`_` を続けられます。最大 64 文字です。キーワードは名前に使えません。

### テキストの表示

| コマンド | 末尾の改行 |
|---|---|
| `print>>` | あり |
| `print.s>>` | あり、`print>>` と同じ |
| `show>>` | なし |

```
print>>"Hello World"
print.s>>'Hello World'
show>>`Hello World`
print>>10
print>>true
print>>b
print>>"umur : "{b}" tahun"
print>>""
```

- 文字列は `"..."`、`'...'`、`` `...` `` のいずれかで書けます。3 つとも同じで、エスケープ `\n \t \r \0 \\ \" \' \`` に対応しています。
- テキストと値を組み合わせるには、各部分を順番に書き、値を `{ }` で囲みます。`print>>"a" b` はエラーで、正しくは `print>>"a"{b}` です。
- 空の `str` は `null` と表示されます。空行は `print>>""` で表示します。

### 算術

```
a.int = 1 + 2 * 3
b.int = (a - 4) * -2
a = a + 1
c.int = a / 2 % 3
print>>"hasil : "{a * b}
```

- 演算子 `+ - * / %`、単項マイナス、括弧が使えます。`* / %` は `+ -` より先に計算されます。
- すべてのオペランドは `int` でなければなりません。32 ビットの範囲を超えた結果はラップアラウンドします。
- `/` と `%` はゼロ方向に切り捨てます: `-10 / 3` は `-3`、`-10 % 3` は `-1` です。
- コンパイル時に判明したゼロ除算はエラーです。実行中に発生した場合、プログラムは `runtime error: division by zero on line N` を表示して終了コード 1 で終了します。
- 小数はまだサポートされていません。

### if、elif、else

```
if a is "ka":
  print>>"satu"
elif a == "kb" or a == "kc":
  print>>"dua"
else :
  print>>"lain"

if x > 3 and y <= 10:
  print>>"masuk"

if a or b is "Hellowin":
  print>>"salah satu"
```

| 演算子 | 意味 | 型 |
|---|---|---|
| `is`、`==` | 等しい | int、str、bool |
| `isnot`、`!=` | 等しくない | int、str、bool |
| `<`、`>`、`<=`、`>=` | 比較 | int |
| `and` | 両辺が真 | 条件 |
| `or` | どちらか一方または両方が真 | 条件 |

- `and` は `or` より優先されます。結果が確定した時点で評価を止めます。
- 省略形: `x or y is Z` は `x is Z or y is Z`、`x and y is Z` は `x is Z and y is Z` を意味します。
- 文字列は内容で比較され、`null` と比較することもできます。
- `if`、`elif`、`else` の行は `:` で終わります。ブロックの中身はより深くインデントします。スペースの数は自由ですが、1 つのブロック内では同じにする必要があり、タブとスペースを混在させることはできません。
- `elif` と `else` は対応する `if` と同じインデントで、直前のブロックのすぐ後に書きます。
- ブロック内では、`int` と `bool` の変数はブロックより前に宣言されている場合のみ再代入できます。ブロック内で新しい `str` を宣言することはできません。

### ループ

```
for i in range(10):
  print>>i

loops(3):
  print>>"ulang"
```

- `for v in range(n):` は `v` = 1、2、…、n でブロックを実行します。ループが終わると `v` は n になります。トップレベルでは `v` は自動的に `int` として作成されます。
- `loops(n):` は変数なしでブロックを n 回実行します。
- `n` は最初に 1 回だけ評価されます。n ≤ 0 の場合、ブロックは実行されません。
- ループと `if` は入れ子にできます。

### 段階ループ

```
loops(adv,
start.adv
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.adv
)
```

- `loops(名前,` で段階ループを開始し、続けて `start.名前` を書きます。ループは `stop.名前` の後に `)` を書いて閉じます。`名前` はラベルにすぎません。
- `start` と `stop` の間には `N(` から `)` までのブロックのみ書けます。各ブロックは上から順に N 回実行されます。上の例は `halo` を 100 回、次に `hello` を 200 回表示します。
- ブロックの中身は括弧で区切られるため、インデントは必須ではありません。

### break と continue

```
for i in range(100):
  if i is 5:
    break
  print>>i

for j in range(10):
  if j % 2 is 0:
    continue
  print>>j
```

- `break` は最も内側のループを終了し、`continue` はすぐに次の繰り返しへ進みます。どちらも `for`、`loops`、`N(` ブロックで使えます。
- `for` で `break` した後、ループ変数は終了した時点の値を保持します。
- 段階ループでは、`break` は実行中の `N(` ブロックだけを終了します。`break.名前` は段階ループ `名前` 全体を終了します。

### takedata

```
loops(adv,
start.adv
3(
print>>adv.takedata
)
2(
print>>"b"{adv.takedata}
break.adv
)
stop.adv
)
```

- `名前.takedata` は段階ループ `名前` で実行中の `N(` ブロックの N を持ちます。上の例は `3` を 3 回表示し、`break.adv` の前に `b2` を 1 回表示します。
- ブロックの外では値は 0 です。

### 入力

```
nama.str = input>>"Siapa namamu? "
umur.int = input>>"Umur: "
print>>"Halo "{nama}", tahun depan umurmu "{umur + 1}
```

- `x.str = input>>"テキスト"` はテキストを改行なしで表示し、キーボードまたは stdin から 1 行読み込みます。`x = input>>"テキスト"` は既存の変数に再代入し、`x.str = input` はプロンプトなしで読み込みます。
- プロンプトは `show>>` と同じ書き方なので、`{ }` で値を含められます。
- `int` 変数では、行の先頭から数値を読み取ります (空白と `-` または `+` の符号は使えます)。数値がなければ結果は 0 です。
- 空行は `""` になります。入力が終わっている場合、`str` は `null`、`int` は 0 になります。
- `bool` 変数は入力から読み込めません。

### 配列

```
nilai.int[5] = 10, 20, 30
nama.str[3] = "Andi", "Budi"
aktif.bool[4] = true.all
print>>nilai[1]
print>>"jumlah elemen: "{nilai.len}
nilai[4] = 40
total.int = 0
for i in range(nilai.len):
  total = total + nilai[i]
print>>"total "{total}
nama[3] = input>>"Nama ketiga? "
print>>nama[3]
```

- `名前.型[N] = 値` は N 個の要素を持つ配列を宣言します。N は 1 から 1048576 までの整数で、必ず書きます。`a.int[] =` はエラーです。
- 要素の番号は 1 から始まります。`nilai[1]` が最初の要素、`nilai[nilai.len]` が最後の要素です。
- 値はカンマで区切り、最初の要素から順に入ります。値のない要素は型のデフォルト (`0`、`null`、`false`) になります。要素数より多い値はエラーです。
- 1 つの値の後に `.all` を付けると (例: `true.all`)、すべての要素にその値が入ります。`aktif.bool[4] = true` は最初の要素だけを設定します。
- `名前[index] = 値` は 1 つの要素を変更し、`名前[index] =` はデフォルトに戻します。`名前[index] = input>>"..."` は `int` または `str` の要素を 1 つ読み込みます。
- 要素は同じ型の値が使える場所ならどこでも使えます。算術、条件、`print>>` の `{ }` の中、別の変数の値などです。
- `名前.len` は要素数です。コンパイル時に決まります。
- 数値で書いた index はコンパイラが検査します。例: `index 6 is outside 1..5 of array 'nilai'`。実行中に計算される index は実行時に検査され、範囲外なら `runtime error: array index out of range on line N` を stderr に出して終了コード 1 で終了します。
- 配列はトップレベルで宣言します。`if` やループの中では宣言できません。同じ型と同じサイズで同じ配列を再宣言すると warning が出て、すべての要素がリセットされます。
- `for` ループの中で `i` のように範囲内だとコンパイラが証明できる index は、実行時の検査なしで使われます。

### 一般的なルール

- 1 行に 1 文です。空行は無視されます。
- コメントは `//` から行末までです。
- プログラムは `main` 関数なしで、最初の行から最後の行まで実行されます。
- キーワード: `print show int str bool true false null if elif else is isnot and or for in range loops break continue input`。

### エラーメッセージ

コンパイラは最初のエラーで停止し、`file:line:col: 種類 error: メッセージ` の形式で表示します。例:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

警告はビルドを止めず、`file:line:col: warning: メッセージ` の形式で表示されます。

## コントリビュート

PR を送る前に `CONTRIBUTOR.md` を読んでください。

## ライセンス

Apache License 2.0。`LICENSE` を参照してください。

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>简体中文</b></summary>

本仓库是 EnderScript 项目的原始和最初的仓库。其他仓库仅为辅助仓库，不能被声称为 EnderScript 项目的原始仓库。

EnderScript 直接编译为机器码，没有解释器、虚拟机、垃圾回收器或庞大的运行时。编译器本身完全用汇编语言编写，并且自己写出 exe 文件，因此构建程序不需要汇编器、链接器或其他工具链。

> **注意:** 与 Python 不同，`range(n)` 从 **1 到 n** (包含 n)。`for i in range(3):` 中 `i` 依次为 1、2、3。数组也从 1 开始编号。

## 为什么选择 EnderScript

### 快

编译器针对循环和算术做了专门优化，但并非所有架构都已具备全部优化:

| 优化 | x86 | x64 | ARM64 |
|---|---|---|---|
| 不使用 `idiv` 的常量除法 | 有 | 有 | 有 |
| 循环计数器保存在寄存器中 | 有 | 有 | 有 |
| 无分支条件 | 有 | 有 | 有 |
| 可证明在范围内时跳过数组下标检查 | 有 | 有 | 有 |
| 热循环中的变量提升到寄存器 | 有 | 有 | - |
| 可证明非负时使用无符号除法 | 有 | 有 | - |
| 用 `rep stosd` 填充数组 | 有 | 有 | - |
| 只做一次范围检查的 sieve 标记循环 | 有 | 有 | - |
| 用 SSE 统计零 | 有 | 有 | - |
| 一次执行多次迭代的 LCG 循环 | 有 | 有 | - |
| 通用循环展开和 SIMD | - | 有 | - |
| 用公式直接计算的循环 | - | 有 | - |

ARM64 目前只有基本优化，因此 ARM64 程序比 x86 和 x64 慢。

### 真实的数字

EnderScript 在下面的基准测试中领先，是因为编译器专门为这些循环模式 (数组填充、sieve、计数、LCG、输出/输入循环) 做了优化。对于普通代码，EnderScript 仍明显慢于 C、C++、Rust 和 Zig。下面三个程序从未针对性调优:

- `gcd`: 对 1 到 3000 的所有数对使用欧几里得算法
- `collatz`: 计算 1 到 100000 的考拉兹步数，重复 20 次
- `matrix`: 用数组上的多重循环做 200x200 整数矩阵乘法，重复 30 次

Windows 32-bit (ms，取最快一次):

| 基准测试 | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| gcd | 691.3 | 391.0 | 395.3 | 352.5 |
| collatz | 669.2 | 319.3 | 315.5 | 348.3 |
| matrix | 280.3 | 61.9 | 58.8 | 90.8 |

Windows x64 (ms，取最快一次，Python 只运行一次):

| 基准测试 | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| gcd | 436.7 | 330.7 | 330.6 | 310.6 | 254.6 | 22900 |
| collatz | 445.6 | 315.7 | 316.9 | 306.9 | 287.2 | 31100 |
| matrix | 238.8 | 58.3 | 57.6 | 59.6 | 56.7 | 39000 |

这里 EnderScript 比 C 慢 1.3 到 4.5 倍。通用代码生成 (寄存器分配、指令选择、多重循环中的数组下标) 是下一步要改进的部分。

专用优化生效的基准测试:

Windows 32-bit 上的基准测试结果 (ms，取最快一次，所有语言的输出完全相同):

| 基准测试 | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| hello | 4.2 | 5.2 | 5.4 | 4.6 |
| lcg | 110.7 | 142.4 | 139.5 | 219.2 |
| fizz | 197.6 | 306.9 | 306.2 | 303.7 |
| modchain | 274.8 | 360.6 | 357.3 | 356.3 |
| sieve | 50.5 | 52.9 | 53.1 | 56.4 |
| print | 20.9 | 95.4 | 102.0 | 23.3 |
| pipe | 30.9 | 243.3 | 1460.2 | 31.4 |

Windows x64 上的基准测试结果 (ms，取最快一次，所有语言的输出完全相同):

| 基准测试 | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| hello | 3.2 | 3.9 | 3.9 | 4.3 | 3.5 | 16.8 |
| lcg | 151.9 | 177.5 | 176.1 | 175.0 | 172.9 | 30571.9 |
| fizz | 175.7 | 264.8 | 263.3 | 260.5 | 277.1 | 17061.0 |
| modchain | 235.8 | 388.4 | 384.3 | 393.0 | 416.5 | 12392.2 |
| sieve | 50.7 | 51.7 | 51.2 | 51.2 | 53.2 | 2629.8 |
| print | 11.3 | 69.4 | 83.4 | 21.6 | 12.0 | 583.4 |
| pipe | 16.6 | 162.8 | 1081.6 | 34.3 | 20.3 | 352.2 |

C 和 C++ 使用 clang (`zig cc -O2`) 构建，Rust 使用 `rustc -C opt-level=3`，Zig 使用 `-O ReleaseFast`。每个基准测试的源代码、完整编译参数和重新运行的脚本都在 [enderscript-bench](https://github.com/iRELDevz/enderscript-bench)。ARM64 的基准测试暂未提供。

### 小

- Windows x64 编译器只有 59 KB，x86 版 61 KB，ARM64 版 58 KB。
- 程序 `print>>"halo"` 生成的 exe 只有 3.5 KB。

### 语法好记

- 类型直接写在名称后面: `umur.int = 17`。
- 易读的单词: `is`、`isnot`、`and`、`or`、`elif`。也可以用 `==` 和 `!=`。
- 简写形式: `if a or b is 3:` 表示 `a is 3 or b is 3`。
- 用 `print>>` 和 `show>>` 输出，用 `{ }` 插入值。
- `loops(n):` 不用变量即可重复 n 次，分段循环可以按顺序运行多个代码块。
- 不需要 `main`、`import` 或分号。

### 安全清晰

- 程序运行前先检查类型。
- 错误信息会给出文件、行和列。
- int 溢出总是回绕，除以零会连同行号一起报告。
- 支持带 UTF-8 BOM 保存的文件 (记事本、PowerShell 5.1)。
- `input` 没有总大小限制，每行最多 65535 字节。

### 尚未支持

函数和小数。

## 目标平台

| 文件夹 | 目标 | 输出 |
|---|---|---|
| `windows/x86` | Windows x86 (32-bit) | PE32 |
| `windows/x64` | Windows x64 | PE32+ |
| `windows/arm64` | Windows ARM64 | PE32+ ARM64 |

Linux 稍后支持。

## 下载

从 [releases](https://github.com/iRELDevz/enderscript/releases) 页面下载适合你机器的 `ender.exe`，无需安装。目前发布版只提供 x86 和 x64。ARM64 可以构建，但尚未在真实 ARM 机器上运行，因此暂不发布。

## 自行构建

依赖:
- x86: NASM、MinGW binutils (`ld`、`dlltool`)
- x64: NASM、GCC MinGW-w64
- ARM64: LLVM (`clang`、`lld-link`、`llvm-dlltool`)

```
.\build.ps1 -Arch x86
.\build.ps1 -Arch x64
.\build.ps1 -Arch arm64
```

生成的文件位于 `build\windows-<arch>\ender.exe`。

## 用法

```
ender <file.es>
ender examine <file.es>
ender run <file.es>
ender --version
ender --help
```

`ender <file.es>` 将程序构建到 `.ender` 文件夹后运行。`examine` 检查语法、语义和类型，并在不写入文件的情况下完成代码生成。`run` 运行之前在 `.ender` 中构建好的程序，不会重新构建。

## 示例程序

保存为 `main.es`:

```
nama.str = "Ender"
umur.int = 17
aktif.bool = true

print>>"halo "{nama}", umur "{umur}

if umur >= 17 and aktif is true:
  print>>"dewasa"
elif umur > 12:
  print>>"remaja"
else :
  print>>"anak"

jumlah.int = 0
for i in range(5):
  jumlah = jumlah + i
print>>"jumlah "{jumlah}
```

用 `ender main.es` 运行。输出:

```
halo Ender, umur 17
dewasa
jumlah 15
```

## 语法

### 变量

变量用 `名称.类型 = 值` 声明。共有三种类型:

| 类型 | 内容 | 为空时的默认值 |
|---|---|---|
| `int` | 有符号 32 位整数，-2147483648 到 2147483647 | `0` |
| `str` | 最多 65535 字节的文本 | `null` |
| `bool` | `true` 或 `false` | `false` |

```
a.str = "DATA"
a2.str = 'DATA'
a3.str = `DATA`
b.int = 12
c.int = -7
d.bool = true
z.int =
```

已有的变量可以不写类型直接重新赋值:

```
b = 30
b =
k.int = b
```

`b =` 将 `b` 恢复为默认值。`k.int = b` 复制另一个同类型变量的值。用相同类型重复声明只会产生警告，并使用最后一次声明。用不同类型重复声明是错误。

变量名以字母或 `_` 开头，后面可以跟字母、数字或 `_`，最长 64 个字符。关键字不能用作名称。

### 输出文本

| 命令 | 末尾换行 |
|---|---|
| `print>>` | 是 |
| `print.s>>` | 是，与 `print>>` 相同 |
| `show>>` | 否 |

```
print>>"Hello World"
print.s>>'Hello World'
show>>`Hello World`
print>>10
print>>true
print>>b
print>>"umur : "{b}" tahun"
print>>""
```

- 字符串可以用 `"..."`、`'...'` 或 `` `...` `` 书写。三者完全相同，并支持转义 `\n \t \r \0 \\ \" \' \``。
- 要组合文本和值，按顺序写出各部分，并用 `{ }` 包裹值。`print>>"a" b` 是错误的，正确写法是 `print>>"a"{b}`。
- 空的 `str` 输出为 `null`。用 `print>>""` 输出空行。

### 算术

```
a.int = 1 + 2 * 3
b.int = (a - 4) * -2
a = a + 1
c.int = a / 2 % 3
print>>"hasil : "{a * b}
```

- 运算符 `+ - * / %`、一元负号和括号。`* / %` 先于 `+ -` 计算。
- 所有操作数必须是 `int`。超出 32 位范围的结果会回绕。
- `/` 和 `%` 向零截断: `-10 / 3` 为 `-3`，`-10 % 3` 为 `-1`。
- 编译时发现的除以零是错误。如果在程序运行时发生，程序会输出 `runtime error: division by zero on line N` 并以退出码 1 结束。
- 暂不支持小数。

### if、elif、else

```
if a is "ka":
  print>>"satu"
elif a == "kb" or a == "kc":
  print>>"dua"
else :
  print>>"lain"

if x > 3 and y <= 10:
  print>>"masuk"

if a or b is "Hellowin":
  print>>"salah satu"
```

| 运算符 | 含义 | 类型 |
|---|---|---|
| `is`、`==` | 等于 | int、str、bool |
| `isnot`、`!=` | 不等于 | int、str、bool |
| `<`、`>`、`<=`、`>=` | 比较 | int |
| `and` | 两边都为真 | 条件 |
| `or` | 一边或两边为真 | 条件 |

- `and` 的优先级高于 `or`。结果一旦确定就停止求值。
- 简写形式: `x or y is Z` 表示 `x is Z or y is Z`，`x and y is Z` 表示 `x is Z and y is Z`。
- 字符串按内容比较，也可以与 `null` 比较。
- `if`、`elif` 和 `else` 行以 `:` 结尾。代码块内容需要更深的缩进。空格数量不限，但同一代码块内必须一致，且不能混用制表符和空格。
- `elif` 和 `else` 与对应的 `if` 对齐，紧接在前一个代码块之后。
- 在代码块内，`int` 和 `bool` 变量只有在代码块之前已声明时才能重新赋值。不能在代码块内声明新的 `str`。

### 循环

```
for i in range(10):
  print>>i

loops(3):
  print>>"ulang"
```

- `for v in range(n):` 以 `v` = 1、2、…、n 运行代码块。循环结束后，`v` 的值为 n。在顶层，`v` 会自动创建为 `int`。
- `loops(n):` 不使用变量，运行代码块 n 次。
- `n` 只在开始时计算一次。如果 n ≤ 0，代码块不会运行。
- 循环和 `if` 可以嵌套。

### 分段循环

```
loops(adv,
start.adv
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.adv
)
```

- `loops(名称,` 开启分段循环，后面接 `start.名称`。循环用 `stop.名称` 加 `)` 关闭。`名称` 只是一个标签。
- `start` 和 `stop` 之间只能有 `N(` 到 `)` 的代码块。每个代码块从上到下依次运行 N 次。上面的例子先输出 `halo` 100 次，再输出 `hello` 200 次。
- 代码块内容由括号界定，因此不要求缩进。

### break 和 continue

```
for i in range(100):
  if i is 5:
    break
  print>>i

for j in range(10):
  if j % 2 is 0:
    continue
  print>>j
```

- `break` 结束最内层的循环，`continue` 直接跳到下一次迭代。两者都可用于 `for`、`loops` 和 `N(` 代码块。
- 在 `for` 中 `break` 之后，循环变量保留循环结束时的值。
- 在分段循环中，`break` 只结束正在运行的 `N(` 代码块。`break.名称` 结束整个分段循环 `名称`。

### takedata

```
loops(adv,
start.adv
3(
print>>adv.takedata
)
2(
print>>"b"{adv.takedata}
break.adv
)
stop.adv
)
```

- `名称.takedata` 是分段循环 `名称` 中正在运行的 `N(` 代码块的 N。上面的例子先输出 `3` 三次，然后在 `break.adv` 之前输出一次 `b2`。
- 在代码块之外，它的值为 0。

### 输入

```
nama.str = input>>"Siapa namamu? "
umur.int = input>>"Umur: "
print>>"Halo "{nama}", tahun depan umurmu "{umur + 1}
```

- `x.str = input>>"文本"` 输出文本 (不换行)，然后从键盘或 stdin 读取一行。`x = input>>"文本"` 给已有变量重新赋值，`x.str = input` 不带提示直接读取。
- 提示的写法与 `show>>` 相同，因此可以用 `{ }` 包含值。
- 对于 `int` 变量，从行首读取数字 (允许空格和 `-` 或 `+` 符号)。如果没有数字，结果为 0。
- 空行得到 `""`。输入结束后，`str` 得到 `null`，`int` 得到 0。
- `bool` 变量不能从输入读取。

### 数组

```
nilai.int[5] = 10, 20, 30
nama.str[3] = "Andi", "Budi"
aktif.bool[4] = true.all
print>>nilai[1]
print>>"jumlah elemen: "{nilai.len}
nilai[4] = 40
total.int = 0
for i in range(nilai.len):
  total = total + nilai[i]
print>>"total "{total}
nama[3] = input>>"Nama ketiga? "
print>>nama[3]
```

- `名称.类型[N] = 值` 声明一个有 N 个元素的数组。N 是 1 到 1048576 的整数，必须写出，所以 `a.int[] =` 是错误。
- 元素从 1 开始编号: `nilai[1]` 是第一个元素，`nilai[nilai.len]` 是最后一个。
- 值用逗号分隔，从第一个元素开始依次填入。没有给值的元素是该类型的默认值 (`0`、`null` 或 `false`)。值比元素多是错误。
- 单个值后面加 `.all` (例如 `true.all`) 会填入所有元素。`aktif.bool[4] = true` 只设置第一个元素。
- `名称[index] = 值` 修改一个元素，`名称[index] =` 把它恢复为默认值。`名称[index] = input>>"..."` 读取一个 `int` 或 `str` 元素。
- 元素可以用在任何允许同类型值的地方: 算术、条件、`print>>` 的 `{ }` 中，以及作为另一个变量的值。
- `名称.len` 是元素个数，在编译时就已确定。
- 写成数字的 index 由编译器检查，例如 `index 6 is outside 1..5 of array 'nilai'`。运行时计算的 index 在运行时检查，越界时程序向 stderr 输出 `runtime error: array index out of range on line N` 并以退出码 1 结束。
- 数组在顶层声明，不能在 `if` 或循环内声明。用相同类型和大小再次声明同一个数组会给出 warning，并重置所有元素。
- 在 `for` 循环中，编译器能证明在范围内的 index (例如 `i`) 不做运行时检查。

### 通用规则

- 每行一条语句。空行会被忽略。
- 注释以 `//` 开头，直到行尾。
- 程序从第一行运行到最后一行，不需要 `main` 函数。
- 关键字: `print show int str bool true false null if elif else is isnot and or for in range loops break continue input`。

### 错误信息

编译器在遇到第一个错误时停止，格式为 `file:line:col: 类别 error: 信息`。例如:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

警告不会中止构建，格式为 `file:line:col: warning: 信息`。

## 贡献

提交 PR 之前请先阅读 `CONTRIBUTOR.md`。

## 许可证

Apache License 2.0。参见 `LICENSE`。

Copyright 2026 iRELDevz

</details>
