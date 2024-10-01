nextflow.enable.dsl=2

process UseMem {
    input:
    val duration
    val memory

    script: 
    "allocate.py ${memory.giga} ${duration.minutes}"
}

workflow {
    duration = Duration.of(params.time)
    memory = MemoryUnit.of(params.memory)
    UseMem(duration, memory)
}
