#!/bin/bash -ue
cp multiqc/* .
echo "custom_logo: $PWD/nextflow_logo.png" >> multiqc_config.yaml
multiqc -n multiqc_report.html .
