#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu


#This script is designed so after completion of ALL jobs, everything created gets individually  gzipped into a folder for downloading/storage.

#This is the absolute path to the library, used to determine where the pod5 files are located. 
library_root_directory="$1"
library_root_name=$(basename $library_root_directory)

#Now our pod5_by_channel directory is stored with the library name in front of it..."bp_g-madeup_pod5_by_channel"...so we need the basename of the path...or the library name. 
# From previous example...returns: bp_g-madeup

mkdir ${library_root_directory}/${library_root_name}_compressed



#Untrimmed Bam
gunzip -ck ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed.bam > ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_untrimmed.bam.tar.gz
gunzip -ck ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam >  ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_trimmed.bam.tar.gz

#Untrimmed summary
if [ -f ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary ]; then
    echo found untrimmed.summary
    gunzip -ck ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed.tsv > ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_untrimmed.tsv.tar.gz
fi

#Trimmed summary
if [ -d ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_summary ]; then

    echo found untrimmed.bam
    gunzip -ck ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed.tsv > ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_trimmed.tsv.tar.gz
fi


################################################################################
# Fastqs                                                                        #
################################################################################

if [ -d ${library_root_directory}/${library_root_name}_trimmed_fastq ]; then

    echo found untrimmed.bam
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_trimmed_fastq.tar.gz -C ${library_root_directory}/${library_root_name}_trimmed_fastq .
fi








