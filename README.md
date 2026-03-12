# FD-7315: Fusion compact symlink directory bug MRE

Minimal reproducible example for a Fusion v2.4.x bug where directory outputs
become orphaned compact symlinks when:

1. A process declares a directory as an output (matching compact patterns)
2. The process does NOT traverse the directory contents during execution
3. Fusion excludes the directory from `.fusion.symlinks` (by design for compact-matched entries)
4. Fusion's `symlinkCompacter` silently fails because the directory children are not populated in memory
5. Downstream tasks see the directory as a ~100-byte file instead of a real directory

## Pipeline structure

```
GENERATE_DIR  →  PASSTHROUGH  →  READ_DIR
  (creates         (declares       (reads files
   directory        dir as          inside the
   with files)      output,         directory)
                    doesn't
                    traverse it)
```

## Expected behavior

| Environment | Expected result |
|---|---|
| Local (no Fusion) | PASS — all samples succeed |
| AWS Batch + Fusion v2.4.20 + compact symlinks | FAIL — READ_DIR can't read files inside the directory |
| AWS Batch + Fusion master + compact symlinks | PASS — bug fixed (on-demand populateDirectory) |
| AWS Batch + Fusion v2.4.20 + `FUSION_COMPACT_SYMLINKS=false` | PASS — compact symlinks disabled |

## How to run

```bash
# On Seqera Platform: launch with Fusion enabled (compact symlinks on by default)
# The pipeline should fail for at least some samples in READ_DIR

# Locally (will pass — no Fusion):
nextflow run main.nf
```

## Root cause

The bug is in `symlinkCompacter()` (`internal/fusion/entry_service.go:905-933` in v2.4.20):

```go
if children, ok := m.directories[target.Path()]; ok {
    // copy children — this path is never taken for unpopulated dirs
    return m.copyEntries(ctx, children, e.Path())
}
return nil  // ← SILENT FAILURE: no error, no compaction
```

When a compact-matched symlink targets a directory that was never traversed, `m.directories`
has no entry for it. The function returns `nil` (no error), leaving the symlink as an orphaned
compact symlink object in S3. The directory was already excluded from `.fusion.symlinks`
because it matched the compact pattern, so it's not recorded anywhere.

Fixed in Fusion master by adding on-demand `populateDirectory` before the `m.directories` check.

## Related

- Ticket: https://support.seqera.io/a/tickets/7315
- Customer: Eli Lilly (sirCLIP pipeline, STAR genome index directories)
- Customer workaround: Declare individual files as separate process inputs/outputs
