nextflow.enable.dsl=2

process MakeFile {
    input: val(name)
    output: path("out.txt")
    script: "echo $name > out.txt"
}

process UseFile {
    cpus { infile.size() }
    input: path(infile)
    script: "cat $infile $infile > doubled.txt"
}

workflow {
    Channel.of("Vince", "Rhonda", "Thomas", "Rob")
    | MakeFile
    | UseFile
}