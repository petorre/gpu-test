#!/bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -ex

source config

if [[ -z "${IMAGEREPOUSER}" ]]; then
    echo "Set env var IMAGEREPOUSER. Exiting..."
    exit
fi

docker rmi -f "${IMAGEREPOUSER}/${IMAGENAME}"
docker tag "${IMAGENAME}" "${IMAGEREPOUSER}/${IMAGENAME}"
docker push "${IMAGEREPOUSER}/${IMAGENAME}"
