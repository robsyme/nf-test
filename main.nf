nextflow.enable.dsl=2

process DebugCli {
    debug true

    "nvidia-smi"
}

process DebugScript {
    debug true

    "test.py"
}
 

workflow {
    DebugCli()
    DebugScript()
}
