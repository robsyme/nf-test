nextflow.enable.dsl=2

process PeekEnvironment {
    debug true

    """
    pwd
    ls -lha
    df -h
    """
}

workflow {
    PeekEnvironment()
}