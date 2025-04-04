workflow {
    Create()
    | Consume
    | GetContents
}

process Create {
    output: path("one")
    script: "mkdir -p one/two && echo 'Hello world!' > one/two/hello.txt"
}

process Consume {
    input: path("one")
    output: path("**/two/*.txt", includeInputs: true)
    script: ":"
}

process GetContents {
    debug true
    input: path(input)
    script: "echo -n 'File contents: ' && cat $input"
}