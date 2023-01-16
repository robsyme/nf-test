nextflow.enable.dsl=2

process Dummy {
    debug true

    "env"
}

workflow {
    Dummy()
}