This directory contains scripts to build an LLVM PAuth toolchain from scratch.

The sources of LLVM, Musl and Linux kernel are first checked out on host under
`./src/` and then the toolchain is built inside a Docker container.
To speed up rebuilds significantly, a `./ccache/` directory is mounted from the host.
The resulting toolchain is written to `./output/llvm-pauth.squashfs` - it is a
compressed read-only file system image which is intended to be `mount`ed to
`/opt/llvm-pauth`.

Another option is building the toolchain without containers, purely on the host,
but keep in mind that Clang is able to auto-discover system-provided sysroots
for cross-compilation (for example, the sysroot under `/usr/aarch64-linux-gnu`
which is installed as a dependency of the `gcc-aarch64-linux-gnu` package in
Ubuntu running on x86_64 host). This is hopefully not an issue for these scripts,
as they explicitly specify the sysroots in Clang `*.cfg` files, and everything
compiles successfully in x86_64 containerized build. Anyway, containerized
builds (especially, when performed on a non-AArch64 host) look like yet another
layer of protection against unintentionally linking to any system-provided
libraries.

The versions of LLVM and Musl as well as a few other tunables are set in `config`:
by default, mainline `llvmorg-21.1.0-rc1` tag is used together with a patched
version of Musl that can be obtained at https://github.com/access-softek/musl.

The choice of Linux kernel version is mostly arbitrary: it is only used to
provide kernel headers to Musl, thus any recent version should work.
(As this version does not have to be adjusted by the user, it is defined in the
`scripts/global-vars` file instead.)

Please note that while basic sanity check is performed to make sure the
expected SHA1 hashes are checked out under `./src/llvm` and `./src/musl`, it is
not checked whether the working copy is clean or not.

# Building the toolchain

Ensure `llvm-project` and `musl` repositories are cloned on the host and contain
the commits specified in the `./config` file (by default, you need the mainline
LLVM monorepo and patched Musl version from https://github.com/access-softek/musl).
Alternatively, you can pass https:// or git:// URLs directly to `./build.sh sources`.

Checkout the particular commits of LLVM and Musl sources under `./src` and
download Linux kernel tarball by running:

```
./build.sh sources <llvm_repo_url> <musl_repo_url>
```

if LLVM and Musl are already cloned on the host, use

```
./build.sh sources file:///absolute/path/to/llvm-project file:///absolute/path/to/musl
```

Then build the toolchain by running

```
./build.sh build
```

The build artifact is `./output/llvm-pauth.squashfs` file.

# Using the toolchain

Mount the produced SquashFS image at `/opt/llvm-pauth`:

```
mkdir /opt/llvm-pauth
mount output/llvm-pauth.squashfs /opt/llvm-pauth
```

The Clang compiler driver is located in `/opt/llvm-pauth/bin`, the PAuth-enabled
sysroot is `/opt/llvm-pauth/aarch64-linux-pauthtest` (alternatively, a non-PAuth
triple `aarch64-linux-musl` can be used with `/opt/llvm-pauth/aarch64-linux-musl` -
both sysroots are configured for the corresponding triples via Clang configuration
files: `/opt/llvm-pauth/bin/aarch64-unknown-linux-*.cfg`).

Programs can be compiled with options like these

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

Please note that is Musl, the `libc.so` shared object is both the C library to
link your executables to as well as the dynamic loader.

# Cross-debugging with qemu-user and GDB

To debug a program for a different CPU architecture, a special GDB build may be
required. For example, on Ubuntu one has to install a `gdb-multiarch` package
that provides a command with the same name.

When the dynamic linker is invoked explicitly to load and run the program (like
in `/path/to/libc.so /path/to/program <program args>`), it may be required to
explicitly inform the debugger about the address at which the main executable
is loaded. To make GDB discover everything automatically, hardcode the dynamic
linker path and run the debugged program directly like `./program <args>`
(or `LD_LIBRARY_PATH=... ./program <args>`).

Define `QEMU_GDB=<port number>` environment variable before executing the program
to make QEMU stop at the first instruction of the guest process and listen at
the specified port for incoming GDB `extended-remote` connection.
See `qemu-aarch64 -h` for other command line options and corresponding
environment variables.

```
$ QEMU_GDB=1234 ./hello-world
# In other terminal:
$ gdb-multiarch
>>> target extended-remote :1234
>>> b main
>>> c
```

# Building the toolchain without Docker

The preferred way to use these scripts is building inside a container, though
it is possible to build the toolchain purely on the host.

This can be achieved by running `./build.sh host-build` instead of
`./build.sh build` after checking out the sources to `./src/*` the same way as
for a containerized build. After a successful build, the toolchain is installed
to the `./inst` subdirectory inside this repository (can be customized in
`./config`) and no archive is created under `./output`.

When the toolchain is being built inside a container, a temporary volume is
attached as a build directory, which is discarded when the container is stopped,
thus the subsequent invocation of `./build.sh build` uses a fresh build directory
automatically. When building on the host, on the other hand, the user is
responsible for removing the half-built subdirectories of the main build
directory after investigating the errors.

Inside the main build directory (which is `./build` by default), each build step
corresponds to `{build step}-{target triple}` subdirectory (it depends on the
particular build step, whether this subdirectory is created or not) and a
corresponding stamp file with `.stamp` suffix (which is always created **after**
the build step finishes successfully):
* the step is skipped if corresponding stamp file exists (whether the directory
  exists or not)
* an error is reported if a half-built subdirectory exists without a stamp file
  indicating a successful build
* otherwise, a build step is performed and the stamp file is `touch`ed on
  success

Please note that each step is performed without taking the dependencies into
account, thus the user is responsible for removing the subdirectories
corresponding to the steps that have to be redone after some other steps (such
as rebuilding everything linking to `crt1.o` after the start files were
rebuilt). It is generally possible to simply remove the entire `./build` and
`./inst` subdirectories, since LLVM should be rebuilt rather quickly thanks to
ccache - the main reason for not removing `./build` automatically, aside from
simplifying the debugging in case of errors, is not to run `rm -rf` with
computed paths, as this can be harmful to the host system in case of
misconfiguration.
