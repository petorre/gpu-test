#! /bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

if [[ "$USE_CPU" == "1" ]]; then
    export PATH="/opt/venv-cpu/bin:${PATH}"
fi
if [[ "$USE_CUDA" == "1" ]]; then
    gpumgrcmd="nvidia-smi --query-gpu=index,name --format=csv,noheader"
    gpufreememcmd="nvidia-smi --query-gpu=memory.free --format=csv,noheader | \
        cut -d' ' -f1"
    export PATH="/opt/venv-cuda/bin:${PATH}"
fi
if [[ "$USE_XPU" == "1" ]]; then
    gpumgrcmd="clinfo -l --raw | tail -1"
    gpufreememcmd="clinfo --raw | grep CL_DEVICE_GLOBAL_MEM_SIZE | awk '{print \$NF}'"
    export PATH="/opt/venv-xpu/bin:${PATH}"
fi

if [[ ! -z "${gpumgrcmd}" ]]; then
    echo "gpumgrcmd: ${gpumgrcmd}"
    echo -n "gpumgrcmdres: "
    eval ${gpumgrcmd}
    echo "gpufreememcmd: ${gpufreememcmd}"
    echo -n "gpufreememres: "
    eval ${gpufreememcmd}
fi

appcmd="python3 test.py"
echo "appcmd: ${appcmd}"
tmpfile=$( mktemp -p /mktemp )
eval ${appcmd} > "${tmpfile}"
echo -n "appcmdres: "
tail -1 $tmpfile | cut -d' ' -f5
echo -n "appcmddebug: "
awk '
    NF != 0 {
        sep = (NR==1 ? "" : "; ");
        printf "%s%s", sep, $0
    }
    END {
        print ""
    }
    ' "${tmpfile}"

sleep infinity

