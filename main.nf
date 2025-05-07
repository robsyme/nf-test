nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    log.info "Found params.outdir = ${params.outdir}"
}
