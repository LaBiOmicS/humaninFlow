# Outputs & Downstream Analysis

**humaninFlow** organizes outputs into two main directories: raw locus-level predictions (`raw_predictions/`) and cohort-level aggregated summaries (`summary/`).

---

## Directory Hierarchy

```
results/
├── raw_predictions/
│   ├── <prefix>_results.csv        # Comprehensive table of all predicted frames
│   ├── <prefix>_results.fasta      # FASTA sequences of predicted peptides
│   ├── <prefix>_results.gff3       # GFF3 gene annotations (1-based inclusive)
│   ├── <prefix>_results.bed        # BED feature coordinates (0-based half-open)
│   ├── <prefix>_run.json           # Execution provenance & SHA-256 integrity hash
│   └── <prefix>_gaps.csv           # Gaps at initiator positions (if any)
└── summary/
    ├── cohort_humanin_summary.csv  # Unified table merged with user metadata
    ├── cohort_humanin_summary.tsv  # Tab-delimited format for R / Python
    ├── cohort_unique_peptides.fasta # Non-redundant unique peptide variants
    └── COHORT_ANALYSIS_REPORT.md   # Executive Markdown summary report
```

---

## Key Columns in Prediction Tables

| Column | Group | Description |
| :--- | :--- | :--- |
| `sample_id` | Identity | FASTA record accession or header ID. |
| `name` | Identity | Peptide name (`Humanin`, `SHLP1`, `SHLP2`, ..., `SHLP6`). |
| `status` | Identity | Frame status: `Complete`, `Incomplete`, `Interrupted`, or `Absent`. |
| `seq` | Identity | Deduced peptide amino acid sequence. |
| `length` | Identity | Length of the peptide in amino acids. |
| `strand` | Location | `+` (forward strand) or `-` (reverse strand). |
| `circular_wrap` | Location | `True` if the open reading frame crosses the circular origin. |
| `synteny_score` | MT-RNR2 Locus| Profile HMM bitscore for the 16S rRNA syntenic alignment. |
| `hmm_bitscore` | Domain | Bitscore against the Humanin domain profile (PF15040). |
| `evidence_source`| Evidence | Evidence type supporting the frame (`Synteny`, `HMM`, or `Synteny+HMM`). |
| `evidence_tier` | Evidence | Reliability tier (`E1` = in silico homologous position conserved). |

---

## Downstream Applications

1. **Multiple Sequence Alignment (MSA):** Load `cohort_unique_peptides.fasta` into Clustal Omega, MAFFT, or MUSCLE to evaluate amino acid substitution frequencies.
2. **Somatic Variant Screening:** Compare paired tumor vs. normal records in `cohort_humanin_summary.csv` to identify acquired non-synonymous mutations.
3. **Structural Modeling:** Use predicted peptide sequences as input for AlphaFold3, ESMFold, or Rosetta to model peptide:receptor docking against BAX or FPRL1.
