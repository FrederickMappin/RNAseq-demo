#!/bin/bash -ue
mkdir fastqc_0004_logs
fastqc -o fastqc_0004_logs -f fastq -q ggal_spleen_1.fq ggal_spleen_2.fq
