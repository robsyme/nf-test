#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.email = 'rob.syme@seqera.io'

process MakeTest {
    debug true

    output:
    path("*.txt")

    exec:
    sendMail {
        to "${params.email}" 
        from "${params.email}"
        subject "My pipeline execution"
        body "test 123"
    }
}

workflow {
    MakeTest()
}