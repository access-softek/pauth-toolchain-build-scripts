#!/bin/sh -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT")"
cd "$ROOT"

# Path inside the container.
export REPO_ROOT=/repo

. ./config
. ./scripts/global-vars

fetch_sources() {
  ./scripts/fetch-sources.sh "$@"

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

build_container() {
  result=$( $DOCKER_CMD images -q "$DOCKER_IMAGE_NAME" )

  # Do not recreate the docker image.
  if [ -z "$result" ]; then
    echo "+++ creating docker container: $DOCKER_IMAGE_NAME at $ROOT"

    $DOCKER_CMD build \
        -t "$DOCKER_IMAGE_NAME" \
        -f Dockerfile.builder \
        --build-arg REPO_ROOT="$REPO_ROOT" \
        "$ROOT"
  fi
}

run_container_with() {
  local script_to_run="$1"

  # Build docker container if missed.
  build_container

  echo "+++ running container command: $script_to_run ..."

  $DOCKER_CMD run -ti \
      --volume "$ROOT/output:$OUTPUT_DIR:rw" \
      --volume "$ROOT/ccache:$CCACHE_DIR:rw" \
      --volume "$ROOT/src:$SRC_DIR:ro" \
      --tmpfs "$INSTALL_DIR:rw,exec,size=2G" \
      --tmpfs "$BUILD_TMP:rw,exec,size=5G" \
      "$DOCKER_IMAGE_NAME" $script_to_run
}

remove_container() {
  result=$( $DOCKER_CMD images -q "$DOCKER_IMAGE_NAME" )

  if [ -n "$result" ]; then
    contid=$( $DOCKER_CMD ps -a -q --filter ancestor="$result" )
    if [ -n "$contid" ]; then
      echo "+++ removing the container and its associated anonymous volumes: $contid ($DOCKER_IMAGE_NAME)"
      $DOCKER_CMD rm -v "$contid"
    fi
  fi
}

remove_image() {
  result=$( $DOCKER_CMD images -q "$DOCKER_IMAGE_NAME" )

  if [ -n "$result" ]; then
    echo "+++ removing the image: $DOCKER_IMAGE_NAME ($result)"
    $DOCKER_CMD rmi "$result"
  fi
}

build_toolchain() {
  check_repo_sha "$ROOT/src/llvm" "$LLVM_SHA"
  check_repo_sha "$ROOT/src/musl" "$MUSL_SHA"

  run_container_with "$REPO_ROOT/scripts/build-in-docker.sh"
  remove_container
}

main() {
  local subcmd="$1"

  case "$subcmd" in
  sources)
    shift
    ./scripts/fetch-sources.sh "$@"
  ;;
  clean-src)
    test -d "$ROOT/src/llvm" && rm -rf "$ROOT/src/llvm"
    test -d "$ROOT/src/musl" && rm -rf "$ROOT/src/musl"
  ;;
  remove)
    # remove the container and its associated anonymous volumes.
    remove_container
  ;;
  remove-image)
    remove_image
  ;;
  build)
    build_toolchain
  ;;
  build-sysroots)
    echo "+++ build-sysroots"
    run_container_with "$REPO_ROOT/scripts/build-linux-header.sh"
  ;;
  build-toolchain)
  ;;
  build-musl)
  ;;
  *)
    echo "Unknown subcommand: $subcmd"
    echo "Expected: 'sources', 'clean-src', 'remove', 'build', 'build-sysroots', 'build-toolchain', 'build-musl'."
    exit 1
  ;;
  esac
}

main "$@"
