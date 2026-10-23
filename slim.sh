#!/bin/bash
# Trim a build-in-container.sh install to what ACT runs, then pack it.  Usage: slim.sh <act4-tools dir> <out.tar.gz>
set -euo pipefail
src=$1; out=$2; tmp=$(mktemp -d); cp -a "$src" "$tmp/act4-tools"; cd "$tmp/act4-tools"
rm -rf spike/include spike/lib/*.a spike/lib/pkgconfig qemu/include qemu/libexec
find qemu/share/qemu -maxdepth 1 -type f ! -name 'opensbi-riscv*' -delete
rm -rf qemu/share/qemu/{firmware,keymaps,dtb,vhost-user} qemu/share/{doc,man,icons,applications}
find . -type f \( -perm -u+x -o -name '*.so' \) -exec sh -c 'file "$1" | grep -q ELF && strip --strip-unneeded "$1"' _ {} \;
cd "$tmp" && tar czf "$out" act4-tools && rm -rf "$tmp"
