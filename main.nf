nextflow.enable.dsl=2

process Dummy {
    debug true
    script: "ls -lha /opt/aws/amazon-cloudwatch-agent"
}

workflow {
    Dummy()
}
