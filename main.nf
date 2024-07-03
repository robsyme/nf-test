workflow {
    Channel.of("Rob")
    | SayHi
}

process SayHi {
    publishDir params.outdir, mode: 'copy'
    input: val(name)
    output: path("*.txt")
    script: "echo 'Hi $name!' > out.${name}.txt"
}
