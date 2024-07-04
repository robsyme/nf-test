include { SayBye } from '../modules/seqera/saybye'

workflow {
    Channel.of(params.moniker)
    | SayBye
    | view { "WorkflowB found: $it.text" }
}