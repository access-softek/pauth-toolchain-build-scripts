#!/usr/bin/env sh
set -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT/..")"

cd "$ROOT"

. ./config
. ./scripts/global-vars

# clean up existing sysroots
echo "+++ Removing existing sysroots at $INSTALL_DIR ..."
[ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"

# Install the target system headers.
./scripts/build-linux-header.sh
# Installing musl/libc headers
LIBC_STARTFILE_STAGE=1 ./scripts/build-musl.sh
# Prepapre the cross toolchain to build the target musl libc libraries.
#Note: we need to build toolchain only with the static runtime libraries here.
# The shared libraries require libc.so module, which is not ready yet.
STATIC_RUNTIMES_ONLY=1 ./scripts/build-toolchain.sh
# Build and install the libc libraries
./scripts/build-musl.sh
