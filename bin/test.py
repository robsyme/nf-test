#!/usr/bin/env python
import numpy as np
import cupy as cp
import time

# Define a simple function to perform some calculations
def cpu_computation(size):
    x = np.random.rand(size, size)
    y = np.random.rand(size, size)
    result = np.dot(x, y)
    return result

def gpu_computation(size):
    x = cp.random.rand(size, size)
    y = cp.random.rand(size, size)
    result = cp.dot(x, y)
    cp.cuda.Stream.null.synchronize()  # Ensure the computation is done
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
if np.allclose(cpu_result, cp.asnumpy(gpu_result)):
    print("Results are close enough!")
else:
    print("Results differ!")

# Print the time difference
time_difference = cpu_time - gpu_time
print(f"Time difference (CPU - GPU): {time_difference:.4f} seconds")
