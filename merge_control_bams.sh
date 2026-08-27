#!/bin/bash
#SBATCH --job-name=merge_fsd1_control
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32gb
#SBATCH --time=2:00:00
#SBATCH --output=../RNAseq_Output/logs/merge_control.%j.out
#SBATCH --error=../RNAseq_Output/logs/merge_control.%j.err


cd "${SLURM_SUBMIT_DIR}"

## Make variable names and directories
outdir="../RNAseq_Output"
control.name="156_OX2_gDNA"

bamdir="${outdir}/bamFiles"

  tmpdir=${outdir}/tempFiles
  mkdir -p "${tmpdir}"
    tmp=${tmpdir}/${control.name}_tmp.bam
    tmp2=${tmpdir}/${control.name}_tmp2.bam
    tmp3=${tmpdir}/${control.name}_tmp3.bam

  split_reads=${outdir}/SplitBams
  mkdir -p "${split_reads}"
    forward=${split_reads}/${control.name}_sense.bam
    reverse=${split_reads}/${control.name}_antisense.bam


module load SAMtools/1.21-GCC-13.3.0
module load BamTools/2.5.2-GCC-13.3.0

merged="${control.name}/156_OX2_gDNA.bam"
samtools merge -@ 4 -o "${merged}" "${bamdir}/156-N28_Genomic_fsd1GFP2_OX__Rep2.bam" "${bamdir}/156-N29_Genomic_fsd1GFP2_OX__Rep3.bam"
samtools index -@ 4 "${merged}"

## Preprocess bam file
echo "Step 1: Checking and fixing read names..."
samtools view -h ${merged} | \
  awk 'BEGIN {FS=OFS="\t"; c=1}
  /^@/ { print; next }
  {
#    # Ensure read name has required format for MarkDuplicates
#    # STAR output: SRR#.position or similar
#    # Picard expects: name:tile:x:y:duplicate
    if ($1 !~ /:[0-9]+:[0-9]+:[0-9]+/) {
      # Add dummy tile:x:y:dup
      $1 = $1 ":0:0:0:" (c % 2)
      c++
    }
    print
  }' | samtools view -b -o ${tmp} -

samtools addreplacerg -r "@RG\tID:RG1\tSM:SampleName\tPL:Illumina\tLB:Library" -o ${tmp2} ${tmp}
samtools sort ${tmp2} -o ${tmp3}
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    --INPUT ${tmp3} \
    --OUTPUT ${deduped} \
    -M ${deduped_dir}/merged.marked_dup_metrics.txt \
    --OPTICAL_DUPLICATE_PIXEL_DISTANCE -1 --REMOVE_DUPLICATES TRUE

    #index again
    samtools index -@ $THREADS ${deduped}



ml BamTools/2.5.2-GCC-13.3.0

bamtools filter -script filter_forward.txt -in ${deduped} -out ${forward}
  samtools index -@ $THREADS ${forward}

bamtools filter -script filter_rev.txt -in ${deduped} -out ${reverse}
  samtools index -@ $THREADS ${reverse}
