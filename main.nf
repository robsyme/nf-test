nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    Dummy()

    log.info("The secret in workflow: ${secrets.TMPSECRET}")
}

