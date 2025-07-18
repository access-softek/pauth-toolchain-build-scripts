#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

BUILD_DIR=".build/compiler-rt-${COMPILER_RT_BUILD}-${CROSS_TARGET}"

COMPILER_RT_INSTALL_PREFIX="$("$INSTALL_DIR/bin/clang" --print-resource-dir)"

cmake \
  -DTOOLCHAIN_BUILD_INSTALL_DIR="$INSTALL_DIR" \
  -DTOOLCHAIN_BUILD_TARGET="$CROSS_TARGET" \
  -DTOOLCHAIN_BUILD_EXTRA_RUNTIME_FLAGS="$RT_EXTRA_FLAGS" \
  --toolchain ../../toolchain-file.cmake \
  -S $LLVM_SOURCE_DIR/compiler-rt \
  -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$COMPILER_RT_INSTALL_PREFIX" \
  -C ./compiler-rt-common.cmake \
  -C ./compiler-rt-${COMPILER_RT_BUILD}.cmake

cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT

normalized_triple=$("$INSTALL_DIR/bin/$CROSS_TARGET-clang" --print-target-triple)
ln -sfn $CROSS_TARGET "$COMPILER_RT_INSTALL_PREFIX/lib/$normalized_triple"
