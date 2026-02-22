process MULTIQC {
    cpus   1
    memory '2 GB'
    time   '15m'
    errorStrategy 'retry'
    maxRetries 2
    publishDir "${params.outdir}/${project_id}/multiqc", mode: 'copy'

    input:
    path '*'
    path config
    val project_id

    output:
    path 'multiqc_report.html'

    script:
    """
    cp ${config}/* .
    echo "custom_logo: \$PWD/nextflow_logo.png" >> multiqc_config.yaml
    multiqc -n multiqc_report.html .
    """
}
