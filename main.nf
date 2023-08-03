nextflow.enable.dsl=2

process MakeFile {
    input: val(name)
    output: tuple val(name), path("out.txt")
    script: "echo $name > out.txt"
}

process UseFile {
    tag { name }
    cpus { infile.size() }
    input: tuple val(name), path(infile)
    script: "cat $infile $infile > doubled.txt"
}

workflow {
    Channel.of("Vince", "Rhonda", "Thomas", "Rob")
    | MakeFile
    | UseFile
}