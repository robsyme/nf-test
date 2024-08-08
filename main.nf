nextflow.enable.dsl=2

process Debug {
    accelerator 1
    debug true

    "nvidia-smi"
}

workflow {
    Debug()
}
