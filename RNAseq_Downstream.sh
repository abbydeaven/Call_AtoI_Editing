#!/bin/bash
#SBATCH --partition=batch
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=ad45368@uga.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=100gb
#SBATCH --time=8:00:00
#SBATCH --output=../RNAseq_Output/logs/%x.out
#SBATCH --error=../RNAseq_Output/logs/%x.err


cd $SLURM_SUBMIT_DIR
##Directory information+variables:
outdir="../RNAseq_Output"
bam="${outdir}/bamFiles"
bw="${outdir}/bigWig"
PeakDir="${outdir}/Peaks"
Motifs="${outdir}/Motifs"
meta="${outdir}/Metaplots"

## For plotting and analysis, merge bam files
ml SAMtools/1.21-GCC-13.3.0

samtools merge -o ${bam}/dpf5_wt_rna.bam ${bam}/CWT1_Aligned.sortedByCoord.out.bam ${bam}/CWT4_Aligned.sortedByCoord.out.bam ${bam}/CWT5_Aligned.sortedByCoord.out.bam 
samtools merge -o ${bam}/dpf5_ko1_rna.bam ${bam}/CM2_Aligned.sortedByCoord.out.bam ${bam}/CM5_Aligned.sortedByCoord.out.bam 
samtools merge -o ${bam}/dpf5_ko2_rna.bam ${bam}/CM4_Aligned.sortedByCoord.out.bam ${bam}/CM3_Aligned.sortedByCoord.out.bam -f

samtools merge -o ${bam}/wt_rna.bam ${bam}/WT1_Aligned.sortedByCoord.out.bam ${bam}/WT2_Aligned.sortedByCoord.out.bam ${bam}/WT3_Aligned.sortedByCoord.out.bam ${bam}/WT4_Aligned.sortedByCoord.out.bam 
samtools merge -o ${bam}/oe_rna.bam ${bam}/OE1_Aligned.sortedByCoord.out.bam ${bam}/OE2_Aligned.sortedByCoord.out.bam ${bam}/OE4_Aligned.sortedByCoord.out.bam -f

samtools index ${bam}/dpf5_wt_rna.bam
samtools index ${bam}/dpf5_ko1_rna.bam
samtools index ${bam}/dpf5_ko2_rna.bam
samtools index ${bam}/wt_rna.bam
samtools index ${bam}/oe_rna.bam

## Extract A-to-I editing tables into human-readable files

## NOTE TO ABBY - this should be a separate script
## make fsd1 sashimi plots
ml R/4.5.1-gfbf-2025a
ml R-bundle-CRAN/2025.10-foss-2025a

## run from /scratch/ad45368/fsd1/ggsashimi
. env/ggsashimi/bin/activate
 ~/ggsashimi/ggsashimi.py \
 -b fsd1_dev.tsv \
 -g ~/NcGenome/fungiDB_GFFtoGTF_conversion.gtf \
 -M 10 \
 -C 3 \
 -O 3 \
 -L 3 \
 -A mean_j \
 --shrink \
 --alpha 0.5 \
  --base-size 20 \
  --ann-height 1.5 \
  -P palette.txt \
 -c CM002239.1:5296170-5303095 \
 -o fsd1_sashimi_v2 \
 -F png 

 ~/ggsashimi/ggsashimi.py -b fsd1_dev.tsv -c CM002236.1:9564599-9667735 -o vsd1 -S plus -M 5 -g ~/NcGenome/fungiDB_GFFtoGTF_conversion.gtf -O 3 -C 3 -L 1 --fix-y-scale --ann-height 1 --base-size 18 -F png python 
 
 ~/ggsashimi/ggsashimi.py -b dev.tsv -c CM002236.1:9664599-9667735 -o fsd1_dev_2 -S plus -M 5 -g ~/NcGenome/fungiDB_GFFtoGTF_conversion.gtf -O 3 -C 3 -L 1 --fix-y-scale --ann-height 1 --base-size 18 -F png -P palette.txt
