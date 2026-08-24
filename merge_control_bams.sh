#!/bin/bash
#SBATCH --job-name=merge_fsd1_control
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32gb
#SBATCH --time=2:00:00
#SBATCH --output=../MappingOutput/logs/merge_control.%j.out
#SBATCH --error=../MappingOutput/logs/merge_control.%j.err

set -euo pipefail

cd "${SLURM_SUBMIT_DIR}"
script_dir=$(cd "$(dirname "$0")" && pwd)

outdir=${outdir:?outdir is required}
control_name=${control_name:?control_name is required}
IFS=',' read -r -a control_accession_list <<< "${control_accessions:?control_accessions is required}"

module load SAMtools/1.21-GCC-13.3.0
module load BamTools/2.5.2-GCC-13.3.0

bamdir="${outdir}/bamFiles"
split_reads="${outdir}/SplitBams"
mkdir -p "${split_reads}"

control_bams=()
for accession in "${control_accession_list[@]}"; do
	name=$(echo "${accession}" | sed -E 's/_S[0-9]{1,3}_L[0-9]{3}//')
	bam="${bamdir}/${name}_Aligned.sortedByCoord.out.bam"
	if [[ ! -f "${bam}" ]]; then
		echo "Missing control BAM: ${bam}" >&2
		exit 1
	fi
	control_bams+=("${bam}")
done

merged="${split_reads}/${control_name}.bam"
samtools merge -@ 4 -f "${merged}" "${control_bams[@]}"
samtools index -@ 4 "${merged}"

bamtools filter \
	-script "${script_dir}/filter_forward.txt" \
	-in "${merged}" \
	-out "${split_reads}/${control_name}_sense.bam"
samtools index -@ 4 "${split_reads}/${control_name}_sense.bam"

bamtools filter \
	-script "${script_dir}/filter_rev.txt" \
	-in "${merged}" \
	-out "${split_reads}/${control_name}_antisense.bam"
samtools index -@ 4 "${split_reads}/${control_name}_antisense.bam"
