#!/usr/bin/env sh
set -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT/..")"

cd "$ROOT"

. ./config
. ./scripts/global-vars

if [ -z "$CROSS_TARGET" ]; then
  targets=$TOOLCHAIN_TARGETS
else
  targets=$CROSS_TARGET
fi

echo "MUSL sources: $MUSL_SOURCE_DIR"

for target in $targets; do
  target_prefx="$INSTALL_DIR/$target/usr"
  target_syslibdir="$INSTALL_DIR/$target/lib"
  build_dir="$BUILD_TMP/musl-$target"

  [ ! -n "$LIBC_STARTFILE_STAGE" ] && build_dir="$build_dir-full"
  # Clean up build dir (rebuild every time).
  [ -d "$build_dir" ] && rm -rf "$build_dir"
  mkdir -p "$build_dir" && cd "$build_dir"

  echo "%%% MUSL: $target => $target_prefx"
  echo "%%% MUSL: target_syslibdir: $target_syslibdir"

  if [ -n "$LIBC_STARTFILE_STAGE" ]; then
    # No need configuration here. Just provide required variables to the make tool.
    echo "Install MUSL header and start files for target $target => $target_prefx"

    make -f "$MUSL_SOURCE_DIR/Makefile" ARCH=aarch64 srcdir="$MUSL_SOURCE_DIR" prefix="$target_prefx" install-headers
  else
    export CC="${TOOLCHAIN_ROOT}/bin/$target-clang"

    resource_dir=$($CC --target=$target -print-resource-dir)
    opt_cflags="$(if_then_else ${BUILD_OPTIMIZED_RUNTIMES:-0} "" "-O0")"
    CFLAGS="--target=$target -isystem ${resource_dir}/include $TARGET_COMMON_CFLAGS $opt_cflags"
    export CFLAGS

    echo "%%% print-resource-dir: $($CC --target=$target -print-resource-dir)"
    echo "%%% print-libgcc-file-name: $($CC --target=$target -print-libgcc-file-name)"

    export AR="${TOOLCHAIN_ROOT}/bin/llvm-ar"
    export RANLIB="${TOOLCHAIN_ROOT}/bin/llvm-ranlib"
    export LIBCC=$($CC --target=$target -print-libgcc-file-name)

    "$MUSL_SOURCE_DIR/configure" \
      --target=$target \
      --prefix="$target_prefx" \
      --syslibdir="$target_syslibdir" \
      --disable-wrapper \
      $(if_then_else ${BUILD_OPTIMIZED_RUNTIMES:-0} --enable-optimize --disable-optimize) \
      --enable-debug

    echo "Install MUSL for target $target => $target_prefx"
    make install-libs -j$CPU_COUNT
    # Convert /lib/ld-* symlinks to relative paths
    for f in `find "$target_syslibdir" -type l -name "ld-musl*"`
    do
      echo "Convert ld-* symlinks to relative path: $f => ../usr/lib/libc.so ..."
      ln -sf ../usr/lib/libc.so "$f"
    done
fi

done
