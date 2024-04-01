

pod5_by_channel_directory="$1" #Set pod5_by_channel_directory to be the first (and only) argument when running the command. 

library_root_directory=$(dirname $pod5_by_channel_directory)


#This converts that path from /path/to/directory to just directory for naming during basecalling. 
library_root_name=$(basename $library_root_directory)

if [ $LSB_JOBINDEX -eq 1 ]; then 
mkdir ${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary
fi 


if ! [ -f ${pod5_by_channel_directory}/*"-"${LSB_JOBINDEX}".pod5" ]; then 
    echo "File does not exist. Ending job." 
    exit
fi




basename=$(basename $pod5_by_channel_directory/*-$LSB_JOBINDEX.pod5 | cut -d. -f1)


/usr/local/usrapps/covi/arb4107/dorado-0.5.1-linux-x64/bin/dorado summary \
${library_root_directory}/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_bam/${library_root_name}_${basename}_untrimmed.bam \
> $library_root_directory/${library_root_name}_basecall_trim/${library_root_name}_untrimmed_summary/${library_root_name}_${basename}_untrimmed.tsv
echo "Untrimmed Summary File Created"




bsub \
-J Dorado_by_channel[1-512] \
-n 1 \
-W 30 \
-q short \
-o stdout.%J \
-e stderr.%J \
"/home/arb4107/share/bp_g4/bp_g4_basecall_trim/dorado_untrimmed_summary.sh /home/arb4107/share/bp_g4/bp_g4_pod5_by_channel" 