FROM ubuntu:18.04

MAINTAINER Fred Tingaud <ftingaud@hotmail.com>

USER root

RUN apt-get update && apt-get -y install \
   git \
   cmake \
   libfreetype6-dev \
   flex \
   bison \
   binutils-dev \
   zlib1g-dev \
   libiberty-dev \
   libelf1 \
   libmpc-dev \
   g++ \
   curl \
   xz-utils \
   wget \
   software-properties-common \
   subversion \
   && add-apt-repository ppa:ubuntu-toolchain-r/test \
   && apt-get update \
   && apt-get upgrade -y libstdc++6 \
   && rm -rf /var/lib/apt/lists/*

ENV CC gcc
ENV CXX g++

RUN cd /usr/src/ \
    && git clone https://github.com/torvalds/linux.git \
    && cd linux \
    && git checkout tags/v4.14 \
    && cd tools/perf \
    && make \
    && cp perf /usr/bin \
    && cd /usr/src \
    && rm -rf linux

ENV CLANG_RELEASE llvmorg-7.0.0

RUN cd /usr/src \
    && git clone https://github.com/llvm/llvm-project.git \
    && cd llvm-project \
    && git checkout $CLANG_RELEASE \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi" ../llvm \
    && make -j"$(nproc)" \
    && make install \
    && make cxx \
    && make install-cxx install-cxxabi \
    && cp ../libcxxabi/include/* /usr/local/include/c++/v1/. \
    && cd ../.. \
    && rm -rf llvm-project \
    && cd /usr/local/bin \
    && rm clang-check opt llvm-lto2 llvm-lto llc llvm-c-test llvm-dwp clang-import-test lli c-index-test bugpoint llvm-mc llvm-objdump sancov llvm-rtdyld dsymutil clang-refactor llvm-exegesis clang-rename clang-func-mapping llvm-cfi-verify


ENV CC clang
ENV CXX clang++

RUN cd /usr/src/ \
    && git clone https://github.com/google/benchmark.git \
    && mkdir -p /usr/src/benchmark/build/ \
    && cd /usr/src/benchmark/build/ \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON -DRUN_HAVE_STD_REGEX=0 -DRUN_HAVE_POSIX_REGEX=0 .. \
    && make -j"$(nproc)" \
    && make install \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++" -DCMAKE_EXE_LINKER_FLAGS="-lc++abi" -DRUN_HAVE_STD_REGEX=0 -DRUN_HAVE_POSIX_REGEX=0 .. \
    && make clean all -j"$(nproc)" \
    && cp src/libbenchmark.a /usr/local/lib/libbenchmark-cxx.a

RUN svn checkout https://github.com/ericniebler/range-v3/tags/0.3.0/include /usr/include

RUN apt-get autoremove -y git \
    cmake \
    flex \
    bison \
    binutils-dev \
    zlib1g-dev \
    libiberty-dev \
    curl \
    xz-utils \
    wget \
    subversion \
    software-properties-common

RUN useradd -m -s /sbin/nologin -N -u 1000 builder

COPY ./annotate /home/builder/annotate

COPY ./build /home/builder/build

COPY ./run /home/builder/run

COPY ./build-libcxx /home/builder/build-libcxx

USER builder

WORKDIR /home/builder
