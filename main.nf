#!/usr/bin/env nextflow

params.outdir = 'results'
params.all = false

workflow {
    First()

    First.out.value | Second
    Second.out.value | Third
}


process First {
	publishDir params.outdir
	container 'quay.io/nextflow/bash'
	output:
	val(1), emit: value
	path('*'), emit: files
	
	script:
	makeAll = params.all ? "echo 1 > my-folder/all.txt" : ""
	"""
    mkdir -p my-folder/subfolder1/subsub
    ${makeAll}
    echo 1 > my-folder/subfolder1/1.txt
	"""
}

process Second {
	publishDir params.outdir
	container 'quay.io/nextflow/bash'

	input:
	val(x)

	output: 
	val(x), emit: value
	path('*'), emit: files

	script:
	makeAll = params.all ? "echo 12 > my-folder/all.txt" : ""
	"""
	mkdir -p my-folder/subfolder2/subsub
	${makeAll}
	echo 2 > my-folder/subfolder2/2.txt
	"""
}

process Third {
	publishDir params.outdir
	container 'quay.io/nextflow/bash'

	input:
	val(x)
	
	output:
	path('*')
	
	script:
	makeAll = params.all ? "echo 123 > my-folder/all.txt" : ""
	"""
	mkdir -p my-folder/subfolder3/subsub
	${makeAll}
	echo 3 > my-folder/subfolder3/3.txt
	"""
}