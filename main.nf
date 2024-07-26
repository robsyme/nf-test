nextflow.enable.dsl=2


workflow {
    Dummy()
}


process Dummy {
    publishDir params.outdir

    output: path('outputs/*.txt')

    """
    mkdir outputs
    echo "Hello, world!" > outputs/example.txt
    echo "Hello, world!" > outputs/another.txt
    """
}   