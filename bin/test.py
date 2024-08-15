#!/usr/bin/env python
import torch
import time

# Define a simple function to perform some calculations on the CPU
def cpu_computation(size):
    x = torch.rand(size, size)
    y = torch.rand(size, size)
    result = torch.mm(x, y)
    return result

# Define a simple function to perform some calculations on the GPU
def gpu_computation(size):
    x = torch.rand(size, size, device='cuda')
    y = torch.rand(size, size, device='cuda')
    result = torch.mm(x, y)
    torch.cuda.synchronize()  # Ensure the computation is done
    return result

# Define the size of the matrices
size = 1000

# Measure time for CPU computation
start_time = time.time()
cpu_result = cpu_computation(size)
cpu_time = time.time() - start_time
print(f"CPU computation time: {cpu_time:.4f} seconds")

# Measure time for GPU computation
start_time = time.time()
gpu_result = gpu_computation(size)
gpu_time = time.time() - start_time
print(f"GPU computation time: {gpu_time:.4f} seconds")

# Optionally, verify that the results are close (they should be if the calculations are the same)
if torch.allclose(cpu_result, gpu_result.cpu()):
    print("Results are close enough!")
else:
    print("Results differ!")

# Print the time difference
time_difference = cpu_time - gpu_time
print(f"Time difference (CPU - GPU): {time_difference:.4f} seconds")

