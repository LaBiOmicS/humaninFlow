#!/usr/bin/env python3
"""Merge HumaninFinder predictions with sample metadata and write the cohort summary.

Shared by the Nextflow (SUMMARIZE_COHORT) and Snakemake (summarize) implementations so both
engines produce identical summary files from the same predictions.

Only the Python standard library is used, so the script runs in any environment that has
python3, including the HumaninFinder container.
"""
import argparse
import csv
import os
from collections import Counter, defaultdict

META_KEYS = ("accession", "isolate", "sample_id", "id")


def read_predictions(paths):
    """Concatenate one or more HumaninFinder *_results.csv files (same schema)."""
    rows, fieldnames = [], []
    for path in paths:
        with open(path, newline="") as fh:
            reader = csv.DictReader(fh)
            for name in reader.fieldnames or []:
                if name not in fieldnames:
                    fieldnames.append(name)
            rows.extend(reader)
    return rows, fieldnames


def read_metadata(path):
    """Index metadata rows by every identifier column, with and without the version suffix.

    The first row seen for a key wins, so a later isolate name can never overwrite an accession.
    """
    index, columns = {}, []
    if not path:
        return index, columns
    if not os.path.exists(path):
        raise SystemExit(f"ERROR: metadata file not found: {path}")
    delim = "\t" if path.endswith((".tsv", ".tab", ".txt")) else ","
    with open(path, newline="") as fh:
        reader = csv.DictReader(fh, delimiter=delim)
        columns = list(reader.fieldnames or [])
        for row in reader:
            for key in META_KEYS:
                value = (row.get(key) or "").strip()
                if value:
                    index.setdefault(value, row)
                    index.setdefault(value.split(".")[0], row)
    return index, columns


def sample_key(sample_id):
    parts = (sample_id or "").split()
    return parts[0] if parts else ""


def pct(n, total):
    return f"{100 * n / total:.1f}%" if total else "n/a"


def by_count(counter):
    return sorted(counter.items(), key=lambda kv: (-kv[1], str(kv[0])))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--results-csv", required=True, nargs="+", help="HumaninFinder *_results.csv file(s)")
    ap.add_argument("--results-fasta", nargs="*", default=[], help="Accepted for backward compatibility; unused")
    ap.add_argument("--metadata", default=None, help="Sample metadata CSV/TSV (optional)")
    ap.add_argument("--out-csv", required=True)
    ap.add_argument("--out-tsv", required=True)
    ap.add_argument("--out-peptides", required=True)
    ap.add_argument("--out-report", required=True)
    args = ap.parse_args()

    pred_rows, pred_fields = read_predictions(sorted(args.results_csv))
    meta_index, meta_cols = read_metadata(args.metadata)
    extra_cols = [c for c in meta_cols if c not in pred_fields]
    merged_fields = pred_fields + extra_cols

    matched = 0
    merged = []
    for row in pred_rows:
        sid = sample_key(row.get("sample_id"))
        meta = meta_index.get(sid) or meta_index.get(sid.split(".")[0])
        matched += meta is not None
        out = dict(row)
        for col in extra_cols:
            out[col] = (meta or {}).get(col, "N/A")
        merged.append(out)

    for path in (args.out_csv, args.out_tsv, args.out_peptides, args.out_report):
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

    with open(args.out_csv, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=merged_fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(merged)
    with open(args.out_tsv, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=merged_fields, delimiter="\t",
                                extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        writer.writerows(merged)

    # Unique peptide alleles, ranked by frequency (ties broken by name, then sequence).
    counts = Counter()
    samples = defaultdict(list)
    for row in pred_rows:
        seq = (row.get("seq") or "").strip()
        if not seq:
            continue
        key = (row.get("name") or "Peptide", seq)
        counts[key] += 1
        samples[key].append(sample_key(row.get("sample_id")))
    ranked = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0][0], kv[0][1]))

    with open(args.out_peptides, "w") as fh:
        for (name, seq), n in ranked:
            fh.write(f">{name}_variant_count_{n}|len_{len(seq)}|samples_{','.join(samples[(name, seq)][:3])}\n{seq}\n")

    total = len(pred_rows)
    n_samples = len({sample_key(r.get("sample_id")) for r in pred_rows})
    by_name = Counter(r.get("name") for r in pred_rows)
    by_status = Counter(r.get("status") for r in pred_rows)
    hn_status = Counter(r.get("status") for r in pred_rows if r.get("name") == "Humanin")
    hn_total = sum(hn_status.values())

    lines = [
        "# Relatório Analítico Consolidado: HumaninFinder Cohort",
        "",
        "## 1. Visão Geral das Predições",
        f"- **Total de predições geradas:** {total}",
        f"- **Sequências com ao menos uma predição:** {n_samples}",
        (f"- **Predições pareadas com metadados:** {matched} ({pct(matched, total)})"
         if args.metadata else "- **Metadados:** não fornecidos"),
        "- **Distribuição por peptídeo:**",
    ]
    lines += [f"  - `{k}`: {v} registros" for k, v in by_count(by_name)]
    lines += ["", "## 2. Status dos Peptídeos Preditos", "- **Status geral:**"]
    lines += [f"  - `{k}`: {v} ({pct(v, total)})" for k, v in by_count(by_status)]
    lines += ["", "## 3. Humanina Específica", f"- **Total de amostras avaliadas para Humanin:** {hn_total}"]
    lines += [f"  - `{k}`: {v} ({pct(v, hn_total)})" for k, v in by_count(hn_status)]
    lines += [
        "",
        "## 4. Diversidade Peptídica (Variantes de Humanina)",
        "| Peptídeo | Sequência | Comprimento | Frequência (N) | Amostras (Exemplo) |",
        "| :--- | :--- | :---: | :---: | :--- |",
    ]
    lines += [
        f"| {name} | `{seq}` | {len(seq)} aa | {n} | {', '.join(samples[(name, seq)][:2])} |"
        for (name, seq), n in ranked if name == "Humanin"
    ]
    with open(args.out_report, "w") as fh:
        fh.write("\n".join(lines) + "\n")

    print(f"{total} prediction rows, {n_samples} sequences, {matched} matched to metadata -> {args.out_csv}")


if __name__ == "__main__":
    main()
