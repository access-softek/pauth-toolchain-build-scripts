# This file defines global variables that are used by most of the build scripts.
#
# The variables defined by this file are global, but are not expected
# to be adjusted by the users.
#
# On the other hand, the versions of LLVM and Musl to build, or the variables
# that may have to be adjusted according to the host system configuration are
# defined in the `config` file in the root of this repository instead.


# Sets global configuration variables suffixed with "_host_build", "_docker_host",
# or "_docker".
#
# Usage: set_global_variables host_build  <host repo root>
#        set_global_variables docker_host <host repo root>
#        set_global_variables docker
#
# NB: Make sure host_repo_root is absolute, as relative paths may be interpreted
# in surprising ways in some contexts, such as in the argument of `--toolchain`
# option of CMake.
set_global_variables() {
  local purpose="$1"
  local host_repo_root="$2" # Must be empty if purpose is "docker"

  local repo_root
  case "$purpose" in
  host_build)
    repo_root="$host_repo_root"
  ;;
  docker_host)
    repo_root="$host_repo_root"
  ;;
  docker)
    [ "x$host_repo_root" != "x" ] && \
        report_fatal_error "Do not specify host_repo_root with 'docker'."

    repo_root="/repo"
  ;;
  *)
    report_fatal_error "Expected one of host_build, docker_host, docker."
  esac

  # The expression string passed to the 'eval' built-in is something like this:
  # OUTPUT_DIR_host_build="$repo_root/output"

  eval  REPO_ROOT_$purpose='"$repo_root"'
  eval OUTPUT_DIR_$purpose='"$repo_root/output"'
  eval CCACHE_DIR_$purpose='"$repo_root/ccache"'
  eval  BUILD_TMP_$purpose='"$repo_root/build"'

  eval SRC_DIR_$purpose='"$repo_root/src"'
  eval LLVM_SOURCE_DIR_$purpose='"$repo_root/src/llvm"'
  eval MUSL_SOURCE_DIR_$purpose='"$repo_root/src/musl"'

  eval CMAKE_DIR_$purpose='"$repo_root/cmake"'
}

# Re-defines previously set global variables without suffix and exports them.
reexport_variables() {
  local suffix="$1"

  case "$suffix" in
  host_build|docker_host|docker) true ;;
  *) report_fatal_error "Expected one of host_build, docker_host, docker."
  esac

  local var_name
  for var_name in REPO_ROOT OUTPUT_DIR CCACHE_DIR BUILD_TMP \
                  SRC_DIR LLVM_SOURCE_DIR MUSL_SOURCE_DIR \
                  CMAKE_DIR; do
    # Eval-ed expression looks like this:
    # export REPO_ROOT="$REPO_ROOT_host_build"
    eval "export $var_name=\"\$${var_name}_${suffix}\""
  done
}

export CPU_COUNT="$(nproc)"

# Linux kernel version to be used to provide user-space headers to libc.
# Any recent version should work, so this variable is defined here instead
# of $REPO_ROOT/config.
LINUX_KERNEL_VERSION=6.19.12
LINUX_KERNEL_TARBALL_BASENAME="linux-$LINUX_KERNEL_VERSION.tar.xz"
LINUX_KERNEL_TARBALL_URL="https://cdn.kernel.org/pub/linux/kernel/v${LINUX_KERNEL_VERSION%%.*}.x/$LINUX_KERNEL_TARBALL_BASENAME"
LINUX_KERNEL_SHA256=ce5c4f1205f9729286b569b037649591555f31ca1e03cc504bd3b70b8e58a8d5
