FROM ubuntu:18.04

RUN apt update && apt install -y --no-install-recommends \
        curl \
        make \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG XMCM=aarch64-linux-musl

WORKDIR /tmp
RUN curl -so ${XMCM}-cross.tgz https://musl.cc/${XMCM}-cross.tgz \
 && tar -xf ${XMCM}-cross.tgz \
 && rm ${XMCM}-cross.tgz

ARG ZLIB_VERSION=1.2.11
WORKDIR /tmp
RUN curl -so zlib-${ZLIB_VERSION}.tar.gz https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
 && tar -xf zlib-${ZLIB_VERSION}.tar.gz \
 && rm zlib-${ZLIB_VERSION}.tar.gz

RUN apt update && apt install -y --no-install-recommends \
        binutils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN cd zlib-${ZLIB_VERSION} \
 && CC=/tmp/${XMCM}-cross/bin/${XMCM}-gcc \
        ./configure --prefix=/usr/local/zlib --static \
 && make -j$(nproc) \
 && make install

ARG OPENSSL_VERSION=1.1.1m
WORKDIR /tmp
RUN curl -so openssl-${OPENSSL_VERSION}.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
 && tar -xf openssl-${OPENSSL_VERSION}.tar.gz \
 && rm openssl-${OPENSSL_VERSION}.tar.gz

RUN apt update && apt install -y --no-install-recommends \
        perl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN cd openssl-${OPENSSL_VERSION} \
 && ./Configure \
        --prefix=/usr/local/openssl \
        --openssldir=/usr/local/openssl \
        --cross-compile-prefix=/tmp/${XMCM}-cross/bin/${XMCM}- \
        --static \
        --with-zlib-lib=/usr/local/zlib/lib \
        --with-zlib-include=/usr/local/zlib/include \
        no-tests \
        no-shared \
        zlib \
        linux-aarch64

WORKDIR /tmp
RUN cd openssl-${OPENSSL_VERSION} \
 && make -j$(nproc) \
 && make install_sw


ARG CMAKE_VERSION=3.22.1

WORKDIR /tmp
RUN curl -Lso cmake-${CMAKE_VERSION}.tar.gz https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
 && tar -xzf cmake-${CMAKE_VERSION}.tar.gz \
 && rm cmake-${CMAKE_VERSION}.tar.gz

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && CC=/tmp/${XMCM}-cross/bin/${XMCM}-gcc \
    CFLAGS="-static -g0 -s -Os" \
    CXX=/tmp/${XMCM}-cross/bin/${XMCM}-g++ \
    CXXFLAGS="-static -g0 -s -Os" \
    OPENSSL_ROOT_DIR=/usr/local/openssl \
    ZLIB_ROOT=/usr/local/zlib \
        ./bootstrap --system-zlib --parallel=$(nproc) -- \
            -DCMAKE_INSTALL_PREFIX=/cmake-package \
            -DCMAKE_USE_OPENSSL=ON

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && make -j$(nproc) \
 && make install

# (ref: https://cmake.org/pipermail/cmake/2018-October/068467.html)

