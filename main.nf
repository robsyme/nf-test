nextflow.enable.dsl=2

params.outdir = 's3://scidev-testing'

workflow {
    Dummy() 
    | Publish
}

process Dummy {
    debug true

    output: path("dummy.txt")

    "echo 'Hello world!' > dummy.txt"
}

process Publish {
    publishDir "${params.outdir}"
    input: path(dummy)
    output: path("*.txt", includeInputs: true)
    script:
    """
    cat $dummy > duplicate.txt
    """
}