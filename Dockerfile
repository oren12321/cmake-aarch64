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

ARG CMAKE_VERSION=3.22.1

WORKDIR /tmp
RUN curl -Lso cmake-${CMAKE_VERSION}.tar.gz https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
 && tar -xzf cmake-${CMAKE_VERSION}.tar.gz \
 && rm cmake-${CMAKE_VERSION}.tar.gz

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && CC=/tmp/${XMCM}-cross/bin/${XMCM}-gcc \
    CFLAGS="-static --static -g0 -s -Os" \
    CXX=/tmp/${XMCM}-cross/bin/${XMCM}-g++ \
    CXXFLAGS="-static --static -g0 -s -Os" \
        ./bootstrap --parallel=$(nproc) -- \
            -DCMAKE_INSTALL_PREFIX=/cmake-package \
            -DCMAKE_USE_OPENSSL=OFF

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && make -j$(nproc) \
 && make install

# (ref: https://cmake.org/pipermail/cmake/2018-October/068467.html)

