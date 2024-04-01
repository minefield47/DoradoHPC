#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is the driver for taking raw pod5 files directly from the sequencer and automatically proceed all the way to summary file generation
# Simply run the script with the required argument ($1) being the input directory

#Run Script:
# ~/dorado/trimming.sh <path to untrimmed bam file>


################################################################################
# Trimming                                                                     #
################################################################################
#One could pipe the duplex command directly into the trim command but this would lose the intermediatary untrimmed reads. 

#Trimming the Simplex reads of the adapters and primers. 
/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado trim $1 > $(echo "$1" | rev | cut -f 2- -d "_" |rev)_trimmed.bam

#Turn Dorado on andd trim adapters/primers 
#and save it as a new file.