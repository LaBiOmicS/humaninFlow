#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
   humaninFlow · Nextflow DSL2 implementation
   Data-agnostic discovery of Humanin and SHLP1-6 with HumaninFinder
   Laboratory of Bioinformatics and Omics Sciences (LaBiOmicS)
========================================================================================
*/

def helpMessage() {
    log.info """
    =======================================================================
     humaninFlow · Nextflow pipeline (HumaninFinder 1.0.0b4)
    =======================================================================
     Usage:
       nextflow run workflow/nextflow/main.nf --input <fasta|glob> [options]

     Inputs:
       --input             FASTA file or quoted glob ("cohort/*.fasta"); plain or .gz
       --metadata          CSV/TSV with an accession, isolate, sample_id or id column
       --outdir            Output directory (default: results/nextflow)

     HumaninFinder options:
       --command           'predict' (best frame per table) or 'scan' (all non-redundant)
       --table             NCBI genetic code: 'auto' (default), '2', '2,1', ...
       --circular          Treat records <= 50 kb as circular (default: true)
       --all_candidates    Every non-redundant candidate with 'predict' (default: false)
       --no_hmm            Skip the PF15040 HMM domain search
       --no_rescue         Skip HMM-guided frame rescue
       --no_shlp           Skip SHLP1-6 annotation
       --no_synteny        Skip the MT-RNR2 synteny search

     Profiles: local, conda, docker, singularity, apptainer, slurm
    =======================================================================
    """.stripIndent()
}

process HUMANIN_LINT {
    tag "${fasta.name}"
    label 'process_low'

    input:
    path fasta

    output:
    path fasta, emit: validated_fasta

    script:
    """
    humanin-finder lint "${fasta}"
    """
}

process HUMANIN_RUN {
    tag "${fasta.name}"
    label 'process_medium'
    publishDir "${params.outdir}/raw_predictions", mode: 'copy'

    input:
    path fasta

    output:
    path "*_results.csv",   emit: csv
    path "*_results.fasta", emit: fasta
    path "*_results.gff3",  emit: gff3
    path "*_results.bed",   emit: bed
    path "*_run.json",      emit: json
    path "*_gaps.csv",      emit: gaps, optional: true

    script:
    def prefix = fasta.name.replaceAll(/\.(fa|fasta|fna|fas)(\.gz)?$/, '')
    def args = []
    if (params.table)                                       args << "-g ${params.table}"
    if (params.circular)                                    args << '--circular'
    if (params.all_candidates && params.command == 'predict') args << '--all-candidates'
    if (params.no_hmm)                                      args << '--no-hmm'
    if (params.no_rescue)                                   args << '--no-rescue'
    if (params.no_shlp)                                     args << '--no-shlp'
    if (params.no_synteny)                                  args << '--no-synteny'
    """
    humanin-finder ${params.command} \\
        -i "${fasta}" \\
        -o "${prefix}" \\
        ${args.join(' ')}
    """
}

process SUMMARIZE_COHORT {
    tag "cohort"
    label 'process_low'
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    path results_csv
    path metadata_file
    path summarize_script

    output:
    path "cohort_humanin_summary.csv",   emit: summary_csv
    path "cohort_humanin_summary.tsv",   emit: summary_tsv
    path "cohort_unique_peptides.fasta", emit: unique_peptides
    path "COHORT_ANALYSIS_REPORT.md",    emit: report

    script:
    def meta_arg = metadata_file ? "--metadata '${metadata_file}'" : ''
    """
    python3 ${summarize_script} \\
        --results-csv ${results_csv} \\
        ${meta_arg} \\
        --out-csv cohort_humanin_summary.csv \\
        --out-tsv cohort_humanin_summary.tsv \\
        --out-peptides cohort_unique_peptides.fasta \\
        --out-report COHORT_ANALYSIS_REPORT.md
    """
}

workflow {
    if (params.help) {
        helpMessage()
        exit(0)
    }
    if (!params.input) {
        error "Missing mandatory argument: --input <fasta or glob>"
    }
    if (!(params.command in ['predict', 'scan'])) {
        error "--command must be 'predict' or 'scan' (got '${params.command}')"
    }

    fasta_ch  = channel.fromPath(params.input, checkIfExists: true)
    meta_file = params.metadata ? file(params.metadata, checkIfExists: true) : []
    script    = file("${projectDir}/../scripts/merge_and_report.py", checkIfExists: true)

    HUMANIN_LINT(fasta_ch)
    HUMANIN_RUN(HUMANIN_LINT.out.validated_fasta)

    // One summary for the whole cohort, however many FASTA files went in.
    SUMMARIZE_COHORT(HUMANIN_RUN.out.csv.collect(), meta_file, script)
}
