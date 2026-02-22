
# Dockerfile for the RNA-seq pipeline implemented with Nextflow
FROM mambaorg/micromamba:1.5.10-noble

ARG MAMBA_USER=mambauser
ARG VERSION=1.5.1
ENV MAMBA_USER=${MAMBA_USER}

LABEL org.opencontainers.image.title="rnaseq-nf" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.description="RNA-seq pipeline implemented with Nextflow" \
      org.opencontainers.image.source="https://github.com/nextflow-io/rnaseq-nf" \
      org.opencontainers.image.created="2026-02-22"


RUN micromamba install -y -n base \
    bioconda::fastqc=0.12.1 \
    bioconda::multiqc=1.25 \
    bioconda::salmon=1.10.3 \
    conda-forge::procps-ng \
    && micromamba clean -a -y

ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
