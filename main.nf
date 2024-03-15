nextflow.enable.dsl=2

process Dummy {
    secret 'ROBSYME_SECRET'
    debug true

    script:
    """
    echo 'Hello world!'
    echo Found secret: \$ROBSYME_SECRET
    """
}

workflow {
    Dummy()
}
