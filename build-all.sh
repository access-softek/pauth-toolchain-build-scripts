#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

./build-llvm.sh
./build-wrapper.sh
./build-linux-header.sh
LIBC_STARTFILE_STAGE=1 ./build-musl.sh
./build-compiler-rt.sh
./build-musl.sh
./build-runtimes.sh
COMPILER_RT_FULL_BUILD=1 ./build-compiler-rt.sh
