nextflow.enable.dsl=2

params.outdir = 'results'

process MakeTxt {
    publishDir params.outdir

    output:
    path("*.txt"), emit: txt
    path(".command.run"), emit: run

    "echo Minimal example > example_output.txt"
}

workflow {
    MakeTxt()

    MakeTxt.out.run | view { runfile ->
        matcher = runfile.text =~ /(?ms)nxf_unstage.*?^}/
        matcher[0]
    }
}