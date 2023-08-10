import groovy.json.JsonSlurper

process PROCESS {
    input: val(sample)

    output: tuple val(sample), path("metadata.json")

    script:
    """
    echo '{"sample_id": "ABC", "read_structure": "+T +T", "process": true, "size": 1235}' > metadata.json
    """
}

workflow {
    Channel.of("Verve")
    | PROCESS
    | map { sample, json -> [sample, new JsonSlurper().parse(json)] }
    | view
}
