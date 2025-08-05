#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. "$REPO_ROOT/config"
. ./global-vars

COMPILER_RT_INSTALL_PREFIX="$("$INSTALL_DIR/bin/clang" --print-resource-dir)"

# Assertion: COMPILER_RT_INSTALL_PREFIX should be under INSTALL_DIR.
rel_install_prefix="$(realpath --relative-to="$INSTALL_DIR" "$COMPILER_RT_INSTALL_PREFIX")"
if [ "${rel_install_prefix#..}" != "${rel_install_prefix}" ]; then
  # Removing an optional '..' prefix yields a different string - path is relative.
  echo "Expected compiler-rt to be installed under $INSTALL_DIR" 1>&2
  echo "The path returned by Clang is $COMPILER_RT_INSTALL_PREFIX" 1>&2
  exit 1
fi

cmake \
  -G Ninja \
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
