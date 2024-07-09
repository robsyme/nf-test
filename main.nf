nextflow.enable.dsl=2

process Dummy {
    debug true

    "echo 'Hello world!'"
}

workflow {
    // lic = System.getenv().get("NXF_XPACK_LICENCE")
    // try {
    //     licenceBytes = lic.decodeBase64()
    //     jsonSlurper = new groovy.json.JsonSlurper()
    //     decoded = jsonSlurper.parse(licenceBytes)
    //     log.info "Licence valid! Licence version: ${decoded.ver}"
    // } catch (groovy.json.JsonException ex) {
    //     log.info "Licence not valid"
    // } catch (java.lang.NullPointerException ex) {
    //     log.info "Licence not valid"
    // } catch(Exception ex) {
    //     log.info "Some other exception ${ex}"
    // }

    isEnabled = session.config.navigate('tower.enabled')
    log.info "Tower enabled: $isEnabled"
}
