#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is typically ran as an executable passed from jobscript.sh. If only wanting to run pod5, call this script with the input directory. 

#Necessary Arguments:
#$1 = pod5_input_directory

#If running only sorting: Run this from command line, replacing $pod5_directory with respective value.  
#bsub \
#-J pod5_sorting \
#-n 1 \
#-W 60 \
#-o stdout.%J\
#-e stderr.%J \
#"~/dorado/pod5_sorting.sh <pod5/input/directory>"


################################################################################
# Conda                                                                        #
################################################################################
#Activate Conda and then activate the pod5 environment. 

#Source the home bash controllers previously setup. 
source ~/.bashrc

#load the conda module. 
module load conda

#This environment is set to my application directory within the Covi Group. 
#If removed the steps to create a conda environment can be found here: https://hpc.ncsu.edu/Software/Apps.php?app=Conda
#pod5 application is installed with pip. https://pod5-file-format.readthedocs.io/en/latest/
conda activate /usr/local/usrapps/covi/arb4107/pod5_env/

################################################################################
# Input                                                                        #
################################################################################
#Ensures an input directory is given whether that be passed from jobscript or submitted via terminal commands. 

#Unset the required argument directory. 
unset -v pod5_directory #Where are the files coming from? <directory path>

pod5_directory="$1" #Set pod5_directory to be the first (and only) argument when running the command. 


#If pod5_directory is missing, throw an error. 
: ${pod5_directory:?Missing input directory (\$1)}

################################################################################
# Input Filter                                                                 #
################################################################################
#Simple QOL implementation. 
#Takes the argument presented and checks if it ends in "/" (present when using tab to autofill) and removes it. 

if [ "${pod5_directory:0-1}" == "/" ]; then #Check if the last character in the string is equal to /
pod5_directory=${pod5_directory%?} #If yes, remove the last character (/) of string to have it be in compliance with dorado. 
fi 

################################################################################
# Output Directory                                                             #
################################################################################
#Create the necessary output directory. 
parent_directory=$(dirname $pod5_directory) 
parent_directory_name=$(basename $parent_directory)


mkdir $parent_directory/${parent_directory_name}_pod5_by_channel

################################################################################
# Pod5 Subsetting                                                              #
################################################################################
#Create a summary and then subset the directory into by channel pod5 files. 

#Create a summary file of the pod5 directory organizing the read_ids and the channel ids. 
pod5 view $pod5_directory --include "read_id, channel" --output $parent_directory/${parent_directory_name}_pod5_summary.tsv

#Create a directory of pod5 files which are sorted by channel id. 
pod5 subset $pod5_directory --summary $parent_directory/${parent_directory_name}_pod5_summary.tsv --columns channel --output $parent_directory/${parent_directory_name}_pod5_by_channel



################################################################################
# Deactivation & Finishing                                                     #
################################################################################
#Deactive environment and modules. 

conda deactivate
module purge
