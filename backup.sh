#!/bin/bash

USERNAME="dsouza56"
ROOT="/home/$USERNAME"
LOG_DIR="$ROOT/home/backup"
CBUP_DIR="$LOG_DIR/cbup24s"
IBUP_DIR="$LOG_DIR/ibup24s"
DBUP_DIR="$LOG_DIR/dbup24s"
LOG_FILE="$LOG_DIR/backup.log"

#Creating relevsnt bakkup directorues
if [ ! -d "$CBUP_DIR" ]; then
    mkdir -p "$CBUP_DIR"
fi
if [ ! -d "$IBUP_DIR" ]; then
    mkdir -p "$IBUP_DIR"
fi
if [ ! -d "$DBUP_DIR" ]; then
    mkdir -p "$DBUP_DIR"
fi

#Cunter variabl to keeep track
cbupCounter=1
ibupCounter=1
dbupCounter=1

#File to store Full backup timestampps respectfully
lastFullBackupTimeStampFile="$LOG_DIR/.lastFullBackupTime"
if [ ! -f "$lastFullBackupTimeStampFile" ]; then
    echo "0" > "$lastFullBackupTimeStampFile"
fi

#file to store Incrementil bakcup timestamps
lastIncremenralBackupTimeStampFile="$LOG_DIR/.lastIncrementalBackupTime"
if [ ! -f "$lastIncremenralBackupTimeStampFile" ]; then
    echo "0" > "$lastIncremenralBackupTimeStampFile"
fi

#file to store Differential backuptimestamps
lastDifferentialBackupTimeStampFile="$LOG_DIR/.lastDifferenitalBackupTime"
if [ ! -f "$lastDifferentialBackupTimeStampFile" ]; then
    echo "0" > "$lastDifferentialBackupTimeStampFile"
fi

#Checking length of user input
if [ $# -lt 0 ] || [ $# -gt 3 ]; then
    echo "Please specify up to 3 file extensions, example: backup24.sh .c .txt .pdf"
    echo "Extension can be skipped to consider all file types"
fi
fileTypes=("$@") #User input arguements

#Will b used to update timestamp and details in th backup.log file
logbackupDetails() {
    local filename=$1
    echo "$(date +"%a %d %b%Y %I:%M:%S %p %Z") $filename" >> "$LOG_FILE"
}

# Func will backup files wrt to key received
backupFiles() {
    local key=$1;

    #Step 1 For complete backup of all fil when user doesnt specify any file typea
    if [[ $key == "complete" ]]; then
        echo "Complete Backup Started. Visitng entire ROOT directory, may take some time. Please wait..."
        filesToBackup=()
        for arg in ${fileTypes[@]}
            do
                #echo "Searching for files ending with $arg in $ROOT"
                while IFS= read -r file; do
                    filesToBackup+=("$file")
                done < <(find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$LOG_DIR/*")
        done
        local timestamp=$(date +%s) 
        local filename="cbup24s-${cbupCounter}.tar"
        
        #Finfing and backin up files
        if [ ${#filesToBackup[@]} -eq 0 ]; then # If no file types are specified, backup all files            
            find "$ROOT" -type f -not -path '*/\.*' -print #ffind
            tar --exclude=".*" -cvf "$CBUP_DIR/$filename" -C "$ROOT" . 2>/dev/null #tar
        else #Backing up file types specified by user
            tar -cvf "$CBUP_DIR/$filename" "${filesToBackup[@]}" 2>/dev/null
        fi

        #Check if tar was succesfull
        if [ $? -eq 0 ]; then
            logbackupDetails "$filename was created." #Update log file
            ((cbupCounter++)) #Increment the counter
            echo "$timestamp" > "$lastFullBackupTimeStampFile" #Update Timestamp in last full backup TS file
            echo "Complete Backup completed."
        fi
    fi

    #Step 2 Incremental backup to back up new or updated files since last full backup
    if [[ $key == "incrementalRound1" ]]; then
        local lastFullBackupTimestamp="$lastFullBackupTimeStampFile"
        local timestamp=$(date +%s) 
        local filename="ibup24s-${ibupCounter}.tar"

        #Temporary files
        local tempFilesFound="$LOG_DIR/.tempFindResults"
        > "$tempFilesFound"

        #Search for files in diretory with extesion typ specified by usr after the last full bak up
        echo "Incremental Backup Round 1 Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Check if the user has entered any file types or not and perform find wrt that
        if [ ${#fileTypes[@]} -eq 0 ]; then
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastFullBackupTimestamp" -print0 >> "$tempFilesFound" 2>/dev/null
        else
            for arg in "${fileTypes[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastFullBackupTimestamp" -print0 >> "$tempFilesFound" 2>/dev/null
            done
        fi

        #Check if any files wer found and backup
        if [ -s "$tempFilesFound" ]; then
            tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFilesFound" 2>/dev/null

            #If backup was succesfull
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created." #Update log file
                ((ibupCounter++))
                echo "$timestamp" > "$lastIncremenralBackupTimeStampFile" #Updae timestamp
                echo "Incremental Backup Round 1 Completed"
            fi
        else #If no files found would giv no changes
            logbackupDetails "No changes-Incremental backup was not created"
            echo "Incremental Backup Round 1 Completed"
        fi
        rm -f "$tempFilesFound" #Delet the temporaary file
    fi

    #Step 3 Incremental backup to back up new or updated files since last incremental backup
    if [[ $key == "incrementalRound2" ]]; then

        local lastIncrementalBackupTimeStamp="$lastIncremenralBackupTimeStampFile"
        local timestamp=$(date +%s) 
        local filename="ibup24s-${ibupCounter}.tar"
        local tempFilesFound="$LOG_DIR/.tempFindResults"
        #echo $filename

        echo "Incremental Round 2 Backup Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Check if the user has entered any file types or not and perform find wrt that
        # Find the updatd or newly created files since last INCREMENTAL bakup based on user input
        if [ ${#fileTypes[@]} -eq 0 ]; then
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastIncrementalBackupTimeStamp" -print0 >> "$tempFilesFound" 2>/dev/null
        else
            for arg in "${fileTypes[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastIncrementalBackupTimeStamp" -print0 >> "$tempFilesFound" 2>/dev/null
            done
        fi

        #If filea were found backup
        if [ -s "$tempFilesFound" ]; then
            tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFilesFound" 2>/dev/null #Bakcuop
            
            #If backup was succesfulll
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((ibupCounter++))
                echo "$timestamp" > "$lastIncremenralBackupTimeStampFile"
                echo "Incremental Round 2 Backup Completed"
            fi
        else #No files were dounf
            logbackupDetails "No changes-Incremental backup was not created"
            echo "Incremental Round 2 Backup Completed"
        fi
        rm -f "$tempFilesFound" #Delete the remporary file
    fi

    #Step 4 differential backup to back up new or updated files since last full backup
    if [[ $key == "differential" ]]; then
        local lastFullBackupTimestamp="$lastFullBackupTimeStampFile"
        local timestamp=$(date +%s) 
        local filename="dbup24s-${dbupCounter}.tar"
        local tempFilesFound="$LOG_DIR/.tempFindResults"
        #echo $filename

        echo "Differential Backup Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Check if the user has entered any file types or not and perform find wrt that
        if [ ${#fileTypes[@]} -eq 0 ]; then
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastFullBackupTimestamp" -print0 >> "$tempFilesFound" 2>/dev/null
        else
            for arg in "${fileTypes[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastFullBackupTimestamp" -print0 >> "$tempFilesFound" 2>/dev/null
            done
        fi

        #If files foind then backup
        if [ -s "$tempFilesFound" ]; then
            tar --null -cvf "$DBUP_DIR/$filename" --files-from="$tempFilesFound" 2>/dev/null #backup
            
            #If backup succesfull
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((dbupCounter++))
                echo "$timestamp" > "$lastDifferentialBackupTimeStampFile"
                echo "Differential backup Completed"
            fi
        else #iF NO files found and dont need to be backed up
            logbackupDetails "No changes-Differential backup was not created"
            echo "Differential backup Completed"
        fi
        rm -f "$tempFilesFound" #Delete the temporary filesx
    fi

    #Step 5 Incremental backup round3 to back up new or updated files since last differential backup
    if [[ $key == "incrementalRound3" ]]; then
        local lastDifferentialBackupTimeStamp="$lastDifferentialBackupTimeStampFile"
        local timestamp=$(date +%s) 
        local filename="ibup24s-${ibupCounter}.tar"
        local tempFilesFound="$LOG_DIR/.tempFindResults"
        #echo $filename

        echo "Incremental Backup Round 3 Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Check if the user has entered any file types or not and perform find wrt that
         # Find the updatd or newly created files since last DIFFERENTIAL bakup based on user input
        if [ ${#fileTypes[@]} -eq 0 ]; then
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastDifferentialBackupTimeStamp" -print0 >> "$tempFilesFound" 2>/dev/null
        else
            for arg in "${fileTypes[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastDifferentialBackupTimeStamp" -print0 >> "$tempFilesFound" 2>/dev/null
            done
        fi

        #If files Found
        if [ -s "$tempFilesFound" ]; then
            tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFilesFound" 2>/dev/null #backup
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((ibupCounter++))
                echo "$timestamp" > "$lastIncremenralBackupTimeStampFile"
                echo "Incremental Backup Round 3 Completed"
            fi
        else #No files found
            logbackupDetails "No changes-Incremental backup was not created"
            echo "Incremental Backup Round 3 Completed"
        fi
        rm -f "$tempFilesFound" #Deletein the temporaty file
    fi
}

#Infinte loop tp perfor bakup operations
while true; do
    backupFiles "complete"
    sleep 60

    backupFiles "incrementalRound1"
    sleep 60

    backupFiles "incrementalRound2"
    sleep 60

    backupFiles "differential"
    sleep 60

    backupFiles "incrementalRound3"
    sleep 60
done
