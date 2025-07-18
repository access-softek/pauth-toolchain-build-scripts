#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

KERNEL_ARCH=arm64
SOURCE_TARBALL=linux-$LINUX_KERNEL_VERSION.tar.xz
SOURCE_DIR="$BUILD_TMP"
BUILD_DIR="$BUILD_TMP/linux-headers-${CROSS_TARGET}"

if [ ! -f "$SOURCE_DIR/$SOURCE_TARBALL" ] && [ -f "/src/$SOURCE_TARBALL" ]; then
    cp "/src/$SOURCE_TARBALL" "$SOURCE_DIR/$SOURCE_TARBALL"
elif [ ! -f "$SOURCE_DIR/$SOURCE_TARBALL" ]; then
    curl -sSL "https://cdn.kernel.org/pub/linux/kernel/v${LINUX_KERNEL_VERSION%%.*}.x/$SOURCE_TARBALL" -o "$SOURCE_DIR/$SOURCE_TARBALL.tmp"
    mv "$SOURCE_DIR/$SOURCE_TARBALL.tmp" "$SOURCE_DIR/$SOURCE_TARBALL"
fi

mkdir "$BUILD_DIR"
tar -xf "$SOURCE_DIR/$SOURCE_TARBALL" -C $BUILD_DIR --strip 1
mkdir "$BUILD_DIR/build-$KERNEL_ARCH"

make -C "$BUILD_DIR" \
     O="$BUILD_DIR/build-$KERNEL_ARCH" \
     ARCH=$KERNEL_ARCH \
     INSTALL_HDR_PATH="$TARGET_PREFIX" \
     headers_install -j$CPU_COUNT

