#!/bin/bash -ue
mkdir fastqc_0001_logs
fastqc -o fastqc_0001_logs -f fastq -q ggal_gut_1.fq ggal_gut_2.fq
