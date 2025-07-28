FROM ubuntu:24.04
RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        ccache \
        cmake \
        curl \
        g++ \
        git \
        libxml2-dev \
        make \
        ninja-build \
        python3 \
        rsync \
        squashfs-tools \
        unzip \
        xz-utils \
        zip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ARG REPO_ROOT

COPY cmake   /${REPO_ROOT}/cmake
COPY scripts /${REPO_ROOT}/scripts
COPY config  /${REPO_ROOT}
