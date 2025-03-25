nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    """
    echo "Counting up for 5 mins..."
    for i in {1..300}; do
        echo \$i
        sleep 1s
    done
    """
}

workflow {
    Dummy()
}
