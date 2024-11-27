nextflow.enable.dsl=2

process Dummy {
    debug true

    "echo 'Hello run $TOWER_WORKFLOW_ID!'"
}

workflow {
    Dummy()
}
