nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    """
    echo "Counting up for 1 hour..."
    for i in {1..3600}; do
        echo \$i
        sleep 1s
    done
    """
}

workflow {
    Dummy()
}
