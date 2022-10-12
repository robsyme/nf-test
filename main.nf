#!/usr/bin/env nextflow
params.email = 'rob.syme@seqera.io'

process MakeTest {
    debug true
    publishDir "results"

    output:
    path("*.txt") into test_ch

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
