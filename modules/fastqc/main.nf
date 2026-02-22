process FASTQC {
    tag "${project_id}/${sample_id}"
    cpus   1
    memory '2 GB'
    time   '30m'
    errorStrategy 'retry'
    maxRetries 2
    publishDir "${params.outdir}/${project_id}/${sample_id}/fastqc", mode: 'copy'

    input:
    tuple val(project_id), val(sample_id), path(fastq_1), path(fastq_2)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${fastq_1} ${fastq_2}
    """
}
