#!/bin/bash

#=====================================================================================
# VARIANT LOOKUP  
# bash program to find genetic variants in a dataset
#
# Options: -v extract selected variant(s)
#          -f extract from file with list of variants
#          -p look for proxy (in LDlink), based on specified R2
#          -o set output directory
#=====================================================================================

unset vars file outdir

while getopts ":o:v:f:p:" opt; do
	case $opt in
		o) oflag=1
		   outdir="$OPTARG"
		   ;;
		v) vflag=1
		   vars+=("$OPTARG")
		   ;;
		f) fflag=1
		   file="$OPTARG"
		   ;;
		p) pflag=1
		   r2="$OPTARG"
		   ;;			
		\?) echo "ERROR: Invalid option: -$OPTARG"
		   exit 1	
		   ;;
		:) echo "ERROR: Option -$OPTARG requires an argument."
           exit 1
           ;;
	esac
done

shift $((OPTIND -1))

if [ $# -eq 0 ]; then
    echo "ERROR. Please supply a file path for lookup"
    exit 1
fi

if [[ -z "$oflag" || ( ! -z "$vflag" && ! -z "$fflag" ) || ( -z "$vflag" && -z "$fflag" ) ]] ; then
	printf "ERROR. Please check the options. Note that:\n"
	printf "\t- Option(s) -o -v -f -p needs to be followed by a valid argument\n"
	printf "\t- Output directory must be specified with option -o <path/for/output/directory>\n"
	printf "\t  and please make sure you have permission to modify the specified path\n"
	printf "\t- Either option -v <variantID> or -f <path/for/variantID/list/file> (not both) must be specified\n"
	exit 1
fi

# create warning if output directory exists
if [ -d $outdir ]; then
	printf "ERROR. Directory ${outdir} already exists. Please specify a new directory path to write results\n"
	exit 1
fi

#START of PROGRAM

printf "\n=======================================================================================================\nSTARTING variant lookup\n\n"

#Create output directory
mkdir -p $outdir


#function to look for sentinel variants
find_sent (){
	if grep -q -m1 "\b${var}\b" $1; then
		printf "Sentinel variant ${var} found in $1\n"
		grep -m1 "\b${var}\b" $1 >> ${outdir}/Sentinel.vars.lookup.results
	else
		echo "${var}" >> ${outdir}/Sentinel.vars.not.found
	fi
}

#function to look for proxies
find_proxies (){
	mkdir -p ${outdir}/proxy_search
	printf "\nSentinel variant ${var} not found. Downloading proxy variant data from LDlink 1000G EUR database to ${outdir}/proxy_search/${var}...\n\n"
		# Use curl to download LDlink proxy data
		curl -k -X GET "https://analysistools.nci.nih.gov/LDlink/LDlinkRest/ldproxy?var=${var}&pop=CEU%2BTSI%2BFIN%2BGBR%2BIBS&r2_d=r2" > ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR

		#check if curl return errors, raise warning
		if grep -q "error" ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR; then
			printf "\nWARNING. Error message found in ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR. Please make sure all variant IDs are valid.\n"
			errflag=1
		fi

		# Use awk to modify LDlink data
		awk -v v="$var" 'BEGIN {OFS="\t"} NR==1 \
			{gsub ("RS_Number", "Proxy_var"); print "Sentinel_var", $0}; \
			NR>1{print v, $0}' \
			${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR > tmp && mv tmp ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR
	printf "\nWriting proxy search results for ${var} to ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR\n"
	printf "\nSearching proxy variants for ${var} with R2 > ${r2}...\n"

	#find best proxies
	mapfile -t proxies < <( awk -v r2="$r2" 'NR>2 && $2!="." && $8>=r2 {print $2}' ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR )
	if [ -z "$proxies" ]; then
		printf "Search done. No proxy variant for ${var} with R2 > ${r2} found\n"
	else
		printf "Search done. Found ${#proxies[@]} proxy variants with R2 > ${r2}\n"
		printf "\nSearching for best proxy...\n"
		# set x to keep count of number of proxies found - before searching
		if [ -f ${outdir}/Proxy.vars.info ]; then
			x=`wc -l < ${outdir}/Proxy.vars.info`
		else
			x=0
		fi
		# loop to search for best proxy, stop if already found
		for p in ${proxies[@]}; do
			if grep -q -m1 "\b${p}\b" $1 ; then
				printf "Search done. Found variant ${p} in ${1} as proxy for ${var}\n"
				awk -v p="$p" '$2==p {print $0; exit;}' ${outdir}/proxy_search/${var}.proxies.LDlink.1000G_EUR >> ${outdir}/Proxy.vars.info
				grep -m1 "\b${p}\b" $1 >> ${outdir}/Proxy.vars.lookup.results
				break
			fi
		done

		# set y to keep count of number of proxies found - after searching
		if [ -f ${outdir}/Proxy.vars.info ]; then
			y=`wc -l < ${outdir}/Proxy.vars.info`
		else
			y=0
		fi

		# if best proxy is not found
		if [[ $y == $x  ]]; then
			echo "${var}" >> ${outdir}/Sentinel_and_proxy.vars.not.found
			printf "Search done. Found ${#proxies[@]} proxy variant(s) with R2 > ${r2} for ${var}, but none is found in ${1}.\n"
		fi
	fi
	printf "\n----------------------------------------------------------------------------------------------------s\n"
}

# If using option -f
if [ ! -z "$fflag" ]; then
	mapfile -t vars < $file
fi

# Search for sentinel variants
for var in ${vars[@]}; do
	find_sent $1
done

# With option -p (search for proxy)
if [[ ! -z "$pflag" && -s ${outdir}/Sentinel.vars.not.found ]]; then
	mapfile -t missvars < ${outdir}/Sentinel.vars.not.found
	for var in ${missvars[@]}; do
		find_proxies $1
	done
fi

printf "\n\n=======================================================================================================\n"
printf "Variant lookup complete. Summary:\n"
printf " - ${#vars[@]} variants searched in ${1}\n"
#check if file exists and not empty
if [ -s ${outdir}/Sentinel.vars.lookup.results ]; then
	printf " - $(wc -l < ${outdir}/Sentinel.vars.lookup.results) sentinel variants found in ${1}\n"
	printf "   Sentinel variant lookup results are written in ${outdir}/Sentinel.vars.lookup.results\n"
	sed -i "1i $( awk 'NR==1 {print $0}' $1 )" ${outdir}/Sentinel.vars.lookup.results
else
	printf " - No sentinel variant found in $1 \n"
fi

#check if there is any missing sentinel variant
if [ -s ${outdir}/Sentinel.vars.not.found ]; then
	printf " - $(wc -l < ${outdir}/Sentinel.vars.not.found) sentinel variant(s) not found in ${1}\n"
	printf "   (listed in ${outdir}/Sentinel.vars.not.found)\n"
fi

#check if file exists and not empty
if [ ! -z "$pflag" ]; then
	if [ -s ${outdir}/Proxy.vars.lookup.results ]; then
		printf " - Proxy variant data for $( find ${outdir}/proxy_search/* | wc -l ) sentinel variant(s) from LDlink 1000G EUR downloaded to ${outdir}/proxy_search\n"
		printf " - $(wc -l < ${outdir}/Proxy.vars.lookup.results) proxy variants with R2 > ${r2} found in ${1}\n"
		printf "   Proxy variant lookup results are written in ${outdir}/Proxy.vars.lookup.results\n"
		printf "   See ${outdir}/Proxy.vars.info for proxy variant info \n" 
		sed -i "1i $( awk 'NR==1 {print $0}' $1 )" ${outdir}/Proxy.vars.lookup.results
		sed -i "1i $( awk 'NR==1 {print $0}' $( find ${outdir}/proxy_search/* | head -1 ))" ${outdir}/Proxy.vars.info
		if [ -s ${outdir}/Sentinel_and_proxy.vars.not.found ]; then
			printf " - $(wc -l < ${outdir}/Sentinel_and_proxy.vars.not.found) sentinel variant(s) have proxy with R2 > ${r2}, but none found in $1 (listed in ${outdir}/Sentinel_and_proxy.vars.not.found)\n"
		fi
	elif [ -s ${outdir}/Sentinel.vars.not.found ]; then
		printf " - No proxy variant with r2 > ${r2} found in $1 \n"
	fi
fi

#check if there is error in proxy search
if [ ! -z "$errflag" ]; then
	printf " - WARNING. At least one proxy search in LDlink database returned an error message. Please make sure all submitted variant IDs are valid.\n"
fi

printf "\nHave a nice day! \n\n"
