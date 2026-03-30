#!/usr/bin/env nextflow

/*
 * MRE for FD-7351: Fusion rename fails with NoSuchKey when S3 keys
 * contain special characters like '+'.
 *
 * The bug is in Fusion <= v2.3.8 where the x-amz-copy-source header
 * is not URL-encoded, causing S3 to interpret '+' as a space.
 *
 * This pipeline creates files with '+' in their names and then
 * renames them using 'mv', which triggers Fusion's CopyObject path.
 */

params.sample_id = "SampleA+SampleB"

process CREATE_AND_RENAME {
    debug true

    output:
    path "output_${params.sample_id}/*"

    script:
    """
    mkdir -p "output_${params.sample_id}"

    # Create files with '+' in the path
    echo "test data" > "output_${params.sample_id}/results.txt"
    echo "log data"  > "output_${params.sample_id}/pipeline_v1.log"

    echo "=== Files before rename ==="
    ls -la "output_${params.sample_id}/"

    # Rename files - this triggers Fusion's CopyObject (mv = rename = copy + delete)
    # On Fusion <= v2.3.8 with S3, '+' in the path causes NoSuchKey because
    # the x-amz-copy-source header is not URL-encoded.
    mv "output_${params.sample_id}/results.txt" "output_${params.sample_id}/results.renamed.txt"
    mv "output_${params.sample_id}/pipeline_v1.log" "output_${params.sample_id}/pipeline_renamed.log"

    echo "=== Files after rename ==="
    ls -la "output_${params.sample_id}/"
    """
}

workflow {
    CREATE_AND_RENAME()
}
