#!/bin/bash
set -euo pipefail

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
mkdir $outdir
fastqPath="${outdir}/fastqFiles/FSD1_RNAseq" #fastq directory generate by https://github.com/UGALewisLab/downloadSRA.gi
script_dir=$(cd "$(dirname "$0")" && pwd)
control_name="156_fsd1GFP_OX2"
control_accessions=(
	"156-N27_Genomic_fsd1GFP2_OX__Rep1_S166_L003"
	"156-N28_Genomic_fsd1GFP2_OX__Rep2_S167_L003"
	"156-N29_Genomic_fsd1GFP2_OX__Rep3_S168_L003"
)

mkdir -p "${outdir}/logs"

#make output file folders
mkdir -p "${outdir}/TrimmedFastQs" "${outdir}/bamFiles" "${outdir}/counts"
mkdir -p "${outdir}/bigWig" "${outdir}/bedGraph"

control_job_ids=()
for accession in "${control_accessions[@]}"; do
	job_id=$(sbatch --parsable \
		--export=ALL,accession="${accession}",fastqPath="${fastqPath}",outdir="${outdir}",sample_type=control \
		"${script_dir}/Call_AtoI_Editing.sh")
	control_job_ids+=("${job_id%%;*}")
	echo "${accession} control mapping job submitted as ${job_id}"
done

control_dependency=$(IFS=:; echo "${control_job_ids[*]}")
merge_job=$(sbatch --parsable \
	--dependency="afterok:${control_dependency}" \
	--export=ALL,outdir="${outdir}",control_name="${control_name}",control_accessions="$(IFS=,; echo "${control_accessions[*]}")" \
	"${script_dir}/merge_control_bams.sh")
echo "Control merge job submitted as ${merge_job}"

while read -r line; do
	[[ -z "${line}" ]] && continue
	[[ " ${control_accessions[*]} " == *" ${line} "* ]] && continue
	job_id=$(sbatch --parsable \
		--dependency="afterok:${merge_job%%;*}" \
		--export=ALL,accession="${line}",fastqPath="${fastqPath}",outdir="${outdir}",sample_type=sample \
		"${script_dir}/Call_AtoI_Editing.sh")
	echo "${line} mapping/editing job submitted as ${job_id}"
done <"$1"
