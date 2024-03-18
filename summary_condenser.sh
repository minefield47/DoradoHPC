#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

################################################################################
# Directory Definitions                                                        #
################################################################################
#Assign the directory in which output directory. 
summary_directory=$1

#Remover of the trailing / for when using independently of basecalling.sh
if [ "${summary_directory:0-1}" == "/" ]; then #Check if the last character in the string is equal to /
summary_directory=${summary_directory%?} #If yes, remove the last character (/) of string to have it be in compliance with dorado. 
fi 

echo $summary_directory
#This is the absolute path to the library...used to determine where the pod5 files are located. 
library_root_directory=$(dirname $(dirname $summary_directory))

echo $library_root_directory
#Now our pod5_by_channel directory is stored with the library name in front of it..."bp_g-madeup_pod5_by_channel"...so we need the basename of the path...or the library name. 
# From previous example...returns: bp_g-madeup
library_root_name=$(basename $library_root_directory)

/home/arb4107/apps/tsv-utils/bin/tsv-append -H ${summary_directory}/*.tsv >> ${library_root_directory}/${library_root_name}_all.tsv