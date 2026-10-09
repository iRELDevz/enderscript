# EnderScript

[Bahasa Indonesia](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [हिन्दी](README.hi.md)

このリポジトリは EnderScript プロジェクトのオリジナルかつ最初のリポジトリです。他のリポジトリはサポート用のリポジトリにすぎず、EnderScript プロジェクトのオリジナルリポジトリであると主張することはできません。

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
