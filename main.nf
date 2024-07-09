nextflow.enable.dsl=2

process Dummy {
    debug true

    "echo 'Hello world!'"
}

workflow {
    lic = System.getenv().get("NXF_XPACK_LICENSE")
    log.info "Found license: ${lic}"
}
