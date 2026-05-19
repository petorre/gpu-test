#! /bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -ex

source config

docker rmi -f "${IMAGENAME}"
docker rmi -f "${IMAGEREPOUSER}/${IMAGENAME}"
echo "Manually delete remote repo image ${IMAGEREPOUSER}/${IMAGENAME}"
