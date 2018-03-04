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

ENV CLANG_VERSION 5.0.0
ENV CLANG_NAME clang-5.0

RUN cd /usr/src/ \
    && wget "http://releases.llvm.org/$CLANG_VERSION/clang+llvm-$CLANG_VERSION-linux-x86_64-ubuntu16.04.tar.xz" -O clang.tar.xz \
    && tar -xf clang.tar.xz \
    && rm clang.tar.xz \
    && mv "/usr/src/clang+llvm-$CLANG_VERSION-linux-x86_64-ubuntu16.04/bin/$CLANG_NAME" /usr/bin/clang \
    && mv "/usr/src/clang+llvm-$CLANG_VERSION-linux-x86_64-ubuntu16.04/bin/llvm-ar" /usr/bin/llvm-ar \
    && mv "/usr/src/clang+llvm-$CLANG_VERSION-linux-x86_64-ubuntu16.04/bin/llvm-nm" /usr/bin/llvm-nm \
    && ln -s /usr/bin/clang /usr/bin/clang++ \
    && ln -s /usr/bin/llvm-ar /usr/bin/llvm-ranlib \
    && mkdir -p "/usr/lib/clang/$CLANG_VERSION" \
    && mv "/usr/src/clang+llvm-$CLANG_VERSION-linux-x86_64-ubuntu16.04/lib/clang/$CLANG_VERSION/include" "/usr/lib/clang/$CLANG_VERSION/." \
    && rm -rf /usr/src/clang*

ENV CC clang
ENV CXX clang++

ENV CLANG_RELEASE release_50

RUN cd /usr/src/ \
    && svn co "http://llvm.org/svn/llvm-project/llvm/branches/$CLANG_RELEASE" llvm \
    && cd llvm/projects \
    && svn co "http://llvm.org/svn/llvm-project/libcxx/branches/$CLANG_RELEASE" libcxx \
    && svn co "http://llvm.org/svn/llvm-project/libcxxabi/branches/$CLANG_RELEASE" libcxxabi \
    && cd .. \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make cxx \
    && make install-cxx install-cxxabi \
    && cp ../projects/libcxxabi/include/* /usr/local/include/c++/v1/. \
    && cd ../.. \
    && rm -rf llvm

RUN cd /usr/src/ \
    && git clone https://github.com/google/benchmark.git \
    && mkdir -p /usr/src/benchmark/build/ \
    && cd /usr/src/benchmark/build/ \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON -DRUN_HAVE_STD_REGEX=0 -DRUN_HAVE_POSIX_REGEX=0 .. \
    && make -j4 \
    && make install \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++" -DCMAKE_EXE_LINKER_FLAGS="-lc++abi" -DRUN_HAVE_STD_REGEX=0 -DRUN_HAVE_POSIX_REGEX=0 .. \
    && make clean all -j4 \
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
