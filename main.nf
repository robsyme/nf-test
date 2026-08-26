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

process WRITEBACK_PROBE {
    debug true
    cpus 2
    memory '4 GB'
    container 'amazon/aws-cli:2'

    output:
    path 'timeline.tsv'

    script:
    """
    set -euo pipefail
    export AWS_DEFAULT_REGION='${params.region}'

    # The task workdir is mounted at /fusion/s3/<bucket>/<key>. Recover the
    # bucket and key so we can query S3 directly, bypassing Fusion entirely.
    here=\$(pwd)
    rel=\${here#/fusion/s3/}
    bucket=\${rel%%/*}
    prefix=\${rel#*/}

    echo "bucket : \$bucket"
    echo "prefix : \$prefix"
    # Precondition. Nextflow uploads .command.sh to this prefix before the task
    # starts, so it is guaranteed to be in S3 right now. If the CLI cannot see
    # it, the credentials or permissions are wrong and every "nothing in S3"
    # reading below would be a false negative. Fail loudly instead.
    if ! aws s3api list-objects-v2 --bucket "\$bucket" --prefix "\$prefix/.command.sh" \\
            --query 'Contents[].Key' --output text 2>&1 | grep -q '.command.sh'; then
        echo "INVALID: the AWS CLI cannot see \$prefix/.command.sh, which is known to exist."
        echo "Credentials or bucket permissions are wrong - the polls below would all read"
        echo "as empty regardless of what Fusion did. Aborting rather than reporting a"
        echo "false negative."
        aws sts get-caller-identity --output text 2>&1 | head -5 || true
        exit 1
    fi
    echo "precondition OK: .command.sh visible in S3, so the CLI can read this prefix"

    poll() {  # poll <label> <seconds-since-t0>
        local keys
        keys=\$(aws s3api list-objects-v2 \\
                  --bucket "\$bucket" \\
                  --prefix "\$prefix/probe" \\
                  --query 'Contents[].[Key,Size]' \\
                  --output text 2>/dev/null || true)
        if [ -z "\$keys" ]; then
            printf '%s\\t%s\\t%s\\t%s\\n' "\$1" "\$2" "-" "0" >> timeline.tsv
            echo "  t=+\$2s  \$1: (nothing in S3)"
        else
            echo "\$keys" | while read -r k s; do
                printf '%s\\t%s\\t%s\\t%s\\n' "\$1" "\$2" "\${k##*/}" "\$s" >> timeline.tsv
                echo "  t=+\$2s  \$1: \${k##*/}  \$s bytes"
            done
        fi
    }

    : > timeline.tsv
    mkdir -p probe/nested

    # --- write. 1KB and 1MB fit inside a single 128MiB chunk; 130MB and 400MB
    #     complete one and three chunks respectively.
    dd if=/dev/urandom of=probe/nested/f_1k.bin   bs=1024        count=1   2>/dev/null
    dd if=/dev/urandom of=probe/nested/f_1m.bin   bs=1048576     count=1   2>/dev/null
    dd if=/dev/urandom of=probe/nested/f_130m.bin bs=1048576     count=130 2>/dev/null
    dd if=/dev/urandom of=probe/nested/f_400m.bin bs=1048576     count=400 2>/dev/null
    sync || true
    t0=\$(date +%s)
    echo "=== wrote 4 files at t0=\$t0; watching S3 for ${params.watch_write}s ==="

    elapsed=0
    while [ \$elapsed -lt ${params.watch_write} ]; do
        poll "written" "\$elapsed"
        sleep ${params.poll_every}
        elapsed=\$(( \$(date +%s) - t0 ))
    done

    # --- rename. If the rename materialises un-uploaded objects at the
    #     destination, probe_moved/ keys appear shortly after this point.
    mv probe probe_moved
    tr=\$(date +%s)
    echo "=== renamed probe -> probe_moved at +\$(( tr - t0 ))s; watching ${params.watch_rename}s ==="

    elapsed=0
    while [ \$elapsed -lt ${params.watch_rename} ]; do
        poll "renamed" "\$(( \$(date +%s) - t0 ))"
        sleep ${params.poll_every}
        elapsed=\$(( \$(date +%s) - tr ))
    done

    echo "=== probe complete; files still on disk: ==="
    find probe_moved -type f -exec ls -l {} +
    """
}

workflow {
    WRITEBACK_PROBE()
}
