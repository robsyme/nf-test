nextflow.enable.dsl=2

process Dummy {
    debug true
    conda 'cowsay'

    "cowsay 'Hello world!'"
}

workflow {
    log.info "Found params: $params"
}
