#!/usr/bin/env nextflow

/*
 * MRE: Fusion silently drops the contents of a nested directory when a
 * directory tree is renamed more than once inside the Fusion mount.
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
 * Mechanism, in internal/entryfs/entry_service.go (line numbers from v2.5.14,
 * unchanged through v2.6.3 and master):
 *
 *   - Rename() carries the "this directory is already populated" marker across
 *     the rename, but only for the top-level path:
 *         :476  if v, ok := m.populated[oldPath]; ok {
 *         :477      m.populated[newPath] = v
 *
 *   - moveEntries(), which walks the children recursively, never does the
 *     equivalent, so every nested directory lands at its new path unpopulated:
 *         :508  if _, ok := m.populated[e.Path()]; !ok && ...IsDirectory() {
 *         :509      _, _ = m.populateDirectory(ctx, e.Path(), children, true)
 *
 *   - populateDirectory() is a wholesale replacement, not a merge. It builds the
 *     child set purely from dataStore.ListDirectory(), discards the `children`
 *     argument, and overwrites the cache:
 *         :1133 children = make([]Entry, 0, len(childrenMap))
 *         :1151 m.directories[path] = children
 *
 * So the second rename re-derives the nested directory's child list from S3,
 * and any child whose bytes have not been uploaded (or whose rename copy has
 * not completed) simply ceases to exist. No error, no warning, exit 0.
 *
 * That makes the loss size-dependent: it preferentially eats the large files a
 * downstream tool actually needs, while the small ones written earlier survive.
 * The `control` variant below waits for every upload to land before renaming
 * and passes, which is what pins the cause to upload timing rather than `mv`.
 *
 * Requires a Fusion + Wave compute environment with an S3 work directory.
 * Outside Platform:
 *   nextflow run robsyme/nf-test -r fusion-nested-rename-drops-children \
 *       -w s3://<bucket>/work -with-wave -with-fusion
 */

// Size of the late-written child, in MiB. Needs to be large enough that its
// upload cannot finish inside `gap` seconds on the instance you are running on.
params.big_mb = 8192

// Size of the late-written child for the 'nogap' variant, in MiB.
params.nogap_mb = 2048

process RENAME_TREE {
    tag "$label"
    debug true
    maxForks 1        // serial, so one variant's uploads don't skew the next
    cpus 2
    memory '8 GB'

    input:
    tuple val(label), val(small_count), val(seed_wait), val(big_mb), val(gap)

    output:
    path "report_${label}.txt"

    script:
    """
    set -euo pipefail

    stage=stage_${label}
    mkdir -p \$stage/nested/deeper

    # Children written early, giving Fusion's uploaders time to push them to S3.
    for i in \$(seq -w 1 ${small_count}); do
        echo "small-\$i" > \$stage/nested/small_\$i.txt
    done
    echo "deep" > \$stage/nested/deeper/deep.txt
    echo "top"  > \$stage/top.txt

    sleep ${seed_wait}

    # One child closed immediately before the first rename, so its upload - and
    # therefore the S3 copy that the rename schedules - is still in flight.
    if [ ${big_mb} -gt 0 ]; then
        dd if=/dev/zero of=\$stage/nested/big.bin bs=1048576 count=${big_mb} 2>/dev/null
    fi

    find \$stage -type f | sed "s|^\$stage/||" | sort > expected.txt

    echo "### \$stage/nested before the first rename"
    ls -l \$stage/nested/

    # Rename 1. nested/ keeps its correct in-memory child list here.
    mv \$stage moved_${label}

    sleep ${gap}

    # Rename 2. moveEntries() sees moved_*/nested as unpopulated, re-lists it
    # from S3, and replaces the child list with whatever the object store has.
    mv moved_${label} final_${label}

    find final_${label} -type f | sed "s|^final_${label}/||" | sort > actual.txt
    comm -23 expected.txt actual.txt > missing.txt

    lost=\$(wc -l < missing.txt | tr -d ' ')

    {
        echo "variant           : ${label}"
        echo "small children    : ${small_count}"
        echo "wait before big   : ${seed_wait}s"
        echo "late child        : ${big_mb} MiB"
        echo "gap between mv    : ${gap}s"
        echo "files written     : \$(wc -l < expected.txt | tr -d ' ')"
        echo "files surviving   : \$(wc -l < actual.txt | tr -d ' ')"
        echo "files lost        : \$lost"
        echo
        echo "-- survived --"
        cat actual.txt
        echo
        echo "-- LOST --"
        cat missing.txt
        echo
        if [ "\$lost" -gt 0 ]; then echo "VERDICT: FAIL"; else echo "VERDICT: PASS"; fi
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

    failed=\$(grep -l 'VERDICT: FAIL' report_*.txt 2>/dev/null | wc -l | tr -d ' ')
    if [ "\$failed" -gt 0 ]; then
        echo "\$failed variant(s) lost files across the nested directory rename"
        exit 1
    fi
    echo "no file loss observed"
    """
}

workflow {
    variants = channel.of(
        // label,     small, wait, big MiB,        gap
        ['subset',       12,   25, params.big_mb,   8],  // some children in S3, the big one not: partial loss
        ['nogap',        12,    0, params.nogap_mb, 0],  // nothing in S3 yet: does an empty listing also drop them?
        ['control',      12,   25,             0,  25],  // everything uploaded before both renames: expected to pass
    )

    RENAME_TREE(variants).collect() | CHECK
}
