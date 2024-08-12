nextflow.enable.dsl=2

process UseMem {
    memory '5 GB'

    input: val(mem)
    script: "allocate.py $mem"
}

workflow {
    Channel.of(1..3) | UseMem
}
