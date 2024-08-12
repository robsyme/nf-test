nextflow.enable.dsl=2

process UseMem {
    memory '5 GB'

    input: val(i)
    script: "allocate.py $i $i"
}

workflow {
    Channel.of(1..3) | UseMem
}
