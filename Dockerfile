FROM ubuntu:18.04

RUN apt update && apt install -y --no-install-recommends \
        rsync \
        curl \
        rename \
        libssl-dev \
        build-essential \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN apt update && apt install -y --no-install-recommends \
        software-properties-common \
 && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
 && apt update && apt install -y --no-install-recommends \
        gcc-11 g++-11 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-11 \
 && rm -rf /var/lib/apt/lists/*

ARG XMCM=aarch64-linux-musl
ARG HVER=x86_64-linux-musl

WORKDIR /tmp
RUN curl -so ${HVER}-native.tgz https://musl.cc/${HVER}-native.tgz \
 && tar -xf ${HVER}-native.tgz \
 && rm ${HVER}-native.tgz

WORKDIR /tmp
RUN curl -so ${XMCM}-cross.tgz https://musl.cc/${XMCM}-cross.tgz \
 && tar -xf ${XMCM}-cross.tgz \
 && rm ${XMCM}-cross.tgz \
 && cd ${XMCM}-cross \
 && ln -sf /usr/lib/x86_64-linux-gnu/libc.so ${XMCM}/lib/ld-musl-aarch64.so.1 \
 && rm usr \
 && rsync -rLq . / \
 && cd /bin \
 && XMCM=${XMCM} rename 's/$ENV{XMCM}\-//g' * \
 && for k in g++ gcc gfortran; do \
        p=$(which /bin/${k}) || true \
        [ ! "x${p}" = "x" ] || continue \
        [ ! -e ${p}.orig ] || continue \
        mv ${p} ${p}.orig \
        echo > ${p} '#!/bin/sh' \
        echo >> ${p} "${k}.orig \${@} -static --static -g0 -s -O3" \
        chmod +x ${p}; \
    done

ARG CMAKE_VERSION=3.12.3

WORKDIR /tmp
RUN curl -Lso cmake-${CMAKE_VERSION}.tar.gz https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
 && tar -xzf cmake-${CMAKE_VERSION}.tar.gz \
 && rm cmake-${CMAKE_VERSION}.tar.gz

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && CC=/tmp/${HVER}-native/bin/gcc \
    CFLAGS="-static --static" \
    CXX=/tmp/${HVER}-native/bin/g++ \
    CXXFLAGS="-static --static" \
        ./bootstrap --parallel=$(nproc) -- -DCMAKE_INSTALL_PREFIX=/tmp/cmake_package

WORKDIR /tmp
RUN ln -sf /bin/g++ ${HVER}-native/bin/g++ \
 && ln -sf /bin/gcc ${HVER}-native/bin/gcc \
 && ln -sf /bin/ld ${HVER}-native/bin/ld \
 && ln -sf /bin/strip ${HVER}-native/bin/strip

#WORKDIR /tmp
#RUN cd /usr/lib/gcc/x86_64-linux-gnu/11 \
# && cp crtbeginS.o crtbeginT.o

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && make -j$(nproc)

# (ref: https://cmake.org/pipermail/cmake/2018-October/068467.html)

