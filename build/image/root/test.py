# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

import time
import torch
import device_redirect  # XPU or CPU

SIZE = 10000
print("=== Device Test with Data Transfer ===\n")
device = torch.device('cuda')
device_name = f"GPU: {torch.cuda.get_device_name(0)}"
print(f"Device: {device}\n{device_name}\nPyTorch: {torch.__version__}\n")

indices = torch.arange(SIZE * SIZE).reshape(SIZE, SIZE)
cpu_data = indices.float()
print(f"Data size: {cpu_data.element_size() * cpu_data.nelement() / 1024**2:.2f} MB")

print(f"\nMoving data to {device}...")
start = time.time()
device_data = cpu_data.cuda()
torch.cuda.synchronize()
transfer_time = time.time() - start
print(f"Transfer time: {transfer_time:.4f} seconds")

print(f"Performing matrix multiplication...")
start = time.time()
result = torch.mm(device_data, device_data.T)
torch.cuda.synchronize()
compute_time = time.time() - start
print(f"Compute time: {compute_time:.4f} seconds")

cpu_result = result.cpu()
print(f"\nResult shape: {cpu_result.shape}")
print(f"Sample value at [0,0]: {cpu_result[0,0]:.2f}")
