
process INDEX {
    tag "${transcriptome.simpleName}"
    cpus   1
    memory '2 GB'
    time   '30m'
    errorStrategy 'retry'
    maxRetries 2

    input:
    path transcriptome

    output:
    path 'index'

    script:
    """
    salmon index --threads ${task.cpus} -t ${transcriptome} -i index
    """
}
