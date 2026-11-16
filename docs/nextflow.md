# Nextflow Pipeline Guide

**humaninFlow** implements a modern Nextflow DSL2 pipeline with automated channel management, execution profiles, and pre-flight validation.

---

## Architecture

The Nextflow implementation comprises three decoupled stages:

1. **`HUMANIN_LINT`**: Validates the input FASTA file for formatting anomalies, illegal IUPAC symbols, or malformed sequence records.
2. **`HUMANIN_RUN`**: Executes `humanin-finder` with profile HMM synteny mapping, genetic code translation, and circular wrapping.
3. **`SUMMARIZE_COHORT`**: Aggregates predictions, merges with sample metadata, determines cohort-wide peptide frequencies, and generates structured reports.

---

## Execution Command

```bash
nextflow run workflow/nextflow/main.nf \
  --input path/to/sequences.fasta \
  --metadata path/to/metadata.csv \
  --outdir results/my_run \
  --table 2 \
  --circular
```

---

## Profiles & Container Environments

`humaninFlow` supports multiple compute engines configured via the `-profile` flag:

### 1. Local Profile (`-profile local`)
Executes directly on the host machine using the installed Python environment:
```bash
nextflow run workflow/nextflow/main.nf -profile local --input data.fasta
```

### 2. Conda Profile (`-profile conda`)
Automatically provisions the isolated conda environment with dependencies:
```bash
nextflow run workflow/nextflow/main.nf -profile conda --input data.fasta
```

### 3. Docker Profile (`-profile docker`)
Pulls and runs the official container image from GitHub Packages (`ghcr.io`):
```bash
nextflow run workflow/nextflow/main.nf -profile docker --input data.fasta
```

### 4. Apptainer / Singularity Profile (`-profile apptainer`)
Ideal for shared HPC clusters without root privileges:
```bash
nextflow run workflow/nextflow/main.nf -profile apptainer --input data.fasta
```

---

## Cluster & HPC Execution (SLURM / SGE)

To run on a compute cluster with SLURM, simply define the executor in your `nextflow.config`:
```groovy
process {
    executor = 'slurm'
    queue    = 'general'
    cpus     = 4
    memory   = '8.GB'
    time     = '2.h'
}
```
