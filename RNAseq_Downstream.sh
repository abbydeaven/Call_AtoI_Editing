#!/bin/bash
#SBATCH --job-name=redi1
#SBATCH --partition=batch
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=ad45368@uga.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64gb
#SBATCH --time=8:00:00
#SBATCH --output=../RNAseq_Output/logs/processRNA.%j.out
#SBATCH --error=../RNAseq_Output/logs/processRNA.%j.err


cd $SLURM_SUBMIT_DIR

THREADS=12
GENOME="/home/zlewis/Genomes/Neurospora/Nc12_RefSeq/GCA_000182925.2_NC12_genomic"

## setting variables
outdir="../RNAseq_Output"
bam="${outdir}/bamFiles"
sashimi="${outdir}/SashimiPlots"

tmpdir=${outdir}/tempFiles

tables=${outdir}/EditTables
final_tables=${outdir}/AtoI_Edit_Tables
mkdir -p "${final_tables}"

## Extract A-to-I edited positions from REDItools output. Since the files are named with a random string, we will use the parameters.txt file to identify the sample before extracting. 
. ~/env/REDItools1/bin/activate

for dir in ${tables}/*/DnaRna*; do

params="$dir/parameters.txt"
bam_file=$(grep -oP 'SplitBams/\S+\.bam' $params | head -1 | xargs basename)
echo $bam_file
name=$(echo "$bam_file" | sed -E 's/.bam//')

analysis_id=$(grep -oP '(?<=Analysis ID: )\d+' ${params})
echo "$analysis_id"

selectPositions.py -i $dir/outTable_${analysis_id} -r -R -s AG -o ${final_tables}/${analysis_id}_edits.txt

done
deactivate

## For plotting -- merge bam files
ml SAMtools/1.21-GCC-13.3.0

samtools merge -o ${bam}/dpf5_wt_rna.bam ${bam}/CWT1_Aligned.sortedByCoord.out.bam ${bam}/CWT4_Aligned.sortedByCoord.out.bam ${bam}/CWT5_Aligned.sortedByCoord.out.bam 
samtools merge -o ${bam}/dpf5_ko1_rna.bam ${bam}/CM2_Aligned.sortedByCoord.out.bam ${bam}/CM5_Aligned.sortedByCoord.out.bam 
samtools merge -o ${bam}/dpf5_ko2_rna.bam ${bam}/CM4_Aligned.sortedByCoord.out.bam ${bam}/CM3_Aligned.sortedByCoord.out.bam

samtools merge -o ${bam}/wt_rna.bam ${bam}/WT1_Aligned.sortedByCoord.out.bam ${bam}/WT2_Aligned.sortedByCoord.out.bam ${bam}/WT3_Aligned.sortedByCoord.out.bam ${bam}/WT4_Aligned.sortedByCoord.out.bam 
samtools merge -o ${bam}/oe_rna.bam ${bam}/OE1_Aligned.sortedByCoord.out.bam ${bam}/OE2_Aligned.sortedByCoord.out.bam ${bam}/OE4_Aligned.sortedByCoord.out.bam

samtools index ${bam}/dpf5_wt_rna.bam
samtools index ${bam}/dpf5_ko1_rna.bam
samtools index ${bam}/dpf5_ko2_rna.bam
samtools index ${bam}/wt_rna.bam
samtools index ${bam}/oe_rna.bam

## This section uses https://github.com/guigolab/ggsashimi
## make fsd1 sashimi plots -- first install ggsashimi in your home directory. 
## You should be able to install inside of a Python virtual environment, and then clone the repository to your home directory. 
## Also, transfer the meta files in ./SashimiPlots to the cluster.
ml R/4.5.1-gfbf-2025a
ml R-bundle-CRAN/2025.10-foss-2025a

## Note - sashimi plots for Perithecial samples and hyphal samples need to be generated separately to get the proper Y-axis -- we want the perithecial samples to be on the same scale, but the hyphal sample is not visible on that scale due to low expression. 
## run from /scratch/ad45368/fsd1/ggsashimi
. env/ggsashimi/bin/activate
 ~/ggsashimi/ggsashimi.py \
 -b ${SashimiPlots}/sashimi_perisamples \
 -g ./fungiDB_GFFtoGTF_conversion.gtf \
 -M 10 \
 -C 3 \
 -O 3 \
 -L 3 \
 -A mean_j \
 --shrink \
 --alpha 0.5 \
  --base-size 20 \
  --ann-height 1.5 \
  -P  ${SashimiPlots}/palette.txt \
 -c CM002239.1:5296170-5303095 \
 -o peri_fsd1_sashimi_v2 \
 -F png 

## Run again for hyphal samples
 ~/ggsashimi/ggsashimi.py \
 -b ${SashimiPlots}/sashimi_hyphalsamples \
 -g ./fungiDB_GFFtoGTF_conversion.gtf \
 -M 10 \
 -C 3 \
 -O 3 \
 -L 3 \
 -A mean_j \
 --shrink \
 --alpha 0.5 \
  --base-size 20 \
  --ann-height 1.5 \
  -P  ${SashimiPlots}/palette_hyph.txt \
 -c CM002239.1:5296170-5303095 \
 -o hyphal_fsd1_sashimi \
 -F png 

deactivate

