#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#Because LSF can sometimes send jobs to the cluster/GPUs that do not have enough memory (crashing the basecalling)
#This script finds files with zero-bytes that either passes (no 0-size files found) and ends...submitting post_basecalling.sh to the cluster,
# or resubmits dorado.sh and fixer.sh for the channels that failed to be tried again. 


# If running via terminal this command can just be submitted as a bash command (bash fixer.sh $untrim_summary $trim_summary $type_array $subset_array)
# This job is not resource intensive so can be ran on a login node before submitting the intesive commands to loop until all channels have been fixed. 


################################################################################
# File Paths                                                                   #
################################################################################
# The input is the trimmed directory...
# However, this is not where the pod_5_by_channel directory is stored. 
# To get that, need to get to the library's root directory, or the parent of the parent.
#Take for instance: 
#1="/home/arb4107/share/bp_g-madeup/bp_g-madeup_basecall_trim/bp_g-madeup_trimmed_bam"
# With the file structure: 
#bp_g-madeup
# ├── bp_g-madeup_basecall_trim
# │   ├── bp_g-madeup_trimmed_bam
# │   │   └── trim_bam_files
# │   ├── bp_g-madeup_trimmed_summary
# │   │   └── trimmed_summary_per_channel
# │   ├── bp_g-madeup_untrimmed_bam
# │   │   └── untrimmed_bams
# │   └── bp_g-madeup_untrimmed_summary
# │       └── untrimmed_channel_summaries
# ├── bp_g-madeup_pod5_by_channel
# │   └── sorted_pod5_files
# └── bp_g-madeup_pod5_original
#     └── Unsorted_pod5_files
# Our input is located here (*) but we need the files here (**)
# bp_g-madeup
# ├── bp_g-madeup_basecall_trim
# │   ├── bp_g-madeup_trimmed_bam (*)
# │   │   └── trim_bam_files 
# │   ├── bp_g-madeup_trimmed_summary
# │   │   └── trimmed_summary_per_channel
# │   ├── bp_g-madeup_untrimmed_bam
# │   │   └── untrimmed_bams
# │   └── bp_g-madeup_untrimmed_summary
# │       └── untrimmed_channel_summaries
# ├── bp_g-madeup_pod5_by_channel
# │   └── sorted_pod5_files (**)
# └── bp_g-madeup_pod5_original
#     └── Unsorted_pod5_files
# To get there: 
# basecall_trim_directory=$(dirname $1) 
# Returns: /home/arb4107/share/bp_g-madeup/bp_g-madeup_basecall_trim/
# If you then run the same command on basecall_trim_directory:
# library_root_directory=$(dirname basecall_trim_directory)
# Returns: /home/arb4107/share/bp_g-madeup
# Which is the root of the library we are basecalling, and the parent directory of bp_g-madeup_pod5_by_channel...our destination directory

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



#These two are not used here but are instead simply passed from basecalling to post_basecalling for utilization.
type_array="${4:-trimmed}"
subset_array="${5:-ALL}"


################################################################################
# File Numbers                                                                 #
################################################################################
#Determine the file numbers. 


#Must be done in this order. 
# $1 = input directory.
#1, find the files
#2, remove path/channel- leaving #.bam
#3, remove the .bam leaving only the numbers
#4, echo the arguments, converting the output from being one per line to being a single line. 
blank_file_numbers=$(find $1 -size 0 | cut -f 2 -d - | cut -f 1 -d . | cut -f 1 -d _ | xargs echo)

#Because nested command substitutions get ugly quickly, 
# I am taking the easy out and just reassigning the variable. 
blank_file_numbers=${blank_file_numbers// /,}

echo $blank_file_numbers

#If the length of failed is greater than zero, 
if [ ${#blank_file_numbers} -gt 0 ];then
    until [ ${#blank_file_numbers} -eq 0 ]; do
        batch=$(echo $blank_file_numbers | cut -d,  -f 1-20)


        bsub \
        -J Dorado_fixer_${library_root_name}[${batch}] \
        -n 1 \
        -W 60 \
        -R "select[a100]" \
        -q new_gpu \
        -gpu "num=1:mode=shared:mps=no" \
        -o Dorado_fixer.stdout.%J_%I \
        -e Dorado_fixer.stderr.%J_%I \
        "~/dorado/dorado.sh ${library_root_directory}/${library_root_name}_pod5_by_channel $untrim_summary $trim_summary" 

        blank_file_numbers=${blank_file_numbers#$batch}
        if [[ $blank_file_numbers == ,* ]]; then blank_file_numbers=${blank_file_numbers:1} ; fi

    done

    sleep 30
#This causes the script to wait between submiting the dorado script and the fixer...both for the user to confirm the right number of files were created...but to prevent the unkillable script issue.  

bsub \
-w "ended("Dorado_fixer_${library_root_name}")" \
-J fixer_${library_root_name} \
-n 1 \
-W 10 \
-o Dorado_fixer.stdout.%J_%I \
-e Dorado_fixer.stderr.%J_%I \
"~/dorado/fixer.sh $1 $untrim_summary $trim_summary $type_array $subset_array"


else 
    echo "All channels successfully basecalled"
    bsub \ 
    -J  \
    -n 1 \
    -W 1 \
    -o Dorado_fixer.stdout.%J_%I \
    -e Dorado_fixer.stderr.%J_%I \
    "~/dorado/post_basecalling.sh $1 $untrim_summary $trim_summary $type_array $subset_array"
fi
