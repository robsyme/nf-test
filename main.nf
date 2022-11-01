#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.email = 'rob.syme@seqera.io'

process MakeTest {
    executor 'local'

    output:
    path("*.txt")

    "echo test > out.txt"
}

workflow {
    MakeTest() 
    | view
}