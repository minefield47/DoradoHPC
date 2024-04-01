#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is the driver for taking raw pod5 files directly from the sequencer and automatically proceed all the way to summary file generation
# Simply run the script with the required argument ($1) being the input directory

#Run Script:
# ~/dorado/basecalling.sh -p </path/to/pod5/directory> <optional arguments>

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
trim_summary="FALSE"
type_array=("-f trimmed")
subset_array=("-s ALL" "-s SIMPLEX_ONLY")
#i = input directory. 
#u=untrim_summary.
#t=trim_summary.

#Input switch case for determining 
while getopts "p:utf:s:h" OPTION;do 
    case $OPTION in
        h) 
            Help #Run the Help function (above) and exit. 
            exit;;
        p) 
            pod5_directory="$OPTARG" ;;
        u) 
            untrim_summary="TRUE" ;;
        t) 
            trim_summary="TRUE" ;;
        s) 
            if [ ${OPTARG^^} == "ALL" ] || [ ${OPTARG^^} == "DUPLEX_NO_PARENTS" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ]; then #What subset of reads do you want?
                subset_array+=("-s ${OPTARG^^}")
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -s: ALL, DUPLEX_NO_PARENTS, SIMPLEX_ONLY, DUPLEX_ONLY"
                exit 1
            fi;;
        f) 
            if [ ${OPTARG,,} == "trimmed" ] || [ ${OPTARG,,} == "untrimmed" ]; then #what type of reads are provided. This is to give the file the right typage. 
                type_array+="-f ${OPTARG,,}"
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


bsub \
-J pod5_sorting_${library_root_name} \
-n 1 \
-W 60 \
-o stdout.%J \
-e stderr.%J \
"~/dorado/pod5_sorting.sh $pod5_directory"


################################################################################
# Basecalling                                                                  #
################################################################################
#Submit to cluster the job for basecalling the separated channels 1-512. 

bsub \
-J Dorado_${library_root_name} \
-w "done("pod5_sorting_${library_root_name}")" \
-n 32 \
-R "span[hosts=1]" \
-W 30 \
-R "select[h100]" \
-q new_gpu \
-gpu "num=1:mode=exclusive_process:mps=no" \
-o Dorado.stdout.%J \
-e Dorado.stderr.%J \
"~/dorado/dorado.sh ${library_root_directory}/${library_root_name}_pod5_by_channel" 

#-J pod5_sorting = jobname
#-n 1 = Number of Cores
#-W 60 = Walltime
#-o stdout.%J #output - %J is the job-id
#-e stderr.%J #error - %J is the job-id
#-R "select[a100||h100]" = request either an a100 or h100 (the compatible GPUs)
#-q gpu = Request a GPU
#-gpu "num=1:mode=shared:mps=no" = Request 1 gpu in shared mode without MPS being turned on. 


################################################################################
# Trimming                                                                     #
################################################################################
bsub \
-J trim_${library_root_name} \
-w "done("Dorado_${library_root_name}")" \
-n 1 \
-W 30 \
-q serial \
-o trim.stdout.%J \
-e trim.stderr.%J \
"~/dorado/trimming.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed.bam"



################################################################################
# Summary                                                                      #
################################################################################
if [ ${untrim_summary} == "TRUE" ];then
bsub \
-J summary_untrim_${library_root_name} \
-w "done("Dorado_${library_root_name}")" \
-n 1 \
-W 30 \
-q serial \
-o summary.stdout.%J \
-e summary.stderr.%J \
"~/dorado/summary.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed.bam"
fi

if [ "$trim_summary" = TRUE ];then
bsub \
-J summary_trim_${library_root_name} \
-w "done("trim_${library_root_name}")" \
-n 1 \
-W 30 \
-q serial \
-o summary.stdout.%J \
-e summary.stderr.%J \
"~/dorado/summary.sh ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed.bam"
fi

# ################################################################################
# # Fastq Exportation                                                            #
# ################################################################################

for type in ${type_array}; do
bsub \
-J bam_${type}_fastq_${type}_${library_root_name} \
-w "done("Dorado_${library_root_name}")" \
-n 1 \
-W 30 \
-q serial \
-o samtool.fastq.${type}.stdout.%J \
-e samtool.fastq.${type}.stderr.%J \
"~/dorado/samtools_fastq.sh -b ${basecall_trim_directory}/${library_root_name}_${type}_bam " ${subset_array[@]} " -f ${type}"
done

# ################################################################################
# # Compression                                                                  #
# ################################################################################

bjobs