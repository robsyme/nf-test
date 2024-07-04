#!/usr/bin/env nextflow

process Dummy {
    debug true
    input: val(memInGb)

    """
    #!/usr/bin/env python
    import time
    foo = bytearray($memInGb * 1000000000)
    time.sleep(10)
    """
}

workflow {
    Channel.of(params.memory) | Dummy
}
