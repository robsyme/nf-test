.PHONY: clean run

run:
	nextflow run main.nf

clean:
	rm -rf .nextflow* work results
