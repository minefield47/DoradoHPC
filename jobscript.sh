#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is the driver for taking raw pod5 files directly from the sequencer and automatically proceed all the way to summary file generation
# Simply run the script with the required argument ($1) being the input directory

#Run Script:
# ~/dorado/jobscript.sh -i </path/to/pod5/directory> <optional arguments>

################################################################################
# Help (Removed switchcase so deprecated but still helpful)                                      #
################################################################################
Help()
{
   # Display Help
   echo "This script is the driver for taking raw pod5 files directly from the sequencer and automatically proceed all the way to summary file generation"
   echo
   echo "Syntax: jobscript.sh -i <optional: >"
   echo "options:"
   echo "   Required:"
   echo "       -p     Pod5 directory of files for basecalling. This can be with or without trailing /"
   echo "    Optional:"
   echo "       -h     Print this help screen."
   echo "       -u     Default = FALSE || Create a summary directory of the untrimmed reads."
   echo "       -t     Default = TRUE ||Create a summary directory of the trimmed reads."
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

#i = input directory. 
#u=untrim_summary.
#t=trim_summary.

#Input switch case for determining 
while getopts "p:u:t:h:" OPTION;do 
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
    esac 
done


#Shift the number of provided options so that the remaining calls start at $1 
shift "$(( OPTIND - 1 ))" 


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
"~/dorado/fixer.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam $untrim_summary $trim_summary" 

#This script should take a maximum of 1 minute, 3 is buffer. 
#The indir/untrim_summary/trim_summary are passed to fixer for utilization during job submission. 


################################################################################
# Seqtools Export Trimmed Reads                                                #
################################################################################
#When the fixer script completes itself, it submits a job to the cluster named "fixer_complete_${library_root_name}"
#This allows the fixer to run multiple times and not proceed down jobscript until no blank files remain. 

bsub \
-w "done("fixer_complete_${library_root_name}")" \
-J seqtools_to_fastq_${library_directory_name} \
-n 1 \
-W 240 \
-q serial \
-o seqtool.fastq..stdout%J \
-e seqtool.fastq.stderr.%J \
"~/dorado/seqtools_fastq.sh <trimmed_bam_directory>"



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