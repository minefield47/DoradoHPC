#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#These are the final post_processing to be conducted after basecalling. 
# As they are only reading the bam files, they can all be executed in parallel. 

# bash ~/dorado/post_basecalling.sh -b 

type_array="-f trimmed"
subset_array=("-s ALL" "-s SIMPLEX_ONLY")

while getopts "b:t:s:f:u:" OPTION;do 
    case $OPTION in
        b) 
            basecall_trim_directory="$OPTARG" ;;
        s) 
            if [ ${OPTARG^^} == "ALL" ] || [ ${OPTARG^^} == "DUPLEX_NO_PARENTS" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ]; then #What subset of reads do you want?
                subset_array+=("-s ${OPTARG^^}")
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -s: ALL, DUPLEX_NO_PARENTS, SIMPLEX_ONLY, DUPLEX_ONLY"
                exit 1
            fi;;
        f) 
            if [ ${OPTARG,,} == "trimmed" ] || [ ${OPTARG,,} == "untrimmed" ]; then #what type of reads are provided. This is to give the file the right typage. 
                type_array+="${OPTARG,,}"
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -t: trimmed, untrimmed"
                exit 1
            fi;;
        u) 
            if [ ${OPTARG^^} == TRUE ] || [ ${OPTARG^^} == FALSE ]; then #Do you want a summary file of the untrimmed reads?  TRUE OR FALSE?
                untrim_summary="${OPTARG^^}"
            else #Error Checker.
                echo "Non-Boolean True/False given for -u"
                exit 1
            fi;;
        t) 
            if [ ${OPTARG^^} == TRUE ] || [ ${OPTARG^^} == FALSE ]; then #Do you want a summary file of the untrimmed reads?  TRUE OR FALSE?
                trim_summary="${OPTARG^^}"
            else #Error Checker.
                echo "Non-Boolean True/False given for -t"
                exit 1
            fi;;            
    esac 
done

#Shift for the number of provided options so that remaining calls start at $1...
shift "$(( OPTIND - 1 ))" 

: ${basecall_trim_directory:?Missing basecall_trim input directory}

################################################################################
# Directory Definitions                                                        #
################################################################################


#Remover of the trailing / for when using independently of basecalling.sh
if [ "${basecall_trim_directory:0-1}" == "/" ]; then #Check if the last character in the string is equal to /
basecall_trim_directory=${basecall_trim_directory%?} #If yes, remove the last character (/) of string to have it be in compliance with dorado. 
fi 


#Now our pod5_by_channel directory is stored with the library name in front of it..."bp_g-madeup_pod5_by_channel"...so we need the basename of the path...or the library name. 
# From previous example...returns: bp_g-madeup
library_root_name=$(basename $(dirname $basecall_trim_directory))

################################################################################
# Summary Files                                                                #
################################################################################
#Do un/trimmed bams get summary files

################################################################################
# Summary Condenser                                                            #
################################################################################
#

if [ "${untrim_summary^^}" == "TRUE" ]; then
bsub \
-J tsv_condenser_untrimmed_${library_root_name} \
-n 1 \
-W 240 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/summary_condenser.sh ${basecall_trim_directory}/${library_root_name}_untrimmed_summary"
fi

if [ "${trim_summary^^}" == "TRUE" ]; then
bsub \
-J tsv_condenser_trimmed_${library_root_name} \
-n 1 \
-W 240 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/summary_condenser.sh ${basecall_trim_directory}/${library_root_name}_trimmed_summary"
fi

################################################################################
# Seqtools Export Reads                                                        #
################################################################################
#Export trimmed reads to fastq format for assembly.


for type in ${type_array}; do
bsub \
-J bam_all_fastq_${type}_${library_root_name} \
-n 1 \
-W 30 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/seqtools_fastq.sh -b ${basecall_trim_directory}/${library_root_name}_${type}_bam ${subset_array[@]} -f ${type}"
done
