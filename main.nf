nextflow.enable.dsl=2

process CheckUlimit {
    debug true
    script: "ulimit -a"
}

workflow {
    CheckUlimit()
}
