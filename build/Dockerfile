# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM ubuntu:24.04

ARG BUILD_CPU
ARG BUILD_CUDA
ARG BUILD_XPU

ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# install Python with venv
RUN apt update && \
    apt install -y python3 python3.12-venv pip && \
    rm -rf /var/lib/apt/lists/*

COPY image/ /

RUN if [ "$BUILD_CPU" = "1" ]; then \
        /opt/prep_venv.sh cpu; \
    fi

RUN if [ "$BUILD_CUDA" = "1" ]; then \
        /opt/install_cuda.sh; \
        /opt/prep_venv.sh cuda; \
    fi

RUN if [ "$BUILD_XPU" = "1" ]; then \
        /opt/install_xpu.sh; \
        /opt/prep_venv.sh xpu; \
    fi

RUN groupadd -g 10001 gpu-test && \
    useradd -u 10001 -g gpu-test gpu-test
USER gpu-test

WORKDIR /root
ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK NONE
