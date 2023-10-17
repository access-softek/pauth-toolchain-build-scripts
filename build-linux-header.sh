#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

SOURCE_TARBALL=linux-$LINUX_KERNEL_VERSION.tar.xz
SOURCE_DIR=".build"
mkdir -p "$SOURCE_DIR"

if [ ! -f "$SOURCE_DIR/$SOURCE_TARBALL" ]; then
    curl -sSL "https://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v${LINUX_KERNEL_VERSION%%.*}.x/$SOURCE_TARBALL" -o "$SOURCE_DIR/$SOURCE_TARBALL.tmp"
    mv "$SOURCE_DIR/$SOURCE_TARBALL.tmp" "$SOURCE_DIR/$SOURCE_TARBALL"
fi
BUILD_DIR=".build/linux-kernel"
(test -d $BUILD_DIR && rm -rf $BUILD_DIR) || true
mkdir -p $BUILD_DIR
tar -xf "$SOURCE_DIR/$SOURCE_TARBALL" -C $BUILD_DIR --strip 1
cd $BUILD_DIR

mkdir build-$KERNEL_ARCH && cd build-$KERNEL_ARCH
make -C .. O="$(pwd)" ARCH=$KERNEL_ARCH INSTALL_HDR_PATH="$TARGET_PREFIX" headers_install -j$CPU_COUNT

