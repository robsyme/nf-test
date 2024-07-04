include { SayBye } from '../modules/seqera/saybye'

workflow {
    Channel.of(params.name)
    | SayBye
    | view
}