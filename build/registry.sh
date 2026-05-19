#!/bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -ex

docker run -d --restart always -p 5000:5000 --name local-registry registry:2
