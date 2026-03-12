#!/usr/bin/env nextflow

/*
 * MRE for FD-7315: Fusion compact symlink bug with directory outputs
 *
 * Reproduces a bug in Fusion v2.4.x where directory outputs are silently
 * lost when compact symlinks are enabled. The bug occurs when:
 *
 *   1. A process declares a directory as an output
 *   2. The process does NOT traverse the directory contents during execution
 *   3. Fusion's compact symlink mechanism diverts the directory from
 *      .fusion.symlinks but fails to compact it (because the directory's
 *      children are not populated in memory)
 *   4. Downstream tasks see the directory as a ~100-byte file instead of
 *      a directory
 *
 * The fix was applied in Fusion master (on-demand populateDirectory in
 * symlinkCompacter). This MRE should:
 *   - FAIL with Fusion <= v2.4.20 (compact symlinks enabled)
 *   - PASS with Fusion master or with compact symlinks disabled
 *   - PASS without Fusion (local/S3 native staging)
 *
 * See: https://support.seqera.io/a/tickets/7315
 */

params.num_samples = 3

workflow {
    samples = Channel.of(1..params.num_samples)

    // Step 1: Generate a directory with files inside
    GENERATE_DIR(samples)

    // Step 2: Passthrough — declares directory as output but does NOT
    //         traverse its contents. This triggers the bug: Fusion matches
    //         the directory against compact patterns (because it's in the
    //         outputs: header), excludes it from .fusion.symlinks, but
    //         then fails to compact it because m.directories is unpopulated.
    PASSTHROUGH(GENERATE_DIR.out.my_dir)

    // Step 3: Read files inside the directory — this fails when the
    //         directory is an orphaned compact symlink (a small file
    //         containing a path string instead of a real directory).
    READ_DIR(PASSTHROUGH.out.my_dir)
}


/*
 * Creates a directory containing several files.
 * Simulates STAR genome index generation.
 */
process GENERATE_DIR {
    input:
    val sample_id

    output:
    path "sample_${sample_id}_index", emit: my_dir

    script:
    """
    mkdir -p sample_${sample_id}_index
    echo "parameter_file_content_for_sample_${sample_id}" > sample_${sample_id}_index/parameters.txt
    dd if=/dev/urandom bs=1024 count=100 2>/dev/null > sample_${sample_id}_index/data.bin
    echo "metadata_for_sample_${sample_id}" > sample_${sample_id}_index/metadata.txt
    echo "Generated index directory for sample ${sample_id}"
    ls -la sample_${sample_id}_index/
    """
}


/*
 * Receives the directory as input, declares it as output, but does NOT
 * read any files inside it. This is the critical condition for the bug:
 *
 *   - The directory name matches the compact pattern (it's in the outputs)
 *   - Fusion excludes it from .fusion.symlinks
 *   - Fusion tries to compact it, but m.directories[target] is empty
 *     because no files inside the directory were accessed
 *   - symlinkCompacter returns nil silently
 *   - The directory remains as a small compact symlink file in S3
 *
 * The script only checks that the path exists (stat / test -e), which
 * Fusion can answer from metadata without populating the directory.
 */
process PASSTHROUGH {
    input:
    path index_dir

    output:
    path "${index_dir}", emit: my_dir

    script:
    """
    # Only check existence — do NOT list or read files inside the directory.
    # This ensures Fusion never populates m.directories for the target.
    if [ -e "${index_dir}" ]; then
        echo "PASSTHROUGH: ${index_dir} exists"
    else
        echo "PASSTHROUGH: ${index_dir} does not exist" >&2
        exit 1
    fi
    """
}


/*
 * Reads files inside the directory. This will fail if the directory is
 * actually an orphaned compact symlink (a ~100-byte file containing a
 * path string instead of a real directory).
 */
process READ_DIR {
    input:
    path index_dir

    output:
    path "result.txt"

    script:
    """
    echo "READ_DIR: Attempting to read files in ${index_dir}/"

    # This is the operation that fails in the bug scenario:
    # The directory is actually a small file, so this cat fails.
    if [ -f "${index_dir}/parameters.txt" ]; then
        echo "SUCCESS: parameters.txt content:" >> result.txt
        cat "${index_dir}/parameters.txt" >> result.txt
    else
        echo "FAILURE: ${index_dir}/parameters.txt not found or not a file" >&2
        echo "Checking what ${index_dir} actually is:"
        file "${index_dir}" >&2 || true
        ls -la "${index_dir}" >&2 || true
        # If it's a file (orphaned compact symlink), show its content
        if [ -f "${index_dir}" ]; then
            echo "Content of ${index_dir} (should be a directory, but is a file):" >&2
            cat "${index_dir}" >&2 || true
        fi
        exit 1
    fi

    # Verify all expected files are present
    for f in parameters.txt data.bin metadata.txt; do
        if [ ! -f "${index_dir}/\${f}" ]; then
            echo "FAILURE: Expected file ${index_dir}/\${f} not found" >&2
            exit 1
        fi
    done

    echo "All files verified in ${index_dir}/" >> result.txt
    echo "SUCCESS: All directory contents accessible"
    """
}
