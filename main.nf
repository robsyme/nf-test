nextflow.enable.dsl=2

process MakeFile {
    input: tuple val(company), val(name)
    output: tuple val(company), path("out.txt")
    script: "sleep \$((RANDOM % 4)); echo $name > out.txt"
}

workflow {
    Channel.of(["Seqera", "Rob S"], ["Altos", "Rob L"], ["Seqera", "Harshil P"], ["Altos", "Felix K"])
    | MakeFile
    | groupTuple(sort: true)
    | view
}
