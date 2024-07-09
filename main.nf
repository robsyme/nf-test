nextflow.enable.dsl=2

// import groovy.json.JsonSlurper

process Dummy {
    debug true

    "echo 'Hello world!'"
}

workflow {
    // jsonSlurper = new JsonSlurper()

    // lic = System.getenv().get("NXF_XPACK_LICENCE")
    // licenceBytes = lic.decodeBase64()
    // licString = new String(licenceBytes, java.nio.charset.StandardCharsets.UTF_8)
    // log.info "Found license: ${licString}"
    // stream = new ByteArrayInputStream(licenceBytes)
    // decoded1 = jsonSlurper.parse(stream)
    // println stream.getText()
    // decoded2 = jsonSlurper.parse(stream)
    // log.info "Decoded1: ${decoded1}"
    // log.info "Decoded2: ${decoded2}"
    // log.info "BuildInfo.version: ${nextflow.BuildInfo.version}"
    validator = nextflow.xpack.LicenseValidator
    log.info "Found validator: ${validator}"
}
