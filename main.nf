nextflow.enable.dsl=2

include { Waitlift } from './modules/local/waitlift'

params.num_files = 100
params.filesize = '1GB'

workflow {
    num_files = Channel.of(params.num_files)
    sizes = Channel.of((params.filesize as nextflow.util.MemoryUnit).toMega())

    num_files
    | combine(sizes)
    | Waitlift
}
