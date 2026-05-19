#! /bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -ex

USAGE="Usage: prep_env {cpu|cuda|xpu}"
if [[ -z $1 ]]; then
    echo "${USAGE}"
    exit 1
fi

function create_venv { # $1 = target dev, $2 = whl name, $3 = torch version
    if [[ -z "$2" ]]; then
        whlname="$1"
    else
        whlname="$2"
    fi
    if [[ -z "$3" ]]; then
        torchversion=""
    else
        torchversion="$3"
    fi

    python3 -m venv "/opt/venv-$1"
    export PATH="/opt/venv-$1/bin:$PATH"
    pip3 install --upgrade pip
    pip3 install numpy

    if [[ "${torchversion}" == "" ]]; then
        # torchvision torchaudio 
        pip3 install torch \
            --index-url "https://download.pytorch.org/whl/${whlname}"
    else
        pip3 install torch=="${torchversion}" \
            --index-url "https://download.pytorch.org/whl/${whlname}"
    fi
}

case $1 in
    "cpu" )
        create_venv cpu
        ;;
    "cuda" )
        create_venv cuda cu130
        ;;
    "xpu" )
        create_venv xpu xpu 2.9.0
        ;;
    *)
        echo "${USAGE}"
        exit 1
        ;;
esac
