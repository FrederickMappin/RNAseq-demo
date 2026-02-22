#!/bin/bash -ue
salmon quant --threads 2 --libType=U -i index -1 ggal_liver_1.fq -2 ggal_liver_2.fq -o quant_0002
