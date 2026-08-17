#!/bin/sh -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT")"
cd "$ROOT"

set -x
. ./scripts/common.inc.sh
. ./scripts/global-vars.inc.sh
set_global_variables host_build  "$ROOT"
set_global_variables docker_host "$ROOT"
set_global_variables docker
# Local configuration file may reference the variables defined above.
. ./config
set +x

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

# NOTE: Non-clean status of the working directory is currently ignored.
#       This makes it possible to checkout the expected commit first
#       and perform quick local experiments later (until switching to another
#       expected commit).
fetch_git_commit() {
  local repo_path="$1"
  local repo_url="$2"
  local branch="$3"
  local expected_sha="$4"

  if [ ! -d "$repo_path" ]; then
    # No repository found - initialize one and create a dummy commit,
    # for rev-parse to return *something*.
    echo "Initializing git repository at $repo_path..."
    git init --initial-branch=temp "$repo_path"
    git -C "$repo_path" commit --allow-empty -m "Dummy commit on a dummy branch"
  fi

  local current_sha="$(git -C "$repo_path" rev-parse HEAD)"
  if [ "$current_sha" != "$expected_sha" ]; then
    local timestamp="$(date '+%Y%m%d_%H_%M_%S')"
    echo "$repo_path: switching from $current_sha to $expected_sha ($branch)..."
    git -C "$repo_path" fetch --depth 1 "$repo_url" "$branch"
    # Create a branch, so that subsequent fetch operations can ask the remote
    # git not to re-pack the existing objects.
    git -C "$repo_path" checkout -b "fetch-$timestamp" FETCH_HEAD
  fi
}

fetch_sources() {
  # Note: the *_host_build variables referenced by this function are the
  # same as their *_docker_host counterparts.

  if [ "$#" != 2 ]; then
    echo "Usage: docker.sh sources <llvm_repo_url> <musl_repo_url>"
    echo "Note that file:///path/to/repo/ URLs can be used."
    exit 1
  fi

  local llvm_repo="$1"
  local musl_repo="$2"

  mkdir -p "$SRC_DIR_host_build"
  fetch_git_commit "$LLVM_SOURCE_DIR_host_build" "$llvm_repo" "$LLVM_BRANCH" "$LLVM_SHA"
  fetch_git_commit "$MUSL_SOURCE_DIR_host_build" "$musl_repo" "$MUSL_BRANCH" "$MUSL_SHA"

  local LOCAL_TARBALL_PATH="$SRC_DIR_host_build/$LINUX_KERNEL_TARBALL_BASENAME"
  if [ ! -f "$LOCAL_TARBALL_PATH" ]; then
    echo "Missing $LOCAL_TARBALL_PATH, downloading from $LINUX_KERNEL_TARBALL_URL..."
    curl -sSL "$LINUX_KERNEL_TARBALL_URL" -o "$LOCAL_TARBALL_PATH"
  fi

  check_repo_sha "$LLVM_SOURCE_DIR_host_build" "$LLVM_SHA"
  check_repo_sha "$MUSL_SOURCE_DIR_host_build" "$MUSL_SHA"

  local computed_sha256="$(sha256sum "$LOCAL_TARBALL_PATH" | sed 's/[ \t].*$//')"
  if [ "$computed_sha256" = "$LINUX_KERNEL_SHA256" ]; then
    echo "Checked SHA256 of $LOCAL_TARBALL_PATH"
  else
    echo "Unexpected SHA256 of $LOCAL_TARBALL_PATH:"
    echo "  expected: $LINUX_KERNEL_SHA256"
    echo "  computed: $computed_sha256"
    exit 1
  fi
}

build_in_docker() {
  check_repo_sha "$LLVM_SOURCE_DIR_docker_host" "$LLVM_SHA"
  check_repo_sha "$MUSL_SOURCE_DIR_docker_host" "$MUSL_SHA"

  $DOCKER_CMD build \
      -t "$DOCKER_IMAGE_NAME" \
      -f Dockerfile.builder \
      --build-arg REPO_ROOT="$REPO_ROOT_docker" \
      "$REPO_ROOT_docker_host"
  $DOCKER_CMD run -ti --rm \
      --volume "$OUTPUT_DIR_docker_host:$OUTPUT_DIR_docker:rw" \
      --volume "$CCACHE_DIR_docker_host:$CCACHE_DIR_docker:rw" \
      --volume "$SRC_DIR_docker_host:$SRC_DIR_docker:ro" \
      --volume "$REPO_ROOT_docker_host/tmp:/tmp:rw" \
      --tmpfs "$DOCKER_BUILD_INSTALL_DIR:rw,exec,size=2G" \
      --tmpfs "$BUILD_TMP_docker:rw,exec,size=8G" \
      "$DOCKER_IMAGE_NAME" "$REPO_ROOT_docker/scripts/build-in-docker.sh"
}

build_on_host() {
  set -x
  reexport_variables host_build
  export INSTALL_DIR="$HOST_BUILD_INSTALL_DIR"
  set +x

  check_repo_sha "$LLVM_SOURCE_DIR_host_build" "$LLVM_SHA"
  check_repo_sha "$MUSL_SOURCE_DIR_host_build" "$MUSL_SHA"

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
