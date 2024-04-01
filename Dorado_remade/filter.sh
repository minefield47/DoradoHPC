#!/bin/bash
#Author: Auden Block
#Contact arb4107 {@} uncw {.} edu

unset output
include=t
while getopts "i:r:eo:" OPTION;do 
    case $OPTION in
        e) 
            include=f ;;
        r) 
            read_ids="${OPTARG}" ;;
        o) 
            output="${OPTARG}" ;;
        i) 
            input="${OPTARG}" ;;   
    esac 
done


#If output is unset...make our own using the input. 
if [ -z ${output+x} ]; then
output="${input}.filtered"
fi

conda activate /home/arb4107/apps/BBmap

filterbyname.sh in=$input out=$output names=${read_ids} include=${include}

conda deactivate