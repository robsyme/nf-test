nextflow.enable.dsl=2

process FusionTest {
    script: "echo -e 'Test' >> job_stats.txt"
}

workflow {
    FusionTest()
}