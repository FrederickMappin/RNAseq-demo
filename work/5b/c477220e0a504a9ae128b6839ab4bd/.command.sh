#!/bin/bash -ue
salmon quant --threads 2 --libType=U -i index -1 ggal_spleen_1.fq -2 ggal_spleen_2.fq -o quant_0004
