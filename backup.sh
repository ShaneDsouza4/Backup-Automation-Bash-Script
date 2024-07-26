#!/bin/bash

#Check to allow user to enter max 3 arguments or min 1 arguments
if [ $# -lt 1 ] || [ $# -gt 3 ]; then 
    echo "Please specify commands example: backup24.sh .c .txt .pdf"
    echo "Extension can be skipped to consider all file types"
    exit 1
fi

#Inputs from command line
directory=$1 
extension=$2