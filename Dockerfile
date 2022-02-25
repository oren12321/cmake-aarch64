FROM ubuntu:18.04

RUN apt update && apt install -y --no-install-recommends \
        rsync \
        curl \
        rename \
        make \
        ca-certificates \
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
 && rm ${XMCM}-cross.tgz

ARG CMAKE_VERSION=3.22.1

WORKDIR /tmp
RUN curl -Lso cmake-${CMAKE_VERSION}.tar.gz https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
 && tar -xzf cmake-${CMAKE_VERSION}.tar.gz \
 && rm cmake-${CMAKE_VERSION}.tar.gz

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && CC=/tmp/${HVER}-native/bin/${HVER}-gcc \
    CFLAGS="-static --static -g0 -s -Os" \
    CXX=/tmp/${HVER}-native/bin/${HVER}-g++ \
    CXXFLAGS="-static --static -g0 -s -Os" \
        ./bootstrap --parallel=$(nproc) -- \
            -DCMAKE_INSTALL_PREFIX=cmake-package \
            -DCMAKE_USE_OPENSSL=OFF

WORKDIR /tmp
RUN ln -sf /tmp/${XMCM}-cross/bin/${XMCM}-g++ ${HVER}-native/bin/${HVER}-g++ \
 && ln -sf /tmp/${XMCM}-cross/bin/${XMCM}-gcc ${HVER}-native/bin/${HVER}-gcc \
 && ln -sf /tmp/${XMCM}-cross/bin/${XMCM}-ld ${HVER}-native/bin/${HVER}-ld \
 && ln -sf /tmp/${XMCM}-cross/bin/${XMCM}-strip ${HVER}-native/bin/${HVER}-strip

WORKDIR /tmp
RUN cd cmake-${CMAKE_VERSION} \
 && make -j$(nproc) \
 && make install

# (ref: https://cmake.org/pipermail/cmake/2018-October/068467.html)

