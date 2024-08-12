#!/usr/bin/env python3
import sys
import time

def allocate_memory(num_bytes, num_blocks):
    result = ['\0' * num_bytes for _ in range(num_blocks)]
    return result

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <num_gb>")
        sys.exit(1)
    
    num_gb = int(sys.argv[1])
    # num_bytes = int(sys.argv[1])
    # num_blocks = int(sys.argv[2])
    
    result = allocate_memory(1024 * 1024 * 1024, num_gb)
    print(f"Allocated {len(result)} 1 GB blocks.")

    # Sleep for 2 minutes (120 seconds)
    print("Memory allocated. Sleeping for 2 minutes...")
    time.sleep(120)
    
    print("Program finished.")
