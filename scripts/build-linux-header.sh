#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. "$REPO_ROOT/config"
. ./global-vars

KERNEL_ARCH=arm64
TARBALL_BASENAME="linux-$LINUX_KERNEL_VERSION.tar.xz"
TARBALL_PATH="$SRC_DIR/$TARBALL_BASENAME"

BUILD_DIR="$BUILD_TMP/linux-headers-${CROSS_TARGET}"

mkdir "$BUILD_DIR"
tar -axf "$TARBALL_PATH" -C "$BUILD_DIR" --strip 1
mkdir "$BUILD_DIR/build-$KERNEL_ARCH"

make -C "$BUILD_DIR" \
     O="$BUILD_DIR/build-$KERNEL_ARCH" \
     ARCH=$KERNEL_ARCH \
     INSTALL_HDR_PATH="$TARGET_PREFIX" \
     headers_install -j$CPU_COUNT
