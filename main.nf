nextflow.enable.dsl=2

process Dummy {
    debug true
    input: path(input)

    script:
    "cat ${input}"
}

workflow {
    Dummy(file("${projectDir}/assets/example.txt"))
}
