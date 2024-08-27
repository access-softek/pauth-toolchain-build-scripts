#!/bin/sh -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT")"
cd "$ROOT"

# Branches being checked out by "docker.sh sources"
LLVM_BRANCH=pauth
MUSL_BRANCH=dkovalev/pauth-release-19.x
# Expected hashes at these branches
LLVM_SHA=b7ed52fbdfe68555de5b19b37cdcbbe84637853f
MUSL_SHA=1268c66ff4bccb1ad10e4bcf7969703e691669b3

LINUX_KERNEL_VERSION=6.1.58

docker="docker"
#docker="sudo docker"

check_repo_sha() {
  local repo_path="$1"
  local expected_sha="$2"

  local sha="$(git -C "$repo_path" rev-parse HEAD)"
  if [ "$sha" != "$expected_sha" ]; then
    echo "Unexpected commit hash:"
    echo "  repo: $repo_path"
    echo "  expected: $expected_sha"
    echo "  observed: $sha"
    exit 1
  else
    echo "Checked commit hash at $repo_path"
  fi
}

fetch_sources() {
  if [ "$#" != 2 ]; then
    echo "Usage: docker.sh sources <llvm_repo_url> <musl_repo_url>"
    echo "Note that file:///path/to/repo/ URLs can be used."
    exit 1
  fi

  local llvm_repo="$1"
  local musl_repo="$2"

  mkdir -p "$ROOT/src"
  test -d "$ROOT/src/llvm" || git clone --depth 1 -b "$LLVM_BRANCH" "$llvm_repo" "$ROOT/src/llvm"
  test -d "$ROOT/src/musl" || git clone --depth 1 -b "$MUSL_BRANCH" "$musl_repo" "$ROOT/src/musl"

  local SOURCE_TARBALL=linux-$LINUX_KERNEL_VERSION.tar.xz
  curl -sSL "https://cdn.kernel.org/pub/linux/kernel/v${LINUX_KERNEL_VERSION%%.*}.x/$SOURCE_TARBALL" \
       -o "$ROOT/src/$SOURCE_TARBALL"

  check_repo_sha "$ROOT/src/llvm" "$LLVM_SHA"
  check_repo_sha "$ROOT/src/musl" "$MUSL_SHA"
}

build_toolchain() {
  check_repo_sha "$ROOT/src/llvm" "$LLVM_SHA"
  check_repo_sha "$ROOT/src/musl" "$MUSL_SHA"

  $docker build -t pauth-toolchain-builder -f Dockerfile.builder "$ROOT"
  $docker run -ti --rm \
      --volume "$ROOT/output:/scripts/output:rw" \
      --volume "$ROOT/ccache:/scripts/ccache:rw" \
      --volume "$ROOT/src:/src:ro" \
      --tmpfs "/opt/llvm-pauth:rw,exec,size=2G" \
      --tmpfs "/scripts/.build:rw,exec,size=5G" \
      pauth-toolchain-builder /scripts/build-in-docker.sh
}

main() {
  local subcmd="$1"

  case "$subcmd" in
  sources)
    shift
    fetch_sources "$@"
  ;;
  build)
    build_toolchain
  ;;
  *)
    echo "Unknown subcommand: $subcmd"
    echo "Expected: 'sources', 'build'."
    exit 1
  ;;
  esac
}

main "$@"
