# Quick Start

Get up and running with **humaninFlow** in less than 5 minutes.

---

## 1. Prerequisites

Make sure you have at least one workflow manager and Python installed:
* **Nextflow** ($\ge 24.04$) or **Snakemake** ($\ge 8.0$)
* **Python** ($\ge 3.10$) with `humanin-finder` ($\ge \text{v1.0.0b4}$)
* *(Optional)* Docker, Apptainer/Singularity, or Conda for containerized environments.

### Installing HumaninFinder (Latest Git)
```bash
pip install git+https://github.com/LaBiOmicS/humaninfinder.git
```

---

## 2. Clone the Repository

```bash
git clone https://github.com/LaBiOmicS/humaninFlow.git
cd humaninFlow
```

---

## 3. Run on Test Data

A minimal test dataset with vertebrate mitogenomes is provided under `examples/`.

### Running with Nextflow
```bash
nextflow run workflow/nextflow/main.nf \
  --input examples/test_mitogenomes.fasta \
  --metadata examples/test_metadata.csv \
  --outdir results/test_nextflow \
  --table 2 \
  --circular
```

### Running with Snakemake
```bash
snakemake \
  --snakefile workflow/snakemake/Snakefile \
  --config input_fasta=../../examples/test_mitogenomes.fasta \
           metadata=../../examples/test_metadata.csv \
           outdir=../../results/test_snakemake \
  --cores 2
```

---

## 4. Inspect Results

Your results will be structured in `results/`:
```
results/
├── raw_predictions/
│   ├── test_mitogenomes_results.csv     # Per-sample predictions
│   ├── test_mitogenomes_results.fasta   # Predicted peptide sequences
│   ├── test_mitogenomes_results.gff3    # Genomic feature tracks
│   ├── test_mitogenomes_results.bed     # BED coordinates
│   └── test_mitogenomes_run.json        # Execution provenance
└── summary/
    ├── cohort_humanin_summary.csv       # Merged with metadata
    ├── cohort_humanin_summary.tsv       # Tab-separated summary
    ├── cohort_unique_peptides.fasta     # Non-redundant unique peptides
    └── COHORT_ANALYSIS_REPORT.md        # Comprehensive Markdown report
```
