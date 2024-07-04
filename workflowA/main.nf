include { SayHi } from '../modules/seqera/sayhi'

workflow {
    Channel.of(params.name)
    | SayHi
    | view
}