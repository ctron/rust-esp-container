FROM debian:buster-slim

# -------------------------------------------------------------------
# Install expected depdendencies
# -------------------------------------------------------------------

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
       bison \
       cmake \
       curl \
       flex \
       g++ \
       gcc \
       git \
       gperf \
       libncurses-dev \
       libssl-dev \
       libusb-1.0 \
       make \
       ninja-build \
       pkg-config \
       python \
       python-pip \
       python-virtualenv \
       wget \
 && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# Globals
# -------------------------------------------------------------------

ARG TOOLCHAIN="/opt/xtensa"

# -------------------------------------------------------------------
# Setup esp-idf
# -------------------------------------------------------------------

ARG IDF_BRANCH="release/v4.2"

ENV IDF_PATH="${TOOLCHAIN}/esp-idf"

RUN  git clone \
       -b "${IDF_BRANCH}" --depth 1 --recursive --single-branch \
       https://github.com/espressif/esp-idf.git \
       "${IDF_PATH}" \
 && cd ${IDF_PATH} \
 && ./install.sh

# -------------------------------------------------------------------
# Build llvm-xtensa
# -------------------------------------------------------------------

ARG LLVM_BRANCH="xtensa_release_10.0.1"
ARG LLVM_SRC="/tmp/llvm"
ARG LLVM_BUILD="${LLVM_SRC}/build"
ARG LLVM_INSTALL_PATH="${TOOLCHAIN}/llvm"

RUN git clone \
      -b "${LLVM_BRANCH}" --depth 1 --single-branch \
      https://github.com/espressif/llvm-project.git \
      "${LLVM_SRC}" \
 && mkdir -p "${LLVM_BUILD}" \
 && cd "${LLVM_BUILD}" \
 && cmake "${LLVM_SRC}/llvm" \
       -DLLVM_TARGETS_TO_BUILD="X86" \
       -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
       -DLLVM_ENABLE_PROJECTS="clang;lld" \
       -DLLVM_INSTALL_UTILS=ON \
       -DLLVM_INCLUDE_EXAMPLES=0 \
       -DLLVM_INCLUDE_TESTS=0 \
       -DLLVM_INCLUDE_DOCS=0 \
       -DLLVM_INCLUDE_BENCHMARKS=0 \
       -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_INSTALL_PREFIX="${LLVM_INSTALL_PATH}" \
       -DCMAKE_CXX_FLAGS="-w" \
       -G "Ninja" \
 && ninja install \
 && rm -rf "${LLVM_BUILD}" "${LLVM_SRC}"

# -------------------------------------------------------------------
# Build rust-xtensa
# -------------------------------------------------------------------

# rust-xtensa
ARG RUST_VERSION="xtensa-v0.2.0"
ARG RUST_SRC="${TOOLCHAIN}/rust_src"
ARG RUST_INSTALL_PATH="${TOOLCHAIN}/rust"

RUN git clone \
        -b "${RUST_VERSION}" --depth 1 --single-branch \
        https://github.com/MabezDev/rust-xtensa.git \
        "${RUST_SRC}" \
 && cd "${RUST_SRC}" \
 && ./configure \
        --disable-compiler-docs \
        --disable-docs \
        --enable-lld \
        --experimental-targets=Xtensa \
        --llvm-root "${LLVM_INSTALL_PATH}" \
        --prefix "${RUST_INSTALL_PATH}" \
 && python ./x.py build \
 && python ./x.py install \
 && python ./x.py clean
 
# -------------------------------------------------------------------
# Setup rustup toolchain
# -------------------------------------------------------------------

RUN curl \
        --proto '=https' \
        --tlsv1.2 \
        -sSf \
        https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable \
 && . $HOME/.cargo/env \
 && rustup toolchain link xtensa "${RUST_INSTALL_PATH}" \
 && cargo install bindgen cargo-xbuild

# -------------------------------------------------------------------
# Our Project
# -------------------------------------------------------------------

ARG PROJECT="/home/project/"

#ENV CARGO_HOME="${PROJECT}target/cargo"
ENV LIBCLANG_PATH="${LLVM_INSTALL_PATH}/lib"
ENV PATH="${LLVM_INSTALL_PATH}/bin:${RUST_INSTALL_PATH}/bin:${PATH}"
#ENV RUSTC="${RUST_INSTALL_PATH}/build/x86_64-unknown-linux-gnu/stage2/bin/rustc"
ENV XARGO_RUST_SRC="${RUST_SRC}/library"

VOLUME "${PROJECT}"
WORKDIR "${PROJECT}"

COPY bindgen-project quick-build entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
