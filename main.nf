nextflow.enable.dsl=2

process UseMem {
    memory '5 GB'

    input: val(i)
    script: "allocate.py ${params.memory} ${params.time}"
}

workflow {
    UseMem()
}
