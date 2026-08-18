#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"

cmake \
  -S "$LLVM_SOURCE_DIR/llvm" \
  -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DLLVM_CCACHE_DIR="$CCACHE_DIR" \
  -G Ninja \
  -C "$CMAKE_DIR/llvm.cmake"

cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT
