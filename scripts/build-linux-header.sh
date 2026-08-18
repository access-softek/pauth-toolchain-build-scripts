#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./global-vars.inc.sh

KERNEL_ARCH=arm64
TARBALL_PATH="$SRC_DIR/$LINUX_KERNEL_TARBALL_BASENAME"

mkdir "$BUILD_DIR"
tar -axf "$TARBALL_PATH" -C "$BUILD_DIR" --strip 1
mkdir "$BUILD_DIR/build-$KERNEL_ARCH"

make -C "$BUILD_DIR" \
     O="$BUILD_DIR/build-$KERNEL_ARCH" \
     ARCH=$KERNEL_ARCH \
     INSTALL_HDR_PATH="$TARGET_PREFIX" \
     headers_install -j$CPU_COUNT
