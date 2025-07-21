#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. "$REPO_ROOT/config"
. ./global-vars

BUILD_DIR="${BUILD_TMP}/musl-${CROSS_TARGET}"
[ ! -n "$LIBC_STARTFILE_STAGE" ] && BUILD_DIR="$BUILD_DIR-full"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

export CROSS_COMPILE="${INSTALL_DIR}/bin/${CROSS_TARGET}-"
export LIBCC="$(${CROSS_COMPILE}clang -print-libgcc-file-name)"

resource_dir="$(${CROSS_COMPILE}clang -print-resource-dir)"
CFLAGS="-fdebug-default-version=4 -gdwarf-4 -march=armv8.3-a+pauth"
CFLAGS="$CFLAGS -O0 -isystem ${resource_dir}/include"
export CFLAGS

"$MUSL_SOURCE_DIR/configure" \
  --prefix="$TARGET_PREFIX" \
  --disable-wrapper \
  --disable-optimize \
  --enable-debug

if [ -n "$LIBC_STARTFILE_STAGE" ]; then
  echo "Install MUSL header and start files for target $CROSS_TARGET"
  make install-headers -j$CPU_COUNT
else
  echo "Install MUSL for target $CROSS_TARGET"
  make install -j$CPU_COUNT
  # Convert /lib/ld-* symlinks to relative paths
  for f in `find "$TARGET_PREFIX/lib" -type l -name "ld-musl*"`
  do
    ln -sf libc.so "$f"
  done
fi
