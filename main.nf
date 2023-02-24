nextflow.enable.dsl=2

process Dummy {
    cpus 1
    memory '1G'

    input:
    val(num)

    script:
    """
    sleep ${params.sleep}
    echo 'Hello world, found $num'
    """
}

workflow {
    Channel.of(1..(params.tasks))
    | Dummy
}
