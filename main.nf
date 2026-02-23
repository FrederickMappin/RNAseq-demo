#!/usr/bin/env nextflow
/*
========================================================================================
                    RNAseq-NF PIPELINE - AN RNA-SEQ QUANTIFICATION PIPELINE
========================================================================================
 RNAseq-NF Pipeline Started 2026-02-21.
 #### Homepage / Documentation
 https://github.com/FrederickMappin/rnaseq-nf
 #### Contributors
 Paolo Di Tommaso 
 Freddy Mappin 
========================================================================================
========================================================================================

Pipeline steps:

    1. Index
       - Build a salmon index from the provided transcriptome FASTA file

    2. FastQC
       - Run quality control on each pair of FASTQ files
       - Output: per-sample FastQC reports

    3. Quant
       - Quantify transcript expression with salmon
       - Output: per-sample quant directories

    4. MultiQC
       - Aggregate FastQC and salmon QC results into a single HTML report
       - Output: multiqc_report.html in the project output folder

*/

def helpMessage() {
    log.info"""
========================================================================================
                    RNAseq-NF PIPELINE - Help Message
========================================================================================

  Version  : 1.5.1
  Docs     : https://github.com/FrederickMappin/rnaseq-nf

Usage:
  nextflow run main.nf -profile <local_test|batch_test> [options]

========================================================================================

Profiles:

  local_test     Run locally using Docker (rnaseq-nf:1.5.2).
            All params default to local project paths — no extra args needed.

            nextflow run main.nf -profile local_test

  batch_test     Run on AWS Batch using the ECR image.
            All params default to the configured S3 paths — no extra args needed.

            nextflow run main.nf -profile batch_test

========================================================================================

Parameters (all have profile defaults — only override if needed):

    --input           Path to samplesheet CSV file.
                      Columns: sample_id, project_id, fastq_1, fastq_2

    --transcriptome   Path to the transcriptome FASTA file for salmon indexing

    --outdir          Directory where results will be saved

    --multiqc         Path to MultiQC config directory

========================================================================================

Override examples:

  # Local run with a different samplesheet
  nextflow run main.nf -profile local_test \\
      --input path/to/my_samplesheet.csv

  # Batch run with a custom transcriptome
  nextflow run main.nf -profile batch_test \\
      --transcriptome s3://my-bucket/refs/transcriptome.fa

========================================================================================

Outputs (written to --outdir/{project_id}/):

  {sample_id}/fastqc/       FastQC reports per sample
  {sample_id}/quant/        Salmon quantification per sample
  multiqc/                  Aggregated MultiQC report
  report.html               Nextflow execution report
  pipeline_provenance.bco.json  BCO provenance record
  .nextflow.log             Pipeline run log

========================================================================================
    """.stripIndent()
}

// Show help message (default defined in nextflow.config)
if (params.help) {
    helpMessage()
    exit 0
}

// import plugins
include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

// import modules
include { RNASEQ } from './modules/rnaseq'
include { MULTIQC } from './modules/multiqc'

/*
========================================================================================
    WORKFLOW
========================================================================================
*/
workflow {

    // validate pipeline parameters against nextflow_schema.json
    validateParameters()

    log.info paramsSummaryLog(workflow)

    // parse and validate samplesheet, emit [project_id, sample_id, fastq_1, fastq_2] tuples
    read_pairs_ch = channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map { meta, fastq_1, fastq_2 -> tuple(meta.project_id, meta.id, fastq_1, fastq_2) }

    // read project_id synchronously from samplesheet so it is reliably available in onComplete
    def _lines   = file(params.input).readLines()
    def _headers = _lines[0].split(',')*.trim()
    def _pidIdx  = _headers.indexOf('project_id')
    def projectId = _lines[1].split(',')[_pidIdx].trim()

    project_id_ch = read_pairs_ch.map { project_id, sample_id, f1, f2 -> project_id }.first()

    (fastqc_ch, quant_ch) = RNASEQ(read_pairs_ch, params.transcriptome)

    multiqc_files_ch = fastqc_ch.mix(quant_ch).collect()

    MULTIQC(multiqc_files_ch, params.multiqc, project_id_ch)

    workflow.onComplete = {
        log.info(
            workflow.success
                ? "\nDone! Open the following report in your browser --> ${params.outdir}/multiqc_report.html\n"
                : "Oops .. something went wrong"
        )

        try {
            def pid    = projectId ?: 'unknown'
            def outdir = params.outdir.toString().replaceAll('/+$', '')
            def projectOutDir = "${outdir}/${pid}"

            // copy the nextflow log into the project output folder
            try {
                def logSrc  = file("${workflow.launchDir}/.nextflow.log")
                def logDest = file("${projectOutDir}/.nextflow.log")
                if (logSrc.exists()) {
                    logDest.parent.mkdirs()
                    logSrc.copyTo(logDest)
                    log.info("Copied log --> ${logDest}")
                }
            } catch (Exception e) {
                log.warn("Could not copy log file: ${e.message}")
            }

            // move provenance and report in a shutdown hook so nf-prov has finished writing first
            try {
                Runtime.runtime.addShutdownHook(new Thread({

                    try {
                        def provSrc  = file("${workflow.launchDir}/pipeline_provenance.bco.json")
                        def provDest = "${projectOutDir}/pipeline_provenance.bco.json"
                        if (provSrc.exists()) {
                            def proc = ["aws", "s3", "cp", provSrc.toString(), provDest].execute()
                            proc.waitFor()
                            if (proc.exitValue() == 0) {
                                provSrc.delete()
                                log.info("Moved provenance --> ${provDest}")
                            } else {
                                log.warn("Could not move provenance file: ${proc.err.text}")
                            }
                        } else {
                            log.warn("Provenance file not found at: ${provSrc}")
                        }
                    } catch (Exception e) {
                        log.warn("Could not move provenance file: ${e.message}")
                    }

                    try {
                        def reportSrc  = file("${workflow.launchDir}/report.html")
                        def reportDest = "${projectOutDir}/report.html"
                        if (reportSrc.exists()) {
                            def proc = ["aws", "s3", "cp", reportSrc.toString(), reportDest].execute()
                            proc.waitFor()
                            if (proc.exitValue() == 0) {
                                reportSrc.delete()
                                log.info("Moved report --> ${reportDest}")
                            } else {
                                log.warn("Could not move report file: ${proc.err.text}")
                            }
                        } else {
                            log.warn("Report file not found at: ${reportSrc}")
                        }
                    } catch (Exception e) {
                        log.warn("Could not move report file: ${e.message}")
                    }

                } as Runnable))
            } catch (IllegalStateException e) {
                log.warn("Could not register shutdown hook for file cleanup: ${e.message}")
            }

        } catch (Exception e) {
            log.warn("onComplete handler error: ${e.message}")
        }
    }
}
