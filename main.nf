nextflow.enable.dsl=2

process MakeFile {
    publishDir "${params.outdir}"

    input:
    tuple val(i), val(filesize)

    output:
    path("*.dat")

    "dd if=/dev/zero of=out.${i}.dat bs=${filesize.toMega()}M count=1"
}

workflow {
    def filesize = new MemoryUnit(params.filesize)
    Channel.of(1..params.count) 
    | combine([filesize])
    | MakeFile
}