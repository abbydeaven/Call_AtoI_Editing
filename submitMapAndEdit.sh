#!/bin/bash

#check for required command line argument

if [[ -z "${1:-}" ]]
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

outdir="../RNAseq_Output"
mkdir -p $outdir
fastqPath="../fastqFiles/FSD1_RNAseq" #fastq directory generate by https://github.com/UGALewisLab/downloadSRA.gi

while read -r line
do

if [[ "${line}" == 156* ]]; then
  echo "Mapping control sample: $line"
	sleep 10
	echo "$line mapping job submitted"
	sbatch --export=ALL,accession="${line}",fastqPath="${fastqPath}",outdir="${outdir}" Map_DNA_Controls.sh
	
else

	sleep 10
	echo "$line RNA mapping job submitted"
  	sbatch --export=ALL,accession="${line}",fastqPath="${fastqPath}",outdir="${outdir}" Call_AtoI_Editing.sh 

fi

done < "$1"