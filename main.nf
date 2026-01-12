#!/usr/bin/env nextflow

workflow {
    main:
        countries = channel.of(
            [name: "Australia", capital: [name: "Canberra", population: 473855]],
            [name: "Canada", capital: [name: "Ottawa", population: 1017449]]
        )
        countries
        | SayHi
        | view

    publish:
        greetings = SayHi.out.map { country, infoFile, infoDir -> country + [nested: [simpleFile: infoFile, myDataDirectory:infoDir]]}
        nationalInfo = countries
}

output {
    greetings {
        path 'hellos'
    }
    nationalInfo {
        path 'information'
    }
}

process SayHi {
    input: val(country)
    output: tuple val(country), path("*.txt"), path("${country.name}_outputs")
    script:
    """
    echo 'The capital of ${country.name} is ${country.capital.name}' > info.${country.name}.txt
    mkdir ${country.name}_outputs
    echo 'Population: ${country.capital.population}' > ${country.name}_outputs/population.txt
    echo 'More details here' > ${country.name}_outputs/details.txt
    """
}
