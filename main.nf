nextflow.enable.dsl=2

process FusionTest {
    script: "echo 'Test' > job_stats.txt"
}

workflow {
    FusionTest()
}