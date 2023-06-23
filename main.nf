nextflow.enable.dsl=2

process Hardlink {
    input: path(input)
    output: path("out.txt")
    script: "ln $input out.txt"
}

workflow {
    Channel.of("one", "two", "three")
    | collectFile(name: 'numbers.txt', newLine: true)
    | Hardlink
    | view
}
