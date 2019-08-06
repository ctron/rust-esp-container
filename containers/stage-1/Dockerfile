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
