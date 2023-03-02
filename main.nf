nextflow.enable.dsl=2

process Dummy {
    debug true

    output:
    path("*.txt")

    "touch out.txt"
}

workflow {
    Dummy()
}
