#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"
. ./config

export PATH="$OUTPUT_DIR/bin:$PATH"
BUILD_DIR=".build/musl"
rm -rf $BUILD_DIR
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

export CFLAGS="-O0 -fno-ptrauth-function-pointer-type-discrimination -fdebug-default-version=4 -gdwarf-4 -DMUSL_EXPERIMENTAL_PAC=1 -march=armv8.3-a+pauth -isystem$OUTPUT_DIR/lib/clang/$LLVM_MAJOR_VERSION/include"

$MUSL_SOURCE_DIR/configure \
  $CONFIGURE_ARGS \
  --host=$CROSS_TARGET \
  --target=$CROSS_TARGET \
  --prefix=/ \
  --disable-wrapper \
  --disable-optimize \
  --enable-debug

if [ -n "$LIBC_STARTFILE_STAGE" ]; then
  echo "Install MUSL header and start files for target $CROSS_TARGET"
  make DESTDIR="$TARGET_PREFIX" install-headers -j$CPU_COUNT
else
  echo "Install MUSL for target $CROSS_TARGET"
  make DESTDIR="$TARGET_PREFIX" install -j$CPU_COUNT
  # Convert /lib/ld-* symlinks to relative paths
  for f in `find "$TARGET_PREFIX/lib" -type l -name "ld-musl*"`
  do
    ln -sf libc.so "$f"
  done
fi
