process PeekEnvironment {
    debug true

    """
    pwd
    ls -lh
    df -h
    """
}

workflow {
    PeekEnvironment()
}