nextflow.enable.dsl=2

process MakeFile {
    publishDir "${params.outdir}"
    memory '4G'

    input:
    tuple val(i), val(filesize)

    output:
    path("*.dat")

    "dd if=/dev/zero bs=1M count=${filesize.toMega()} of=out.${i}.dat"
}

workflow {
    def filesize = new MemoryUnit(params.filesize)
    Channel.of(1..params.count) 
    | combine([filesize])
    | MakeFile
}