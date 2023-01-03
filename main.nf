process Canada {
    memory params.canada_mem
    input:
    val(i)
    
    "echo ${task.index} for Canada"
}

process Spain {
    memory params.spain_mem
    input:
    val(i)

    "echo ${task.index} for Spain"
}

workflow {
    Channel.from(1..params.counter)
    | (Canada & Spain)
}