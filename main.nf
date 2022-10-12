#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.email = 'rob.syme@seqera.io'

process MakeTest {
    debug true
    publishDir "results"

    output:
    path("*.txt")

    'echo "Test Email Attachment" >> test.txt '
}

workflow {
    MakeTest()
}

workflow.onComplete {
    sendMail {
        to "${params.email}" 
        from "${params.email}"
        subject "My pipeline execution"
        body "test 123"
        attach "results/test.txt"
    }
}
