nextflow.enable.dsl=2

params.input = "/pipeline/*.jar"

process TakeInput {
    debug true
    tag "Looking at: ${infile}"

    input:
    path(infile)

    """
    pwd
    ls -lha
    df -h
    ls -lh /pipeline
    """
}

process PeekEnvironment {
    debug true

    """
    pwd
    ls -lha
    df -h
    ls -lh /pipeline
    """
}

workflow {
    // PeekEnvironment()
    Channel.fromPath(params.input)
    | TakeInput
}