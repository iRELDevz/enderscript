# CONTRIBUTOR

makasih udah mau ikut bantu EnderScript. baca ini dulu sebelum ngirim PR.

## maintainer

- [iRELDevz](https://github.com/iRELDevz): pembuat sekaligus maintainer EnderScript

## aturan main

1. syntax ga boleh berubah. program lama harus tetep jalan sama persis.
2. isi repo cuma kode assembly sama powershell (`build.ps1`). ga ada tooling, ga ada script python, ga ada file build.
3. kode harus yang terbaik: paling cepet, paling hemat, paling kecil. kalo ada cara lebih cepet tapi hasilnya beda, ga diterima.
4. ga ada komentar baru di kode. komentar lama yang udah ada ditulis pake bahasa gaul indonesia.
5. ikutin gaya kode yang udah ada: indent 4 spasi, mnemonic huruf kecil, label lokal pake titik, macro yang sama kayak kode sekitarnya.
6. 1 PR = 1 hal. jangan campur fitur, fix, sama rapih-rapih dalam satu PR.

## sebelum ngirim PR

- build semua arch yang lo ubah:
  ```
  .\build.ps1 -Arch x86
  .\build.ps1 -Arch x64
  .\build.ps1 -Arch arm64
  ```
- pastiin output program sama persis antar arch (x86, x64, arm64), termasuk error runtime sama nomor barisnya.
- kalo PR lo nyentuh codegen atau runtime, bandingin dulu sama C, C++, Zig, Rust, Python pake program yang algoritmanya sama. kalo masih kalah, optimasi lagi sampe menang, baru kirim.
- tulis di deskripsi PR apa yang lo ubah, gimana lo ngetesnya, sama hasil bench sebelum/sesudah kalo ada.

## commit sama PR

- judul commit sama PR pake conventional commits bahasa inggris, contoh `fix: wrong line number on array index error` atau `perf: unroll fill loop on x86`.
- deskripsi PR boleh pake bahasa indonesia santai.
- jangan masukin `Co-Authored-By` atau atribusi tool apapun di commit, PR, maupun contributor.

## lapor bug

buka issue, isinya:
- versi (`ender --version`) sama arch
- program `.es` paling kecil yang bisa ngulang bugnya
- output yang lo harapin vs output yang keluar

kalo nemu celah keamanan, jangan dibuka di issue publik. hubungin maintainer langsung lewat github.

## lisensi

dengan ngirim kontribusi, lo setuju kontribusi lo dilisensiin di bawah Apache License 2.0, sama kayak project ini.
