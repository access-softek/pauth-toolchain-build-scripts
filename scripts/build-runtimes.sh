#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. "$REPO_ROOT/config"
. ./global-vars

BUILD_DIR="$BUILD_TMP/runtimes-${CROSS_TARGET}"

rm -rf "$TARGET_PREFIX/include/c++" || true

cmake \
  -DTOOLCHAIN_BUILD_INSTALL_DIR="$INSTALL_DIR" \
  -DTOOLCHAIN_BUILD_TARGET="$CROSS_TARGET" \
  -DCMAKE_INSTALL_PREFIX="$TARGET_PREFIX" \
  --toolchain "$CMAKE_CACHES_DIR/toolchain-file.cmake" \
  -S "$LLVM_SOURCE_DIR/runtimes" \
  -B "$BUILD_DIR" \
  -C "$CMAKE_CACHES_DIR/runtimes.cmake"

cmake --build "$BUILD_DIR" --target cxx cxxabi unwind generate-cxx-headers -- -j$CPU_COUNT
cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT
