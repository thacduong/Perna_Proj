#!/bin/bash
#SBATCH --job-name=stringtie_array
#SBATCH --output=stringtie_%A_%a.out
#SBATCH --error=stringtie_%A_%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=384G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thac.duong@moffitt.org
#SBATCH --array=0-5

# Load modules
ml gcc/11.2.0

stringtie="/share/Lab_Shaw/software/stringtie/stringtie-1.3.4d/stringtie"
REF_GTF_DIR="/share/Lab_Shaw/FabianaPernaProject/Cufflinks_job_2/GRCh38_114_reference/Homo_sapiens.GRCh38.114.gtf" # Original Reference
OUTPUT_DIR="/share/.scratch/thac/HISAT2_scratch_20250604/downstream_analysis_20250608/output_stringtie_gtf_20250623"

#mkdir -p "$OUTPUT_DIR"

# Path to bam list file
BAM_LIST="/share/.scratch/thac/HISAT2_scratch_20250604/output_BAM_merged_full_20250610/bam_list_full.txt"

# Get BAM file for this SLURM array task
BAM_FILE=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $BAM_LIST)

# Extract sample name from BAM filename (adjust this pattern to your BAM names)
SAMPLE_NAME=$(basename "$BAM_FILE" .bam)

echo "Running StringTie on $BAM_FILE"

# Run StringTie with 16 threads
$stringtie "$BAM_FILE" -p 16 -G "$REF_GTF_DIR" -o "$OUTPUT_DIR/${SAMPLE_NAME}.gtf" -l "$SAMPLE_NAME"

echo "Finished $SAMPLE_NAME"

