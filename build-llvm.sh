#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

BUILD_DIR="$BUILD_TMP/llvm"

cmake \
  -S $LLVM_SOURCE_DIR/llvm \
  -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DLLVM_CCACHE_DIR="$CCACHE_DIR" \
  -G Ninja \
  -C ./llvm.cmake

cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT
