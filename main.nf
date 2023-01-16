nextflow.enable.dsl=2

process Dummy {
    debug true

    "echo Hello world"
}

workflow {
    Dummy()
}