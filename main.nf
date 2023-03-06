nextflow.enable.dsl=2

process Dummy {
    publishDir "${params.outdir}/Dummy", tags: [exampleTag: 'Hi all']
    debug true

    output:
    path("*.txt")

    "touch out.txt"
}

workflow {
    Dummy()
}
