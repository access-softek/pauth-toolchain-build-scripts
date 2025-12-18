#!/usr/bin/env bash
set -e

ROOT="$(dirname "$0")"
ROOT="$(realpath "$ROOT/..")"

cd "$ROOT"

. ./config
. ./scripts/global-vars

if [ -z "$CROSS_TARGET" ]; then
  targets=$TOOLCHAIN_TARGETS
else
  targets=$CROSS_TARGET
fi

build_dir="$LLVM_BUILD_DIR"

[ -d "$build_dir" ] && rm -rf "$build_dir"
mkdir -p "$build_dir" && cd "$build_dir"

# Build a list of CMake definition args for all targets to pass the target sysroots and the compiler args.
for target in $targets; do
    cmake_rootfs_args="${cmake_rootfs_args} -DTOOLCHAIN_TARGET_SYSROOTFS-$target=$INSTALL_DIR/$target"
    vn=$(echo "TARGET_EXTRA_CFLAGS_$target" | sed 's|-|_|g')
    vv=$(eval "echo \"\$$vn\"")
    if [ ! -z "$vv" ]; then
        cmake_extra_compiler_args="$cmake_extra_compiler_args -DTOOLCHAIN_TARGET_COMPILER_FLAGS-$target=\"${vv}\""
    fi
done
echo "%%% cmake_rootfs_args: $cmake_rootfs_args"
# Transform a list of the targets into the CMake list variable format.
target_list=$(echo "$targets" | sed 's| |;|g')
echo "%%% targets: $target_list"

echo "%%% cmake_extra_compiler_args: ${cmake_extra_compiler_args[@]}"
echo "%%% cmake_rootfs_args: ${cmake_rootfs_args[@]}"

#NOTE: we have to use that idiotic way to call the cmake tool, because the shell script cannot
# properly pass the quoted variable values with the space characters. As example the compiler
# options such as $cmake_extra_compiler_args => "-Xclang -fptrauth-elf-got" (it splits it to 
# two arguments: '"-Xclang' and '-fptrauth-elf-got"'.

echo "%%% STATIC_RUNTIMES_ONLY: ${STATIC_RUNTIMES_ONLY:-0}"

cmake_args=$(cat <<EOL
    -G Ninja \
    -S "$LLVM_SOURCE_DIR/llvm"
    -DLLVM_TARGETS_TO_BUILD=AArch64
    -DLLVM_INCLUDE_BENCHMARKS=OFF
    -DLLVM_LIT_ARGS="-v -vv --threads=32 --time-tests"
    -DCMAKE_CXX_FLAGS=-D__OPTIMIZE__
    -DLLVM_CCACHE_BUILD=ON
    -DLLVM_CCACHE_DIR="$CCACHE_DIR"
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;llvm"
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind"
    -DCMAKE_INSTALL_PREFIX=dist-install
    -DCMAKE_BUILD_TYPE=Release
    -DLLVM_ENABLE_ASSERTIONS=ON
    -DTOOLCHAIN_TARGET_COMPILER_FLAGS="$TARGET_COMMON_CFLAGS"
    ${cmake_extra_compiler_args}
    ${cmake_rootfs_args}
    -DTOOLCHAIN_TARGET_TRIPLE="$target_list"
    -DTOOLCHAIN_SHARED_LIBS=$(if_then_else "${STATIC_RUNTIMES_ONLY:-0}" "OFF" "ON")
    -DTOOLCHAIN_STATIC_LIBS=ON
    -DTOOLCHAIN_USE_STATIC_LIBS=$(if_then_else "${STATIC_RUNTIMES_ONLY:-0}" "ON" "OFF")
    -C "$CMAKE_DIR/cross-linux-toolchain.cmake"
EOL
)

echo "$cmake_args" | xargs $ROOT/scripts/cmake_call.sh

$ROOT/scripts/cmake_call.sh --build . --target install
