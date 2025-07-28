#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. "$REPO_ROOT/config"
. ./global-vars

BUILD_DIR="${BUILD_TMP}/compiler-rt-${COMPILER_RT_BUILD}-${CROSS_TARGET}"

COMPILER_RT_INSTALL_PREFIX="$("$INSTALL_DIR/bin/clang" --print-resource-dir)"

cmake \
  -DCMAKE_BUILD_TYPE=$(if_then_else $BUILD_OPTIMIZED_RUNTIMES RelWithDebInfo Debug) \
  -DTOOLCHAIN_BUILD_INSTALL_DIR="$INSTALL_DIR" \
  -DTOOLCHAIN_BUILD_TARGET="$CROSS_TARGET" \
  --toolchain "$CMAKE_DIR/toolchain-file.cmake" \
  -S "$LLVM_SOURCE_DIR/compiler-rt" \
  -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$COMPILER_RT_INSTALL_PREFIX" \
  -C "$CMAKE_DIR/compiler-rt-common.cmake" \
  -C "$CMAKE_DIR/compiler-rt-${COMPILER_RT_BUILD}.cmake"

cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT
