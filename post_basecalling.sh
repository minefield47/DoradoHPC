#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#These are the final post_processing to be conducted after basecalling. 
# As they are only reading the bam files, they can all be executed in parallel. 


################################################################################
# Directory Definitions                                                        #
################################################################################
#Assign the directory in which output directory. 
basecall_trim_directory=$(dirname $1)

#Remover of the trailing / for when using independently of basecalling.sh
if [ "${basecall_trim_directory:0-1}" == "/" ]; then #Check if the last character in the string is equal to /
basecall_trim_directory=${basecall_trim_directory%?} #If yes, remove the last character (/) of string to have it be in compliance with dorado. 
fi 


#This is the absolute path to the library...used to determine where the pod5 files are located. 
library_root_directory=$(dirname $basecall_trim_directory)


#Now our pod5_by_channel directory is stored with the library name in front of it..."bp_g-madeup_pod5_by_channel"...so we need the basename of the path...or the library name. 
# From previous example...returns: bp_g-madeup
library_root_name=$(basename $library_root_directory)

################################################################################
# Summary Files                                                                #
################################################################################
#Do un/trimmed bams get summary files

untrim_summary="${2:-FALSE}"
trim_summary="${3:-TRUE}"

################################################################################
# Summary Condenser                                                            #
################################################################################
#

if [ "${trim_summary^^}" == "TRUE" ]; then
bsub \
-J tsv_condenser_${library_directory_name} \
-n 1 \
-W 240 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/summary_condenser.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_summary"
fi

if [ "${untrim_summary^^}" == "TRUE" ]; then
bsub \
-J tsv_condenser_${library_directory_name} \
-n 1 \
-W 240 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/summary_condenser.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary"
fi

################################################################################
# Seqtools Export Reads                                            #
################################################################################
#Export trimmed reads to fastq format for assembly.
type_array="${4:-trimmed}"
subset="${5:-("ALL" "SIMPLEX_ONLY")}"
for type in ${type_array}; do
bsub \
-J bam_all_fastq_${type}_${library_directory_name} \
-n 1 \
-W 30 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/seqtools_fastq.sh -b ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_${type}_bam -s ${subset} -t ${type}"
done
