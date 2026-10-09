# EnderScript

<details open>
<summary><b>English</b></summary>

This repository is the original and first repository of the EnderScript project. Other repositories are supporting repositories only and cannot be claimed as the original EnderScript project repository.

## Why EnderScript

### Fast

EnderScript programs compile straight to machine code, with no interpreter, VM, garbage collector, or large runtime. The compiler also applies optimizations aimed at loops and arithmetic: constant division without `idiv`, loop counters kept in registers, branchless conditions, SIMD, and loops computed directly with a closed formula.

Benchmark results on Windows x64:

| Workload | EnderScript | Rust | Hand-written assembly |
|---|---|---|---|
| lcg | 345 ms | 531 ms | 1020 ms |
| fizz | 225 ms | 382 ms | - |
| mod7 | 120 ms | 215 ms | - |
| modchain | 259 ms | - | 285 ms |

All four benchmarks are loop and int arithmetic workloads.

### Small

- The Windows x64 compiler is only 47 KB.
- The program `print>>"halo"` becomes a 2.5 KB exe.
- The compiler writes the PE or ELF file itself, so building a program needs no assembler, linker, or other toolchain.

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

### Many platforms

The same syntax and results on Windows and Linux, for x64, x86, and ARM64.

### Not available yet

Functions, arrays, decimal numbers, user input, `break`, and `continue`.

## Target

This branch builds the EnderScript compiler for Linux x86 (32-bit). The compiler is written in assembly and produces ELF32 executables directly, without an external assembler or linker.

## Build

Requirements: NASM, GNU ld.

```
./build.sh
```

The result is `ender`.

## Usage

```
./ender check <file.es>
./ender check --syntax <file.es>
./ender build <file.es>
./ender build <file.es> -o <out>
./ender run <file.es>
./ender --version
./ender --help
```

`check` checks syntax, semantics, and types. `build` produces `<file>`. `run` builds the program into the `.ender` folder and runs it.

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

Run it with `ender run main.es`. Output:

```
halo Ender, umur 17
dewasa
jumlah 10
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

- `for v in range(n):` runs the block with `v` = 0, 1, up to n-1. At the top level, `v` is created as an `int` automatically.
- `loops(n):` runs the block n times without a variable.
- `n` is evaluated once at the start. If n ≤ 0, the block does not run.
- Loops and `if` can be nested.

### Staged loops

```
loops(ins,
start.ins
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.ins
)
```

- `loops(name,` opens a staged loop, followed by `start.name`. The loop is closed with `stop.name` and then `)`. `name` is only a label.
- Between `start` and `stop` only `N(` to `)` blocks are allowed. Each block runs N times, in order from the top. The example above prints `halo` 100 times and then `hello` 200 times.
- Block bodies are delimited by parentheses, so indentation is not required.

### General rules

- One statement per line. Empty lines are ignored.
- Comments start with `//` and run to the end of the line.
- The program runs from the first line to the last, without a `main` function.
- Keywords: `print show int str bool true false null if elif else is isnot and or for in range loops`.

### Error messages

The compiler stops at the first error with the format `file:line:col: kind error: message`. Example:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

Warnings do not stop the build and use the format `file:line:col: warning: message`.

## License

Apache License 2.0. See `LICENSE`.

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>Bahasa Indonesia</b></summary>

Repository ini adalah repository original dan awal dari project EnderScript. Repository lain hanya repository pendukung dan tidak bisa diklaim sebagai repository original project EnderScript.

## Kenapa EnderScript

### Cepat

Program EnderScript dikompilasi langsung ke kode mesin, tanpa interpreter, VM, garbage collector, atau runtime besar. Compiler-nya juga melakukan optimasi khusus untuk loop dan aritmetika: pembagian konstanta tanpa `idiv`, penghitung loop di register, kondisi tanpa lompatan, SIMD, dan loop yang dihitung langsung dengan rumus.

Hasil benchmark di Windows x64:

| Beban | EnderScript | Rust | Assembly tulisan tangan |
|---|---|---|---|
| lcg | 345 ms | 531 ms | 1020 ms |
| fizz | 225 ms | 382 ms | - |
| mod7 | 120 ms | 215 ms | - |
| modchain | 259 ms | - | 285 ms |

Keempat benchmark ini adalah beban loop dan aritmetika int.

### Kecil

- Compiler Windows x64 hanya 47 KB.
- Program `print>>"halo"` menjadi exe 2,5 KB.
- Compiler menulis file PE atau ELF sendiri, jadi build program tidak butuh assembler, linker, atau toolchain lain.

### Sintaks mudah dihafal

- Tipe ditulis menempel pada nama: `umur.int = 17`.
- Kata yang mudah dibaca: `is`, `isnot`, `and`, `or`, `elif`. `==` dan `!=` juga bisa.
- Bentuk singkat: `if a or b is 3:` artinya `a is 3 or b is 3`.
- `print>>` dan `show>>` untuk output, dengan nilai disisipkan lewat `{ }`.
- `loops(n):` untuk mengulang n kali tanpa variabel, dan loop bertahap untuk beberapa blok berurutan.
- Tidak perlu `main`, `import`, atau titik koma.

### Aman dan jelas

- Tipe dicek sebelum program jalan.
- Pesan error menyebut file, baris, dan kolom.
- Overflow int selalu wrap, dan pembagian dengan nol dilaporkan beserta nomor barisnya.

### Banyak platform

Sintaks dan hasil yang sama di Windows dan Linux, untuk x64, x86, dan ARM64.

### Yang belum ada

Fungsi, array, bilangan desimal, input pengguna, `break`, dan `continue` belum tersedia.

## Target

Branch ini membangun compiler EnderScript untuk Linux x86 (32-bit). Compiler ditulis dalam assembly dan langsung menghasilkan file executable ELF32 tanpa assembler atau linker eksternal.

## Build

Kebutuhan: NASM, GNU ld.

```
./build.sh
```

Hasilnya `ender`.

## Pemakaian

```
./ender check <file.es>
./ender check --syntax <file.es>
./ender build <file.es>
./ender build <file.es> -o <out>
./ender run <file.es>
./ender --version
./ender --help
```

`check` memeriksa sintaks, semantik, dan tipe. `build` menghasilkan `<file>`. `run` membangun program ke folder `.ender` lalu menjalankannya.

## Contoh program

Simpan sebagai `main.es`:

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

Lalu jalankan dengan `ender run main.es`. Outputnya:

```
halo Ender, umur 17
dewasa
jumlah 10
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

- `for v in range(n):` menjalankan blok dengan `v` = 0, 1, sampai n-1. Di tingkat atas, `v` otomatis dibuat sebagai `int`.
- `loops(n):` menjalankan blok n kali tanpa variabel.
- `n` dihitung sekali di awal. Kalau n ≤ 0, blok tidak dijalankan.
- Loop dan `if` boleh bersarang.

### Loop bertahap

```
loops(ins,
start.ins
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.ins
)
```

- `loops(nama,` membuka loop bertahap, lalu diikuti `start.nama`. Loop ditutup dengan `stop.nama` lalu `)`. `nama` hanya label.
- Di antara `start` dan `stop` hanya boleh ada blok `N(` sampai `)`. Setiap blok dijalankan N kali, berurutan dari atas. Contoh di atas mencetak `halo` 100 kali lalu `hello` 200 kali.
- Isi blok dibatasi kurung, jadi tidak wajib menjorok.

### Aturan umum

- Satu statement per baris. Baris kosong diabaikan.
- Komentar diawali `//` sampai akhir baris.
- Program berjalan dari baris pertama sampai terakhir, tanpa fungsi `main`.
- Keyword: `print show int str bool true false null if elif else is isnot and or for in range loops`.

### Pesan error

Compiler berhenti di error pertama dengan format `file:line:col: jenis error: pesan`. Contoh:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

Warning tidak menghentikan build dan ditulis dengan format `file:line:col: warning: pesan`.

## Lisensi

Apache License 2.0. Lihat `LICENSE`.

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>日本語</b></summary>

このリポジトリは EnderScript プロジェクトのオリジナルかつ最初のリポジトリです。他のリポジトリはサポート用のリポジトリにすぎず、EnderScript プロジェクトのオリジナルリポジトリであると主張することはできません。

## なぜ EnderScript か

### 速い

EnderScript のプログラムはインタプリタ、VM、ガベージコレクタ、大きなランタイムなしで、直接機械語にコンパイルされます。さらにコンパイラはループと算術に特化した最適化を行います: `idiv` を使わない定数除算、レジスタに置かれるループカウンタ、分岐のない条件、SIMD、そして公式で直接計算されるループです。

Windows x64 でのベンチマーク結果:

| 処理 | EnderScript | Rust | 手書きアセンブリ |
|---|---|---|---|
| lcg | 345 ms | 531 ms | 1020 ms |
| fizz | 225 ms | 382 ms | - |
| mod7 | 120 ms | 215 ms | - |
| modchain | 259 ms | - | 285 ms |

4 つのベンチマークはすべてループと int 算術の処理です。

### 小さい

- Windows x64 版コンパイラはわずか 47 KB です。
- `print>>"halo"` のプログラムは 2.5 KB の exe になります。
- コンパイラが PE または ELF ファイルを自分で書き出すため、プログラムのビルドにアセンブラ、リンカ、その他のツールチェーンは不要です。

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

### 多くのプラットフォーム

Windows と Linux の x64、x86、ARM64 で、同じ構文と同じ結果になります。

### まだないもの

関数、配列、小数、ユーザー入力、`break`、`continue`。

## ターゲット

このブランチは Linux x86 (32-bit) 向けの EnderScript コンパイラをビルドします。コンパイラはアセンブリで書かれており、外部のアセンブラやリンカを使わずに ELF32 実行ファイルを直接生成します。

## ビルド

必要なもの: NASM, GNU ld。

```
./build.sh
```

`ender` が生成されます。

## 使い方

```
./ender check <file.es>
./ender check --syntax <file.es>
./ender build <file.es>
./ender build <file.es> -o <out>
./ender run <file.es>
./ender --version
./ender --help
```

`check` は構文、意味、型をチェックします。`build` は `<file>` を生成します。`run` はプログラムを `.ender` フォルダにビルドしてから実行します。

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

`ender run main.es` で実行します。出力:

```
halo Ender, umur 17
dewasa
jumlah 10
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

- `for v in range(n):` は `v` = 0、1、…、n-1 でブロックを実行します。トップレベルでは `v` は自動的に `int` として作成されます。
- `loops(n):` は変数なしでブロックを n 回実行します。
- `n` は最初に 1 回だけ評価されます。n ≤ 0 の場合、ブロックは実行されません。
- ループと `if` は入れ子にできます。

### 段階ループ

```
loops(ins,
start.ins
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.ins
)
```

- `loops(名前,` で段階ループを開始し、続けて `start.名前` を書きます。ループは `stop.名前` の後に `)` を書いて閉じます。`名前` はラベルにすぎません。
- `start` と `stop` の間には `N(` から `)` までのブロックのみ書けます。各ブロックは上から順に N 回実行されます。上の例は `halo` を 100 回、次に `hello` を 200 回表示します。
- ブロックの中身は括弧で区切られるため、インデントは必須ではありません。

### 一般的なルール

- 1 行に 1 文です。空行は無視されます。
- コメントは `//` から行末までです。
- プログラムは `main` 関数なしで、最初の行から最後の行まで実行されます。
- キーワード: `print show int str bool true false null if elif else is isnot and or for in range loops`。

### エラーメッセージ

コンパイラは最初のエラーで停止し、`file:line:col: 種類 error: メッセージ` の形式で表示します。例:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

警告はビルドを止めず、`file:line:col: warning: メッセージ` の形式で表示されます。

## ライセンス

Apache License 2.0。`LICENSE` を参照してください。

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>简体中文</b></summary>

本仓库是 EnderScript 项目的原始和最初的仓库。其他仓库仅为辅助仓库，不能被声称为 EnderScript 项目的原始仓库。

## 为什么选择 EnderScript

### 快

EnderScript 程序直接编译为机器码，没有解释器、虚拟机、垃圾回收器或庞大的运行时。编译器还针对循环和算术做了专门优化: 不使用 `idiv` 的常量除法、保存在寄存器中的循环计数器、无分支条件、SIMD，以及用公式直接算出结果的循环。

Windows x64 上的基准测试结果:

| 负载 | EnderScript | Rust | 手写汇编 |
|---|---|---|---|
| lcg | 345 ms | 531 ms | 1020 ms |
| fizz | 225 ms | 382 ms | - |
| mod7 | 120 ms | 215 ms | - |
| modchain | 259 ms | - | 285 ms |

这四个基准测试都是循环和 int 算术负载。

### 小

- Windows x64 编译器只有 47 KB。
- 程序 `print>>"halo"` 生成的 exe 只有 2.5 KB。
- 编译器自己写出 PE 或 ELF 文件，因此构建程序不需要汇编器、链接器或其他工具链。

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

### 多平台

在 Windows 和 Linux 的 x64、x86、ARM64 上语法和结果都相同。

### 尚未支持

函数、数组、小数、用户输入、`break` 和 `continue`。

## 目标平台

此分支构建适用于 Linux x86 (32-bit) 的 EnderScript 编译器。编译器用汇编语言编写，无需外部汇编器或链接器即可直接生成 ELF32 可执行文件。

## 构建

依赖: NASM, GNU ld。

```
./build.sh
```

生成 `ender`。

## 用法

```
./ender check <file.es>
./ender check --syntax <file.es>
./ender build <file.es>
./ender build <file.es> -o <out>
./ender run <file.es>
./ender --version
./ender --help
```

`check` 检查语法、语义和类型。`build` 生成 `<file>`。`run` 将程序构建到 `.ender` 文件夹后运行。

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

用 `ender run main.es` 运行。输出:

```
halo Ender, umur 17
dewasa
jumlah 10
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

- `for v in range(n):` 以 `v` = 0、1、…、n-1 运行代码块。在顶层，`v` 会自动创建为 `int`。
- `loops(n):` 不使用变量，运行代码块 n 次。
- `n` 只在开始时计算一次。如果 n ≤ 0，代码块不会运行。
- 循环和 `if` 可以嵌套。

### 分段循环

```
loops(ins,
start.ins
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.ins
)
```

- `loops(名称,` 开启分段循环，后面接 `start.名称`。循环用 `stop.名称` 加 `)` 关闭。`名称` 只是一个标签。
- `start` 和 `stop` 之间只能有 `N(` 到 `)` 的代码块。每个代码块从上到下依次运行 N 次。上面的例子先输出 `halo` 100 次，再输出 `hello` 200 次。
- 代码块内容由括号界定，因此不要求缩进。

### 通用规则

- 每行一条语句。空行会被忽略。
- 注释以 `//` 开头，直到行尾。
- 程序从第一行运行到最后一行，不需要 `main` 函数。
- 关键字: `print show int str bool true false null if elif else is isnot and or for in range loops`。

### 错误信息

编译器在遇到第一个错误时停止，格式为 `file:line:col: 类别 error: 信息`。例如:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

警告不会中止构建，格式为 `file:line:col: warning: 信息`。

## 许可证

Apache License 2.0。参见 `LICENSE`。

Copyright 2026 iRELDevz

</details>

<details>
<summary><b>हिन्दी</b></summary>

यह रिपॉज़िटरी EnderScript प्रोजेक्ट की मूल और पहली रिपॉज़िटरी है। अन्य रिपॉज़िटरी केवल सहायक रिपॉज़िटरी हैं और उन्हें EnderScript प्रोजेक्ट की मूल रिपॉज़िटरी होने का दावा नहीं किया जा सकता।

## EnderScript क्यों

### तेज़

EnderScript प्रोग्राम बिना इंटरप्रेटर, VM, गार्बेज कलेक्टर या बड़े रनटाइम के सीधे मशीन कोड में कंपाइल होते हैं। कंपाइलर लूप और अंकगणित के लिए ख़ास ऑप्टिमाइज़ेशन भी करता है: `idiv` के बिना स्थिरांक से भाग, रजिस्टर में रखे लूप काउंटर, बिना ब्रांच वाली शर्तें, SIMD, और सूत्र से सीधे गणना किए जाने वाले लूप।

Windows x64 पर बेंचमार्क परिणाम:

| कार्य | EnderScript | Rust | हाथ से लिखी असेंबली |
|---|---|---|---|
| lcg | 345 ms | 531 ms | 1020 ms |
| fizz | 225 ms | 382 ms | - |
| mod7 | 120 ms | 215 ms | - |
| modchain | 259 ms | - | 285 ms |

चारों बेंचमार्क लूप और int अंकगणित वाले कार्य हैं।

### छोटा

- Windows x64 कंपाइलर केवल 47 KB का है।
- प्रोग्राम `print>>"halo"` 2.5 KB का exe बनता है।
- कंपाइलर PE या ELF फ़ाइल ख़ुद लिखता है, इसलिए प्रोग्राम बिल्ड करने के लिए असेंबलर, लिंकर या किसी और टूलचेन की ज़रूरत नहीं होती।

### याद रखने में आसान सिंटैक्स

- टाइप नाम के साथ जुड़ा होता है: `umur.int = 17`।
- पढ़ने में आसान शब्द: `is`, `isnot`, `and`, `or`, `elif`। `==` और `!=` भी चलते हैं।
- संक्षिप्त रूप: `if a or b is 3:` का अर्थ `a is 3 or b is 3` है।
- आउटपुट के लिए `print>>` और `show>>`, और मान `{ }` से जोड़े जाते हैं।
- `loops(n):` बिना वेरिएबल के n बार दोहराता है, और चरणबद्ध लूप कई ब्लॉक क्रम से चलाता है।
- `main`, `import` या सेमीकोलन की ज़रूरत नहीं।

### सुरक्षित और स्पष्ट

- प्रोग्राम चलने से पहले टाइप की जाँच होती है।
- त्रुटि संदेश फ़ाइल, लाइन और कॉलम बताते हैं।
- int ओवरफ़्लो हमेशा रैप होता है, और शून्य से भाग लाइन नंबर के साथ बताया जाता है।

### कई प्लेटफ़ॉर्म

Windows और Linux पर x64, x86 और ARM64 के लिए एक जैसा सिंटैक्स और एक जैसे परिणाम।

### अभी उपलब्ध नहीं

फ़ंक्शन, ऐरे, दशमलव संख्याएँ, उपयोगकर्ता इनपुट, `break` और `continue`।

## लक्ष्य

यह ब्रांच Linux x86 (32-bit) के लिए EnderScript कंपाइलर बनाती है। कंपाइलर असेंबली में लिखा गया है और बिना किसी बाहरी असेंबलर या लिंकर के सीधे ELF32 एक्ज़िक्यूटेबल बनाता है।

## बिल्ड

आवश्यकताएँ: NASM, GNU ld।

```
./build.sh
```

परिणाम `ender` है।

## उपयोग

```
./ender check <file.es>
./ender check --syntax <file.es>
./ender build <file.es>
./ender build <file.es> -o <out>
./ender run <file.es>
./ender --version
./ender --help
```

`check` सिंटैक्स, सिमैंटिक्स और टाइप की जाँच करता है। `build` `<file>` बनाता है। `run` प्रोग्राम को `.ender` फ़ोल्डर में बिल्ड करके चलाता है।

## उदाहरण प्रोग्राम

`main.es` के रूप में सहेजें:

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

इसे `ender run main.es` से चलाएँ। आउटपुट:

```
halo Ender, umur 17
dewasa
jumlah 10
```

## सिंटैक्स

### वेरिएबल

वेरिएबल `नाम.टाइप = मान` से घोषित किया जाता है। तीन टाइप हैं:

| टाइप | सामग्री | खाली होने पर डिफ़ॉल्ट |
|---|---|---|
| `int` | साइन वाला 32-बिट पूर्णांक, -2147483648 से 2147483647 | `0` |
| `str` | 65535 बाइट तक का टेक्स्ट | `null` |
| `bool` | `true` या `false` | `false` |

```
a.str = "DATA"
a2.str = 'DATA'
a3.str = `DATA`
b.int = 12
c.int = -7
d.bool = true
z.int =
```

मौजूदा वेरिएबल को टाइप लिखे बिना दोबारा मान दिया जा सकता है:

```
b = 30
b =
k.int = b
```

`b =` `b` को उसके डिफ़ॉल्ट मान पर लौटा देता है। `k.int = b` उसी टाइप के दूसरे वेरिएबल का मान कॉपी करता है। उसी टाइप से दोबारा घोषित करने पर केवल चेतावनी मिलती है और आख़िरी घोषणा मान्य होती है। अलग टाइप से दोबारा घोषित करना त्रुटि है।

वेरिएबल का नाम अक्षर या `_` से शुरू होता है, उसके बाद अक्षर, अंक या `_` आ सकते हैं, अधिकतम 64 अक्षर। कीवर्ड को नाम के रूप में इस्तेमाल नहीं किया जा सकता।

### टेक्स्ट दिखाना

| कमांड | अंत में नई लाइन |
|---|---|
| `print>>` | हाँ |
| `print.s>>` | हाँ, `print>>` के समान |
| `show>>` | नहीं |

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

- स्ट्रिंग `"..."`, `'...'` या `` `...` `` से लिखी जा सकती है। तीनों एक समान हैं और एस्केप `\n \t \r \0 \\ \" \' \`` का समर्थन करते हैं।
- टेक्स्ट और मान जोड़ने के लिए हिस्सों को क्रम से लिखें और मान को `{ }` में रखें। `print>>"a" b` त्रुटि है, सही रूप `print>>"a"{b}` है।
- खाली `str` `null` के रूप में छपता है। खाली लाइन `print>>""` से छपती है।

### अंकगणित

```
a.int = 1 + 2 * 3
b.int = (a - 4) * -2
a = a + 1
c.int = a / 2 % 3
print>>"hasil : "{a * b}
```

- ऑपरेटर `+ - * / %`, यूनरी माइनस और कोष्ठक। `* / %` की गणना `+ -` से पहले होती है।
- सभी ऑपरेंड `int` होने चाहिए। 32-बिट सीमा से बाहर के परिणाम रैप हो जाते हैं।
- `/` और `%` शून्य की ओर काटते हैं: `-10 / 3` का मान `-3` और `-10 % 3` का मान `-1` है।
- कंपाइल के समय पता चला शून्य से भाग त्रुटि है। अगर यह प्रोग्राम चलते समय होता है, तो प्रोग्राम `runtime error: division by zero on line N` छापता है और exit code 1 के साथ बंद होता है।
- दशमलव संख्याएँ अभी समर्थित नहीं हैं।

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

| ऑपरेटर | अर्थ | टाइप |
|---|---|---|
| `is`, `==` | बराबर | int, str, bool |
| `isnot`, `!=` | बराबर नहीं | int, str, bool |
| `<`, `>`, `<=`, `>=` | तुलना | int |
| `and` | दोनों पक्ष सही | शर्तें |
| `or` | एक या दोनों पक्ष सही | शर्तें |

- `and` की प्राथमिकता `or` से अधिक है। परिणाम तय होते ही जाँच रुक जाती है।
- संक्षिप्त रूप: `x or y is Z` का अर्थ `x is Z or y is Z` है, और `x and y is Z` का अर्थ `x is Z and y is Z` है।
- स्ट्रिंग की तुलना उसकी सामग्री से होती है, और उसकी तुलना `null` से भी की जा सकती है।
- `if`, `elif` और `else` की लाइनें `:` पर ख़त्म होती हैं। ब्लॉक की सामग्री ज़्यादा इंडेंट की जाती है। स्पेस की संख्या कुछ भी हो सकती है, बशर्ते एक ब्लॉक में समान रहे, और टैब को स्पेस के साथ नहीं मिलाया जा सकता।
- `elif` और `else` अपने `if` के समान इंडेंट पर, पिछले ब्लॉक के ठीक बाद लिखे जाते हैं।
- ब्लॉक के अंदर `int` और `bool` वेरिएबल को तभी दोबारा मान दिया जा सकता है जब वे ब्लॉक से पहले घोषित हों। ब्लॉक के अंदर नया `str` घोषित नहीं किया जा सकता।

### लूप

```
for i in range(10):
  print>>i

loops(3):
  print>>"ulang"
```

- `for v in range(n):` ब्लॉक को `v` = 0, 1, …, n-1 के साथ चलाता है। शीर्ष स्तर पर `v` अपने-आप `int` के रूप में बन जाता है।
- `loops(n):` बिना वेरिएबल के ब्लॉक को n बार चलाता है।
- `n` की गणना शुरुआत में एक बार होती है। अगर n ≤ 0 है, तो ब्लॉक नहीं चलता।
- लूप और `if` एक-दूसरे के अंदर रखे जा सकते हैं।

### चरणबद्ध लूप

```
loops(ins,
start.ins
100(
print>>"halo"
)
200(
print>>"hello"
)
stop.ins
)
```

- `loops(नाम,` चरणबद्ध लूप खोलता है, उसके बाद `start.नाम` आता है। लूप `stop.नाम` और फिर `)` से बंद होता है। `नाम` केवल एक लेबल है।
- `start` और `stop` के बीच केवल `N(` से `)` तक के ब्लॉक हो सकते हैं। हर ब्लॉक ऊपर से क्रम में N बार चलता है। ऊपर का उदाहरण `halo` 100 बार और फिर `hello` 200 बार छापता है।
- ब्लॉक की सामग्री कोष्ठकों से सीमित होती है, इसलिए इंडेंट ज़रूरी नहीं है।

### सामान्य नियम

- हर लाइन में एक स्टेटमेंट। खाली लाइनें अनदेखी की जाती हैं।
- टिप्पणी `//` से शुरू होकर लाइन के अंत तक चलती है।
- प्रोग्राम पहली लाइन से आख़िरी लाइन तक चलता है, `main` फ़ंक्शन के बिना।
- कीवर्ड: `print show int str bool true false null if elif else is isnot and or for in range loops`।

### त्रुटि संदेश

कंपाइलर पहली त्रुटि पर रुकता है, प्रारूप `file:line:col: प्रकार error: संदेश` के साथ। उदाहरण:

```
main.es:2:1: semantic error: variable 'a' is already declared as an int variable
```

चेतावनियाँ बिल्ड नहीं रोकतीं और `file:line:col: warning: संदेश` प्रारूप में लिखी जाती हैं।

## लाइसेंस

Apache License 2.0। `LICENSE` देखें।

Copyright 2026 iRELDevz

</details>
