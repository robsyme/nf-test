#!/usr/bin/env nextflow

/*
 * Measurement probe: when does a file written through Fusion actually become
 * visible in S3?
 *
 * Motivation. COMP-2323 is a silent data-loss bug in Fusion's recursive
 * directory rename: moveEntries drops the "populated" marker for nested
 * directories, so a second rename re-lists them from the object store and
 * replaces the cached child list with whatever is there. The loss needs a
 * PARTIAL listing - at least one child already in S3, at least one not. An
 * empty prefix is reported as ErrNotFound and skips the replacement.
 *
 * Two attempts to reproduce that from a pipeline both failed because nothing
 * ever reached S3 during a short task. Reading the source, three separate
 * knobs that look like they schedule uploads turn out to be dead:
 *
 *   - FUSION_MIN_FREE / FUSION_CACHE_SOFT_LIMIT / FUSION_CACHE_HARD_LIMIT are
 *     parsed into MinFreeSpace / CacheSoftLimitPercentage /
 *     CacheHardLimitPercentage (cmd/fusion/config.go), logged in the startup
 *     `configuration` line, and never read. The GC thresholds that apply are
 *     hardcoded at max(0.5*total, 50GB) free
 *     (internal/chunkcontent/chk_content_factory.go).
 *   - DefaultUploadDelay = 2 * time.Minute is assigned to a `uploadDelay`
 *     field that is never read, in v2.5.14 and master alike. There is no
 *     writeback timer.
 *   - The snapshot feature does not flush the mount; the manager only signals
 *     the wrapped fusion-snapshot process (internal/snapshot/manager.go).
 *
 * Closing a file does not upload either - Release only decrements a refcount.
 * So on paper the only paths to S3 are GC eviction (never fires on a roomy
 * cache disk; the production task logged zero GC activity in 57 minutes) and
 * the unmount flush. Yet the production task demonstrably had 4 of 15 files in
 * S3 mid-run. Something uploads that the source reading has not accounted for.
 *
 * Rather than guess a fourth time, measure. This probe asks three questions
 * against S3 ground truth, using the AWS CLI rather than the Fusion mount so
 * the answers are not served from Fusion's own metadata cache:
 *
 *   1. Does any file data reach S3 while the mount is open, with no GC pressure?
 *   2. Does size matter? 1KB and 1MB sit inside one 128MiB chunk; 130MB and
 *      400MB span completed chunk boundaries.
 *   3. Does renaming an un-uploaded file materialise it at the destination?
 *      This is the most load-bearing question for COMP-2323, because in the
 *      production trace the destination prefix held objects 53s after the
 *      first rename.
 *
 * FUSION_LOG_LEVEL=trace is set so .fusion.log is available as a second,
 * independent view of the same window.
 *
 * Read the results from the task's .command.out, and the trace from
 * .fusion.log:
 *   tw runs view -i <id> -w <workspace> tasks
 *   curl -H "Authorization: Bearer $TOWER_ACCESS_TOKEN" \
 *     "https://api.cloud.seqera.io/workflow/<id>/download/1?workspaceId=<ws>&fileName=.fusion.log"
 */

params.region      = 'us-east-1'
params.poll_every   = 20    // seconds between S3 polls
params.watch_write  = 480   // seconds to watch after writing
params.watch_rename = 240   // seconds to watch after renaming

process CANARY {
    debug true
    container 'robsyme/fusion-probe:1.0.0'

    output:
    path 'canary.txt'

    script:
    """
    echo "canary: shell=\$0 pwd=\$(pwd)" > canary.txt
    echo "canary: bash=\$(command -v bash) tee=\$(command -v tee)" >> canary.txt
    cat canary.txt
    """
}

process WRITEBACK_PROBE {
    debug true
    cpus 2
    memory '4 GB'
    container 'robsyme/fusion-probe:1.0.0'

    output:
    path 'timeline.tsv'
    path 'report.txt'

    script:
    """
    # Deliberately no `set -e`. Earlier attempts died silently because a failing
    # setup command aborted the script before its own diagnostic could print.
    set -uo pipefail

    # Mirror everything to report.txt, a declared output. A task that exits
    # non-zero never gets its stdout flushed by Fusion, so on earlier attempts
    # the diagnostics explaining the failure were themselves lost. This script
    # therefore always exits 0 and records its verdict in the file instead.
    : > timeline.tsv   # declared output; must exist even if we stop at a guard

    # Everything goes to report.txt, then a trap copies it to the real stdout on
    # every exit path. Writing only to the file left the data unreachable: the
    # Platform API serves .command.* and .fusion.log, not arbitrary work files.
    exec 3>&1 4>&2
    finish() { exec 1>&3 2>&4; echo "----- report.txt -----"; cat report.txt; }
    trap finish EXIT
    exec > report.txt 2>&1

    echo "=== environment ==="
    echo "pwd    : \$(pwd)"
    echo "python : \$(python3 --version 2>&1)"
    echo "curl   : \$(command -v curl || echo MISSING)"
    echo "s3ls   : \$(command -v s3ls.py || echo 'NOT ON PATH')"
    echo "AWS_* env vars present: \$(env | grep -c '^AWS_')"

    here=\$(pwd)
    rel=\${here#/fusion/s3/}
    bucket=\${rel%%/*}
    prefix=\${rel#*/}
    echo "bucket : \$bucket"
    echo "prefix : \$prefix"

    case "\$here" in
        /fusion/s3/*) ;;
        *) echo "VERDICT: INVALID - cwd is not under /fusion/s3, not a Fusion mount"
           exit 0 ;;
    esac

    s3ls() { s3ls.py "\$bucket" '${params.region}' "\$1"; }

    # Precondition. Nextflow uploads .command.sh to this prefix before the task
    # starts, so it is in S3 right now. If we cannot see it, credentials or
    # permissions are wrong and every reading below would be a false negative.
    echo "=== precondition ==="
    if ! s3ls "\$prefix/.command.sh" | grep -qF '.command.sh'; then
        echo "VERDICT: INVALID - cannot read \$prefix/.command.sh from S3, though"
        echo "         Nextflow put it there before this task started. Stopping rather"
        echo "         than reporting 'nothing was uploaded' when the truth is"
        echo "         'we cannot look'."
        exit 0
    fi
    echo "precondition OK: S3 is readable from inside the task"

    poll() {  # poll <label> <seconds-since-t0>
        local out
        out=\$(s3ls "\$prefix/probe" 2>/dev/null)
        if [ -z "\$out" ]; then
            printf '%s\\t%s\\t%s\\t%s\\n' "\$1" "\$2" "-" "0" >> timeline.tsv
            echo "  t=+\$2s  \$1: (nothing under probe*)"
        else
            echo "\$out" | while IFS=\$'\\t' read -r k sz; do
                printf '%s\\t%s\\t%s\\t%s\\n' "\$1" "\$2" "\$k" "\$sz" >> timeline.tsv
                echo "  t=+\$2s  \$1: \${k#\$prefix/}  \$sz bytes"
            done
        fi
    }

    mkdir -p probe/nested

    # 1KB and 1MB sit inside a single 128MiB chunk; 130MB and 400MB complete one
    # and three chunks respectively.
    dd if=/dev/urandom of=probe/nested/f_1k.bin   bs=1024    count=1   2>/dev/null
    dd if=/dev/urandom of=probe/nested/f_1m.bin   bs=1048576 count=1   2>/dev/null
    dd if=/dev/urandom of=probe/nested/f_130m.bin bs=1048576 count=130 2>/dev/null
    dd if=/dev/urandom of=probe/nested/f_400m.bin bs=1048576 count=400 2>/dev/null
    t0=\$(date +%s)
    echo "=== wrote 4 files at t0; watching S3 for ${params.watch_write}s ==="

    elapsed=0
    while [ \$elapsed -lt ${params.watch_write} ]; do
        poll "written" "\$elapsed"
        sleep ${params.poll_every}
        elapsed=\$(( \$(date +%s) - t0 ))
    done

    # If the rename is what materialises un-uploaded objects, probe_moved/ keys
    # appear shortly after this point. That is the load-bearing question for
    # COMP-2323.
    mv probe probe_moved
    tr_at=\$(date +%s)
    echo "=== renamed probe -> probe_moved at +\$(( tr_at - t0 ))s; watching ${params.watch_rename}s ==="

    elapsed=0
    while [ \$elapsed -lt ${params.watch_rename} ]; do
        poll "renamed" "\$(( \$(date +%s) - t0 ))"
        sleep ${params.poll_every}
        elapsed=\$(( \$(date +%s) - tr_at ))
    done

    echo "=== still on the mount at exit ==="
    ls -lR probe_moved
    echo "VERDICT: COMPLETE"
    """
}

workflow {
    CANARY()
    WRITEBACK_PROBE()
}
