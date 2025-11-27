#!/usr/bin/env nextflow

workflow {
    log.info "Found parameters: ${params}"

    Dummy()
}

process Dummy {
    output: path("output.txt")
    script: "echo 'This is a dummy task.' > output.txt"
}
