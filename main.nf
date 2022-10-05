nextflow.enable.dsl=2

process MakeDirectory {
    publishDir "results", mode: 'copy'
    output:
    path("out")

    """
    mkdir -p out/one/two
    echo "name,city" >> out/one/two/fromdir.csv
    echo "Rob,Montreal" >> out/one/two/fromdir.csv
    echo "Harshil,London" >> out/one/two/fromdir.csv
    """
}

process DirectlyOutput {
    publishDir "results", mode: 'copy'
    output:
    path("out/one/two/direct.csv")

    """
    mkdir -p out/one/two
    echo "animal,sound" >> out/one/two/direct.csv
    echo "cat,meow" >> out/one/two/direct.csv
    echo "dog,bark" >> out/one/two/direct.csv
    """
}

process WithGlob {
    publishDir "results", mode: 'copy'
    output:
    path("out/one/two/with_glob.csv")

    """
    mkdir -p out/one/two
    echo "os,interface" >> out/one/two/with_glob.csv
    echo "linux,cli" >> out/one/two/with_glob.csv
    echo "windows,gui" >> out/one/two/with_glob.csv
    """
}

workflow {
    MakeDirectory()
    DirectlyOutput()
    WithGlob()
}