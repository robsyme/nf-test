include { SayHi } from '../modules/seqera/sayhi'

workflow {
    Channel.of(params.name)
    | SayHi
    | view { "WorkflowA found: $it.text" }
}