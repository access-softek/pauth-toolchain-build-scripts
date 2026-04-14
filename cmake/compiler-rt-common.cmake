set(LLVM_ENABLE_PER_TARGET_RUNTIME_DIR TRUE  CACHE BOOL "" FORCE)
set(COMPILER_RT_DEFAULT_TARGET_ONLY    TRUE  CACHE BOOL "" FORCE)

set(COMPILER_RT_BUILD_SANITIZERS       FALSE CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_XRAY             FALSE CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_MEMPROF          FALSE CACHE BOOL "" FORCE)
set(COMPILER_RT_BUILD_ORC              FALSE CACHE BOOL "" FORCE)

# Enable `check-*` targets, so that they can be manually executed after
# building the toolchain with `./build.sh host-build`.
set(test_cflags "")
set(sysroot_lib_path "${TOOLCHAIN_BUILD_INSTALL_DIR}/${TOOLCHAIN_BUILD_TARGET}/usr/lib")
string(APPEND test_cflags " -march=armv8.3-a+pauth")
string(APPEND test_cflags " -Wl,--rpath=${sysroot_lib_path}")
string(APPEND test_cflags " -L ${sysroot_lib_path}")
string(APPEND test_cflags " -Wl,--dynamic-linker=${sysroot_lib_path}/libc.so")
set(COMPILER_RT_TEST_COMPILER_CFLAGS "${test_cflags}" CACHE STRING "" FORCE)
set(COMPILER_RT_CAN_EXECUTE_TESTS TRUE CACHE BOOL "" FORCE)
set(COMPILER_RT_INCLUDE_TESTS     TRUE CACHE BOOL "" FORCE)
