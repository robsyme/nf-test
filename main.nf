nextflow.enable.dsl=2

params.name = "Value set in main.nf"

workflow {
    log.info "Full params: $params"
}
