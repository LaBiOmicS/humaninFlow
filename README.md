<div align="center">

# `humaninFlow`

### **High-Throughput, Data-Agnostic Workflows for Humanin & Mitochondrial-Derived Peptide (MDP) Discovery**

[![GitHub Release](https://img.shields.io/github/v/release/LaBiOmicS/humaninFlow?include_prereleases&color=0969da&label=Release)](https://github.com/LaBiOmicS/humaninFlow/releases)
[![Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A524.04%20DSL2-23aa62?style=flat&logo=nextflow&logoColor=white)](https://www.nextflow.io/)
[![Snakemake](https://img.shields.io/badge/Snakemake-%E2%89%A58.0-4a90e2?style=flat&logo=snakemake&logoColor=white)](https://snakemake.github.io/)
[![Engine](https://img.shields.io/badge/Engine-HumaninFinder%20v1.0.0b4-f97316?style=flat&logo=python&logoColor=white)](https://github.com/LaBiOmicS/humaninfinder)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/Documentation-GitHub%20Pages-blue?style=flat&logo=github)](https://labiomics.github.io/humaninFlow/)
[![CI](https://github.com/LaBiOmicS/humaninFlow/actions/workflows/ci.yml/badge.svg)](https://github.com/LaBiOmicS/humaninFlow/actions/workflows/ci.yml)

<p align="center">
  <b>A dual-engine pipeline framework developed by the Laboratory of Bioinformatics and Omics Sciences (<a href="https://github.com/LaBiOmicS">LaBiOmicS</a>)</b>
</p>

[📖 Documentation](https://labiomics.github.io/humaninFlow/) •
[⚡ Quick Start](#-quick-start) •
[🧬 Biological Motivation](#-biological-motivation) •
[⚙️ Architecture](#-pipeline-architecture) •
[🚀 Execution Modes](#-execution-modes) •
[📊 Output Specifications](#-output-specifications) •
[📚 Citation](#-citation)

</div>

---

## 📌 Executive Summary

**`humaninFlow`** is an enterprise-grade, scalable, and data-agnostic workflow pipeline designed to identify, annotate, and characterize **Humanin** and the six **Small Humanin-Like Peptides (SHLP1–6)** across single mitogenomes, large-scale population cohorts, and whole nuclear genome assemblies.

Implemented simultaneously in **Nextflow DSL2** and **Snakemake**, `humaninFlow` harnesses the core algorithms of **[HumaninFinder](https://github.com/LaBiOmicS/humaninfinder)**. It abstracts all software dependencies, parallelizes execution across local multi-core workstations or distributed HPC clusters, pre-validates FASTA syntax, and directly merges peptide discoveries with user-supplied epidemiological and clinical metadata.

---

## 🧬 Biological Motivation

Mitochondrial-derived peptides (MDPs) are short functional micropeptides (20–40 amino acids) encoded by small open reading frames (sORFs) nested inside mitochondrial structural RNA genes:

* **Humanin (HN):** A 21–24 aa cytoprotective peptide originally identified for its neuroprotective activity against amyloid-β and familial Alzheimer's disease mutants. Humanin binds directly to pro-apoptotic BCL-2 family proteins (**BAX** and **BID**), physically preventing outer mitochondrial membrane permeabilization (MOMP) and suppressing apoptotic cascades.
* **SHLP1–6:** Six peptides encoded within the same *MT-RNR2* (16S rRNA) locus that regulate cell survival, insulin sensitivity, oxidative stress, and metabolic homeostasis.

### The Annotation Problem
Standard gene prediction suites (e.g., *Prodigal*, *Prokka*, *GeneMark*) fail to detect MDPs because:
1. **Structural RNA Overlap:** The sORFs reside within the catalytic structure of the 16S ribosomal RNA gene (*MT-RNR2*).
2. **Non-Canonical Translation:** Initiation often utilizes alternative non-AUG codons across eukaryotic lineages.
3. **NUMTs & Pseudogenization:** Nuclear mitochondrial DNA insertions (NUMTs) accumulate substitutions and frameshifts across evolutionary time, requiring simultaneous assessment under mitochondrial (Table 2) and standard/cytosolic (Table 1) genetic codes.

`humaninFlow` solves this through **profile HMM synteny mapping**, **clade-specific coordinate resolution**, and **HMM domain validation (PF15040)**.

---

## ⚙️ Pipeline Architecture

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      Input: Any FASTA + Metadata                       │
 │         (Mitogenomes, Viral/Bacterial Scaffolds, or Nuclear WGS)       │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                   Stage 1: Pre-flight FASTA Linting                   │
 │           (Checks syntax, illegal IUPAC symbols, duplicate IDs)        │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                  Stage 2: HumaninFinder Discovery Core                 │
 │   • Syntenic Mapping: Clade-specific MT-RNR2 Profile HMMs             │
 │   • In Silico Reading: Species Genetic Code Translation (auto/2/1/5)  │
 │   • Domain Verification: Pfam PF15040 Gathering Threshold Scoring      │
 │   • Structural Wrap: Circular sequence boundary resolution (≤ 50 kb)   │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                  Stage 3: Multi-Omics Cohort Synthesis                 │
 │   • Metadata Merge: Prediction tables joined with sample covariates    │
 │   • Variant Extraction: Non-redundant FASTA of unique peptide alleles  │
 │   • Executive Reporting: Automated Markdown and TSV/CSV summaries      │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
    [ Raw Prediction Directory ]             [ Cohort Summary Directory ]
     • <prefix>_results.csv                   • cohort_humanin_summary.csv
     • <prefix>_results.fasta                 • cohort_humanin_summary.tsv
     • <prefix>_results.gff3                  • cohort_unique_peptides.fasta
     • <prefix>_results.bed                   • COHORT_ANALYSIS_REPORT.md
     • <prefix>_run.json
```

---

## ⚖️ Nextflow vs. Snakemake: Which Engine to Choose?

`humaninFlow` is distributed with first-class implementations in both major bioinformatics workflow managers:

| Feature | Nextflow DSL2 | Snakemake |
| :--- | :--- | :--- |
| **Primary Use Case** | Cloud, institutional clusters, SLURM, and large batches | Local workstations, single-node servers, Conda-centric labs |
| **Engine Executable** | `nextflow run workflow/nextflow/main.nf` | `snakemake --snakefile workflow/snakemake/Snakefile` |
| **Containers Supported**| Docker, Apptainer/Singularity, Podman, Wave | Apptainer/Singularity, Docker |
| **Environment Control** | Profiles (`conda`, `docker`, `apptainer`, `singularity`, `slurm`, `test`) | `config.yaml` + `--use-conda` / `--use-apptainer` |
| **Execution Logging** | Detailed execution tracing (`.nextflow.log`, `-with-report`) | Snakemake DAG visualization and HTML report |

---

## ⚡ Quick Start

### 1. Installation

Clone the repository and install the latest `humanin-finder` release:

```bash
git clone https://github.com/LaBiOmicS/humaninFlow.git
cd humaninFlow

# Either let a profile provide HumaninFinder (-profile docker|apptainer|conda, --use-conda, --use-apptainer)
# or install the release the workflows are validated against:
pip install humanin-finder==1.0.0b4
```

### 2. Run with Nextflow

```bash
# Bundled example (human + mouse mitogenomes); drop ",docker" if humanin-finder is installed locally
nextflow run workflow/nextflow/main.nf -profile test,docker

# Your data: a single FASTA or a quoted glob, one cohort summary at the end
nextflow run workflow/nextflow/main.nf -profile docker \
  --input 'cohort/*.fasta' \
  --metadata samples.csv \
  --table 2 \
  --outdir results/nextflow
```

### 3. Run with Snakemake

```bash
# Run from the repository root; paths are relative to where you run snakemake.
# With no --config the bundled example data are used.
snakemake -s workflow/snakemake/Snakefile --cores 4 \
  --config input_fasta=examples/test_mitogenomes.fasta \
           metadata=examples/test_metadata.csv \
           outdir=results/snakemake
# add --use-conda or --use-apptainer to let Snakemake provide HumaninFinder
```

---

## 🚀 Execution Modes & Practical Recipes

### Recipe 1: Population Mitogenomics (Vertebrates)
Run on a multi-FASTA file of complete circular mitogenomes using vertebrate mitochondrial code (NCBI Table 2):
```bash
nextflow run workflow/nextflow/main.nf \
  --input my_mitogenomes.fasta \
  --metadata sample_metadata.csv \
  --outdir results/vertebrate_cohort \
  --table 2 \
  --circular
```

### Recipe 2: NUMT Hunting in Nuclear Assemblies
Screen draft contigs or nuclear scaffolds for transposed nuclear mitochondrial insertions, disabling circularity and reporting all non-redundant matches under standard code (Table 1):
```bash
nextflow run workflow/nextflow/main.nf \
  --input nuclear_scaffolds.fasta.gz \
  --command scan \
  --table 1 \
  --circular false \
  --outdir results/numts_scan
```

### Recipe 3: High-Performance Computing via SLURM
Submit jobs directly to an institutional HPC cluster via Nextflow:
```bash
nextflow run workflow/nextflow/main.nf \
  -profile apptainer,slurm \
  --input 'massive_cohort/*.fasta' \
  --outdir results/hpc_run \
  -process.queue batch
```

---

## 📊 Output Specifications

All outputs are categorized into **raw predictions** and **cohort summary**:

### Prediction Files (`results/raw_predictions/`)
* **`<prefix>_results.csv`**: Tabular discovery ledger with coordinates, strand, frame status, profile scores, and deduced sequences.
* **`<prefix>_results.fasta`**: Translated amino acid FASTA of all detected peptides.
* **`<prefix>_results.gff3`**: Standard 1-based inclusive genomic feature tracks.
* **`<prefix>_results.bed`**: 0-based half-open feature coordinates with circular wrap blocks.
* **`<prefix>_run.json`**: Run record (command line, options, software version, SHA-256 of the input).

### Cohort Summary (`results/summary/`)
* **`cohort_humanin_summary.csv` / `.tsv`**: Combined master table integrating predictions with all user metadata columns.
* **`cohort_unique_peptides.fasta`**: Non-redundant multi-FASTA of all unique peptide alleles, ranked by observed frequency.
* **`COHORT_ANALYSIS_REPORT.md`**: Markdown report with counts per peptide and frame status, metadata match rate, and Humanin allele frequencies.

Both engines call the same HumaninFinder release and the same summary script ([`workflow/scripts/merge_and_report.py`](workflow/scripts/merge_and_report.py)); CI fails unless their outputs on the example data are byte-for-byte identical.

---

## 📚 Citation

If you use **humaninFlow** or **HumaninFinder** in published research, please cite the software version and repository as shown below. The accompanying scientific article is currently in preparation; this section will be updated when it is published.

```bibtex
@software{humaninflow,
  author       = {Menegidio, Fabiano Bezerra and {LaBiOmicS}},
  title        = {{humaninFlow}: Scalable and reproducible dual-engine workflow (Nextflow \& Snakemake) for high-throughput Humanin and mitochondrial-derived peptide discovery},
  version      = {1.0.0},
  year         = {2026},
  url          = {https://github.com/LaBiOmicS/humaninFlow}
}

@software{humaninfinder,
  author       = {Menegidio, Fabiano Bezerra and {LaBiOmicS}},
  title        = {{HumaninFinder}: homology-first location and annotation of Humanin and SHLP1-6},
  version      = {1.0.0b4},
  year         = {2026},
  doi          = {10.5281/zenodo.24108118},
  url          = {https://github.com/LaBiOmicS/humaninfinder}
}
```

Machine-readable citation metadata are provided in [`CITATION.cff`](CITATION.cff) (or via GitHub's **"Cite this repository"** button).

---

## 🏛️ Laboratory & Contact

Developed and maintained by the **Laboratory of Bioinformatics and Omics Sciences (LaBiOmicS)**, Universidade de Mogi das Cruzes (UMC), São Paulo, Brazil.

* **GitHub Organization**: [https://github.com/LaBiOmicS](https://github.com/LaBiOmicS)
* **Workflow Repository**: [https://github.com/LaBiOmicS/humaninFlow](https://github.com/LaBiOmicS/humaninFlow)
* **Core Engine**: [https://github.com/LaBiOmicS/humaninfinder](https://github.com/LaBiOmicS/humaninfinder)
* **Questions & Issues**: [https://github.com/LaBiOmicS/humaninFlow/issues](https://github.com/LaBiOmicS/humaninFlow/issues)

---

## 📄 License

This project is released under the terms of the **MIT License**. See [`LICENSE`](LICENSE) for full details.
