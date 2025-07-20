This directory contains scripts to build an LLVM PAuth toolchain from scratch.

The sources of LLVM, Musl and Linux kernel are first checked out on host under
`./src/` and then the toolchain is built inside a Docker container.
To speed up rebuilds significantly, a `./ccache/` directory is mounted from the host.
The resulting toolchain is written to `./output/llvm-pauth.squashfs` - it is a
compressed read-only file system image which is intended to be `mount`ed to
`/opt/llvm-pauth`.

The versions of LLVM, Musl and Linux kernel are set in `llvm-branch-config`:
by default, mainline `llvmorg-21.1.0-rc1` tag is used together with a patched
version of Musl that can be obtained at https://github.com/access-softek/musl.
The choice of Linux kernel version is mostly arbitrary: it is only used to
provide kernel headers to Musl, thus any recent version should work.
Please note that while basic sanity check is performed to make sure the
expected SHA1 hashes are checked out under `./src/llvm` and `./src/musl`, it is
not checked whether the working copy is clean or not.

# Building the toolchain

Ensure `llvm-project` and `musl` repositories are cloned on the host and contain
the commits specified in `llvm-brach-config` file (by default, you need the
mainline LLVM monorepo and patched Musl version from
https://github.com/access-softek/musl). Alternatively, you can pass HTTPS URLs
directly to `./docker.sh sources`.

Checkout the particular commits of LLVM and Musl sources under `./src` and
download Linux kernel tarball by running:

```
./docker.sh sources <llvm_repo_url> <musl_repo_url>
```

if LLVM and Musl are already cloned on the host, use

```
./docker.sh sources file:///absolute/path/to/llvm-project file:///absolute/path/to/musl
```

Then build the toolchain by running

```
./docker.sh build
```

The build artifact is `./output/llvm-pauth.squashfs` file.

# Using the toolchain

Mount the produced SquashFS image at `/opt/llvm-pauth`:

```
mkdir /opt/llvm-pauth
mount output/llvm-pauth.squashfs /opt/llvm-pauth
```

The Clang compiler driver is installed to `/opt/llvm-pauth/bin`, the PAuth-enabled
sysroot is `/opt/llvm-pauth/aarch64-linux-pauthtest` (alternatively, a non-PAuth
triple `aarch64-linux-musl` can be used with `/opt/llvm-pauth/aarch64-linux-musl`
sysroot - both sysroots are configured for the corresponding triples via Clang
config files: `/opt/llvm-pauth/bin/aarch64-unknown-linux-*.cfg`).

Programs can be compiled with

```
$ /opt/llvm-pauth/bin/clang++ -target aarch64-linux-pauthtest -march=armv8.3-a hello-world.cpp -o hello-world
```

and executed on x86_64 host with qemu-user and binfmt-misc configured by specifying
the dynamic loader and the path to shared libraries:

```
$ LD_LIBRARY_PATH=/opt/llvm-pauth/aarch64-linux-pauthtest/usr/lib /opt/llvm-pauth/aarch64-linux-pauthtest/usr/lib/libc.so ./hello-world
Hello world!
```

Alternatively, these paths can be hardcoded into the executable:

```
$ /opt/llvm-pauth/bin/clang++ -target aarch64-linux-pauthtest -march=armv8.3-a \
    -Wl,--dynamic-linker=/opt/llvm-pauth/aarch64-linux-pauthtest/usr/lib/libc.so \
    -Wl,--rpath=/opt/llvm-pauth/aarch64-linux-pauthtest/usr/lib \
    hello-world.cpp -o hello-world
$ ./hello-world
Hello world!
```
