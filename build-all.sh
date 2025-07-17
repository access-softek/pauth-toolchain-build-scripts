#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

. ./llvm-branch-config
export LLVM_MAJOR_VERSION

./build-llvm.sh

build_target_libs() {
  export TARGET_PREFIX="$INSTALL_DIR/$CROSS_TARGET/usr"
  ./build-wrapper.sh
  ./build-linux-header.sh
  LIBC_STARTFILE_STAGE=1 ./build-musl.sh
  ./build-compiler-rt.sh
  ./build-musl.sh
  ./build-runtimes.sh
  COMPILER_RT_FULL_BUILD=1 ./build-compiler-rt.sh
}

for environment in pauthtest musl; do
cat > $INSTALL_DIR/bin/aarch64-unknown-linux-$environment-clang.cfg <<EOF
--sysroot $INSTALL_DIR/aarch64-linux-$environment
-rtlib=compiler-rt
-fuse-ld=lld
EOF
cat > $INSTALL_DIR/bin/aarch64-unknown-linux-$environment-clang++.cfg <<EOF
--sysroot $INSTALL_DIR/aarch64-linux-$environment
-rtlib=compiler-rt
--driver-mode=g++
-stdlib=libc++
-fuse-ld=lld
EOF
done

export CROSS_TARGET="aarch64-linux-pauthtest"
export RT_EXTRA_FLAGS="$EXTRA_FLAGS_PAUTHTEST"
build_target_libs

export CROSS_TARGET="aarch64-linux-musl"
export RT_EXTRA_FLAGS="$EXTRA_FLAGS_MUSL"
build_target_libs
