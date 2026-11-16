# Parameters & CLI Reference

Both Nextflow and Snakemake pipelines share a consistent parameter scheme that controls the underlying execution of `humanin-finder`.

---

## Core Input & Output Parameters

| Parameter (Nextflow) | Key (Snakemake) | Default | Description |
| :--- | :--- | :---: | :--- |
| `--input` | `input_fasta` | *None* | Path to input FASTA file (plain or `.gz`). |
| `--metadata` | `metadata` | *None* | Path to CSV/TSV metadata table with sample annotations. |
| `--outdir` | `outdir` | `results` | Directory where all generated outputs will be written. |

---

## HumaninFinder Engine Options

| Parameter (Nextflow) | Key (Snakemake) | Default | Description |
| :--- | :--- | :---: | :--- |
| `--command` | `command` | `predict` | Operation mode: `predict` (reports best frame per code) or `scan` (every non-redundant locus, recommended for NUMTs). |
| `--table` | `table` | `auto` | NCBI genetic code: `auto` (Table 2 for mitogenomes $\le 50$ kb, Table 1 otherwise), `2` (vertebrate mt), `2,1`, `5` (invertebrate), etc. |
| `--circular` | `circular` | `true` | Treat records $\le 50$ kb as circular, reading loci that wrap through the assembly origin. |
| `--all_candidates` | `all_candidates` | `false` | Report every non-redundant candidate frame rather than only the top-scoring one. |
| `--no_hmm` | `no_hmm` | `false` | Skip the Pfam PF15040 HMM domain profile search. |
| `--no_rescue` | `no_rescue` | `false` | Disable HMM-guided rescue of interrupted or frameshifted open reading frames. |
| `--no_shlp` | `no_shlp` | `false` | Skip annotation of the six Small Humanin-Like Peptides (SHLP1-6). |
| `--no_synteny` | `no_synteny` | `false` | Skip syntenic *MT-RNR2* profile search (run HMM domain search only). |

---

## Example Parameter Combinations

### 1. High-Throughput Mitogenome Population Cohort
```bash
nextflow run workflow/nextflow/main.nf \
  --input mitogenomes.fasta \
  --metadata cohort_metadata.csv \
  --table 2 \
  --circular
```

### 2. Scanning Whole Nuclear Genomes for NUMTs
```bash
nextflow run workflow/nextflow/main.nf \
  --input nuclear_assembly.fasta.gz \
  --command scan \
  --table 1 \
  --circular false
```
