#!/bin/sh
set -e
cd "$(dirname "$0")"
mkdir -p build
objs=""
for src in compiler/*.asm; do
    obj="build/$(basename "$src" .asm).o"
    nasm -f elf32 -I compiler/inc/ -o "$obj" "$src"
    objs="$objs $obj"
done
ld -m elf_i386 -s -static -e start -o ender $objs
echo "built ender"
