#!/usr/bin/env sh
set -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT/..")"

cd "$ROOT"

. ./config
. ./scripts/global-vars

KERNEL_ARCH=arm64
TARBALL_BASENAME="linux-$LINUX_KERNEL_VERSION.tar.xz"
TARBALL_PATH="$SRC_DIR/$TARBALL_BASENAME"

if [ -z "$CROSS_TARGET" ]; then
  targets=$TOOLCHAIN_TARGETS
else
  targets=$CROSS_TARGET
fi

if [ -d "$BUILD_TMP" ]; then
  echo "--- removing $BUILD_TMP ..."
  rm -rf "$BUILD_TMP"
fi

for target in $targets; do
  target_prefx="$INSTALL_DIR/$target/usr" 
  build_dir="$BUILD_TMP/linux-headers-$target"

  echo "+++ processing headers for target: $target -> $target_prefx ..."

  mkdir -p "$build_dir"
  tar -axf "$TARBALL_PATH" -C "$build_dir" --strip 1
  mkdir "$build_dir/build-$KERNEL_ARCH"

  make -C "$build_dir" \
       O="$build_dir/build-$KERNEL_ARCH" \
       ARCH=$KERNEL_ARCH \
       INSTALL_HDR_PATH="$target_prefx" \
       headers_install -j$CPU_COUNT
done
