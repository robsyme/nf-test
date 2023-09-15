nextflow.enable.dsl=2

params.input = "/vast/input.txt"

process Dummy {
    debug true

    script:
    """
    echo 'Hello world!'
    
    echo -n "Current working directory: "
    pwd
    
    echo "Contents of root directory:"
    ls -lh /

    echo "Contents of /rob:"
    ls -lh /rob || true
    echo "Contents of /vast:"
    ls -lh /vast || true
    """
}

process ReadFile {
    debug true
    input: path(input)
    script: "wc $input"
}

workflow {
    Dummy()
    Channel.fromPath(params.input) | ReadFile
}
