# Building on host

Set LLVM_SOURCE_DIR and MUSL_SOURCE_DIR in config, then run ./build-all.sh

# Building in docker container

Checkout LLVM and Musl sources under `./src` by running:

```
./docker.sh sources <llvm_repo_url> <musl_repo_url>
```

This creates shallow clones under `./src/llvm` and `./src/musl`.
The branches to fetch are intentionally hardcoded in `docker.sh`,
as well as the expected SHA1 hashes of commits to be checked out.

Note that the path to a local repository can be specified as `file:///path/to/repo`.

Build the toolchain by running

```
./docker.sh build
```

It can take quite long to build for the first time but rebuilding is fast
(but hopefully reproducible) due to `./ccache` volume being mounted from host.
This should produce an `./output/llvm-pauth.squashfs` image that can be mounted
on host (the toolchain is built assuming `/opt/llvm-pauth` as the installation
prefix).
