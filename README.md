# EnderScript

Repository ini adalah repository original dan awal dari project EnderScript. Repository lain hanya repository pendukung dan tidak bisa diklaim sebagai repository original project EnderScript.

Dokumentasi lengkap: https://enderscript.site

## Target

Branch ini membangun compiler EnderScript untuk Windows x86 (32-bit). Compiler ditulis dalam assembly dan langsung menghasilkan file executable PE32 tanpa assembler atau linker eksternal.

## Build

Kebutuhan: NASM dan GNU ld (MinGW).

```
.\build.ps1
```

Hasilnya `ender.exe`.

## Pemakaian

```
.\ender.exe check <file.es>
.\ender.exe check --syntax <file.es>
.\ender.exe build <file.es>
.\ender.exe build <file.es> -o <out>
.\ender.exe run <file.es>
.\ender.exe --version
.\ender.exe --help
```

`check` memeriksa sintaks, semantik, dan tipe. `build` menghasilkan `<file>.exe`. `run` membangun program ke folder `.ender` lalu menjalankannya.

## Lisensi

Lihat `LICENSE`.
