#!/usr/bin/env nextflow

process Dummy {
    debug true

    input:
    val message

    script:
    "echo 'message=${message}'"
}

workflow {
    Dummy(params.input)
}
