#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process PredictPPI {
    publishDir(
        path: "${params.s3_publish}",
        mode: 'copy',
    )
    accelerator 1
    input:
    tuple path(interactions), path(embeddings), path(weights)
    
    output:
    path "*"

    script:
    """
    conda run -n ppi_prediction /app/predict_parameterized.py \
    -interactions $interactions \
    -embeddings $embeddings \
    -weights $weights
    """
}

workflow {
    Channel.fromPath(params.index) \
        | splitCsv(header:true) \
        | map { row -> [file(row.interactions), file(row.embeddings), file(row.weights)] } \
        | PredictPPI
}
