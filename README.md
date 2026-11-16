<div align="center">

# humaninFlow

### Scalable, Data-Agnostic Workflows for Humanin & Mitochondrial-Derived Peptide (MDP) Discovery

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A524.04-23aa62.svg)](https://www.nextflow.io/)
[![Snakemake](https://img.shields.io/badge/Snakemake-%E2%89%A58.0-blue.svg)](https://snakemake.github.io/)
[![HumaninFinder](https://img.shields.io/badge/HumaninFinder-v1.0.0b4-orange.svg)](https://github.com/LaBiOmicS/humaninfinder)
[![Documentation](https://img.shields.io/badge/Docs-GitHub%20Pages-brightgreen.svg)](https://labiomics.github.io/humaninFlow/)

**[Documentation](https://labiomics.github.io/humaninFlow/)** •
**[Quick Start](#quick-start)** •
**[Nextflow](#nextflow-pipeline)** •
**[Snakemake](#snakemake-pipeline)** •
**[Outputs](#outputs)** •
**[Citation](#citation)**

</div>

---

## Overview

**humaninFlow** is a dual-engine workflow pipeline (**Nextflow DSL2** & **Snakemake**) for high-throughput, reproducible and automated prediction of **Humanin** and the six **Small Humanin-Like Peptides (SHLP1-6)** across complete mitogenomes, contigs, and nuclear assemblies.

Powered by the latest git release of **[HumaninFinder](https://github.com/LaBiOmicS/humaninfinder)** (Laboratory of Bioinformatics and Omics Sciences — **LaBiOmicS**), `humaninFlow` abstracts data dependencies, automates sequence linting, scales parallel execution, and merges genomic predictions directly with epidemiological and clinical metadata.

```
                    ┌──────────────────────────────────────────┐
                    │    Input FASTA (Mitogenomes / Contigs)   │
                    └────────────────────┬─────────────────────┘
                                         │
                                         ▼
                               [ Step 1: FASTA Lint ]
                                         │
                                         ▼
                        [ Step 2: HumaninFinder Predict ]
                          • MT-RNR2 Profile HMM Synteny
                          • Species Frame Translation
                          • Origin Wrap Resolution
                                         │
                                         ▼
                         [ Step 3: Cohort Aggregation ]
                          • Metadata Merging (CSV / TSV)
                          • Unique Peptides Extraction
                          • Markdown & CSV Reports
```

---

## Quick Start

### 1. Prerequisites
* **Nextflow** ($\ge 24.04$) or **Snakemake** ($\ge 8.0$)
* **Python** ($\ge 3.10$) with `humanin-finder` ($\ge \text{v1.0.0b4}$):
  ```bash
  pip install git+https://github.com/LaBiOmicS/humaninfinder.git
  ```

### 2. Run with Nextflow
```bash
nextflow run workflow/nextflow/main.nf \
  --input examples/test_mitogenomes.fasta \
  --metadata examples/test_metadata.csv \
  --outdir results/nextflow \
  --table 2 \
  --circular
```

### 3. Run with Snakemake
```bash
snakemake \
  --snakefile workflow/snakemake/Snakefile \
  --config input_fasta=../../examples/test_mitogenomes.fasta \
           metadata=../../examples/test_metadata.csv \
           outdir=../../results/snakemake \
  --cores 4
```

---

## Outputs

Each pipeline run generates:
* `results/raw_predictions/<prefix>_results.csv`: Complete table of all predicted frames and scores.
* `results/raw_predictions/<prefix>_results.fasta`: FASTA file containing all translated peptides.
* `results/raw_predictions/<prefix>_results.gff3` & `.bed`: Genomic coordinate annotation tracks.
* `results/summary/cohort_humanin_summary.csv`: Aggregated table merged with user-supplied metadata.
* `results/summary/cohort_unique_peptides.fasta`: Non-redundant unique peptide variants found across the cohort.
* `results/summary/COHORT_ANALYSIS_REPORT.md`: Comprehensive executive report summarizing discovery rates.

---

## Documentation

Full documentation, parameter references, and container setup guides are available at:  
👉 **[https://labiomics.github.io/humaninFlow/](https://labiomics.github.io/humaninFlow/)**

---

## Citation

If you use `humaninFlow` or `HumaninFinder` in your research, please cite:

```bibtex
@software{humaninflow2026,
  author       = {Dayhoff Genomics Lab and LaBiOmicS},
  title        = {humaninFlow: Scalable and Agnostic Workflows for Humanin and Mitochondrial Peptide Discovery},
  year         = {2026},
  url          = {https://github.com/LaBiOmicS/humaninFlow}
}
```

---

## License

Distributed under the **MIT License**. See `LICENSE` for details.
