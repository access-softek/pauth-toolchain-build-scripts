#!/bin/sh -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT")"
cd "$ROOT"

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
  . ./config
  . ./scripts/global-vars

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

build_in_docker() {
  # Path inside the container.
  REPO_ROOT=/repo
  . ./config
  . ./scripts/global-vars

  check_repo_sha "$ROOT/src/llvm" "$LLVM_SHA"
  check_repo_sha "$ROOT/src/musl" "$MUSL_SHA"

  $DOCKER_CMD build \
      -t "$DOCKER_IMAGE_NAME" \
      -f Dockerfile.builder \
      --build-arg REPO_ROOT="$REPO_ROOT" \
      "$ROOT"
  $DOCKER_CMD run -ti --rm \
      --volume "$ROOT/output:$OUTPUT_DIR:rw" \
      --volume "$ROOT/ccache:$CCACHE_DIR:rw" \
      --volume "$ROOT/src:$SRC_DIR:ro" \
      --tmpfs "$INSTALL_DIR:rw,exec,size=2G" \
      --tmpfs "$BUILD_TMP:rw,exec,size=5G" \
      "$DOCKER_IMAGE_NAME" "$REPO_ROOT/scripts/build-in-docker.sh"
}

build_on_host() {
  REPO_ROOT="$ROOT"
  . ./config
  . ./scripts/global-vars

  check_repo_sha "$ROOT/src/llvm" "$LLVM_SHA"
  check_repo_sha "$ROOT/src/musl" "$MUSL_SHA"

  ./scripts/build-on-host.sh
}

main() {
  local subcmd="$1"

  case "$subcmd" in
  sources)
    shift
    fetch_sources "$@"
  ;;
  build)
    build_in_docker
  ;;
  host-build)
    build_on_host
  ;;
  *)
    echo "Unknown subcommand: $subcmd"
    echo "Expected one of 'sources', 'build', or 'host-build' (experimental)."
    exit 1
  ;;
  esac
}

main "$@"
