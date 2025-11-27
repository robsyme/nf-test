#!/usr/bin/env nextflow

workflow {
    log.info "Found parameters: ${params.s3_output_directory}"

    Dummy()
}

process Dummy {
    debug true
    script:
    """
    echo 'Found workflow: ${workflow.repository?.tokenize("/")?.last(2)?.join("/") ?: "local"}'
    echo 'Found task: ${task.process}'
    """
}
