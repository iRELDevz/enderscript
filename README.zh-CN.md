# EnderScript

[Bahasa Indonesia](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [हिन्दी](README.hi.md)

本仓库是 EnderScript 项目的原始和最初的仓库。其他仓库仅为辅助仓库，不能被声称为 EnderScript 项目的原始仓库。

## 目标平台

此分支构建适用于 Windows x86 (32-bit) 的 EnderScript 编译器。编译器用汇编语言编写，无需外部汇编器或链接器即可直接生成 PE32 可执行文件。

## 构建

依赖: NASM, GNU ld (MinGW)。

```
.\build.ps1
```

生成 `ender.exe`。

## 用法

```
.\ender.exe check <file.es>
.\ender.exe check --syntax <file.es>
.\ender.exe build <file.es>
.\ender.exe build <file.es> -o <out>
.\ender.exe run <file.es>
.\ender.exe --version
.\ender.exe --help
```

`check` 检查语法、语义和类型。`build` 生成 `<file>.exe`。`run` 将程序构建到 `.ender` 文件夹后运行。

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
