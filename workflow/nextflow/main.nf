#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
   HumaninFinder Pipeline (Nextflow DSL2)
   Scalable, Data-Agnostic Discovery of Humanin and SHLPs across Mitogenomes & Contigs
========================================================================================
*/

def helpMessage() {
    log.info """
    =======================================================================
     HumaninFinder Nextflow Pipeline (v1.0.0b4)
    =======================================================================
     Usage:
       nextflow run main.nf [options]

     Mandatory Arguments:
       --input             Path to FASTA file (plain or .gz)
       --outdir            Output directory for results (default: results)

     Optional Arguments:
       --metadata          Path to CSV/TSV sample metadata (to merge with predictions)
       --command           'predict' (default, best frame) or 'scan' (all non-redundant)
       --table             NCBI genetic code ('auto', '2', '2,1', etc. Default: 'auto')
       --circular          Treat records <= 50kb as circular (default: true)
       --all_candidates    Report every non-redundant candidate for 'predict' (default: false)
       --no_hmm            Skip PF15040 HMM domain search (default: false)
       --no_rescue         Skip HMM-guided frame rescue (default: false)
       --no_shlp           Skip SHLP1-6 annotation (default: false)
       --no_synteny        Skip MT-RNR2 synteny search (default: false)
       --help              Display this help message
    =======================================================================
    """.stripIndent()
}

if (params.help) {
    helpMessage()
    exit 0
}

// Validation of input
if (!params.input) {
    exit 1, "ERROR: Missing mandatory argument: --input <path_to_fasta>"
}

fasta_ch = Channel.fromPath(params.input, checkIfExists: true)
meta_ch  = params.metadata ? Channel.fromPath(params.metadata, checkIfExists: true) : Channel.empty()

process HUMANIN_LINT {
    tag "lint_${fasta.name}"
    label 'process_low'

    input:
    path fasta

    output:
    path fasta, emit: validated_fasta

    script:
    """
    echo "=== Running HumaninFinder Lint ==="
    humanin-finder lint "${fasta}"
    """
}

process HUMANIN_RUN {
    tag "${fasta.baseName}"
    label 'process_medium'
    publishDir "${params.outdir}/raw_predictions", mode: 'copy'

    input:
    path fasta

    output:
    path "${prefix}_results.csv",   emit: csv
    path "${prefix}_results.fasta", emit: fasta
    path "${prefix}_results.gff3",  emit: gff3
    path "${prefix}_results.bed",   emit: bed
    path "${prefix}_run.json",      emit: json
    path "${prefix}_gaps.csv",      emit: gaps, optional: true

    script:
    prefix = fasta.baseName.replaceAll(/\\.(fa|fasta|fna)/, "")
    def cmd_args = []
    
    // Genetic code
    if (params.table) {
        cmd_args << "-g ${params.table}"
    }
    // Circular
    if (params.circular) {
        cmd_args << "--circular"
    }
    // All candidates
    if (params.all_candidates && params.command == 'predict') {
        cmd_args << "--all-candidates"
    }
    if (params.no_hmm)     cmd_args << "--no-hmm"
    if (params.no_rescue)  cmd_args << "--no-rescue"
    if (params.no_shlp)    cmd_args << "--no-shlp"
    if (params.no_synteny) cmd_args << "--no-synteny"

    """
    humanin-finder ${params.command} \\
        -i "${fasta}" \\
        -o "${prefix}" \\
        ${cmd_args.join(' ')}
    """
}

process SUMMARIZE_COHORT {
    tag "cohort_summary"
    label 'process_low'
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    path results_csv
    path results_fasta
    path metadata_file

    output:
    path "cohort_humanin_summary.csv",   emit: summary_csv
    path "cohort_humanin_summary.tsv",   emit: summary_tsv
    path "cohort_unique_peptides.fasta", emit: unique_peptides
    path "COHORT_ANALYSIS_REPORT.md",    emit: report

    script:
    def meta_arg = metadata_file ? "--metadata ${metadata_file}" : ""
    """
    cat << 'EOF' > summarize.py
import sys, os, csv, argparse
from collections import Counter

parser = argparse.ArgumentParser(description="Summarize HumaninFinder Cohort Results")
parser.add_argument("--results-csv", required=True)
parser.add_argument("--results-fasta", required=True)
parser.add_argument("--metadata", default=None)
args = parser.parse_args()

# 1. Parse prediction CSV
pred_rows = []
with open(args.results_csv) as f:
    reader = csv.DictReader(f)
    pred_fieldnames = reader.fieldnames
    for row in reader:
        pred_rows.append(row)

print(f"Total predictions loaded: {len(pred_rows)}")

# 2. Parse metadata if supplied
meta_dict = {}
if args.metadata and os.path.exists(args.metadata):
    delim = '\\t' if args.metadata.endswith('.tsv') else ','
    with open(args.metadata) as f:
        m_reader = csv.DictReader(f, delimiter=delim)
        for r in m_reader:
            # Try accession or isolate as key
            for k in ['accession', 'isolate', 'sample_id', 'id']:
                if k in r and r[k]:
                    clean_k = r[k].split('.')[0]
                    meta_dict[clean_k] = r
                    meta_dict[r[k]] = r

print(f"Total metadata records mapped: {len(meta_dict)}")

# 3. Merge predictions with metadata
merged_rows = []
all_meta_keys = list(next(iter(meta_dict.values())).keys()) if meta_dict else []
merged_keys = pred_fieldnames + [k for k in all_meta_keys if k not in pred_fieldnames]

for row in pred_rows:
    sample_id = row.get('sample_id', '')
    clean_id = sample_id.split()[0].split('.')[0]
    matched_meta = meta_dict.get(sample_id, meta_dict.get(clean_id, {}))
    
    m_row = dict(row)
    for mk in all_meta_keys:
        if mk not in m_row:
            m_row[mk] = matched_meta.get(mk, 'N/A')
    merged_rows.append(m_row)

# Save merged CSV & TSV
with open("cohort_humanin_summary.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=merged_keys)
    writer.writeheader()
    writer.writerows(merged_rows)

with open("cohort_humanin_summary.tsv", "w") as f:
    f.write("\\t".join(merged_keys) + "\\n")
    for r in merged_rows:
        f.write("\\t".join(str(r.get(k, '')) for k in merged_keys) + "\\n")

# 4. Extract unique peptide sequences
peptides = Counter()
pep_to_samples = {}
for r in pred_rows:
    seq = r.get('seq', '').strip()
    pname = r.get('name', 'Peptide')
    sid = r.get('sample_id', '')
    if seq:
        key = (pname, seq)
        peptides[key] += 1
        if key not in pep_to_samples:
            pep_to_samples[key] = []
        pep_to_samples[key].append(sid)

with open("cohort_unique_peptides.fasta", "w") as f:
    for (pname, seq), count in peptides.most_common():
        sample_sample = pep_to_samples[(pname, seq)][:3]
        f.write(f">{pname}_variant_count_{count}|len_{len(seq)}|samples_{','.join(sample_sample)}\\n{seq}\\n")

# 5. Generate Markdown Report
status_counts = Counter(r.get('status') for r in pred_rows)
names_counts = Counter(r.get('name') for r in pred_rows)
humanin_statuses = Counter(r.get('status') for r in pred_rows if r.get('name') == 'Humanin')

report_lines = [
    "# Relatório Analítico Consolidado: HumaninFinder Cohort",
    "",
    "## 1. Visão Geral das Predições",
    f"- **Total de predições geradas:** {len(pred_rows)}",
    f"- **Distribuição por peptídeo:**",
]
for p, c in names_counts.most_common():
    report_lines.append(f"  - `{p}`: {c} registros")

report_lines.extend([
    "",
    "## 2. Status dos Peptídeos Preditos",
    f"- **Status geral:**"
])
for s, c in status_counts.most_common():
    report_lines.append(f"  - `{s}`: {c} ({round(c/len(pred_rows)*100, 1)}%)")

report_lines.extend([
    "",
    "## 3. Humanina Específica",
    f"- **Total de amostras avaliadas para Humanin:** {sum(humanin_statuses.values())}",
])
for s, c in humanin_statuses.most_common():
    report_lines.append(f"  - `{s}`: {c} ({round(c/sum(humanin_statuses.values())*100, 1)}%)")

report_lines.extend([
    "",
    "## 4. Diversidade Peptídica (Top Variantes de Humanina)",
    "| Peptídeo | Sequência | Comprimento | Frequência (N) | Amostras (Exemplo) |",
    "| :--- | :--- | :---: | :---: | :--- |"
])

for (pname, seq), count in peptides.most_common():
    if pname == 'Humanin':
        samples = ", ".join(pep_to_samples[(pname, seq)][:2])
        report_lines.append(f"| {pname} | `{seq}` | {len(seq)} aa | {count} | {samples} |")

report_lines.append("")
with open("COHORT_ANALYSIS_REPORT.md", "w") as f:
    f.write("\\n".join(report_lines) + "\\n")

print("Summary & report successfully generated!")
EOF

    python3 summarize.py \\
        --results-csv "${results_csv}" \\
        --results-fasta "${results_fasta}" \\
        ${meta_arg}
    """
}

workflow {
    // 1. Lint the input FASTA
    HUMANIN_LINT(fasta_ch)

    // 2. Run HumaninFinder
    HUMANIN_RUN(HUMANIN_LINT.out.validated_fasta)

    // 3. Summarize and merge with metadata
    SUMMARIZE_COHORT(
        HUMANIN_RUN.out.csv,
        HUMANIN_RUN.out.fasta,
        meta_ch.ifEmpty([])
    )
}
