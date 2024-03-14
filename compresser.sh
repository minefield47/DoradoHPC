#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu


#This script is designed so after completion of ALL jobs, everything created gets individually tarred and gzipped into a folder for downloading/storage.

#This is the absolute path to the library, used to determine where the pod5 files are located. 
library_root_directory="$1"
library_root_name=$(basename $library_root_directory)

#Now our pod5_by_channel directory is stored with the library name in front of it..."bp_g-madeup_pod5_by_channel"...so we need the basename of the path...or the library name. 
# From previous example...returns: bp_g-madeup

mkdir ${library_root_directory}/${library_root_name}_compressed


################################################################################
# Pod5 Files                                                                   #
################################################################################


#Original Pod5 Files
if [ -d ${library_root_directory}/${library_root_name}_pod5 ]; then
    echo found pod5
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_pod5_compressed.tar.gz ${library_root_directory}/${library_root_name}_pod5
fi

#Pod5_by_channel
if [ -d ${library_root_directory}/${library_root_name}_pod5_by_channel ]; then

    # mkdir ${library_root_directory}/${library_root_name}_compressed/
    echo found pod5_by_channel
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_pod5_by_channel.tar.gz ${library_root_directory}/${library_root_name}_pod5_by_channel
fi
################################################################################
# Basecalled/Trim                                                              #
################################################################################

#Untrimmed Bam
if [ -d ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam ]; then

    echo found untrimmed.bam
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_untrimmed.bam.tar.gz ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam
fi

#Untrimmed summary
if [ -d ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary ]; then

    echo found untrimmed.bam
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_untrimmed_summary.tar.gz ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary
fi


#Trimmed bam
if [ -d ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam ]; then

    echo found untrimmed.bam
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_trimmed.bam.tar.gz ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam
fi


#Trimmed summary
if [ -d ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_summary ]; then

    echo found untrimmed.bam
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_trimmed_summary.tar.gz ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_summary
fi


################################################################################
# Fastq                                                                        #
################################################################################

if [ -d ${library_root_directory}/${library_root_name}_trimmed_fastq ]; then

    echo found untrimmed.bam
    tar -czf ${library_root_directory}/${library_root_name}_compressed/${library_root_name}_trimmed.fastq.tar.gz ${library_root_directory}/${library_root_name}_trimmed_fastq
fi








