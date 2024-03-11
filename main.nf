nextflow.enable.dsl=2

process TestGPU {
    debug true
    accelerator 1
    container 'pytorch/pytorch:latest'
    containerOptions = "--gpus 'all,capabilities=utility'"

    script: "nvidia-smi"
}

process TestPython {
    debug true
    accelerator 1
    container 'pytorch/pytorch:latest'
    containerOptions = "--gpus 'all,capabilities=utility'"

    script: "test.py"
}

workflow {
    TestPython()
    TestGPU()
}
