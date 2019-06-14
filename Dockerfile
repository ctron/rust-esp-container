FROM fedora:30

RUN dnf -y update
RUN dnf -y install make automake gcc gcc-c++ kernel-devel git cmake ninja-build python file ncurses-devel flex bison gperf which

RUN git clone https://github.com/espressif/llvm-xtensa.git
RUN git clone https://github.com/espressif/clang-xtensa.git llvm-xtensa/tools/clang

RUN mkdir llvm_build
WORKDIR llvm_build

RUN cmake ../llvm-xtensa -DLLVM_TARGETS_TO_BUILD="Xtensa;X86" -DCMAKE_BUILD_TYPE=Release -G "Ninja"

RUN cmake --build .

WORKDIR /
RUN git clone -b v3.3-beta3 --recursive https://github.com/espressif/esp-idf.git esp-idf

ENV IDF_PATH=/esp-idf
ENV PATH=$PATH:$IDF_PATH/tools
RUN /usr/bin/python -m pip install --user -r /esp-idf/requirements.txt

RUN curl -o /xtensa-esp32-elf-linux64.tar.gz -L https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz && mkdir /esp && cd /esp && tar xzf /xtensa-esp32-elf-linux64.tar.gz && rm /xtensa-esp32-elf-linux64.tar.gz
ENV PATH=$PATH:/esp/xtensa-esp32-elf/bin

RUN echo 'int main() {  printf("Hello world\n"); }' > test.c \
 && /llvm_build/bin/clang -target xtensa -fomit-frame-pointer -S  test.c -o test.S \
 && xtensa-esp32-elf-as test.S \
 && file a.out \
 && rm a.out test.c test.C

# RUN git clone https://github.com/MabezDev/rust-xtensa.git
RUN git clone -b xtensa-target https://github.com/MabezDev/rust-xtensa.git \
 && cd rust-xtensa \
 && mkdir /rust_build \
 && ./configure --llvm-root="/llvm_build" --prefix="/rust_build" \
 && python ./x.py build \
 && python ./x.py install \
 && rm -Rf rust-xtensa

RUN /rust_build/bin/rustc --print target-list | grep xtensa
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=$PATH:/root/.cargo/bin

RUN cargo install xargo
RUN cargo install bindgen
RUN rustup component add rustfmt

RUN rustup toolchain link xtensa /rust_build
RUN rustup run xtensa rustc --print target-list | grep xtensa

ENV XARGO_RUST_SRC=/rust-xtensa/src

RUN mkdir /build
VOLUME /build
WORKDIR /build


