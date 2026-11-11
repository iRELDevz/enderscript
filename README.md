# EnderScript 1.2.0

ini repo asli dan pertama dari project EnderScript. repo lain cuma pendukung, ga bisa ngaku-ngaku jadi repo utama EnderScript.

EnderScript itu bahasa yang langsung di-compile jadi machine code. ga ada interpreter, ga ada VM, ga ada garbage collector, ga ada runtime gede. compilernya sendiri ditulis full pake assembly, terus nulis file exe-nya sendiri juga, jadi pas build program lo ga butuh assembler, linker, atau toolchain lain.

## kenapa EnderScript

### kenceng

compilernya punya optimasi khusus buat loop sama aritmetika: bagi pake konstanta tanpa `idiv`, counter loop ditaro di register, kondisi tanpa cabang, SIMD, loop yang bisa diitung langsung pake rumus, sama loop pola tertentu (isi array, sieve, hitung, lcg) yang dikompilasi khusus.

hasil bench di windows 32-bit (ms, ambil yang paling cepet, output semua bahasa sama persis):

| bench | EnderScript | C | C++ | Zig |
|---|---|---|---|---|
| hello | 4.4 | 5.4 | 5.7 | 4.6 |
| lcg | 112.3 | 143.7 | 143.1 | 224.8 |
| fizz | 201.6 | 313.4 | 314.6 | 308.2 |
| modchain | 280.2 | 368.8 | 367.6 | 364.6 |
| sieve | 53.4 | 54.0 | 55.2 | 58.0 |
| print | 23.1 | 100.0 | 107.1 | 24.3 |
| pipe | 33.2 | 252.5 | 1505.1 | 35.0 |

hasil bench di windows x64 (ms, ambil yang paling cepet, output semua bahasa sama persis):

| bench | EnderScript | C | C++ | Rust | Zig | Python |
|---|---|---|---|---|---|---|
| hello | 3.3 | 3.9 | 4.2 | 4.7 | 3.6 | 17.4 |
| lcg | 155.6 | 691.7 | 680.3 | 178.2 | 173.6 | 30928.6 |
| fizz | 186.1 | 577.9 | 579.3 | 264.2 | 278.1 | 16668.5 |
| modchain | 237.1 | 371.9 | 369.0 | 390.2 | 413.4 | 11783.2 |
| sieve | 50.1 | 53.1 | 53.2 | 51.2 | 52.8 | 2551.9 |
| print | 11.2 | 66.7 | 33.6 | 21.6 | 12.0 | 577.4 |
| pipe | 15.9 | 167.3 | 94.7 | 33.8 | 21.5 | 363.1 |

bench arm64 belom ada, nyusul abis dites di mesin arm beneran.

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

ambil `ender.exe` yang sesuai mesin lo dari halaman [releases](https://github.com/iRELDevz/enderscript/releases), ga perlu install apa-apa.

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
