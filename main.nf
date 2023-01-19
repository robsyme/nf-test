include { EXAMPLE } from './modules/main'
include { EXAMPLE as EXAMPLE_B } from './modules/main'

workflow {
    Channel.of("Nextflow")
    | ( EXAMPLE & EXAMPLE_B)
}
