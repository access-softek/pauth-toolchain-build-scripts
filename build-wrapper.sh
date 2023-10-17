#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

cp toolchain-wrapper/python-backend/* "$OUTPUT_DIR/bin"
${HOST_CC:-cc} -O2 $HOST_CFLAGS $HOST_LDFLAGS toolchain-wrapper/native-runner/toolchain-wrapper.c -o "$OUTPUT_DIR/bin/toolchain-wrapper"

cd "$OUTPUT_DIR/bin"
for file in clang clang++ gcc g++ cc c++ as; do
  ln -sf toolchain-wrapper $CROSS_TARGET-$file
done
for file in addr2line ar ranlib nm objcopy strings strip objdump readelf size; do
  ln -sf llvm-$file $CROSS_TARGET-$file
done
ln -sf toolchain-wrapper $CROSS_TARGET-ld
ln -sf llvm-cxxfilt $CROSS_TARGET-c++filt
