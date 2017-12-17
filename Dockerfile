FROM ubuntu:16.04

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
   libelf-dev \
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
    && git checkout tags/v4.9 \
    && cd tools/perf \
    && make \
    && cp perf /usr/bin \
    && cd /usr/src \
    && rm -rf linux

RUN cd /usr/src/ \
    && wget http://releases.llvm.org/3.9.1/clang+llvm-3.9.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz -O clang.tar.xz \
    && tar -xf clang.tar.xz \
    && rm clang.tar.xz \
    && mv /usr/src/clang+llvm-3.9.1-x86_64-linux-gnu-ubuntu-16.04/bin/clang-3.9 /usr/bin/clang \
    && mv /usr/src/clang+llvm-3.9.1-x86_64-linux-gnu-ubuntu-16.04/bin/llvm-ar /usr/bin/llvm-ar \
    && mv /usr/src/clang+llvm-3.9.1-x86_64-linux-gnu-ubuntu-16.04/bin/llvm-nm /usr/bin/llvm-nm \
    && ln -s /usr/bin/clang /usr/bin/clang++ \
    && ln -s /usr/bin/llvm-ar /usr/bin/llvm-ranlib \
    && mkdir -p /usr/lib/clang/3.9.1 \
    && mv /usr/src/clang+llvm-3.9.1-x86_64-linux-gnu-ubuntu-16.04/lib/clang/3.9.1/include /usr/lib/clang/3.9.1/. \
    && rm -rf /usr/src/clang*

ENV CC clang
ENV CXX clang++
    
RUN cd /usr/src/ \
    && git clone https://github.com/google/benchmark.git \
    && mkdir -p /usr/src/benchmark/build/ \
    && cd /usr/src/benchmark/build/ \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON .. \
    && make -j4 \
    && make install

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

USER builder

WORKDIR /home/builder
