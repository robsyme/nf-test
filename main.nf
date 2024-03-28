#!/usr/bin/env nextflow

workflow {
    First()

    First.out.value | Second
    Second.out.value | Third
}


process First {
	publishDir params.outdir, saveAs: { filename -> filename == "my-folder/all.txt" ? "my-folder/all.${task.name}.txt" : filename }

	output:
	val(1), emit: value
	path('**'), emit: files
	
	script:
	"""
    mkdir -p my-folder/subfolder1
    echo 1 > my-folder/all.txt
    echo 1 > my-folder/subfolder1/1.txt
	"""
}

process Second {
	publishDir params.outdir, saveAs: { filename -> filename == "my-folder/all.txt" ? "my-folder/all.${task.name}.txt" : filename }

	input:
	val(x)

	output: 
	val(x), emit: value
	path('**'), emit: files

	script:
	"""
    mkdir -p my-folder/subfolder2
    echo 12 > my-folder/all.txt
    echo 2 > my-folder/subfolder2/2.txt
	"""
}

process Third {
	publishDir params.outdir, saveAs: { filename -> filename == "my-folder/all.txt" ? "my-folder/all.${task.name}.txt" : filename }

	input:
	val(x)
	
	output:
	path('**')
	
	script:
	"""
    mkdir -p my-folder/subfolder3
    echo 123 > my-folder/all.txt
    echo 3 > my-folder/subfolder3/3.txt
	"""
}