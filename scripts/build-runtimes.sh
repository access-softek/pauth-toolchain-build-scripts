#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./common.inc.sh

if [ -d "$TARGET_PREFIX/include/c++" ]; then
  report_fatal_error "ERROR: The destination directory already exists: $TARGET_PREFIX/include/c++"
fi

cmake \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=$(if_then_else $BUILD_OPTIMIZED_RUNTIMES RelWithDebInfo Debug) \
  -DTOOLCHAIN_BUILD_INSTALL_DIR="$INSTALL_DIR" \
  -DTOOLCHAIN_BUILD_TARGET="$CROSS_TARGET" \
  -DCMAKE_INSTALL_PREFIX="$TARGET_PREFIX" \
  --toolchain "$CMAKE_DIR/toolchain-file.cmake" \
  -S "$LLVM_SOURCE_DIR/runtimes" \
  -B "$BUILD_DIR" \
  -C "$CMAKE_DIR/runtimes.cmake"

cmake --build "$BUILD_DIR" --target cxx cxxabi unwind generate-cxx-headers -- -j$CPU_COUNT
cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT
