nextflow.enable.dsl=2

// Run bcParser to extract and correct cell-barcodes
// Optionally demuxes fastq files based on some barcodes
process barcodeDemux {
    publishDir "${params.outDir}/demux/", pattern: "$outDir/*gz"
    publishDir "${params.outDir}/demux/", mode: 'copy', pattern: "$outDir/*{txt,tsv,json}" //, saveAs: {"${fqName}.${it.getName()}"}

    input:
    path(sheet) // Samples CSV
    path(libDir) // Directory containing the library definition file (barcode sequence lists are loaded from here)
    val(libName) // Filename of the library definition file
    tuple(val(fqName), path(fqFiles)) // Input fastq file

    output:
    tuple(val(fqName), path("$outDir/*_S[1-9]*.fastq.gz"), emit: fastq)
    path("$outDir/*_S0_*.fastq.gz"), emit: unknown optional true
    path("$outDir/*.tsv")
    tuple(val(fqName), path("$outDir/metrics.json"), emit: metrics)

    script:
    outDir = "${fqName}.demux"
    lib = "$libDir/$libName"
    """
    bc_parser --library $lib --demux $sheet --fastq-name $fqName -v --reads ${fqFiles.join(" ")} --write-fastq --out $outDir
    """
}

process sampleReport {
    publishDir "$params.outDir", mode: 'copy'

    input: 
    val(sample)
    path(samplesheet)
    path(libJson)

    output:
    path("${sample}.csv")
    """
    cat $samplesheet $libJson > ${sample}.csv
    """
}

workflow inputReads {
    take:
	samples // samples.csv parsed into a channel
	samplesCsv // samples.csv file
	libJson // library definition json
	fqDir // Path to directory with input fastqs; empty if running from BCL 

    main:
	fqs = fqDir.flatMap{file(it).listFiles()}.filter{it.name =~ /.fastq.gz$/}
	// Organize fastq files by sample
	fqFiles = fqs.map { file ->
		def ns = file.getName().toString().tokenize('_')
		return tuple(ns.get(0), file)
	}.groupTuple()
	fqSamples = samples.map({it.fastqName}).unique().join(fqFiles)

    fqSamples | view { "fqSamples: $it"}

	// Process cell-barcodes and (optionally) split fastqs into samples based on tagmentation barcode
	barcodeDemux(samplesCsv, libJson.getParent(), libJson.getName(), fqSamples)
	demuxFqs = barcodeDemux.out.fastq.flatMap({it[1]}).map { file ->
		def ns = file.getName().toString().tokenize('_')
		return tuple(ns.get(0), file)
	}.groupTuple(size:2)
    
    emit:
	fqs = demuxFqs
	metrics = barcodeDemux.out.metrics
}


workflow {
	samplesCsv = file(params.samples)
	samples = Channel.fromPath(samplesCsv).splitCsv(header:true, strip:true)
	libJson = file(params.libStructure)
	fqDir = Channel.fromPath(params.fastqDir, checkIfExists:true)
    
    fqDir | view { "fqDir: $it"}
    samples | view { "samples: $it" }
    
    inputReads(samples, samplesCsv, libJson, fqDir)
    foo = inputReads.out.fqs.map{it[0]}
    foo | view { "Foo: $it" }
    // sampleReport(foo, samplesCsv, libJson)
}