# Biological Methodology

## Background: Mitochondrial-Derived Peptides (MDPs)

Mitochondrial-derived peptides (MDPs) represent an unconventional class of bioactive micropeptides encoded by small open reading frames (sORFs) nested within mitochondrial ribosomal RNA genes. 

* **Humanin (HN):** A 21–24 amino acid cytoprotective peptide originally identified as an endogenous neuroprotective factor. Humanin binds directly to pro-apoptotic BCL-2 family proteins (notably **BAX** and **BID**), inhibiting mitochondrial outer membrane permeabilization (MOMP) and apoptosis.
* **Small Humanin-Like Peptides (SHLP1–6):** Six short functional peptides discovered within the same 16S rRNA (*MT-RNR2*) locus that modulate cell survival, metabolic rate, and reactive oxygen species (ROS) production.

---

## The Challenge of Nested sORFs

Ordinary structural gene finders (e.g. Prodigal, GeneMark) consistently fail to annotate MDPs because:
1. They reside within a structural non-coding RNA (**16S rRNA** / *MT-RNR2*).
2. They feature non-canonical translation initiators and alternative genetic codes across clades.
3. Mitochondrial DNA fragments frequently transpose into nuclear chromosomes (**NUMTs**), creating pseudogenized, fragmented copies.

---

## How HumaninFinder Solves It

**humaninFlow** leverages `humanin-finder`'s dual-evidence approach:

```
[ Input Mitogenome ] ──► [ MT-RNR2 Synteny HMM ] ──► Map Precise Homologous Coordinates
                                                         │
[ Read Species Frame ] ◄─────────────────────────────────┘
         │
         ▼
[ Translate with Genetic Code (Table 2 / 1) ]
         │
         ▼
[ HMM Domain Verification (PF15040) ] ──► Report Frame Status & In Silico Evidence Tier
```

1. **Synteny Profile HMMs:** Profiles constructed across diverse vertebrate clades identify the precise position of the *MT-RNR2* gene and locate the homologous sORF window.
2. **Species-Specific Reading:** The reading frame is translated according to the appropriate mitochondrial genetic code (e.g., Table 2 for vertebrates).
3. **PF15040 Domain Search:** Profile hidden Markov models verify domain homology and guide the rescue of interrupted or frameshifted frames.
4. **Circularity Handling:** Sequences marked circular with length $\le 50$ kb are seamlessly read through the origin, resolving assembly cut-site artifacts.
