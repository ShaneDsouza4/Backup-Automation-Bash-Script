#!/bin/bash

ROOT="/home/dsouza56"
LOG_DIR="$ROOT/backup"
CBUP_DIR="$LOG_DIR/cbup24s" 
LOG_FILE="$LOG_DIR/backup.log"

cbupCounter=1;

# Check if the source directory exists, if not, create it
if [ ! -d "CBUP_DIR" ]; then
    mkdir -p "$CBUP_DIR"
fi

#Check to allow user to enter max 3 arguments or min 1 arguments
if [ $# -lt 0 ] || [ $# -gt 3 ]; then 
    echo "Please specify commands example: backup24.sh .c .txt .pdf"
    echo "Extension can be skipped to consider all file types"
    exit 1
fi

#Backup
performBackup(){
    echo $1;
    
    # Determine prefix and filename based on backup type
    if [[ $1 == "complete" ]]; then
        filename="cbup24s-${cbupCounter}.tar"
        echo $filename;
    fi
}

while true; do
    performBackup "complete" 
    #echo "Arguments: $@"

    sleep 1
done