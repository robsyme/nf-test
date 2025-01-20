nextflow.enable.dsl=2

params.size = 10

process Dummy {
    input: val(i)
    output: stdout

    """
    # Sleep a random time up to 2 minutes
    sleep \$((RANDOM % 120))
    echo done
    """
}

workflow {
    Channel.of(1..params.size)
    | Dummy
    | map { exit 0 }
}
