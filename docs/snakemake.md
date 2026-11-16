# Snakemake Pipeline Guide

**humaninFlow** includes a production-grade Snakemake workflow providing deterministic dependency resolution, file-based checkpoints, and native Conda integration.

---

## Directory Structure

```
workflow/snakemake/
├── Snakefile              # Rule definitions (lint, predict, summarize)
├── config/
│   └── config.yaml        # YAML configuration for data and CLI flags
├── envs/
│   └── humaninfinder.yaml # Conda environment with latest humanin-finder git
└── scripts/
    └── merge_and_report.py # Standalone reporting & metadata merge script
```

---

## Running the Workflow

### Quick Invocation
```bash
snakemake \
  --snakefile workflow/snakemake/Snakefile \
  --configfile workflow/snakemake/config/config.yaml \
  --cores 4
```

### Overriding Config from Command Line
You can dynamically override inputs and parameters without editing `config.yaml`:
```bash
snakemake \
  --snakefile workflow/snakemake/Snakefile \
  --config input_fasta=path/to/my_samples.fasta \
           metadata=path/to/my_metadata.csv \
           outdir=results/snakemake_run \
           table=2 \
  --cores 8
```

### Using Conda Environments
To let Snakemake automatically manage the software environment using Conda/Mamba:
```bash
snakemake \
  --snakefile workflow/snakemake/Snakefile \
  --use-conda \
  --cores 4
```

---

## Rules Overview

* **`rule lint`**: Runs `humanin-finder lint` on the input FASTA file, producing a timestamp checkpoint `.lint.done`.
* **`rule predict`**: Runs `humanin-finder predict` (or `scan`) on the validated input, generating `.csv`, `.fasta`, `.gff3`, `.bed`, and `.json`.
* **`rule summarize`**: Executes `merge_and_report.py` to produce consolidated TSV/CSV tables and the Markdown cohort report.
