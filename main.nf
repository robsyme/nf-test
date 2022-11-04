params.outdir = 'results'

process MakeTxt {
    publishDir params.outdir

    output:
    path("*.txt")

    "echo Minimal example > example_output.txt"
}

workflow {
    MakeTxt | view { "Found file: $it" }
}