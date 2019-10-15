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
   software-properties-common \
   zip \
   unzip \
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

ENV GCC_VERSION 6.4.0

RUN curl -fSL "http://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz" -o gcc.tar.xz \
    && mkdir -p /usr/src/gcc \
    && tar -xf gcc.tar.xz -C /usr/src/gcc --strip-components=1 \
    && rm gcc.tar.xz* \
    && cd /usr/src/gcc \
    && sed -i "s/struct ucontext/ucontext_t/g" libgcc/config/i386/linux-unwind.h \
    && sed -i "s/struct ucontext/ucontext_t/g" libjava/include/x86_64-signal.h \
    && sed -i "s/struct sigaltstack/stack_t/g" libsanitizer/sanitizer_common/sanitizer_linux.cc \
    && sed -i "s/struct sigaltstack\([^;]\)/stack_t\1/g" libsanitizer/sanitizer_common/sanitizer_linux.h \
    && sed -i "s/#include \"sanitizer_platform_limits_posix\.h\"/#include \"sanitizer_platform_limits_posix\.h\"\n#include \"bits\/types\/stack_t\.h\"/g" libsanitizer/sanitizer_common/sanitizer_linux.h \
    && sed -i "s/struct sigaltstack/stack_t/g" libsanitizer/sanitizer_common/sanitizer_stoptheworld_linux_libcdep.cc \
    && sed -i "s/resolv\.h/bits\/types\/res_state\.h/g" libsanitizer/tsan/tsan_platform_linux.cc \
    && mkdir build \
    && cd build \
    && /usr/src/gcc/configure --disable-multilib \
    && make -j4 \
    && make install-strip \
    && cd ../.. \
    && rm -rf gcc

ENV LD_LIBRARY_PATH /usr/local/lib64/

RUN cd /usr/src/ \
    && git clone https://github.com/google/benchmark.git \
    && cd /usr/src/benchmark \
    && git checkout v1.3.0 \
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
    unzip \
    subversion \
    zip \
    software-properties-common


RUN useradd -m -s /sbin/nologin -N -u 1000 builder

COPY ./annotate /home/builder/annotate

COPY ./build /home/builder/build

COPY ./run /home/builder/run

USER builder

WORKDIR /home/builder
