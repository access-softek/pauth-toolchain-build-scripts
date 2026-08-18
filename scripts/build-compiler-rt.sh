#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./common.inc.sh

COMPILER_RT_INSTALL_PREFIX="$("$INSTALL_DIR/bin/clang" --print-resource-dir)"
normalized_triple="$("$INSTALL_DIR/bin/clang" -target $CROSS_TARGET --print-target-triple)"

# Assertion: COMPILER_RT_INSTALL_PREFIX should be under INSTALL_DIR.
rel_install_prefix="$(realpath --relative-to="$INSTALL_DIR" "$COMPILER_RT_INSTALL_PREFIX")"
if [ "${rel_install_prefix#..}" != "${rel_install_prefix}" ]; then
  # Removing an optional '..' prefix yields a different string - path is relative.
  report_fatal_error \
      "Expected compiler-rt to be installed under $INSTALL_DIR" \
      "The path returned by Clang is $COMPILER_RT_INSTALL_PREFIX"
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

# Provide the run-time libraries to link the test executables.
mkdir -p "${BUILD_DIR}/lib/${normalized_triple}"
ln -sr "${COMPILER_RT_INSTALL_PREFIX}/lib/${normalized_triple}/clang_rt.crtbegin.o" \
       "${COMPILER_RT_INSTALL_PREFIX}/lib/${normalized_triple}/clang_rt.crtend.o" \
       "${COMPILER_RT_INSTALL_PREFIX}/lib/${normalized_triple}/libclang_rt.builtins.a" \
       "${BUILD_DIR}/lib/${normalized_triple}"

cmake --build "$BUILD_DIR" --target install -- -j$CPU_COUNT
