# EnderScript

[Bahasa Indonesia](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [हिन्दी](README.hi.md)

This repository is the original and first repository of the EnderScript project. Other repositories are supporting repositories only and cannot be claimed as the original EnderScript project repository.

## Target

This branch builds the EnderScript compiler for Windows x64. The compiler is written in assembly and produces PE32+ executables directly, without an external assembler or linker.

## Build

Requirements: NASM, GCC (MinGW-w64).

```
.\build.ps1
```

The result is `ender.exe`.

## Usage

```
.\ender.exe check <file.es>
.\ender.exe check --syntax <file.es>
.\ender.exe build <file.es>
.\ender.exe build <file.es> -o <out>
.\ender.exe run <file.es>
.\ender.exe --version
.\ender.exe --help
```

`check` checks syntax, semantics, and types. `build` produces `<file>.exe`. `run` builds the program into the `.ender` folder and runs it.

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
