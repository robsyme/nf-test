nextflow.enable.dsl=2

process MakeBigFile {
    publishDir "${params.outdir}"
    memory '4G'

    input:
    val(i)

    output:
    path("*.dat")

    script:
    def filesize = new MemoryUnit(params.bigfilesize)
    """
    for j in `seq 1 ${params.bigfilecountmulti}`; do
        dd if=/dev/random bs=1M count=${filesize.toMega()} of=out.${i}.\${j}.dat
    done
    """
}

process MakeSmallFiles {
    publishDir "${params.outdir}"
    memory '4G'

    input:
    val(flag)

    output:
    path("*.dat")

    when:
    params.smallfilecount > 0

    script:
    def filesize = new MemoryUnit(params.smallfilesize)
    """
    dd if=/dev/zero bs=1M count=0 seek=${filesize.toMega()} of=out.small.template.dat
    for j in {1..${params.smallfilecount}}; do cp out.small.template.dat "out.small.\${j}.dat"; done
    rm -f out.small.template.dat
    """
}

process Summarize {
    input:
    val(signal)

    when:
    params.summarize

    "echo done"
}

workflow {
    Channel.of(0..params.bigfilecount)
    | filter { it > 0 } 
    | MakeBigFile
    | collect
    | map { true }
    | MakeSmallFiles
    
    MakeBigFile.out
    | mix(MakeSmallFiles.out)
    | collect 
    | map { true }
    | Summarize 
}