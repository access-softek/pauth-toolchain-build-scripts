#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

./build-llvm.sh

build_target_libs() {
  ./build-wrapper.sh
  ./build-linux-header.sh
  LIBC_STARTFILE_STAGE=1 ./build-musl.sh
  ./build-compiler-rt.sh
  ./build-musl.sh
  ./build-runtimes.sh
  COMPILER_RT_FULL_BUILD=1 ./build-compiler-rt.sh
}

build_target_libs

export CROSS_TARGET="aarch64-linux-musl"
export TARGET_PREFIX="$OUTPUT_DIR/$CROSS_TARGET/usr"

build_target_libs
