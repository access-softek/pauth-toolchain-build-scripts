#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"

# This script starts the build on the host, similar to build-in-docker.sh for a
# containeraized build.
# Its location is expected to be $REPO_ROOT/scripts/build-on-host.sh.

# Export the REPO_ROOT variable, so it can be used by the 'global-vars' script
# sourced by this script, as well as its subprocesses.
export REPO_ROOT="$(pwd)/.."
. ../config
. ./global-vars

./build-all.sh

echo "Build finished, the toolchain is installed to $INSTALL_DIR."
