nextflow.enable.dsl=2

workflow {
    html = Channel.fromPath("${baseDir}/assets/index.html")
    img = Channel.fromPath("${baseDir}/assets/seqera.png")
    DoSomething(html, img)
}

process DoSomething {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path(html)
    path(img)

    output:
    path("out/*")

    script:
    """
    mkdir -p out
    cp $html $img out/
    """
}
