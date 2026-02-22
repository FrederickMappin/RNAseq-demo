#!/bin/bash -ue
mkdir fastqc_0003_logs
fastqc -o fastqc_0003_logs -f fastq -q ggal_lung_1.fq ggal_lung_2.fq
