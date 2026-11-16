# Frequently Asked Questions (FAQ)

### Can I run humaninFlow on fragmented contigs or WGS assemblies?
Yes. When running on draft assemblies or nuclear chromosomes, set `--circular false` and consider using `--command scan` to locate both intact mitochondrial copies and nuclear mitochondrial insertions (NUMTs).

### How do I know which genetic code table to choose?
* For vertebrate mitogenomes: use `--table 2` (or default `auto`).
* For invertebrate mitogenomes: use `--table 5`.
* For nuclear genomes (including NUMTs): use `--table 1`.
* To evaluate both mitochondrial and cytosolic readings simultaneously: use `--table 2,1`.

### Can I run Nextflow and Snakemake on the same machine?
Yes. Both engines write to independent output directories by default (`results/nextflow` and `results/snakemake`), allowing you to benchmark or validate results side by side.

### Does humaninFlow claim that predicted peptides are functional proteins?
No. All annotations are **in silico homology predictions** (Evidence Tier E1). Validation of transcription, translation, or exogenous biological activity requires experimental assays (RNA-seq, mass spectrometry, or functional cell assays).
