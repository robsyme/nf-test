nextflow.enable.dsl=2

process Example {
    debug true
    input: path(infile)

    "ls -lha"
}

workflow {
    Channel.fromPath(params.input)
    | Example
}
