nextflow.enable.dsl=2

workflow {
    Create()
    | Consume
    | view
}

process Create {
    debug true

    output:
    path("hello.txt")

    script:
    "echo 'Hello world!' > hello.txt"
}

process Consume {
    input: path(input)

    output: path("*.txt", includeInputs: true)

    script:
    ":"
}