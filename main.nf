nextflow.enable.dsl=2

process MakeFiles {
    publishDir path: "${params.outdir}/${sample_id}"

    input: 
    val(sample_id)

    output: 
    path(".command.*")
    path("${sample_id}/*")

    script:
    """
    mkdir "${sample_id}"
    echo example > ${sample_id}/${sample_id}_fastqc.txt
    echo example > ${sample_id}/${sample_id}_fastqc.html
    """
}

workflow {
    Channel.of("FOO", "BAR") | MakeFiles
}
