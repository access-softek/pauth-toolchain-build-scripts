#!/usr/bin/env sh
set -e

# This script invokes all other build-*.sh scripts.
# Inside the container, it is called by build-in-docker.sh.
# FIXME: Add another entry point script to perform build directly on host.

set -x
cd "$(dirname "$0")"
. "$REPO_ROOT/config"
. ./global-vars
set +x

write_clang_config_files() {
  cat > "$INSTALL_DIR/bin/aarch64-unknown-linux-pauthtest.cfg" <<EOF
--sysroot <CFGDIR>/../aarch64-linux-pauthtest
$EXTRA_FLAGS_PAUTHTEST
EOF
  cat > "$INSTALL_DIR/bin/aarch64-unknown-linux-musl.cfg" <<EOF
--sysroot <CFGDIR>/../aarch64-linux-musl
$EXTRA_FLAGS_MUSL
EOF
}

# Usage: try_build <stamp-prefix> <command line...>
# Note:  CROSS_TARGET is added to the stamp file name.
#
# Try performing the build step:
# * skip this step if the stamp file already exists
# * create the stamp file if the build step succeeded
# * print an error to the user if the build step failed
#
# The primary goal of this function is to improve usability of restarting
# partially successful builds performed on the host. Note that no directories
# are removed in case of an error to minimize the amount of "rm -rf" calls
# performed on the host and to simplify the debugging of build errors.
try_build() {
  local stamp_prefix="$1"
  shift 1

  local build_dir="${BUILD_TMP}/${stamp_prefix}-${CROSS_TARGET}"

  local stamp_file_name="${build_dir}.stamp"
  if [ -f "$stamp_file_name" ]; then
    echo "Stamp found, skipping '$*'."
    return
  fi

  if [ -d "$build_dir" ]; then
    echo "Incomplete build directory is found at $build_dir." 1>&2
    exit 1
  fi

  # Try performing the build step.
  # On error, print a message to the user instead on exiting due to 'set -e'.

  export BUILD_DIR="$build_dir" # Used by called subprocess.
  echo "Executing: $*"
  if "$@"; then
    touch "$stamp_file_name"
  else
    echo "Execution of '$stamp_prefix' step for '$CROSS_TARGET' failed." 1>&2
    echo "Please remove incomplete build at '$BUILD_DIR' before restarting the build." 1>&2
    exit 1
  fi
}

build_target_libs() {
  export CROSS_TARGET
  export TARGET_PREFIX="$INSTALL_DIR/$CROSS_TARGET/usr"
  echo "Building runtime libs in $TARGET_PREFIX..."
  try_build symlinks      ./create-symlinks.sh
  try_build linux-headers ./build-linux-header.sh
  LIBC_STARTFILE_STAGE=1     try_build musl-startfiles      ./build-musl.sh
  COMPILER_RT_BUILD=builtins try_build compiler-rt-builtins ./build-compiler-rt.sh
  try_build musl-full ./build-musl.sh
  try_build runtimes  ./build-runtimes.sh
  COMPILER_RT_BUILD=full     try_build compiler-rt-full ./build-compiler-rt.sh
}

CROSS_TARGET="all" try_build llvm ./build-llvm.sh

write_clang_config_files
CROSS_TARGET="aarch64-linux-pauthtest" build_target_libs
CROSS_TARGET="aarch64-linux-musl"      build_target_libs
