workflow {
    Create()
    | Consume
    | GetContents
}

process Create {
    output: path("hello.txt")
    script: "echo 'Hello world!' > hello.txt"
}

process Consume {
    input: path("one/two/input.txt")
    output: path("**/two/*.txt", includeInputs: true)
    script: ":"
}

process GetContents {
    debug true
    input: path(input)
    script: "echo -n 'File contents: ' && cat $input"
}