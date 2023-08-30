nextflow.enable.dsl=2

process Dummy {
    publishDir "${params.outdir}"
    output: path("out.txt")
    script: "echo 'Hello world!' > out.txt"
}

workflow {
    Dummy()
}
