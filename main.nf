nextflow.enable.dsl=2

process CreateFile {
    output: path("out.txt")
    script: "echo 'Hello world!' > out.txt"
}

// See https://github.com/nextflow-io/nextflow/issues/1636
// This is the only way to publish files from a workflow whilst
// decoupling the publish from the process steps.
process PublishArtifact {
    publishDir params.outdir, saveAs: { it - ~/^out\//}
    input: path "in/*"
    output: path "out/*"
    script: "mkdir -p out && cp -r in/* out"
}

workflow {
    CreateFile() | PublishArtifact
}
