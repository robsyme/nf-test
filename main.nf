nextflow.enable.dsl=2

params.num_files = 100
params.filesize = '5GB'

process Waitlift {
    debug true
    input: tuple val(num_files), val(size)    
    script: "waitlift make --num $num_files --size $size data"
}

workflow {
    num_files = Channel.of(params.num_files)
    sizes = Channel.of((params.filesize as nextflow.util.MemoryUnit).toMega())

    num_files
    | combine(sizes)
    | Waitlift
}
