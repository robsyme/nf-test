#!/usr/bin/env nextflow

include { validateParameters } from 'plugin/nf-schema'

params {
    bool_flag: Boolean = true
}

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    validateParameters()

    log.info "bool_flag = ${params.bool_flag}"
    log.info "bool_flag type = ${params.bool_flag.getClass()}"

    Dummy()
}
