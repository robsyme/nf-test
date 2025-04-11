nextflow.enable.dsl=2

process UnTar {
    input: path(tgz)
    output: path("*")
    script: "tar -xzvf ${tgz}"
}

workflow {
    Channel.fromPath(params.tgz)
    | UnTar
    | view
}
