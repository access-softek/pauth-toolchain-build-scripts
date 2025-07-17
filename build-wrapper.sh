#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

cd "$OUTPUT_DIR/bin"

clang_real="$(readlink clang)"
for file in clang clang++ gcc g++ cc c++ as; do
  ln -sf "$clang_real" $CROSS_TARGET-$file
done

for file in addr2line ar ranlib nm objcopy strings strip objdump readelf size; do
  ln -sf llvm-$file $CROSS_TARGET-$file
done

ln -sf lld $CROSS_TARGET-ld
ln -sf llvm-cxxfilt $CROSS_TARGET-c++filt
