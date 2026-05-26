# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

import torch

class CPU_CUDA:
    def is_available(self): return True
    def get_device_name(self, x): return "CPU (simulated)"
    def synchronize(self): pass
    def current_device(self): return 0
    def device_count(self): return 1
    def max_memory_allocated(self): return 0
    def reset_peak_memory_stats(self): pass

def setup_device():
    """Setup device redirection - XPU to CUDA, or CPU fallback if no GPU"""
    if hasattr(torch, 'xpu') and torch.xpu.is_available():
        # Redirect CUDA to XPU
        torch.cuda = torch.xpu
        torch.Tensor.cuda = torch.Tensor.xpu
        torch.version.cuda = getattr(torch.version, 'xpu', 'N/A')
    elif not torch.cuda.is_available():
        # CPU fallback with mock CUDA
        torch.cuda = CPU_CUDA()
        torch.Tensor.cuda = lambda self, *args, **kwargs: self
        # Preserve original device function to avoid recursion
        _original_device = torch.device
        torch.device = lambda x, **kwargs: _original_device('cpu') if x == 'cuda' else _original_device(x, **kwargs)

setup_device()
