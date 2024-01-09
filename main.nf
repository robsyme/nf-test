nextflow.enable.dsl=2

process Dummy {
    publishDir "${params.outdir}/${name}", tags: [type: "demonstration"], overwrite: true
    input: val(name)
    output: path("out.txt")
    script: "echo '$name' > out.txt"
}

workflow {
    // Channel.of("Nextflow", "Seqera") | Dummy
    log.info (params.withdefault ? "withdefault is true" : "withdefault is false")
    log.info (params.defaultisnull ? "defaultisnull is true" : "defaultisnull is false")
}
