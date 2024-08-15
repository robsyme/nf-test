nextflow.enable.dsl=2

process DebugCli {
    debug true
    accelerator 1

    "nvidia-smi"
}

process DebugScript {
    debug true
    accelerator 1
    memory '10G'

    "test.py"
}
 

workflow {
    DebugCli()
    DebugScript()
}
