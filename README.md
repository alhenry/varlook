# varlook
---
a tool for genetic variants lookup and proxy search

### Description
varlook is a simple tool for extracting genetic variant(s) information from a dataset. Originally, the script was written to extract summary statistics for given variant IDs from publicly available GWAS results, but this tool can also potentially be used for other purposes, e.g. extracting genetic variant information from .vcf files.

### Dependencies
varlook was written in *GNU bash, version 4.2.46(2)-release (x86_64-redhat-linux-gnu)* using several commands such as *GNU sed (4.2.2)* and *GNU awk (4.0.2)*. While these tools are commonly found in Unix or Unix-like OS, please be aware that their behaviour can vary slightly across different versions and OSs, which might lead to errors.

*MacOS users are recommended to install GNU sed, for example by typing the following command in a terminal window (requires [Homebrew](https://brew.sh/)):*

`brew install --default-names gnu-sed`

### Installation
1. Download the raw `varlook.sh` file from https://github.com/alhenry/varlook/raw/master/varlook, e.g. by typing the following in a Unix shell (change `/path/to/install` as necessary):

    `wget https://github.com/alhenry/varlook/raw/master/varlook -P ~/path/to/install/`
    
2. Make the script executable:
    
    `chmod +x ~/path/to/install/varlook`
    
3. [OPTIONAL] Export `path/to/install` to `$PATH` variable and add to `~/.bash_profile`:

    `echo 'export PATH="$PATH:~/path/to/install"' >> ~/.bash_profile`
    
4. To run the program, type:

    `. ~/path/to/install/varlook <options> <arguments>`
    
   If step 3 has been done, we can also type:
   
    `varlook <options> <arguments>`
    
### Usage
varlook command has the following structure:

`varlook [-v <variantID> -v <variantID> ... | -f <variantID list file>] -p <r2> -o <output directory> <dataset for lookup>`

* Option `-v <variantID>` specifies a variantID to extract as input. This option can be repeated to extract multiple variants, e.g.: `-v rs4977574 -v rs55730499 -v rs9349379 ...`
* Option `-f <variantID list file>` specifies a file with variantID list as input. Each row of the input file should contain a unique variantID without any trailing whitespace, for example:

```
rs4977574
rs55730499
rs9349379
...
```

* [OPTIONAL] Option `-p <r2>` tells the program to look for best proxy variants in linkage disequilibrium with R2 > `<r2>` using [LDproxy](https://ldlink.nci.nih.gov/?tab=ldproxy) functionality in LDlink, if the queried variantIDs are not found in the dataset. At the moment, this option is limited to use the 1000G phase3v5 European (EUR) population as reference.

* Option `-o <output directory>` specifies the output directory path to write the lookup results. Output directory must be new and writable.
* After specifying all options and arguments, type the filename of the `<dataset for lookup>` at the end of the commmand. To minimise error, it is advised to have the lookup dataset in tab-separated text file format. 

### Terminology
For ease of reference, the term *Input variants* is used to refer genetic variants specified as input. The term *Proxy variants* refers to proxy genetic variants found in LDlink database when option `-p` is used.

### Output
Depending on the options and lookup results, varlook can yield the following output file(s):
1. `Input.vars.lookup.results`: Extracted information for every input variant found in the lookup dataset. By default, this file will have the same header (first line) and columns as the lookup dataset.
2. `Input.vars.not.found`: List of input variantIDs not found in the lookup dataset
3. `Proxy.vars.lookup.results`: Extracted information for every best proxy variant found in the lookup dataset with the option `-p`. By default, this file will have the same header (first line) and columns as the lookup dataset.
4. `Proxy.vars.info`: Information about correlation with input variants for every best proxy variant found in the lookup dataset.
5. `Input_and_proxy.vars.not.found`: List of input variantIDs not found in the lookup dataset, whose proxy variants are also not found.
6. Directory `proxy_search` contains full proxy variant information downloaded from LDlink.

All output folders and files are put inside the output directory specified by option `-o`.

### Examples
1. Single variant lookup, without proxy search

    `varlook -v rsID1 -o GWAS_lookup/output_dir ~/path/to/GWAS_summary_stats.txt`

2. Multiple variant lookup, with proxy search R2 > 0.8

    `varlook -v rsID1 -v rsID2 -v rsID3 -p 0.8 -o GWAS_lookup/output_dir ~/path/to/GWAS_summary_stats.txt`
    
3. Multiple variant lookup listed in a file, with proxy search R2 > 0.9
    
    `varlook -f rsID_list.txt -p 0.9 -o GWAS_lookup/output_dir ~/path/to/GWAS_summary_stats.txt`

4. Multiple variant lookup listed in a file, with proxy search R2 > 0.8, in multiple lookup datasets.
    
    ```{sh}
    #!/bin/bash
    
    # Create an array of lookup datasets
    files=()
    files+=('~/path/to/GWAS_summary_stats_A.txt')
    files+=('~/path/to/GWAS_summary_stats_B.txt')
    files+=('~/path/to/GWAS_summary_stats_C.txt')
    
    # Create an array of output directories, matching lookup datasets name & order
    out_dirs=('output_dir_A' 'output_dir_B' 'output_dir_C')
    
    # Execute varlook in a loop
    for (( i = 0; i < ${#files[@]}; i++ )); do
        varlook -f rsID_list.txt -p 0.8 -o ${out_dirs[$i]} ${files[$i]}
    done
    
    ```





