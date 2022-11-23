process Make {
    publishDir "${params.outdir}", saveAs: { it.startsWith("reports/") ? null : it }

    input: 
    val(name)

    output: 
    path("sample*")
    path("reports/*")

    """
    run $name
    mkdir -p reports
    find $name -name '*.html' -exec cp {} reports/ \\;
    """
}

workflow {
    Channel.of("sampleA", "sampleB")
    | Make
}