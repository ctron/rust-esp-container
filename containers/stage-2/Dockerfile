FROM quay.io/ctron/rust-esp-stage-1:develop

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
ARG RUST_REF=xtensa-target
RUN git clone -b ${RUST_REF} https://github.com/MabezDev/rust-xtensa.git \
 && mkdir /rust_build \
 && cd rust-xtensa \
 && ./configure --llvm-root="/llvm_build" --prefix="/rust_build" \
 && python ./x.py build \
 && python ./x.py install \
 && cd ..

RUN /rust_build/bin/rustc --print target-list | grep xtensa
