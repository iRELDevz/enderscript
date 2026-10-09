# EnderScript

Repository ini adalah repository original dan awal dari project EnderScript. Repository lain hanya repository pendukung dan tidak bisa diklaim sebagai repository original project EnderScript.

## Target

Branch ini membangun compiler EnderScript untuk Linux x86 (32-bit). Compiler ditulis dalam assembly dan langsung menghasilkan file executable ELF32 tanpa assembler atau linker eksternal.

## Build

Kebutuhan: NASM dan GNU ld.

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
