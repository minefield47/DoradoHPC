#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is the driver for taking raw pod5 files directly from the sequencer and automatically proceed all the way to summary file generation
# Simply run the script with the required argument ($1) being the input directory

#Run Script:
# ~/dorado/jobscript.sh -p </path/to/pod5/directory> <optional arguments>

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
    echo "This script is the driver for taking raw pod5 files directly from the sequencer and automatically proceed all the way to summary file generation"
    echo
    echo "Syntax: jobscript.sh -p <pod5_directory_path> <optional arguments>"
    echo "options:"
    echo "   Required:"
    echo "       -p     Pod5 directory of files for basecalling. This can be with or without trailing /"
    echo "    Optional:"
    echo "       -h     Print this help screen."
    echo "       -u     Default = FALSE || Create a summary directory of the Untrimmed reads."
    echo "       -t     Default = TRUE ||Create a summary directory of the Trimmed reads."
    echo "       -f     Default = trimmed || Convert bam files into a single fastq file. This flag can be called multiple times for multiple file types (-f trimmed -f untrimmed)."
    echo "       -s     Default = ALL || Subset of Simplex/Duplex reads to output. This flag can be called multiple times for multiple file types (-s ALL -s SIMPLEX_ONLY)."
    echo "                  ALL: Output everything, duplex, paired simplex parents of the duplex data, and unpaired simplex reads"
    echo "                  SIMPLEX_ONLY: Paired simplex parents and the unpaired simplex reads."
    echo "                  DUPLEX_NO_PARENTS: Duplex reads and the unpaired simplex reads. "
    echo "                  DUPLEX_ONLY: Duplex reads only. "
    echo
}

################################################################################
# Input                                                                        #
################################################################################
#Ensures an input directory is given. 


#Unset the required argument directory. 
unset -v pod5_directory #Where are the files coming from? <directory path>

#Set the optional arguments to default parameters. 
untrim_summary="FALSE"
trim_summary="TRUE"
type_array="trimmed"
subset_array="ALL"
#i = input directory. 
#u=untrim_summary.
#t=trim_summary.

#Input switch case for determining 
while getopts "p:u:t:hf:s:" OPTION;do 
    case $OPTION in
        h) 
            Help #Run the Help function (above) and exit. 
            exit;;

        p) 
            pod5_directory="$OPTARG" ;;
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
        s) 
            if [ ${OPTARG^^} == "ALL" ] || [ ${OPTARG^^} == "DUPLEX_NO_PARENTS" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ]; then #What subset of reads do you want?
                subset_array+=("${OPTARG^^}")
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -s: ALL, DUPLEX_NO_PARENTS, SIMPLEX_ONLY, DUPLEX_ONLY"
                exit 1
            fi;;
        t) 
            if [ ${OPTARG,,} == "trimmed" ] || [ ${OPTARG,,} == "untrimmed" ]; then #what type of reads are provided. This is to give the file the right typage. 
                type_array+="${OPTARG,,}"
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -t: trimmed, untrimmed"
                exit 1
            fi;;      
    esac 
done

#Typically a shift for the number of provided options so that remaining calls start at $1...
# However, any additional options given here are going to be considered invalid so removed. 
# shift "$(( OPTIND - 1 ))" 


#If indir is missing, throw an error. 
: ${pod5_directory:?Missing pod5 input directory}


################################################################################
# library Directory                                                             #
################################################################################
#Used for everything after the pod5_sorting as the input directory is now different. 


#Create the necessary output directory. 
library_root_directory=$(dirname $pod5_directory) 

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
# Pod5 Separating by channel                                                   #
################################################################################
#Separate the input directory into pod5 files by channel.

bsub \
-J pod5_sorting_${library_root_name} \
-n 1 \
-W 60 \
-o stdout.%J \
-e stderr.%J \
"~/dorado/pod5_sorting.sh $pod5_directory"

#-J pod5_sorting = jobname
#-n 1 = Number of Cores
#-W 60 = Walltime
#-o stdout.%J #output - %J is the job-id
#-e stderr.%J #error - %J is the job-id
#Script location and the necessary arguments. 
# ${untrim_summary^^} coerces the output to being in all caps for simplicity


################################################################################
# Basecalling                                                                  #
################################################################################
#Submit to cluster the job for basecalling the separated channels 1-512. 
bjobs

sleep 30 

bsub \
-w "done("pod5_sorting_${library_root_name}")" \
-J Dorado_by_channel_${library_root_name}[1-512] \
-n 1 \
-W 30 \
-R "select[a100]" \
-q new_gpu \
-gpu "num=1:mode=shared:mps=no" \
-o stdout.%J_%I \
-e stderr.%J_%I \
"~/dorado/dorado.sh ${library_root_directory}/${library_root_name}_pod5_by_channel $untrim_summary $trim_summary" 

#-J pod5_sorting = jobname
#-n 1 = Number of Cores
#-W 60 = Walltime
#-o stdout.%J #output - %J is the job-id
#-e stderr.%J #error - %J is the job-id
#-R "select[a100||a10||rtx2080||gtx1080]" = request either an a100, a10, rtx2080, or gtx1080 (the compatible GPUs)
#-q gpu = Request a GPU
#-gpu "num=1:mode=shared:mps=no" = Request 1 gpu in shared mode without MPS being turned on. 

################################################################################
# Fixer                                                                        #
################################################################################
#Because LSB can sometimes send jobs to the cluster/GPUs that do not have enough memory (crashing the basecalling)
#This script waits for Dorado_by_channel to finish and runs a quanitative analyzer that either passes and ends,
#or resubmits Dorado for the channels that failed. 
bjobs

sleep 5

bjobs

bsub \
-w "done("Dorado_by_channel_${library_root_name}")" \
-J fixer_${library_root_name} \
-n 1 \
-W 05 \
-q short \
-o Fixer_stdout.%J_%I \
-e Fixer_stderr.%J_%I \
"~/dorado/fixer.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam $untrim_summary $trim_summary $type_array $subset_array" 

#This script should take a maximum of 1 minute, 3 is buffer. 
#The indir/untrim_summary/trim_summary are passed to fixer for utilization during job submission. 

################################################################################
# Compressing                                                                  #
################################################################################
#When all files are finished being utilized, submit this compressing script that takes all outputs and tars/gzips them.

#Currently turned off as it creates an archive of files down the absolute path. Need to fix. 

# bsub \
# -w "done("seqtools_to_fastq_${library_directory_name}")" \
# -J compresser_${library_directory_name} \
# -n 1 \
# -W 240 \
# -q serial \
# -o compresser.stdout.%J \
# -e compresser.stderr.%J_%I \
# "~/dorado/compresser.sh <library_directory>"