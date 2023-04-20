nextflow.enable.dsl=2

process Dummy {
    debug true

    """
    touch out.bam out.bam.bai
    touch sample_{A,B,C}.R{1,2}.fastq.gz
    ls -lh
    """
}

workflow {
    Dummy()
}
