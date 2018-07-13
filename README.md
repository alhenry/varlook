# varlook
---
a tool for genetic variants lookup

### Description
varlook is a simple tool written in bash for extracting genetic variant(s) information from a dataset. Originally, the script was written to extract summary statistics for given variant IDs from publicly available GWAS results, but this tool can also potentially be used to extract variant information, e.g. from .vcf or .bgen files.

### Dependencies
varlook was built on a Linux machine (Red Hat Enterprise Linux Server 7.4) using several commands like GNU sed (4.2.2) and GNU awk (4.0.2). While these tools are commonly found in Unix or Unix-like OS, their behaviour can vary slightly across different versions and OSs, which might lead to bugs / errors.

### Installation
1. Download the raw `varlook.sh` file from https://github.com/alhenry/varlook/raw/master/varlook.sh, e.g. by typing the following in a Unix shell:

    `wget https://github.com/alhenry/varlook/raw/master/varlook.sh`
    
2. Make the script executable:
    
    `chmod +x varlook.sh`
    
3. [OPTIONAL] move to 
