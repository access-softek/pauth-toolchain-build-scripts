#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"

export OUTPUT_DIR=/opt/llvm-pauth
. ./config

./build-all.sh

# Formally support building for aarch64-linux-musl target for testing.
# It is up to the user to ensure pointer authentication is enabled on
# relevant runtime / user program boundaries.
ln -s aarch64-linux-pauthtest /opt/llvm-pauth/aarch64-linux-musl
ln -s aarch64-unknown-linux-pauthtest /opt/llvm-pauth/lib/clang/$LLVM_MAJOR_VERSION/lib/aarch64-unknown-linux-musl

# It is important to remove an old image, if any, as otherwise it would be
# appended to instead of overwritten!
rm -f /scripts/output/llvm-pauth.squashfs

mksquashfs \
    /opt/llvm-pauth \
    /scripts/output/llvm-pauth.squashfs \
    -comp zstd \
    -no-xattrs \
    -all-root
