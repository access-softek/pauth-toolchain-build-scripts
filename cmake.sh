#!/usr/bin/env sh
set -e
PRE_PWD="$(pwd)"
cd "$(dirname "$0")"
. ./config
cd "$PRE_PWD"

TARGET=$1
AR="$TARGET-ar"
LLVM_TARGET_TRIPLE=$TARGET
shift

cmake \
  -D CMAKE_SYSTEM_NAME=Linux \
  -D CMAKE_C_COMPILER="$OUTPUT_DIR/bin/$TARGET-clang" \
  -D CMAKE_CXX_COMPILER="$OUTPUT_DIR/bin/$TARGET-clang++"  \
  -D CMAKE_AR="$OUTPUT_DIR/bin/$AR" \
  -D CMAKE_RANLIB="$OUTPUT_DIR/bin/$TARGET-ranlib" \
  -D CMAKE_STRIP="$OUTPUT_DIR/bin/$TARGET-strip" \
  -D CMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
  "$@"
