#!/bin/sh -e

set -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT/..")"

cd "$ROOT"

. ./config
. ./scripts/global-vars

fetch_sources() {
  if [ "$#" != 2 ]; then
    echo "Usage: docker.sh sources <llvm_repo_url> <musl_repo_url>"
    echo "Note that file:///path/to/repo/ URLs can be used."
    exit 1
  fi

  local llvm_repo="$1"
  local musl_repo="$2"

  mkdir -p "$ROOT/src"
  echo "fetching llvm-project: $llvm_repo / $LLVM_BRANCH -> $ROOT/src/llvm ..."
  test -d "$ROOT/src/llvm" || git clone --depth 1 -b "$LLVM_BRANCH" "$llvm_repo" "$ROOT/src/llvm"
  echo "fetching musl: $musl_repo / $MUSL_BRANCH -> $ROOT/src/musl ..."
  test -d "$ROOT/src/musl" || git clone --depth 1 -b "$MUSL_BRANCH" "$musl_repo" "$ROOT/src/musl"

  local SOURCE_TARBALL=linux-$LINUX_KERNEL_VERSION.tar.xz
  local SOURCE_URL="https://cdn.kernel.org/pub/linux/kernel/v${LINUX_KERNEL_VERSION%%.*}.x/$SOURCE_TARBALL"
  local SOURCE_OUTPUT_PATH="$ROOT/src/$SOURCE_TARBALL"
  echo "donwloading kernel sources: $SOURCE_URL -> $SOURCE_OUTPUT_PATH ..."
  curl -sSL $SOURCE_URL -o $SOURCE_OUTPUT_PATH

  check_repo_sha "$ROOT/src/llvm" "$LLVM_SHA"
  check_repo_sha "$ROOT/src/musl" "$MUSL_SHA"
}

echo "ROOT: $ROOT"

llvm_repo_url=${1:-$DEFAULT_LLVM_REPO_URL}
musl_repo_url=${2:-$DEFAULT_MUSL_REPO_URL}

fetch_sources "$llvm_repo_url" "$musl_repo_url"
