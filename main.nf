nextflow.enable.dsl=2

workflow {
    Create()
    | Consume
    | view { "Contents of ${it}: ${it.text}"}
}

process Create {
    debug true

    output:
    path("hello.txt")

    script:
    "echo 'Hello world!' > hello.txt"
}

process Consume {
    input: path(input, stageAs: "one/two/input.txt")

    output: path("**/*.txt", includeInputs: true)

    script:
    ":"
}