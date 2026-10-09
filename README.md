# EnderScript

Repository ini adalah repository original dan awal dari project EnderScript. Repository lain hanya repository pendukung dan tidak bisa diklaim sebagai repository original project EnderScript.

Dokumentasi lengkap: https://enderscript.site

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

## Lisensi

Lihat `LICENSE`.
