nextflow.enable.dsl=2

process Make {
    // publishDir "${params.outdir}", saveAs: { it.startsWith("reports/") ? null : it }
    publishDir "${params.outdir}"

    input: 
    val(name)

    output: 
    // path("$name")
    path("**/*.html")

    """
    run $name
    """
}

workflow {
    Channel.of("sampleA", "sampleB")
    | Make
}