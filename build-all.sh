#!/usr/bin/env sh
set -xe
cd "$(dirname "$0")"
. ./config
. ./llvm-branch-config

./build-llvm.sh

build_target_libs() {
  export TARGET_PREFIX="$INSTALL_DIR/$CROSS_TARGET/usr"
  ./create-symlinks.sh
  ./build-linux-header.sh
  LIBC_STARTFILE_STAGE=1 ./build-musl.sh
  COMPILER_RT_BUILD=builtins ./build-compiler-rt.sh
  ./build-musl.sh
  ./build-runtimes.sh
  COMPILER_RT_BUILD=full ./build-compiler-rt.sh
}

cat > "$INSTALL_DIR/bin/aarch64-unknown-linux-pauthtest.cfg" <<EOF
--sysroot <CFGDIR>/../aarch64-linux-pauthtest
$EXTRA_FLAGS_PAUTHTEST
EOF
cat > "$INSTALL_DIR/bin/aarch64-unknown-linux-musl.cfg" <<EOF
--sysroot <CFGDIR>/../aarch64-linux-musl
$EXTRA_FLAGS_MUSL
EOF

export CROSS_TARGET="aarch64-linux-pauthtest"
build_target_libs

export CROSS_TARGET="aarch64-linux-musl"
build_target_libs
