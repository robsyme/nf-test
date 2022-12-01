nextflow.enable.dsl=2

params.outdir = 'results'

process MakeDirectory {
    publishDir "${params.outdir}/mkdir", mode: 'copy'
    container 'ubuntu'

    output:
    path("out/**")
    path("out/**/*.csv")

    """
    mkdir -p out/one/two
    echo "name,city" >> out/one/two/fromdir.csv
    echo "Rob,Montreal" >> out/one/two/fromdir.csv
    echo "Harshil,London" >> out/one/two/fromdir.csv
    """
}

process DirectlyOutput {
    publishDir "${params.outdir}/direct", mode: 'copy'
    container 'ubuntu'

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
    container 'ubuntu'

    output:
    path("out/**/*.csv")

    """
    mkdir -p out/one/two
    echo "os,interface" >> out/one/two/with_glob.csv
    echo "linux,cli" >> out/one/two/with_glob.csv
    echo "windows,gui" >> out/one/two/with_glob.csv
    """
}

process WithSaveAs {
    publishDir "results", mode: 'copy', saveAs: { it != 'copied.csv' ? it : null }
    publishDir "results", mode: 'copy', saveAs: { it == 'copied.csv' ? "out/one/two/${it}" : null }
    container 'ubuntu'

    output:
    path("out")
    path("*.csv")

    """
    mkdir -p out/one/two
    echo "os,interface" >> out/one/two/saveas_notcopied.csv
    echo "linux,cli" >> out/one/two/saveas_notcopied.csv
    echo "windows,gui" >> out/one/two/saveas_notcopied.csv
    echo "foo,bar" >> out/one/two/copied.csv
    find out -name copied.csv -exec mv {} . \\;
    """
}

workflow {
    MakeDirectory()
    DirectlyOutput()
    WithGlob()
    WithSaveAs()
}
