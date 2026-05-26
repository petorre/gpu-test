# Sylva \ WG2 Validation \ Flavor Validation \ GPU test

## Target

Deploy a flavour cluster for GPU workloads. How to confirm if GPU-based application could run on it?

This test validates GPU device allocation, GPU manager accessing GPU, and dummy PyTorch-based app working on GPU. It confirms that DRA or dev. plugin can do device allocation, drivers configured, GPU manager and dummy app able to use GPU in a containerized environment.

## Build

Prerequisites: bash, Docker Engine.

For NVidia GPUs build image with

```
cd build
./build.sh --build-cuda
```

which will build Ubuntu-based container image with Container Toolkit, and Python virtual environment for that GPU.

For other build options like with Intel GPUs or CPUs do

```
./build.sh --help
```

Optionally modify [config](./config) file with your image repository, image name or k8s namespace to be used.

Optionally start local Docker Registry, or modify [push.sh](./build/push.sh) to authenticate to your image repository.

Push image to repository with

```
./push.sh
```

## Test

Prerequisites: bash, kubectl, jq, jo, awk.

Assumption is that GPU requirements were satisfied on Sylva k8s worker nodes.

Check and optionally edit lines in [config.json](./config.json) file.

```
./gpu-test.sh --help
```

will give

```
Usage: ./gpu-test.sh [OPTIONS]
  --debug                With debug field
  --config FILE          Config file
  --label KEY[=VALUE]    Only test nodes with label KEY[=VALUE]
  --node NAME            Only test node NAME
  --delete-ns            Delete k8s Namespace
```


```
./gpu-test.sh
```

should give something like

```
{
  "flavourValidation": {
    "testCases": [
      {
        "name": "gpu-test",
        "description": "Validate GPU allocation, run GPU manager and dummy app",
        "nodes": [
          {
            "name": "node1",
            "result": true,
            "debug": "gpumgrcmdres:_0,_NVIDIA_L4;_gpufreemem:_22564;_appcmdres:_333283328000.00;_appcmddebug:_===_Device_Test_with_Data_Transfer_===;_Device:_cuda;_GPU:_NVIDIA_L4;_PyTorch:_2.12.0+cu130;_Data_size:_381.47_MB;_Moving_data_to_cuda...;_Transfer_time:_0.1237_seconds;_Performing_matrix_multiplication...;_Compute_time:_0.2321_seconds;_Result_shape:_torch.Size([10000,_10000]);_Sample_value_at_[0,0]:_333283328000.00"
          }
        ],
        "timeStamps": {
          "startTime": "Tue May 19 10:22:11 UTC 2026",
          "stopTime": "Tue May 19 10:22:24 UTC 2026"
        }
      }
    ]
  }
}
```

Started with debug flag ```./gpu-test.sh --debug``` would override debug=false field in config.json.

## Validated OS, k8s distribution and server/VM with GPU

Ubuntu 24.04.4 LTS, k3s v1.35.4+k3s1, EC2 with L4.
