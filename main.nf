nextflow.enable.dsl=2

process Sup {
    debug true
    input: val(name)
    script: "sup $name"
}

workflow {
    Channel.from("Jordi", "Paolo")
    | Sup
}
