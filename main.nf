nextflow.enable.dsl=2

process Sleeper {
    """
    for i in {1..1000}; do
        echo "Hello world \$i" >> out.txt
        sleep 1
    done
    """
}

workflow {
    Sleeper()
}
