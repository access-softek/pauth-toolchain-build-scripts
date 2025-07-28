#!/usr/bin/env sh
set -xe
cd "$(dirname "$0")"

# This script is an entry point inside the Docker container.
# Its location is expected to be $REPO_ROOT/scripts/build-in-docker.sh.

# Export the REPO_ROOT variable, so it can be used by the 'config' script
# sourced by this script and its subprocesses.
export REPO_ROOT="$(pwd)/.."
. ../config
. ./global-vars

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
