nextflow.enable.dsl=2

params.storeDir = 's3://scidev-testing/projects/robsyme-publishing-testing/removeme'

process KittyCat {
    container 'quay.io/nextflow/bash'
    debug true
    input: path(file)
    script: "ls -lh $file"
}

workflow {
    Channel.of( 1, 2, 3, 4 )
    | map { "Counter: $it" }
    | collectFile(
        name: 'collected.txt',
        storeDir: params.storeDir,
        newLine: true,
        sort: true,
    )
    | KittyCat
}
