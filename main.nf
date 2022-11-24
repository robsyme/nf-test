nextflow.enable.dsl=2

process TakeTime {
    time '2m'

    "sleep 600"
}

workflow {
    TakeTime()
}