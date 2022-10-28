nextflow.enable.dsl=2

process Test {
    input:
    path(infile)

    output:
    path("data.txt")

    "du -sh $infile > data.txt"
}

workflow {
    Channel.fromPath(params.reads)
    | Test
    | view { it.text.trim() }
}