FROM alpine:edge AS builder
# todo: fix version as soon as clang-14 is available outside of edge
ARG MARCH="x86-64-v3"
ARG CONAN_USER="none"
ARG CONAN_PW="none"


RUN apk update && \
    apk add \
    make cmake autoconf automake pkgconfig \
    gcc g++ gdb \
    clang clang-dev clang-libs clang-extra-tools clang-static lldb\
    openjdk11-jdk \
    pythonispython3 py3-pip \
    bash git libtool util-linux-dev linux-headers \
    && \
    apk add mold --repository=https://mirrors.edge.kernel.org/alpine/edge/testing

ARG CC="clang"
ARG CXX="clang++"
ENV CXXFLAGS="${CXXFLAGS} -march=${MARCH}"
RUN rm /usr/bin/ld && ln -s /usr/bin/mold /usr/bin/ld # use mold as default linker


# Compile more recent tcmalloc-minimal with clang-14 + -march
RUN git clone --quiet --branch gperftools-2.9.1 --depth 1 https://github.com/gperftools/gperftools
WORKDIR /gperftools
RUN ./autogen.sh
RUN ./configure \
    --enable-minimal \
    --disable-debugalloc \
    --enable-sized-delete \
    --enable-dynamic-sized-delete-support && \
    make -j$(nproc) && \
    make install
WORKDIR /

ARG UID=1000
ENV USER=builder
ENV GID=10000

RUN addgroup -S "$USER" && adduser -u "$UID" -S "$USER" -G "$USER"
USER "$USER"


# install and configure conan
ENV PATH=$PATH:/home/builder/.local/bin
RUN pip3 install --user conan && \
    conan user && \
    conan profile new --detect default && \
    conan profile update settings.compiler=clang default && \
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.compiler.cppstd=20 default && \
    conan profile update env.CXXFLAGS="${CXXFLAGS}" default && \
    conan profile update env.CXX="${CXX}" default && \
    conan profile update env.CC="${CC}" default && \
    conan profile update options.boost:extra_b2_flags="cxxflags=\\\"${CXXFLAGS}\\\"" default

# add conan repositories
RUN conan remote add dice-group https://conan.dice-research.org/artifactory/api/conan/tentris
RUN conan remote add tentris-private https://conan.dice-research.org/artifactory/api/conan/tentris-private
RUN conan user ${CONAN_USER} -p ${CONAN_PW} -r tentris-private