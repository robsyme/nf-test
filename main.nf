nextflow.enable.dsl=2

params.workflowId = TOWER_WORKFLOW_ID

process SayHi {
    debug true
    input: val(name)
    "echo 'Hello run $name!'"
}

workflow {
    SayHi(params.workflowId)
}
