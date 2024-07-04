#!/usr/bin/env nextflow

process Dummy {
    debug true
    beforeScript 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y python3'
    input: val(memInGb)

    """
    #!/usr/bin/env python3
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
