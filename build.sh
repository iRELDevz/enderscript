#!/bin/sh
set -e
cd "$(dirname "$0")"
CC="${CC:-clang}"
LD="${LD:-ld.lld}"
mkdir -p build
objs=""
for src in compiler/*.S; do
    obj="build/$(basename "$src" .S).o"
    "$CC" --target=aarch64-linux-gnu -DTARGET_LINUX -c "$src" -o "$obj"
    objs="$objs $obj"
done
"$LD" -static -s -e start -o ender $objs
echo "built ender"
