nextflow.enable.dsl=2

process Dummy {
    debug true

    "echo Hello world from the updated workflow"
}

workflow {
    Dummy()
}
