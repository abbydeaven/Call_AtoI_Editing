#!/bin/bash

#check for required command line argument

if [[ -z "$1" ]]
then
		echo "
		################
		ERROR: You must include the path to your accession file in the command line call.
		eg. sh submit.sh Path/To/Your/AccessionFile.txt
		##################
		"
		exit
fi

#iterates through list of accessions and passes to mapping script

outdir="../MappingOutput"
bamPath="${outdir}/FastqFiles" #fastq directory generate by https://github.com/UGALewisLab/downloadSRA.git


while read -r line

	do
	sleep 10
	echo "$line mapping job submitted"
	sbatch --export=ALL,accession="${line}",bamPath="${bamPath}",outdir="${outdir}" Call_AtoI_Events.sh & done <"$1"
