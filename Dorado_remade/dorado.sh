#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is typically ran as an executable passed from basecalling.sh. To run only basecalling:
# bsub \
# -J Dorado_${library_root_name} \
# -n 64 \
# -R "span[hosts=1]" \
# -W 30 \
# -R "select[a100||h100]" \
# -q new_gpu \
# -gpu "num=1:mode=exclusive_process:mps=no" \
# -o Dorado_${library_root_name}.stdout.%J \
# -e Dorado_${library_root_name},stderr.%J \
# "~/dorado/dorado.sh $pod5_directory" 

#Necessary Arguments:
#$1 = pod5_by_channel = input directory
#$2 = untrimmed summary TRUE/FALSE default = FALSE
#$3 = trimmed summary TRUE/FALSE default = FALSE
#$4 = basecalling directory = 



#This script is designed for duplexing, which means pod5_sorting.sh needs to have been previously ran and each channel isolated as it's own pod5 file. 
#If running only basecalling: Run this from command line, replacing $pod5_directory with respective value.  




################################################################################
# Input Directory                                                              #
################################################################################
#Ensures an input directory is given whether that be passed from jobscript or submitted via terminal commands. 
#If running independently of jobscript.sh, $1 is set to the input directory.

#Unset the required argument directory. 
unset pod5_directory #Where are the files coming from? <directory path>
pod5_directory="$1" #Set pod5_directory to be the first (and only) argument when running the command. 

#If pod5_directory is missing, throw an error. 
: ${pod5_directory:?Missing input directory}


#This gives an absolute/relative path to the variable so something like /path/to/directory
library_root_directory=$(dirname $pod5_directory)


#This converts that path from /path/to/directory to just directory for naming during basecalling. 
library_root_name=$(basename $library_root_directory)

################################################################################
# Input Filter                                                                 #
################################################################################
#Simple QOL implementation. 
#Takes the argument presented and checks if it ends in "/" (present when using tab to autofill) and removes it. 

if [ "${pod5_directory:0-1}" == "/" ]; then #Check if the last character in the string is equal to /
pod5_directory=${pod5_directory%?} #If yes, remove the last character (/) of string to have it be in compliance with dorado. 
fi 


################################################################################
# basecalling Directory Creation                                                    #
################################################################################
#Create the dependent directories. 

mkdir ${library_root_directory}/${library_root_name}_basecall_trim


################################################################################
# Basecalling                                                                  #
################################################################################

#Basecalling/Duplexing using the superaccurate model. 
/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado duplex \
/usr/local/usrapps/covi/arb4107/models/dna_r10.4.1_e8.2_400bps_sup@v4.3.0 \
${pod5_directory} \
> ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed.bam
# Call Duplexing
#Using Superaccurate model (with the stereo model in the same directory)
#On file $directory/*-$LSB_JOBINDEX.pod5 
#Save it to $library_root_directory/basecall_trim/untrimmed_bam/channel-#.bam


