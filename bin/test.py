#!/usr/bin/env python
import torch

def check_cuda():
    if torch.cuda.is_available():
        print("CUDA is available!")
    else:
        print("CUDA is not available.")

if __name__ == "__main__":
    check_cuda()
