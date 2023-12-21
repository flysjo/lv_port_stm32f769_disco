FROM "ubuntu:focal"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt-get install --no-install-recommends -y \
    apt-utils \
    locales \
    ca-certificates \
    ccache \
    curl \
    wget \
    flex \
    git \
    git-lfs \
    gperf \
    lcov \
    graphviz \
    build-essential \
    cmake \
    ninja-build \
    git \
    python3 \
    python3-pip \
    unzip \
    xz-utils \
    zip \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    gdb-multiarch \
    usbutils \
    autoconf automake texinfo libtool pkg-config libusb-1.0-0-dev \
    && apt clean

    # && update-alternatives --install /usr/bin/python python /usr/bin/python3 10 \
    # && python -m pip install --upgrade \
    # pip \
    # virtualenv \

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ARG OPENOCD_VER=v0.12.0


# Install all the required tools
RUN update-ca-certificates --fresh

# RUN git clone git://github.com/Dashlane/hidapi.git \
#     && cd hidapi \
#     && git checkout b00982f \
#     && ./bootstrap \
#     && ./configure --enable-static --disable-shared \
#     && make clean \
#     && make \
#     && export HIDAPI_LIBS="-L`pwd`/mac/.libs/ -lhidapi" \
#     && export PKG_CONFIG_PATH="`pwd`/pc/" \
#     && echo $HIDAPI_LIBS

RUN cd /usr/src/ \
    && git clone --depth 1 https://github.com/STMicroelectronics/OpenOCD.git --branch $OPENOCD_VER \
    && cd OpenOCD \
    && ./bootstrap \
    # && ./configure --enable-stlink --enable-jlink --enable-ftdi --enable-cmsis-dap \
    && ./configure --enable-stlink --enable-jlink --enable-ftdi \
    && make -j"$(nproc)" \
    && make install


# user name in container
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -G root,dialout \
    && usermod -a -G root $USERNAME \
    && usermod -a -G plugdev $USERNAME
