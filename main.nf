nextflow.enable.dsl=2

process Dummy {
    debug true
    containerOptions '--volume /opt/aws/amazon-cloudwatch-agent'
    script: "ls -lha /opt/aws/amazon-cloudwatch-agent"
}

workflow {
    Dummy()
}
