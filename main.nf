nextflow.enable.dsl=2


include { validateParameters; paramsHelp; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'


process Dummy {
    debug true

    "echo 'Hello world!'"
}

workflow {
    validateParameters()
    log.info "Found: ${params.my_threshold}"
}
