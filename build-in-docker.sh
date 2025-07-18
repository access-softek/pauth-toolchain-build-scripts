#!/usr/bin/env sh
set -xe
cd "$(dirname "$0")"
. ./config

./build-all.sh

# It is important to remove an old image, if any, as otherwise it would be
# appended to instead of overwritten!
rm -f "$OUTPUT_DIR/llvm-pauth.squashfs"

mksquashfs \
    "$INSTALL_DIR" \
    "$OUTPUT_DIR/llvm-pauth.squashfs" \
    -comp zstd \
    -no-xattrs \
    -all-root
