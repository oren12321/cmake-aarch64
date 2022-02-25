ARG CMAKE_AARCH64_TAG
FROM --platform=linux/amd64 ${CMAKE_AARCH64_TAG} as builder

FROM --platform=linux/arm64 arm64v8/ubuntu:18.04

RUN apt update && apt install -y --no-install-recommends \
        rsync \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /cmake-package /tmp/cmake-package

WORKDIR /tmp/cmake-package
RUN rsync -rLq . /usr \
 && rm -rf /tmp/*

WORKDIR /app

ENTRYPOINT ["cmake", "--version"]

