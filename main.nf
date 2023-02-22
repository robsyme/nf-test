nextflow.enable.dsl=2

process FusionTest {
    output: path("*.txt")
    script:
    """
    #now="\$(TZ=EST5EDT date +'%d-%b-%Y_%H%M') EDT"
    #echo -e "STAR-FUSION finished at:\t \$now" >> job_stats.txt
    echo -e "Test" >> job_stats.txt
    """
}

workflow {
    FusionTest()
    | view
}