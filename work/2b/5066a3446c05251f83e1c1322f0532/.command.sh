#!/bin/bash -ue
mkdir fastqc_0002_logs
fastqc -o fastqc_0002_logs -f fastq -q ggal_liver_1.fq ggal_liver_2.fq
