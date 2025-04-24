nextflow.enable.dsl=2

def getFileLength(Path file) {
    file.readLines().size()
}

process Dummy {
    debug true

    output: path("out.txt")

    script:
    """
    echo 'Hello world!' >> out.txt
    echo 'Hello world!' >> out.txt
    """
}

workflow {
    Dummy()
    | map { file -> getFileLength(file) }
    | view { length -> "Found file of length: ${length}"}
}
