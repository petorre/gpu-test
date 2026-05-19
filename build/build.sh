#! /bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

source config

USAGE="USAGE: ./build.sh [--build-cpu] [--build-cuda] [--build-xpu]"
BUILDARGS=""
if [[ $# -ne 0 ]]; then
    for var in "$@"; do
        case "$var" in
            "--build-cpu")
                BUILDARGS+=" --build-arg BUILD_CPU=1"
                ;;
            "--build-cuda")
                BUILDARGS+=" --build-arg BUILD_CUDA=1"
                ;;
            "--build-xpu")
                BUILDARGS+=" --build-arg BUILD_XPU=1"
                ;;
            *)
                echo "${USAGE}"
                exit 1
                ;;
        esac
    done
else
    echo "${USAGE}"
    exit 1
fi

if [[ ! -z $HTTP_PROXY || ! -z $HTTPS_PROXY ]]; then
    BUILDARGS+=" --build-arg HTTP_PROXY=${HTTP_PROXY}"
    BUILDARGS+=" --build-arg HTTPS_PROXY=${HTTPS_PROXY}"
    echo $BUILDARGS
fi
echo "Build arguments are: ${BUILDARGS}"

cmd="docker build ${BUILDARGS} -t ${IMAGENAME} ."
$cmd
