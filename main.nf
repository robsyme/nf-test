nextflow.enable.dsl=2

process DebugCli {
    accelerator 1
    debug true

    "nvidia-smi"
}

process DebugScript {
    accelerator 1
    debug true

    "test.py"
}
 

workflow {
    DebugCli()
    DebugScript()
}
