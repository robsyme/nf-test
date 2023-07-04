nextflow.enable.dsl=2

process TestCache {
    container 'thisdoesnotexist:latest'
    input: val(meta)
    output: tuple val(meta), path("*")
    script: "touch ${meta}.txt "
}

workflow {
    Channel.of(1)
    | TestCache
}
