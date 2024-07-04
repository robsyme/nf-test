process SayHi {
    input: val(name)
    output: path("out.txt")
    script: "echo 'Hello, $name!' > out.txt"
}