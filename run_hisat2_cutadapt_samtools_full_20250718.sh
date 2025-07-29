#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=32G
#SBATCH --time=1-0:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thac.duong@moffitt.org

module load HISAT2/2.2.1-foss-2020a
module load SAMtools/1.19.2-GCC-13.2.0
module load cutadapt/2.10-GCCcore-9.3.0-Python-3.8.2  # Adjust if your module is named differently

# Define directories
FASTQ_DIR="/share/Lab_Shaw/FabianaPernaProject/rawfiles"
GENOME_INDEX="/share/Lab_Shaw/FabianaPernaProject/HISAT2_job/HISAT2_Index/grch38/genome"
TRIMMED_DIR="/share/.scratch/thac/HISAT2_scratch_20250604/trimmed_fastq_full_20250610"
OUTPUT_DIR="/share/.scratch/thac/HISAT2_scratch_20250604/output_BAM_full_20250610"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TRIMMED_DIR"

# Loop through all R1 files and process all samples
for READ1 in "${FASTQ_DIR}"/*_1_*.fastq.gz; do
    READ2="${READ1/_1_/_2_}"
    if [[ ! -f "$READ2" ]]; then
        echo "Missing pair for $READ1, skipping..."
        continue
    fi

    BASENAME=$(basename "${READ1}" | sed 's/_1_/_/; s/\.fastq\.gz//')
    SAMPLE_NAME="${BASENAME}"

    # Set output SAM/BAM paths
    SAM_OUT="${OUTPUT_DIR}/${SAMPLE_NAME}.sam"
    BAM_SORTED="${OUTPUT_DIR}/${SAMPLE_NAME}.sorted.bam"

    if [[ "$SAMPLE_NAME" == *U37* ]]; then
        echo "Skipping Cutadapt for U37: ${SAMPLE_NAME}"
        echo "Mapping untrimmed U37 reads..."
        hisat2 -x "$GENOME_INDEX" -1 "$READ1" -2 "$READ2" -p 16 --dta --rna-strandness FR -S "$SAM_OUT"
    else
        # Define trimmed FASTQ output files
        TRIMMED_READ1="${TRIMMED_DIR}/${SAMPLE_NAME}_R1_trimmed.fastq.gz"
        TRIMMED_READ2="${TRIMMED_DIR}/${SAMPLE_NAME}_R2_trimmed.fastq.gz"

        echo "Trimming reads for sample: ${SAMPLE_NAME}"
        cutadapt -e 0.2 -m 75 -q 10 -j 16 -o "$TRIMMED_READ1" -p "$TRIMMED_READ2" "$READ1" "$READ2"

        echo "Mapping trimmed sample: ${SAMPLE_NAME}"
        hisat2 -x "$GENOME_INDEX" -1 "$TRIMMED_READ1" -2 "$TRIMMED_READ2" -p 16 --dta --rna-strandness FR -S "$SAM_OUT"
    fi

    # Convert SAM to sorted BAM and index
    samtools view -@ 16 -bS "$SAM_OUT" | samtools sort -@ 16 -o "$BAM_SORTED"
    samtools index "$BAM_SORTED"
    rm "$SAM_OUT"
done
