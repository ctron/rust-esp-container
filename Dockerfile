FROM fedora:30

# Update system and install some build tools

RUN dnf -y update
RUN dnf -y install make automake gcc gcc-c++ kernel-devel git cmake ninja-build python file ncurses-devel flex bison gperf which

# Clone xtensa version of llvm & clang

ARG LLVM_REF=esp-develop
ARG CLANG_REF=esp-develop

RUN git clone -b ${LLVM_REF} https://github.com/espressif/llvm-xtensa.git
RUN git clone -b ${CLANG_REF} https://github.com/espressif/clang-xtensa.git llvm-xtensa/tools/clang

RUN mkdir llvm_build
WORKDIR llvm_build

RUN cmake ../llvm-xtensa -DLLVM_TARGETS_TO_BUILD="Xtensa;X86" -DCMAKE_BUILD_TYPE=Release -G "Ninja"
RUN cmake --build .

WORKDIR /

# Clone esp-idf

RUN git clone -b v3.3-beta3 --recursive https://github.com/espressif/esp-idf.git esp-idf

ENV IDF_PATH=/esp-idf
ENV PATH=$PATH:$IDF_PATH/tools
RUN /usr/bin/python -m pip install --user -r /esp-idf/requirements.txt

# Download xtensa-esp32 toolchain

ARG XTENSA_ESP32_VERSION=1.22.0-80-g6c4433a-5.2.0
RUN curl -o /xtensa-esp32-elf-linux64.tar.gz -L https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-${XTENSA_ESP32_VERSION}.tar.gz && mkdir /esp && cd /esp && tar xzf /xtensa-esp32-elf-linux64.tar.gz && rm /xtensa-esp32-elf-linux64.tar.gz
ENV PATH=$PATH:/esp/xtensa-esp32-elf/bin

RUN echo 'int main() {  printf("Hello world\n"); }' > test.c \
 && /llvm_build/bin/clang -target xtensa -fomit-frame-pointer -S  test.c -o test.S \
 && xtensa-esp32-elf-as test.S \
 && file a.out \
 && rm a.out test.c test.S

# RUN git clone https://github.com/MabezDev/rust-xtensa.git
ARG RUST_REF="fix/register_calculation"
RUN git clone -b ${RUST_REF} https://github.com/0ndorio/rust-xtensa.git \
 && mkdir /rust_build \
 && cd rust-xtensa \
 && ./configure --llvm-root="/llvm_build" --prefix="/rust_build" \
 && python ./x.py build \
 && python ./x.py install \
 && cd ..

RUN /rust_build/bin/rustc --print target-list | grep xtensa
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

# set up the build directory
RUN mkdir /build
VOLUME /build
WORKDIR /build

COPY create-project image-project bindgen-project build-project xargo-project /usr/local/bin/
RUN chmod a+x /usr/local/bin/*
COPY templates /templates

CMD /usr/local/bin/build-project

