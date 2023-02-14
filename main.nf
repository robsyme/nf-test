nextflow.enable.dsl=2

process FindSize {
    input: path(infile)
    output: path("outfile.txt")
    script: "du -sh . > outfile.txt"
}

workflow {
    Channel.fromPath(params.input)
    | FindSize
}
