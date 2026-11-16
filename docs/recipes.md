# Recipes & Practical Use Cases

**humaninFlow** is completely data-agnostic. Below are production recipes for standard workflows in evolutionary genomics, comparative oncology, and NUMT screening.

---

## 1. Vertebrate Population Mitogenomics

When analyzing dozens or hundreds of complete circular mitogenomes from a cohort (e.g. canine, feline, primate, or rodent populations):

### Nextflow Command
```bash
nextflow run workflow/nextflow/main.nf \
  --input data/cohort_mitogenomes.fasta \
  --metadata data/cohort_metadata.csv \
  --outdir results/population_run \
  --table 2 \
  --circular
```

### Snakemake Command
```bash
snakemake \
  --snakefile workflow/snakemake/Snakefile \
  --config input_fasta=data/cohort_mitogenomes.fasta \
           metadata=data/cohort_metadata.csv \
           outdir=results/population_run \
           table=2 \
           circular=True \
  --cores 8
```

---

## 2. Scanning Whole Nuclear Genomes for NUMTs

Nuclear Mitochondrial DNA insertions (NUMTs) represent ancient transpositions of *MT-RNR2* into the nuclear genome. Because NUMTs reside in chromosomes and are translated by cytosolic ribosomes, they should be evaluated under **NCBI Table 1** (Standard Code) without circular wrap:

### Nextflow Command
```bash
nextflow run workflow/nextflow/main.nf \
  --input data/nuclear_assembly.fasta.gz \
  --command scan \
  --table 1 \
  --circular false \
  --outdir results/nuclear_numts
```

---

## 3. Simultaneous Mitochondrial and Cytosolic Translation

To test whether mitochondrial sORFs could potentially produce an alternative peptide if exported and read by cytosolic ribosomes:

```bash
nextflow run workflow/nextflow/main.nf \
  --input data/mitogenomes.fasta \
  --table "2,1" \
  --circular \
  --outdir results/dual_reading
```

---

## 4. Non-Vertebrate Metazoan Mitogenomes

Invertebrates (e.g., *Drosophila*, molluscs, nematodes) utilize alternative mitochondrial codes:
* **Invertebrate Mitochondrial Code (Table 5):**
  ```bash
  nextflow run workflow/nextflow/main.nf \
    --input data/drosophila_mitogenomes.fasta \
    --table 5 \
    --circular \
    --outdir results/invertebrates
  ```
* **Echinoderm / Flatworm Mitochondrial Code (Table 9):**
  ```bash
  nextflow run workflow/nextflow/main.nf \
    --input data/echinoderm_mitogenomes.fasta \
    --table 9 \
    --circular \
    --outdir results/echinoderms
  ```

---

## 5. High-Throughput Cluster Execution (SLURM)

To dispatch execution across an institutional SLURM cluster with automated container management:

```bash
nextflow run workflow/nextflow/main.nf \
  -profile apptainer \
  --input /shared/data/huge_cohort.fasta \
  --metadata /shared/data/metadata.tsv \
  --outdir /shared/results/humanin_slurm \
  -process.executor slurm \
  -process.queue batch \
  -process.cpus 8 \
  -process.memory 16.GB
```
