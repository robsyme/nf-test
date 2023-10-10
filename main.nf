nextflow.enable.dsl=2

include { Terrible } from './modules/local/example'

workflow {
    Terrible()
}
