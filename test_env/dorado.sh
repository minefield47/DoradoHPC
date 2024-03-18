#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

#This script is typically ran as an executable passed from jobscript.sh. If only wanting to run basecalling, call this script with the input directory. 

#Necessary Arguments:
#$1 = pod5_by_channel = input directory
#$2 = untrimmed summary TRUE/FALSE default = FALSE
#$3 = trimmed summary TRUE/FALSE default = FALSE
#$4 = basecalling directory = 
#THIS SCRIPT MUST BE RUN AS AN ARRAY INDEX TO HAZEL/LSB. 


#This script is designed for duplexing, which means pod5_sorting.sh needs to have been previously ran and each channel isolated as it's own pod5 file. 
#If running only basecalling: Run this from command line, replacing $pod5_by_channel_directory with respective value.  




################################################################################
# Input Directory                                                              #
################################################################################
#Ensures an input directory is given whether that be passed from jobscript or submitted via terminal commands. 
#If running independently of jobscript.sh, $1 is set to the input directory.

#Unset the required argument directory. 
unset pod5_by_channel_directory #Where are the files coming from? <directory path>
pod5_by_channel_directory="$1" #Set pod5_by_channel_directory to be the first (and only) argument when running the command. 

#If pod5_by_channel_directory is missing, throw an error. 
: ${pod5_by_channel_directory:?Missing input directory}


################################################################################
# Summary Files                                                                #
################################################################################
untrim_summary="${2:-FALSE}"
trim_summary="${3:-TRUE}"


#Do you want a summary file of the untrimmed reads?  TRUE OR FALSE?
if [ ${untrim_summary^^} != TRUE ] && [ ${untrim_summary^^} != FALSE ]; then #Input checker:
    #Value that is not true or false given.
    echo "Non-Boolean TRUE/FALSE given for untrimmed summary" 
    exit 1

fi

#Do you want a summary file of the trimmed reads?  TRUE OR FALSE?
if [ ${trim_summary^^} != "TRUE" ] && [ ${trim_summary^^} != "FALSE" ]; then #Input checker:
    #Value that is not true or false given.
    echo "Non-Boolean TRUE/FALSE given for untrimmed summary" 
    exit 1

fi


################################################################################
# basecalling Directory                                                            #
################################################################################
 # Whether being passed from jobscript.sh or run at the command line, 
 # the second input determines where the files will be stored. 
 #By default (i.e. no second argument), it will be stored in the same library directory of the pod5 input directory.

#This should not be typically envoked as it changes the name of the following directories.
# It is best to just keep it to the default so the script keeps the library identifier consistent, 
# And prevents the fixer script from breaking/having to be redefined. 
#This gives an absolute/relative path to the variable so something like /path/to/directory
library_root_directory=$(dirname $pod5_by_channel_directory)


#This converts that path from /path/to/directory to just directory for naming during basecalling. 
library_root_name=$(basename $library_root_directory)

################################################################################
# Input Filter                                                                 #
################################################################################
#Simple QOL implementation. 
#Takes the argument presented and checks if it ends in "/" (present when using tab to autofill) and removes it. 

if [ "${pod5_by_channel_directory:0-1}" == "/" ]; then #Check if the last character in the string is equal to /
pod5_by_channel_directory=${pod5_by_channel_directory%?} #If yes, remove the last character (/) of string to have it be in compliance with dorado. 
fi 


################################################################################
# basecalling Directory Creation                                                    #
################################################################################
#Create the dependent directories. 



#If the job index is equal to 1 (the job first submitted and ran), create the directories necessary for the jobs.
if [ $LSB_JOBINDEX -eq 1 ]; then 
    mkdir ${library_root_directory}/${library_root_name}_basecall_trim
    mkdir ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam
    mkdir ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam


    if [ $untrim_summary == TRUE ]; then
    mkdir ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary
    fi

    if [ $trim_summary == TRUE ]; then
    mkdir ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_summary
    fi

fi


################################################################################
# CUDA                                                                         #
################################################################################
#GPUs/Dorado use CUDA to control the graphic cards for computational work. 


#Load the CUDA module for all necessary scripts. 
module load cuda/12.0


################################################################################
# Basecalling                                                                  #
################################################################################
#Basecalling with Dorado.

#Because some channels produce no data, it does not make sense to run dorado as it will simply error code, making sorting difficult. 
#This checks if the file does NOT exist, ending the script/job. 
#If the file does exist, move to else and continue. 

if ! [ -f ${pod5_by_channel_directory}/*"-"${LSB_JOBINDEX}".pod5" ]; then 
    echo "File does not exist. Ending job." 
    exit
fi

#If this is being read, the file exists so run dorado on it. 

echo "Currently Starting Dorado on pod file number: $pod5_by_channel_directory/*-$LSB_JOBINDEX.pod5"


################################################################################
# Basename Variable                                                            #
################################################################################


basename=$(basename $pod5_by_channel_directory/*-$LSB_JOBINDEX.pod5 | cut -d. -f1)


################################################################################
# Basecalling                                                                  #
################################################################################

#Basecalling/Duplexing using the superaccurate model. 
/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado duplex \
/usr/local/usrapps/covi/arb4107/models/dna_r10.4.1_e8.2_400bps_sup@v4.3.0 \
$pod5_by_channel_directory/*-$LSB_JOBINDEX.pod5 \
> ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam/${library_root_name}_${basename}_untrimmed.bam
# Call Duplexing
#Using Superaccurate model (with the stereo model in the same directory)
#On file $directory/*-$LSB_JOBINDEX.pod5 
#Save it to $library_root_directory/basecall_trim/untrimmed_bam/channel-#.bam




################################################################################
# Untrim Summary                                                               #
################################################################################

if [ $untrim_summary = TRUE ];then

/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado summary \
${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam/${library_root_name}_${basename}_untrimmed.bam \
> $library_root_directory/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary/${library_root_name}_${basename}_untrimmed.tsv
echo "Untrimmed Summary File Created"

fi

echo "Finished Dorado duplex calling. Now trimming"


################################################################################
# Trimming                                                                     #
################################################################################
#One could pipe the duplex command directly into the trim command but this would lose the intermediatary untrimmed reads. 

#Trimming the Simplex reads of the adapters and primers. 
/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado trim ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam/${library_root_name}_${basename}_untrimmed.bam \
> ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam/${library_root_name}_${basename}_trimmed.bam

#Turn Dorado on, 
#use the previously downloaded model and trim adapters/primers 
#and save it. 


################################################################################
# Trim Summary                                                                 #
################################################################################

if [ "$trim_summary" = TRUE ];then

/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado \
summary ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_trimmed_bam/${library_root_name}_${basename}_trimmed.bam \
> $library_root_directory/${library_root_name}_basecall_trim/${library_root_name}_trimmed_summary/${library_root_name}_${basename}_trimmed.tsv
echo "Trimmed Summary File Created"

fi



################################################################################
# CUDA PURGE & FINISH                                                          #
################################################################################
module purge 
