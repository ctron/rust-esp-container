FROM debian:buster-slim

# -------------------------------------------------------------------
# Toolchain Version Config
# -------------------------------------------------------------------

# esp-idf framework
ARG IDF_VERSION="v4.0"

# llvm-xtensa
ARG CLANG_VERSION="248d9ce8765248d953c3e5ef4022fb350bbe6c51"
ARG LLVM_VERSION="757e18f722dbdcd98b8479e25041b1eee1128ce9"

# rust-xtensa
ARG RUSTC_VERSION="2d3ec14f587789a9cab55597e376ea15d76fd75e"

# -------------------------------------------------------------------
# Toolchain Path Config
# -------------------------------------------------------------------

ARG TOOLCHAIN="/home/esp32-toolchain"

ARG ESP_BASE="${TOOLCHAIN}/esp"
ENV IDF_PATH "${ESP_BASE}/esp-idf"

ARG LLVM_BASE="${TOOLCHAIN}/llvm"
ARG LLVM_PATH="${LLVM_BASE}/llvm_xtensa"
ARG LLVM_BUILD_PATH="${LLVM_BASE}/llvm_build"
ARG LLVM_INSTALL_PATH="${LLVM_BASE}/llvm_install"

ARG RUSTC_BASE="${TOOLCHAIN}/rustc"
ARG RUSTC_PATH="${RUSTC_BASE}/rust_xtensa"
ARG RUSTC_BUILD_PATH="${RUSTC_BASE}/rust_build"

ENV PATH "/root/.cargo/bin:${PATH}"

# -------------------------------------------------------------------
# Install expected depdendencies
# -------------------------------------------------------------------

RUN apt-get update \
 && apt-get install -y \
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
       libusb-1.0.0 \
       make \
       ninja-build \
       pkg-config \
       python \
       python-pip \
       python-virtualenv \
       wget \
 && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# Setup esp-idf
# -------------------------------------------------------------------

WORKDIR "${ESP_BASE}"
RUN  git clone \
       --recursive --single-branch -b "${IDF_VERSION}" \
       https://github.com/espressif/esp-idf.git \
 && cd "${IDF_PATH}" \
 && ./install.sh

# -------------------------------------------------------------------
# Build llvm-xtensa
# -------------------------------------------------------------------

WORKDIR "${LLVM_BASE}"
RUN mkdir "${LLVM_PATH}" \
 && cd "${LLVM_PATH}" \
 && git init \
 && git remote add origin https://github.com/espressif/llvm-xtensa.git \
 && git fetch --depth 1 origin "${LLVM_VERSION}" \
 && git checkout FETCH_HEAD \
 && mkdir -p "${LLVM_PATH}/tools/clang" \
 && cd "${LLVM_PATH}/tools/clang" \
 && git init \
 && git remote add origin https://github.com/espressif/clang-xtensa.git \
 && git fetch --depth 1 origin "${CLANG_VERSION}" \
 && git checkout FETCH_HEAD \
 && mkdir -p "${LLVM_BUILD_PATH}" \
 && cd "${LLVM_BUILD_PATH}" \
 && cmake "${LLVM_PATH}" \
       -DLLVM_TARGETS_TO_BUILD="Xtensa;X86" \
       -DLLVM_INSTALL_UTILS=ON \
       -DLLVM_BUILD_TESTS=0 \
       -DLLVM_INCLUDE_TESTS=0 \
       -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_INSTALL_PREFIX="${LLVM_BASE}/llvm_install" \
       -DCMAKE_CXX_FLAGS="-w" \
       -G "Ninja" \
 && ninja install \
 && rm -rf "${LLVM_PATH}" "${LLVM_BUILD_PATH}"

# -------------------------------------------------------------------
# Build rust-xtensa
# -------------------------------------------------------------------

WORKDIR "${RUSTC_BASE}"
RUN git clone \
        --recursive --single-branch \
        https://github.com/MabezDev/rust-xtensa.git \
        "${RUSTC_PATH}" \
 && mkdir -p "${RUSTC_BUILD_PATH}" \
 && cd "${RUSTC_PATH}" \
 && git reset --hard "${RUSTC_VERSION}" \
 && ./configure \
        --llvm-root "${LLVM_INSTALL_PATH}" \
        --prefix "${RUSTC_BUILD_PATH}" \
 && python ./x.py build \
 && python ./x.py install

# -------------------------------------------------------------------
# Setup rustup toolchain
# -------------------------------------------------------------------

RUN curl \
        --proto '=https' \
        --tlsv1.2 \
        -sSf \
        https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable \
 && rustup component add rustfmt \
 && rustup toolchain link xtensa "${RUSTC_BUILD_PATH}" \
 && cargo install cargo-xbuild bindgen

# -------------------------------------------------------------------
# Our Project
# -------------------------------------------------------------------

ENV PROJECT="/home/project/"

ENV XARGO_RUST_SRC="${RUSTC_PATH}/src"
ENV TEMPLATES="${TOOLCHAIN}/templates"
ENV LIBCLANG_PATH="${LLVM_INSTALL_PATH}/lib"
ENV CARGO_HOME="${PROJECT}target/cargo"

VOLUME "${PROJECT}"
WORKDIR "${PROJECT}"

COPY bindgen-project build-project create-project image-project xbuild-project flash-project /usr/local/bin/
COPY templates/ "${TEMPLATES}"

CMD ["/usr/local/bin/build-project"]
