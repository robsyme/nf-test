nextflow.enable.dsl=2

process MakeFile {
    publishDir "${params.outdir}"

    input:
    tuple val(i), val(filesize)

    output:
    path("*.dat")

    "truncate -s ${filesize.toMega()}M out.${i}.dat"
}

workflow {
    def filesize = new MemoryUnit(params.filesize)
    Channel.of(1..params.count) 
    | combine([filesize])
    | MakeFile
}