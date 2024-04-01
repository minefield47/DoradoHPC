#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is typically ran as an executable passed from jobscript.sh. If only wanting to run basecalling, call this script with the input directory. 

#Necessary Arguments:
#$1 = 

#This script is designed for duplexing, which means pod5_sorting.sh needs to have been previously ran and each channel isolated as it's own pod5 file. 
#If running only basecalling: Run this from command line, replacing $pod5_directory with respective value.  




new_file=$(echo "$1" | cut -f 1 -d. )

library_root_name=$(basename $(dirname ${file}))


################################################################################
# Untrim Summary                                                               #
################################################################################

/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado summary \
$1 \
> ${new_file}.tsv

