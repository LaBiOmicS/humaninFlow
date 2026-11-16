#!/usr/bin/env python3
import sys, os, csv, argparse
from collections import Counter

def main():
    parser = argparse.ArgumentParser(description="Summarize HumaninFinder Cohort Results for Snakemake")
    parser.add_argument("--results-csv", required=True, help="Path to HumaninFinder results.csv")
    parser.add_argument("--results-fasta", required=True, help="Path to HumaninFinder results.fasta")
    parser.add_argument("--metadata", default=None, help="Path to sample metadata CSV/TSV")
    parser.add_argument("--out-csv", required=True, help="Output merged CSV path")
    parser.add_argument("--out-tsv", required=True, help="Output merged TSV path")
    parser.add_argument("--out-peptides", required=True, help="Output unique peptides FASTA")
    parser.add_argument("--out-report", required=True, help="Output Markdown report path")
    args = parser.parse_args()

    # 1. Parse prediction CSV
    pred_rows = []
    with open(args.results_csv) as f:
        reader = csv.DictReader(f)
        pred_fieldnames = reader.fieldnames or []
        for row in reader:
            pred_rows.append(row)

    print(f"Total predictions loaded: {len(pred_rows)}")

    # 2. Parse metadata if supplied
    meta_dict = {}
    if args.metadata and os.path.exists(args.metadata):
        delim = '\t' if args.metadata.endswith('.tsv') else ','
        with open(args.metadata) as f:
            m_reader = csv.DictReader(f, delimiter=delim)
            for r in m_reader:
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
    os.makedirs(os.path.dirname(os.path.abspath(args.out_csv)), exist_ok=True)
    with open(args.out_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=merged_keys)
        writer.writeheader()
        writer.writerows(merged_rows)

    with open(args.out_tsv, "w") as f:
        f.write("\t".join(merged_keys) + "\n")
        for r in merged_rows:
            f.write("\t".join(str(r.get(k, '')) for k in merged_keys) + "\n")

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

    with open(args.out_peptides, "w") as f:
        for (pname, seq), count in peptides.most_common():
            sample_sample = pep_to_samples[(pname, seq)][:3]
            f.write(f">{pname}_variant_count_{count}|len_{len(seq)}|samples_{','.join(sample_sample)}\n{seq}\n")

    # 5. Generate Markdown Report
    status_counts = Counter(r.get('status') for r in pred_rows)
    names_counts = Counter(r.get('name') for r in pred_rows)
    humanin_statuses = Counter(r.get('status') for r in pred_rows if r.get('name') == 'Humanin')

    report_lines = [
        "# Relatório Analítico Consolidado: HumaninFinder Pipeline (Snakemake)",
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
    with open(args.out_report, "w") as f:
        f.write("\n".join(report_lines) + "\n")

    print(f"Report saved to: {args.out_report}")

if __name__ == "__main__":
    main()
