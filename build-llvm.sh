#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

BUILD_DIR=".build/llvm"
if [ ! -d "$BUILD_DIR" ]; then
  mkdir -p $BUILD_DIR && cd $BUILD_DIR
  cmake \
    -S $LLVM_SOURCE_DIR/llvm \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
    -DLLVM_CCACHE_BUILD=ON \
    -DLLVM_CCACHE_DIR="$CCACHE_DIR" \
    -DLLVM_CCACHE_MAXSIZE="30G" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBXML2=FORCE_ON \
    -DLLVM_ENABLE_THREADS=OFF \
    -DLLVM_TARGETS_TO_BUILD="AArch64"
else
    cd "$BUILD_DIR"
fi

cmake --build . --target install -- -j$CPU_COUNT
