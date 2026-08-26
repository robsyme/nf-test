#!/usr/bin/env nextflow

/*
 * MRE: Fusion silently drops the contents of a nested directory when a
 * directory tree is renamed twice inside the Fusion mount.
 *
 * Seen in the wild as nf-core/scrnaseq CELLRANGER_COUNT failing with
 *
 *     [error] Your reference doesn't appear to be indexed. Please run the mkreference tool
 *
 * `cellranger mkref` moves its output through chained directory renames
 * (martian join dir -> pipestance outs/ -> Nextflow scratch -> task workdir).
 * The second rename left only 4 of the 15 files in reference/star/ - the STAR
 * index files Genome, SA and SAindex among the casualties - and the task still
 * exited 0.
 *
 * MECHANISM (verified against v2.5.14, unchanged through v2.6.3 and master)
 *
 * 1. Rename() carries the "already populated" marker to the new path, but only
 *    for the top-level directory:
 *        entry_service.go:476  if v, ok := m.populated[oldPath]; ok {
 *        entry_service.go:477      m.populated[newPath] = v
 *
 * 2. moveEntries(), which walks the children recursively, never does the
 *    equivalent. Every nested directory therefore lands at its new path
 *    unpopulated, and the next rename re-lists it from the object store:
 *        entry_service.go:508  if _, ok := m.populated[e.Path()]; !ok && ...IsDirectory() {
 *        entry_service.go:509      _, _ = m.populateDirectory(ctx, e.Path(), children, true)
 *
 * 3. populateDirectory() is a wholesale replacement, not a merge. It builds the
 *    child set purely from dataStore.ListDirectory(), discards its `children`
 *    argument, and overwrites the cache:
 *        entry_service.go:1133 children = make([]Entry, 0, len(childrenMap))
 *        entry_service.go:1151 m.directories[path] = children
 *
 * 4. The replacement is guarded by `err == nil`, and an empty object-store
 *    prefix reports ErrNotFound:
 *        remote_store_adapter.go:208  // We assume that empty folders do not exist
 *                                     if err == nil && empty { ... err = fusion.ErrNotFound }
 *
 * So the loss needs the nested directory to be PARTIALLY materialised in S3:
 * at least one child present, so the listing is not empty, and at least one
 * absent, so it is incomplete. All-or-nothing is harmless either way.
 *
 * WHAT PUTS A CHILD IN S3 MID-TASK
 *
 * Not closing the file - Release() only decrements a refcount
 * (data_service_adapter.go:193). Not cache eviction - the garbage collector
 * thresholds are max(0.5*total, 50GB) free (chk_content_factory.go:92) and it
 * never fires on a mostly-empty cache disk. Not the snapshot feature - the
 * snapshot manager only signals the wrapped fusion-snapshot process
 * (manager.go:104), it does not flush the mount.
 *
 * It is the chunk writeback scheduler:
 *        chk_content_factory.go:25  const DefaultUploadDelay = 2 * time.Minute
 *        "Older chunks use shorter multiples to upload sooner."
 *
 * A file written and left alone reaches S3 roughly two minutes later. That is
 * what makes the loss look size-dependent in the wild: STAR writes
 * chrName.txt and friends at the start of genomeGenerate, so they were long
 * since uploaded, while the .tab files and the multi-GB Genome/SA/SAindex were
 * written in the last moments before the rename and had not been.
 *
 * The variants below straddle that 2 minute window in both directions.
 *
 * Requires a Fusion + Wave compute environment with an S3 work directory.
 * Outside Platform:
 *   nextflow run robsyme/nf-test -r fusion-nested-rename-drops-children \
 *       -w s3://<bucket>/work -with-wave -with-fusion
 */

// Fusion's chunk writeback base delay, in seconds. Seed files must be older
// than this to have reached S3; late files must be younger.
params.upload_delay = 120

process RENAME_TREE {
    tag "$label"
    debug true
    maxForks 1
    cpus 2
    memory '4 GB'

    input:
    tuple val(label), val(seed_wait), val(late_mb), val(gap), val(expect)

    output:
    path "report_${label}.txt"

    script:
    """
    set -euo pipefail

    stage=stage_${label}
    mkdir -p \$stage/nested/deeper

    # --- seed children: written first, then left alone long enough for the
    #     writeback scheduler to push them to the object store.
    for i in 01 02 03 04 05 06; do
        echo "seed-\$i" > \$stage/nested/seed_\$i.txt
    done
    echo "seed-deep" > \$stage/nested/deeper/seed_deep.txt
    echo "top"       > \$stage/top.txt

    echo "waiting ${seed_wait}s for the writeback scheduler..."
    sleep ${seed_wait}

    # --- late children: written immediately before the first rename, so their
    #     chunks are still dirty and no S3 object exists at either path.
    for i in 01 02 03 04 05 06; do
        echo "late-\$i" > \$stage/nested/late_\$i.txt
    done
    if [ ${late_mb} -gt 0 ]; then
        dd if=/dev/zero of=\$stage/nested/late_big.bin bs=1048576 count=${late_mb} 2>/dev/null
    fi

    find \$stage -type f | sed "s|^\$stage/||" | sort > expected.txt

    # --- rename 1: nested/ still has its correct in-memory child list.
    mv \$stage moved_${label}

    sleep ${gap}

    # --- rename 2: moveEntries() sees moved_*/nested as unpopulated, re-lists
    #     it from S3, and replaces the child list with whatever is there.
    mv moved_${label} final_${label}

    find final_${label} -type f | sed "s|^final_${label}/||" | sort > actual.txt
    comm -23 expected.txt actual.txt > missing.txt
    lost=\$(wc -l < missing.txt | tr -d ' ')

    {
        echo "variant         : ${label}"
        echo "seed wait       : ${seed_wait}s   (writeback delay is ~${params.upload_delay}s)"
        echo "late big file   : ${late_mb} MiB"
        echo "gap between mv  : ${gap}s"
        echo "expectation     : ${expect}"
        echo "files written   : \$(wc -l < expected.txt | tr -d ' ')"
        echo "files surviving : \$(wc -l < actual.txt | tr -d ' ')"
        echo "files lost      : \$lost"
        echo
        echo "-- survived --"
        cat actual.txt
        echo
        echo "-- LOST --"
        cat missing.txt
        echo
        if [ "\$lost" -gt 0 ]; then echo "VERDICT: FILES LOST"; else echo "VERDICT: intact"; fi
    } > report_${label}.txt

    cat report_${label}.txt
    """
}

process CHECK {
    debug true

    input:
    path reports

    script:
    """
    cat report_*.txt
    echo "=================================================================="

    lost=\$(grep -l 'VERDICT: FILES LOST' report_*.txt 2>/dev/null | wc -l | tr -d ' ')
    if [ "\$lost" -gt 0 ]; then
        echo "REPRODUCED: \$lost variant(s) lost files across the nested rename"
        exit 1
    fi
    echo "no file loss observed in any variant"
    """
}

workflow {
    variants = channel.of(
        // label,        seed wait, late MiB, gap, expectation
        ['writeback',          180,      256,  10, 'FILES LOST - seeds are in S3, late children are not'],
        ['too-early',           20,      256,  10, 'intact - nothing in S3 yet, ErrNotFound guard holds'],
        ['all-settled',        180,        0, 180, 'intact - every upload has landed before rename 2'],
    )

    RENAME_TREE(variants).collect() | CHECK
}
