#!/usr/bin/env nextflow

workflow {
    First()
    | Second
    | Third
}


process First {
	output: tuple val(1), path('*')
	script:
	"""
    mkdir -p my-folder/subfolder1
    echo 1 > my-folder/all.txt
    echo 1 > my-folder/subfolder1/1.txt
	"""
}

process Second {
	input: tuple val(x), path(_)
	output: tuple val(x), path("my-folder")
	script:
	"""
    mkdir -p my-folder/subfolder2
    echo 2 > my-folder/all.txt
    echo 2 > my-folder/subfolder2/2.txt
	"""
}

process Third {
	input: tuple val(x), path(_)
	output: path('my-folder')
	script:
	"""
    mkdir -p my-folder/subfolder3
    echo 3 > my-folder/all.txt
    echo 3 > my-folder/subfolder3/3.txt
	"""
}