#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config
export PATH="$OUTPUT_DIR/bin:$PATH"

BUILD_DIR=".build/runtimes"
(test -d $BUILD_DIR && rm -rf $BUILD_DIR) || true
mkdir -p $BUILD_DIR && cd $BUILD_DIR

rm -rf "$TARGET_PREFIX/include/c++" || true

cmake \
  -DTOOLCHAIN_BUILD_OUTPUT_DIR="$OUTPUT_DIR" \
  -DTOOLCHAIN_BUILD_TARGET="$CROSS_TARGET" \
  -DTOOLCHAIN_BUILD_EXTRA_RUNTIME_FLAGS="$RT_EXTRA_FLAGS" \
  --toolchain ../../toolchain-file.cmake \
  -S $LLVM_SOURCE_DIR/runtimes \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
  -DCMAKE_INSTALL_PREFIX="$TARGET_PREFIX" \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DLIBCXX_ENABLE_SHARED=ON \
  -DLIBCXX_ENABLE_STATIC=ON \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=OFF \
  -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_INCLUDE_TESTS=OFF \
  -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
  -DLIBCXXABI_ENABLE_SHARED=ON \
  -DLIBCXXABI_ENABLE_STATIC=ON \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBUNWIND_ENABLE_STATIC=ON \
  -DLIBUNWIND_ENABLE_SHARED=ON \
  -DCMAKE_BUILD_TYPE=Debug \
  -DLIBCXX_HAS_MUSL_LIBC=ON \
  $LIBCXX_CMAKE_FLAGS

cmake --build . --target cxx cxxabi unwind generate-cxx-headers -- -j$CPU_COUNT
cmake --build . --target install -- -j$CPU_COUNT
