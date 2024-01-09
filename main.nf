nextflow.enable.dsl=2

params.name = WorkflowMain.getGenomeAttribute(params, 'name')

workflow {
    log.info (params.withdefault ? "withdefault is true" : "withdefault is false")
    log.info (params.defaultisnull ? "defaultisnull is true" : "defaultisnull is false")

    log.info "Full params: $params"
}
