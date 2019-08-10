FROM quay.io/ctron/rust-esp-stage-2:develop

# Clone esp-idf

RUN git clone -b v3.3-beta3 --recursive https://github.com/espressif/esp-idf.git esp-idf

ENV IDF_PATH=/esp-idf
ENV PATH=$PATH:$IDF_PATH/tools
RUN /usr/bin/python -m pip install --user -r /esp-idf/requirements.txt

# Install rust toolchain

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=$PATH:/root/.cargo/bin

RUN rustup component add rustfmt

# install bindgen
RUN cargo install bindgen
# set LIBCLANG_PATH for bindgen
ENV LIBCLANG_PATH=/llvm_build/lib

RUN rustup toolchain link xtensa /rust_build
RUN rustup run xtensa rustc --print target-list | grep xtensa

# add xargo
RUN cargo install xargo
ENV XARGO_RUST_SRC=/rust-xtensa/src
