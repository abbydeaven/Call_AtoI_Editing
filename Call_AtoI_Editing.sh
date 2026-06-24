#!/bin/bash
#SBATCH --job-name=redi1
#SBATCH --partition=batch
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=ad45368@uga.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64gb
#SBATCH --time=8:00:00
#SBATCH --output=../MappingOutput/logs/mapREDI1.%j.out
#SBATCH --error=../MappingOutput/logs/mapREDI1.%j.err


cd $SLURM_SUBMIT_DIR

THREADS=12

## set genomic DNA control accession
control="156_fsd1GFP_OX2"

## setting variables
name=$(echo "$accession" | sed -E 's/_S[0-9]{1,3}_L[0-9]{3}//')

bamdir="${outdir}/bamFiles"
bam="${bamdir}/${name}_"

deduped_dir=${outdir}/DedupedBams
deduped=${deduped_dir}/${name}_deduped.bam

tmp=${tmpdir}/${accession}_tmp.bam
tmp2=${tmpdir}/${accession}_tmp2.bam
tmp3=${tmpdir}/${accession}_tmp3.bam

split_reads=${outdir}/SplitBams
tables=${outdir}/EditTables_OX2
mkdir ${tables}

forward=${split_reads}/${name}_sense.bam
reverse=${split_reads}/${name}_antisense.bam

forward_table=${tables}/${name}_forward_edits.txt
reverse_table=${tables}/${name}_reverse_edits.txt

ml SAMtools/1.21-GCC-13.3.0
ml picard/3.3.0-Java-17
ml R/4.4.2-gfbf-2024a

# preproccessing bam files

echo "Step 1: Checking and fixing read names..."
samtools view -h ${bam}Aligned.sortedByCoord.out.bam | \
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
    -M ${deduped_dir}/${accession}.marked_dup_metrics.txt \
    --OPTICAL_DUPLICATE_PIXEL_DISTANCE -1 --REMOVE_DUPLICATES TRUE

    #index again
    samtools index -@ $THREADS ${deduped}



ml BamTools/2.5.2-GCC-13.3.0

bamtools filter -script filter_forward.txt -in ${deduped} -out ${forward}
  samtools index -@ $THREADS ${forward}

bamtools filter -script filter_rev.txt -in ${deduped} -out ${reverse}
  samtools index -@ $THREADS ${reverse}



## use reditools1
# ml Python/2.7.18-GCCcore-13.3.0

# python -m virtualenv ~/env/REDItools1
. ~/env/REDItools1/bin/activate
#   pip install pysam

  REDItoolDnaRna.py -i ${forward} -j ${split_reads}/${control}_sense.bam \
    -f ~/NcGenome/GCA_000182925.2_NC12_genomic.fna \
      -o ${tables}/${name}_fwd \
-k exclude.bed \
        -o ${tables}/${name}_fwd \
        -k exclude.bed \
        -t 12 \
        -m 20,20 -q 25,25 -c 10,10 \
         -v 3 -n 0.03 -a 6-0 -z -e -u \
        -s 1 -S

    REDItoolDnaRna.py -i ${reverse} -j ${split_reads}/${control}_antisense.bam \
      -f ~/NcGenome/GCA_000182925.2_NC12_genomic.fna \
      -o ${tables}/${name}_rev \
      -k exclude.bed \
      -t 12 \
      -m 20,20 -q 25,25 -c 10,10 \
      -v 3 -n 0.03 -a 6-0 -z -e -u \
      -s 2 -S



#  REDItoolDnaRna.py -i ${forward} -j ${split_reads}/SRR5177531_sense.bam,${split_reads}/SRR5177532_sense.bam \
#    -f ~/NcGenome/GCA_000182925.2_NC12_genomic.fna \
#      -o ${tables}/${name}_fwd \
#-k exclude.bed \
#       -o ${tables}/${name}_fwd -t 12 \ -m 20,20 -q 25,25 -c 10,10 \ -v 3 -n 0.03 -a 6-0 -z -e -u \ -s 1 -S

#    REDItoolDnaRna.py -i ${reverse} -j ${split_reads}/SRR5177531_antisense.bam,${split_reads}/SRR5177532_antisense.bam \
#      -f ~/NcGenome/GCA_000182925.2_NC12_genomic.fna \
#      -o ${tables}/${name}_rev \
#      -k exclude.bed \
#      -t 12 \
#      -m 20,20 -q 25,25 -c 10,10 \
#      -v 3 -n 0.03 -a 6-0 -z -e -u \
#      -s 2 -S

deactivate

