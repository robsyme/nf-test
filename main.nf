nextflow.enable.dsl=2

process FusionTest {
    output: path("*.txt")
    script:
    """
    #date 
    #echo "ALL OK"
    now="\$(TZ=EST5EDT date +'%d-%b-%Y_%H%M') EDT"
    #echo "============ Running STAR-Fusion \$now ============="
    #mkdir ./tempdir_star
    #export TMPDIR=./tempdir_star
    #touch 123.txt
    #cat 123.txt > abcdef.txt 
    #now="\$(TZ=EST5EDT date +'%d-%b-%Y_%H%M') EDT"
    #echo "============ Finished STAR-Fusion \$now ============="
    echo -e "STAR-FUSION finished at:\t \$now" >> job_stats.txt
    """
}

workflow {
    FusionTest()
    | view
}