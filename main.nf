nextflow.enable.dsl=2

workflow {
    html = Channel.fromPath("${baseDir}/assets/index.html")
    img = Channel.fromPath("${baseDir}/assets/seqera.png")
    DoSomething(html, img)
}

process DoSomething {
    publishDir "${params.outdir}"

    input:
    path(html)
    path(img)

    output:
    path("*", includeInputs: true)

    script:
    "true"
}