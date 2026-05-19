#! /bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -ex

# 1. Install system dependencies
apt-get update && \
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2

# 2. Add GPU repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update

# 3. Install GPU drivers
VERSION=1.19.0-1
apt-get install -y \
    nvidia-container-toolkit=${VERSION} \
    nvidia-container-toolkit-base=${VERSION} \
    libnvidia-container-tools=${VERSION} \
    libnvidia-container1=${VERSION}
apt-get clean
rm -rf /var/lib/apt/lists/*
