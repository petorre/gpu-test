#! /bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -ex

# https://docs.pytorch.org/docs/stable/notes/get_start_xpu.html
# https://dgpu-docs.intel.com/driver/installation-lts2.html#ubuntu

# 1. Install system dependencies
apt-get update
apt-get install -y \
    gnupg \
    wget

# 2. Add GPU repository
wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
    gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg
echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy unified" | \
    tee /etc/apt/sources.list.d/intel-gpu-jammy.list
apt-get update

# 3. Install and configure GPU drivers
apt-get install -y \
    intel-opencl-icd \
    libze1 \
    libze-intel-gpu1 \
    clinfo \
    pciutils
mkdir -p /etc/OpenCL/vendors
ldconfig

# 4. Install additional packages required for PyTorch
apt-get install -y \
    libze-dev \
    intel-ocloc
apt-get clean
rm -rf /var/lib/apt/lists/*

