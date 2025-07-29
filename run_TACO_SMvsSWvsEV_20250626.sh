#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=2-0:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thac.duong@moffitt.org

# Load necessary modules
ml gcc/11.2.0
ml taco/0.7.3

# Set directories
GTF_OUTPUT_DIR="/share/.scratch/thac/HISAT2_scratch_20250604/downstream_analysis_20250608/output_stringtie_gtf_20250623"
TACO_OUT_DIR="/share/.scratch/thac/HISAT2_scratch_20250604/downstream_analysis_20250608/taco_output_SMvsSWvsEV_20250626"

# Create output directory if it doesn't exist
# mkdir -p "$TACO_OUT_DIR"

# Step 1: Create a file containing only GTF paths with "SM" or "SW" or "EV" in the filename
find "$GTF_OUTPUT_DIR" -name "*.gtf" \( -name "*SM*.gtf" -o -name "*SW*.gtf" -o -name "*EV*.gtf" \) > "$GTF_OUTPUT_DIR/gtf_files_SMvsSWvsEV_v2.txt"

# Step 2: Run TACO to merge transcriptomes
cd "$GTF_OUTPUT_DIR"
taco_run -o "$TACO_OUT_DIR" -p 8 "$GTF_OUTPUT_DIR/gtf_files_SMvsSWvsEV_v2.txt" --filter-min-length 0 --gtf-expr-attr TPM

echo "TACO transcriptome merging complete. Output directory: $TACO_OUT_DIR"
