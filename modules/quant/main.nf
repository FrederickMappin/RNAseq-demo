
process QUANT {
    tag "${project_id}/${sample_id}"
    cpus   2
    memory '4 GB'
    time   '30m'
    errorStrategy 'retry'
    maxRetries 2
    publishDir "${params.outdir}/${project_id}/${sample_id}/quant", mode: 'copy'

    input:
    tuple val(project_id), val(sample_id), path(fastq_1), path(fastq_2)
    path index

    output:
    path "quant_${sample_id}"

    script:
    """
    salmon quant --threads ${task.cpus} --libType=U -i ${index} -1 ${fastq_1} -2 ${fastq_2} -o quant_${sample_id}
    """
}
