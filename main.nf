#!/usr/bin/env nextflow

/*
 * MRE for FD-7351: Fusion rename fails with NoSuchKey when S3 keys
 * contain special characters like '+'.
 *
 * This replicates the customer's actual command pattern from their
 * split-pipe pipeline: creating output in a directory with '+' in
 * the name, then renaming files within it.
 */

params.sample_id = "S1+wt"

process SPLITPIPE_INQC {
    debug true

    output:
    path "output_${params.sample_id}_INQC/*"
    path "INQC_${params.sample_id}.command.sh"

    script:
    """
    mkdir -p "output_${params.sample_id}_INQC/process"

    # Simulate split-pipe output files (matching customer's actual file structure)
    echo '{"run_proc_def": "test"}' > "output_${params.sample_id}_INQC/process/run_proc_def.json"
    echo "split-pipe log content" > "output_${params.sample_id}_INQC/split-pipe_v1_6_3.log"
    echo "barcode,count" > "output_${params.sample_id}_INQC/process/barcode_data.csv"

    echo "=== Files before rename ==="
    find "output_${params.sample_id}_INQC" -type f | sort

    # This is the exact rename pattern from the customer's .command.sh:
    # mv "output_S1+wt_INQC/split-pipe_v*.log" "output_S1+wt_INQC/split-pipe_S1+wt_INQC.log"
    mv output_${params.sample_id}_INQC/split-pipe_v*.log "output_${params.sample_id}_INQC/split-pipe_${params.sample_id}_INQC.log"

    # Also replicate the cat append pattern
    cat .command.sh >> "INQC_${params.sample_id}.command.sh"

    echo "=== Files after rename ==="
    find "output_${params.sample_id}_INQC" -type f | sort
    """
}

workflow {
    SPLITPIPE_INQC()
}
