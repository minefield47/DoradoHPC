#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

# While one can immediately output fastq files from dorado using --emit-fastq, 
# This results in the reads having its tags removed and other identifying information. 
# As such, it is recommended by the devs to use seqtools/samtools to convert the .bam files output into .fastq
#For this I opted to use samtools. 

################################################################################
# Conda Activate                                                               #
################################################################################

source ~/.bashrc
#Change to be your env
conda activate /usr/local/usrapps/covi/arb4107/samtools_env/


################################################################################
# Directory Definitions                                                        #
################################################################################
#Input of trimmed_bam directory:
trimmed_bam_directory="$1"

#Take the directory of the directory: /home/arb4107/share/bp_g1.3_random_gpus/bp_g1/
library_root_directory=$(dirname $(dirname ${trimmed_bam_directory}))
#Get the basename: bp_g1
library_root_name=$(basename ${library_root_directory})


# ALL: Output everything, duplex, paired simplex parents of the duplex data, and unpaired simplex reads
# SIMPLEX_ONLY: Output the paired simplex parents and the unpaired simplex reads: for utilization of kmer counting. 
# DUPLEX_NO_PARENTS: Duplex reads and the unpaired simplex reads. 



subset="${2:ALL}"

################################################################################
# Summary Files                                                                #
################################################################################
#Do un/trimmed bams get summary files

untrimmed="${3:-FALSE}"
trimmed="${4:-TRUE}"

if [ "${trimmed^^}" == "TRUE" ]; then
for bam_file in $trimmed_bam_directory/*; do
    bam_file_name=$(basename ${bam_file} | cut -d. -f1)

    if [ "${subset^^}" == "ALL" ]; then 
        
        mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs
        
        samtools fastq $bam_file -T '*' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
    
    elif [ "${subset^^}" == "DUPLEX_NO_PARENTS" ];then
        
        mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs

        samtools fastq $bam_file -d 'dx:1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
        samtools fastq $bam_file -d 'dx:0' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
        
    elif [ "${subset^^}" == "SIMPLEX_ONLY" ];then
    
        mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs

        samtools fastq $bam_file -d 'dx:0' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
        samtools fastq $bam_file -d 'dx:-1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq

    elif [ "${subset^^}" == "DUPLEX_ONLY" ];then
    
        samtools fastq $bam_file -d 'dx:1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
    else 
        echo "${subset} is not an accepted value: ALL DUPLEX_ONLY SIMPLEX_ONLY DUPLEX_NO_PARENTS."
        exit; 

    fi
done
fi 


if [ "${untrimmed^^}" == "TRUE" ]; then
    untrimmed_bam_directory="$(dirname $trimmed_bam_directory)/${library_root_name}_untrimmed_bam"

for bam_file in $untrimmed_bam_directory/*; do
    bam_file_name=$(basename ${bam_file} | cut -d. -f1)

    if [ "${subset^^}" == "ALL" ]; then 
        
        mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs
        
        samtools fastq $bam_file -T '*' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.untrimmed.fastq
    
    elif [ "${subset^^}" == "DUPLEX_NO_PARENTS" ];then
        
        mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs

        samtools fastq $bam_file -d 'dx:1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.untrimmed.fastq
        samtools fastq $bam_file -d 'dx:0' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.untrimmed.fastq
        
    elif [ "${subset^^}" == "SIMPLEX_ONLY" ];then
    
        mkdir ${library_root_directory}/${library_root_name}_${subset}_fastqs

        samtools fastq $bam_file -d 'dx:0' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
        samtools fastq $bam_file -d 'dx:-1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq

    elif [ "${subset^^}" == "DUPLEX_ONLY" ];then
    
        samtools fastq $bam_file -d 'dx:1' >> ${library_root_directory}/${library_root_name}_${subset}_fastqs/${library_root_name}_${subset}.trimmed.fastq
    else 
        echo "${subset} is not an accepted value: ALL DUPLEX_ONLY SIMPLEX_ONLY DUPLEX_NO_PARENTS."
        exit; 

    fi
done
fi 


conda deactivate
