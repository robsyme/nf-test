process Make {
    publishDir "${params.outdir}", saveAs: { it.startsWith("reports/") ? null : it }

    input: 
    val(name)

    output: 
    path("$name")
    path("reports/*")

    script:
    """
    run $name
    mkdir -p reports
    find $name -name '*.pdf' -exec cp {} reports/ \\;
    """
}

workflow {
    Channel.of("one", "two")
    | Make
}