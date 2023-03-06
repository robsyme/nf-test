nextflow.enable.dsl=2

process Dummy {
    publishDir "${params.outdir}/Dummy"
    debug true

    output:
    path("*.txt")

    "touch out.txt"
}

workflow {
    Dummy()
}
