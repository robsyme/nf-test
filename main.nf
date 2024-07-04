#!/usr/bin/env nextflow

process Dummy {
    debug true
    input: val(memInGb)

    """
    #!/usr/bin/env python
    import time
    try:
        foo = bytearray($memInGb * 1000000000)
        time.sleep(10)
    except MemoryError:
        print("Exiting afer MemoryError")
        exit(42)
    """
}

workflow {
    Channel.of(params.memory) | Dummy
}
