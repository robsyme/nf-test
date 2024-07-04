process SayBye {
    input: val(name)
    output: path("out.txt")
    script: "echo 'Goodbye, $name!' > out.txt"
}