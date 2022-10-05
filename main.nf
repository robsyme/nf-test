process TestEnv {
    debug true
    container 'robsyme/nf-test:latest'

    'echo $NF_TEST_VERSION'
}

workflow {
    TestEnv()
}