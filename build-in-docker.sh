#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"

export OUTPUT_DIR=/opt/llvm-pauth
./build-all.sh

# It is important to remove an old image, if any, as otherwise it would be
# appended to instead of overwritten!
rm -f /scripts/output/llvm-pauth.squashfs

mksquashfs \
    /opt/llvm-pauth \
    /scripts/output/llvm-pauth.squashfs \
    -comp zstd \
    -no-xattrs \
    -all-root
