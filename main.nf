nextflow.enable.dsl=2

process TestGPU {
    debug true
    accelerator 1
    container 'wave.seqera.io/wt/7cc987bfcc02/wave/build:pytorch--6549ec36d7c141e7'
    containerOptions = '-e NVIDIA_DRIVER_CAPABILITIES=utility'

    script: "nvidia-smi"
}

process TestPython {
    debug true
    accelerator 1
    container 'wave.seqera.io/wt/7cc987bfcc02/wave/build:pytorch--6549ec36d7c141e7'
    // containerOptions = '-e NVIDIA_DRIVER_CAPABILITIES=compute,utility --gpus all'

    script: "test.py"
}

workflow {
    TestPython()
    TestGPU()
}
