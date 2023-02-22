nextflow.enable.dsl=2

process FusionTest {
    input: val(sample_id)
    script:
    """
    #which STAR-Fusion
    date 
    echo "ALL OK"
    now="\$(TZ=EST5EDT date +'%d-%b-%Y_%H%M') EDT"
    echo "============ Running STAR-Fusion \$now ============="
    echo -e "STAR-FUSION started at:\t \$now" > ${sample_id}.job_stats.txt
    mkdir ./tempdir_star
    export TMPDIR=./tempdir_star
    touch 123.txt
    cat 123.txt > abcdef.txt 
    now="\$(TZ=EST5EDT date +'%d-%b-%Y_%H%M') EDT"
    #echo "============ Finished STAR-Fusion \$now ============="
    echo -e "STAR-FUSION finished at:\t \$now" >> ${sample_id}.job_stats.txt
    cat <<-EOF > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
        container: "${task.container}"
    EOF
    """
}

workflow {
    Channel.of("foo") | FusionTest
}