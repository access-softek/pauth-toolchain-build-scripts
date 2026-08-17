#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"

# This script starts the build on the host, similar to build-in-docker.sh for a
# containeraized build.
# Its location is expected to be $REPO_ROOT/scripts/build-on-host.sh.

# All global configuration variables are expected to be already exported
# by the calling ./build.sh script.

./build-all.sh

echo "Build finished, the toolchain is installed to $INSTALL_DIR."
