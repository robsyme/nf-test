#!/usr/bin/env nextflow

workflow {
    channel.of(1..60) | SLEEP_TASK
}

process SLEEP_TASK {
    cpus 1
    memory '2 GB'

    input: val x
    script:"sleep 600"
}