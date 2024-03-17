#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

# While one can immediately output fastq files from dorado using --emit-fastq, 
# This results in the reads having its tags removed and other identifying information. 
# As such, it is recommended by the devs to use seqtools/samtools to convert the .bam files output into .fastq
#For this I opted to use samtools. 

#

################################################################################
# Conda Activate                                                               #
################################################################################

source ~/.bashrc
#Change to be your env
conda activate /usr/local/usrapps/covi/arb4107/samtools_env/

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
    echo "This script is the driver for taking the BAM files and converting into fastq format"
    echo
    echo "Syntax: samtools_fastq.sh -i <optional: >"
    echo "options:"
    echo "   Required:"
    echo "       -b     Directory of BAM files for conversion. This can be with or without trailing /"
    echo "    Optional:"
    echo "       -h     Print this help screen."
    echo "       -t     Default = trimmed || Trimmed or untrimmed directory input?"
    echo "       -s     Default = ALL || Subset of Simplex/Duplex reads to output. This flag can be called multiple times for multiple file types (-s ALL -s SIMPLEX_ONLY)."
    echo "                  ALL: Output everything, duplex, paired simplex parents of the duplex data, and unpaired simplex reads"
    echo "                  SIMPLEX_ONLY: Paired simplex parents and the unpaired simplex reads."
    echo "                  DUPLEX_NO_PARENTS: Duplex reads and the unpaired simplex reads. "
    echo "                  DUPLEX_ONLY: Duplex reads only. "
    
    echo
}
################################################################################
# Defaults and Sorting                                                         #
################################################################################
# ALL: Output everything, duplex, paired simplex parents of the duplex data, and unpaired simplex reads
# SIMPLEX_ONLY: Paired simplex parents and the unpaired simplex reads.
# DUPLEX_NO_PARENTS: Duplex reads and the unpaired simplex reads. 
# DUPLEX_ONLY: Duplex reads only. 

subset_array="ALL"
type="trimmed"

while getopts "hb:t:s:" OPTION;do 
    case $OPTION in
        b) 
            bam_directory="$OPTARG" ;;
        h) 
            Help #Run the Help function (above) and exit. 
            exit ;;
        s) 
            if [ ${OPTARG^^} == "ALL" ] || [ ${OPTARG^^} == "DUPLEX_NO_PARENTS" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ] || [ ${OPTARG^^} == "SIMPLEX_ONLY" ]; then #What subset of reads do you want?
                subset_array+=("${OPTARG^^}")
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -s: ALL, DUPLEX_NO_PARENTS, SIMPLEX_ONLY, DUPLEX_ONLY"
                exit 1
            fi;;
        t) 
            if [ ${OPTARG,,} == "trimmed" ] || [ ${OPTARG,,} == "untrimmed" ]; then #what type of reads are provided. This is to give the file the right typage. 
                type="${OPTARG,,}"
            else #Error Checker.
                echo "Invalid Parameter given. Valid options for -t: trimmed, untrimmed"
                exit 1
            fi;;            
    esac 
done

#Shift for the number of provided options so that remaining calls start at $1...
shift "$(( OPTIND - 1 ))" 

: ${bam_directory:?Missing bam input directory}

################################################################################
# Directory Definitions                                                        #
################################################################################
#Input of trimmed_bam directory:


#Take the directory of the directory: /home/arb4107/share/bp_g1.3_random_gpus/bp_g1/
library_root_directory=$(dirname $(dirname ${bam_directory}))
#Get the basename: bp_g1
library_root_name=$(basename ${library_root_directory})


################################################################################
# Make Directory                                                               #
################################################################################
mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs

################################################################################
# Execution                                                                    #
################################################################################
for subset in "${subset_array[@]}"; do
    #For users that apply -s multiple times, an array of types will be created. As such, iterate each index of array.
    for bam_file in $trimmed_bam_directory/*; do
        bam_file_name=$(basename ${bam_file} | cut -d. -f1)

        if [ "${subset^^}" == "ALL" ]; then 
            
            samtools fastq $bam_file -T '*' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.${type}.fastq
        
        elif [ "${subset^^}" == "DUPLEX_NO_PARENTS" ];then

            samtools fastq $bam_file -d 'dx:1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.${type}.fastq
            samtools fastq $bam_file -d 'dx:0' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.${type}.fastq
            
        elif [ "${subset^^}" == "SIMPLEX_ONLY" ];then
        
            samtools fastq $bam_file -d 'dx:0' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.${type}.fastq
            samtools fastq $bam_file -d 'dx:-1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.${type}.fastq

        elif [ "${subset^^}" == "DUPLEX_ONLY" ];then
        
            samtools fastq $bam_file -d 'dx:1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.${type}.fastq

        fi
    done
done

conda deactivate
