nextflow.enable.dsl=2

process Detect {
    debug true

    """
    #!/usr/bin/env python
    import torch
    if torch.cuda.is_available():
        print("CUDA found!")
        print(torch.cuda.current_device())
        print(torch.cuda.device(0))
        print(torch.cuda.get_device_name(0))
    else:
        print("CUDA not found")
    """
}

workflow {
    Detect()
}
