# humaninFlow

**Scalable, Data-Agnostic Workflows for Humanin & Mitochondrial-Derived Peptide (MDP) Discovery**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Workflow: Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A524.04-23aa62.svg)](https://www.nextflow.io/)
[![Workflow: Snakemake](https://img.shields.io/badge/Snakemake-%E2%89%A58.0-blue.svg)](https://snakemake.github.io/)
[![Engine: humanin-finder](https://img.shields.io/badge/humanin--finder-v1.0.0b4-orange.svg)](https://github.com/LaBiOmicS/humaninfinder)

---

## Overview

**humaninFlow** is a dual-engine pipeline framework (**Nextflow DSL2** and **Snakemake**) engineered to run large-scale, automated and reproducible searches for **Humanin** and the six **Small Humanin-Like Peptides (SHLP1-6)** across complete mitogenomes, contigs, and whole-genome assemblies.

Powered by the latest release of [HumaninFinder](https://github.com/LaBiOmicS/humaninfinder) (developed by the Laboratory of Bioinformatics and Omics Sciences — **LaBiOmicS**), `humaninFlow` abstracts data dependencies, parallelizes execution, validates sequence integrity, and automatically integrates genomic predictions with user-provided cohort metadata.

```
                     ┌──────────────────────────────────────────┐
                     │   Any Input FASTA (Mitogenome / WGS)     │
                     └────────────────────┬─────────────────────┘
                                          │
                                          ▼
                               [ Step 1: FASTA Lint ]
                                          │
                                          ▼
                         [ Step 2: HumaninFinder Predict ]
                           • MT-RNR2 Profile HMM Synteny
                           • Species Reading Frame Mapping
                           • Circular Wrap Resolution
                                          │
                                          ▼
                          [ Step 3: Cohort Aggregation ]
                           • Metadata Merging (CSV / TSV)
                           • Unique Peptides Extraction
                           • Cohort Analysis Report (MD)
```

---

## Key Features

* **Data-Agnostic Design:** Execute effortlessly on single mitogenomes, population cohorts (e.g. hundreds of canine CTVT and host samples), or massive nuclear assemblies containing NUMTs.
* **Dual Pipeline Support:** Choose between **Nextflow** (ideal for cloud, HPC clusters via SLURM, and containerized runs) or **Snakemake** (ideal for local compute, file-driven dependencies, and Conda environments).
* **Metadata Integration:** Seamlessly merges prediction tables with epidemiological, clinical, and evolutionary sample metadata.
* **Reproducible Environments:** Out-of-the-box support for **Local Environment**, **Conda/Micromamba**, **Docker**, and **Apptainer/Singularity**.
* **Pre-flight Linting:** Integrates `humanin-finder lint` to catch corrupted sequences, formatting syntax issues, or ambiguous headers prior to execution.
