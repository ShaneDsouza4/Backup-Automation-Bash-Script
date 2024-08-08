#!/bin/bash

ROOT="/home/dsouza56"
LOG_DIR="$ROOT/backup"
CBUP_DIR="$LOG_DIR/cbup24s"
IBUP_DIR="$LOG_DIR/ibup24s"
DBUP_DIR="$LOG_DIR/dbup24s"

LOG_FILE="$LOG_DIR/backup.log"

# Check if the backup directory exists, if not, create it
if [ ! -d "$CBUP_DIR" ]; then
    mkdir -p "$CBUP_DIR"
fi
if [ ! -d "$IBUP_DIR" ]; then
    mkdir -p "$IBUP_DIR"
fi
if [ ! -d "$DBUP_DIR" ]; then
    mkdir -p "$DBUP_DIR"
fi

cbupCounter=1
ibupCounter=1
dbupCounter=1

#File to store the timestamp of last full and incremental backup
lastFullBackupTimeStampFile="$LOG_DIR/.last_full_backup_time"
if [ ! -f "$lastFullBackupTimeStampFile" ]; then
    echo "0" > "$lastFullBackupTimeStampFile"
fi

lastIncremenralBackupTimeStampFile="$LOG_DIR/.last_incremental_backup_time"
if [ ! -f "$lastIncremenralBackupTimeStampFile" ]; then
    echo "0" > "$lastIncremenralBackupTimeStampFile"
fi

lastDifferentialBackupTimeStampFile="$LOG_DIR/.last_differenital_backup_time"
if [ ! -f "$lastDifferentialBackupTimeStampFile" ]; then
    echo "0" > "$lastDifferentialBackupTimeStampFile"
fi

logbackupDetails() {
    local filename=$1
    echo "$(date +"%a %d %b%Y %I:%M:%S %p %Z") $filename" >> "$LOG_FILE"
}

# Backup
performBackup() {
    local backupType=$1;
    
    if [[ $backupType == "complete" ]]; then
        local timestamp=$(date +%s) #unix epoch
        local filename="cbup24s-${cbupCounter}.tar"
        echo $filename
        echo "Creating backup: $filename"

        # Handle backup for all file types or specified file types
        find "$ROOT" -type f -not -path '*/\.*' -print
        tar --exclude=".*" -cvf "$CBUP_DIR/$filename" -C "$ROOT" .  

        #Check exit status of tar to see if success
        if [ $? -eq 0 ]; then
            logbackupDetails "$filename was created."
            ((cbupCounter++))
            echo "$timestamp" > "$lastFullBackupTimeStampFile" #Update Timestamp in last full backup TS file
            echo "Cbup completed"
        else
            logbackupDetails "Error creating $filename"
            echo "Cbup Else completed"
        fi
    fi
    echo "------------------------"
    #Step 2 Incremental backup
    if [[ $backupType == "incrementalRound1" ]]; then

        #local lastFullBackupTimestamp=$(cat "$lastFullBackupTimeStampFile")
        local lastFullBackupTimestamp="$lastFullBackupTimeStampFile"

        local timestamp=$(date +%s) # Unix epoch
        local filename="ibup24s-${ibupCounter}.tar"
        local tempFile="$LOG_DIR/.temp_find_results"
        echo $filename

        # Find the modified or new file;
        start_time=$(date +%s)
        #find "$ROOT" -type f -not -path '*/\.*' -newermt "@$lastFullBackupTimestamp" -print0 > "$tempFile"
        #find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newermt "@$lastFullBackupTimestamp" -print0 > "$tempFile"
        find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastFullBackupTimestamp" -print0 > "$tempFile"

        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "Find command executed in $elapsed_time seconds"

        if [ -s "$tempFile" ]; then
            #tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile"
            tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile" 2>/dev/null
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((ibupCounter++))
                echo "$timestamp" > "$lastIncremenralBackupTimeStampFile"
                echo "Incremental backup completed"
            else
                logbackupDetails "Error creating $filename"
                echo "Incremental backup failed"
            fi
        else
            logbackupDetails "No changes-Incremental backup was not created"
        fi
        rm -f "$tempFile"
    fi
    echo "------------------------"

    #Step 3 Incremental backup
    if [[ $backupType == "incrementalRound2" ]]; then

        #local lastIncremenralBackupTimeStampFile=$(cat "$lastIncremenralBackupTimeStampFile")
        local lastIncrementalBackupTimeStamp="$lastIncremenralBackupTimeStampFile"
        local timestamp=$(date +%s) # Unix epoch
        local filename="ibup24s-${ibupCounter}.tar"
        local tempFile="$LOG_DIR/.temp_find_results"
        echo $filename

        # Find the modified or new file;
        start_time=$(date +%s)
        #find "$ROOT" -type f -not -path '*/\.*' -newermt "@$lastIncremenralBackupTimeStampFile" -print0 > "$tempFile"
        #find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newermt "$lastIncremenralBackupTimeStamp" -print0 > "$tempFile"
        find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastIncrementalBackupTimeStamp" -print0 > "$tempFile"
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "Find command executed in $elapsed_time seconds"

        if [ -s "$tempFile" ]; then
            #tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile"
            tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile" 2>/dev/null
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((ibupCounter++))
                echo "$timestamp" > "$lastIncremenralBackupTimeStampFile"
                echo "Incremental backup completed"
            else
                logbackupDetails "Error creating $filename"
                echo "Incremental backup failed"
            fi
        else
            logbackupDetails "No changes-Incremental backup was not created"
        fi
        rm -f "$tempFile"
    fi
    echo "------------------------"

    #Step 4 differential backup
    if [[ $backupType == "differential" ]]; then

        #local lastFullBackupTimestamp=$(cat "$lastFullBackupTimeStampFile")
        local lastFullBackupTimestamp="$lastFullBackupTimeStampFile"

        local timestamp=$(date +%s) # Unix epoch
        local filename="dbup24s-${dbupCounter}.tar"
        local tempFile="$LOG_DIR/.temp_find_results"
        echo $filename

        # Find the modified or new file;
        start_time=$(date +%s)
        #find "$ROOT" -type f -not -path '*/\.*' -newermt "@$lastFullBackupTimestamp" -print0 > "$tempFile"
        #find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newermt "@$lastFullBackupTimestamp" -print0 > "$tempFile"
        find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastFullBackupTimestamp" -print0 > "$tempFile"

        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "Find command executed in $elapsed_time seconds"

        if [ -s "$tempFile" ]; then
            #tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile"
            tar --null -cvf "$DBUP_DIR/$filename" --files-from="$tempFile" 2>/dev/null
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((dbupCounter++))
                echo "$timestamp" > "$lastDifferentialBackupTimeStampFile"
                echo "Differential backup completed"
            else
                logbackupDetails "Error creating $filename"
                echo "Differential backup failed"
            fi
        else
            logbackupDetails "No changes-Differential backup was not created"
        fi
        rm -f "$tempFile"
    fi
    echo "------------------------"
    if [[ $backupType == "incrementalRound3" ]]; then

        #local lastIncremenralBackupTimeStampFile=$(cat "$lastIncremenralBackupTimeStampFile")
        local lastDifferentialBackupTimeStamp="$lastDifferentialBackupTimeStampFile"
        local timestamp=$(date +%s) # Unix epoch
        local filename="ibup24s-${ibupCounter}.tar"
        local tempFile="$LOG_DIR/.temp_find_results"
        echo $filename

        # Find the modified or new file;
        start_time=$(date +%s)
        #find "$ROOT" -type f -not -path '*/\.*' -newermt "@$lastIncremenralBackupTimeStampFile" -print0 > "$tempFile"
        #find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newermt "$lastIncremenralBackupTimeStamp" -print0 > "$tempFile"
        find "$ROOT" -type f -not -path '*/\.*' -not -path "$LOG_DIR/*" -newer "$lastDifferentialBackupTimeStamp" -print0 > "$tempFile"
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "Find command executed in $elapsed_time seconds"

        if [ -s "$tempFile" ]; then
            #tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile"
            tar --null -cvf "$IBUP_DIR/$filename" --files-from="$tempFile" 2>/dev/null
            if [ $? -eq 0 ]; then
                logbackupDetails "$filename was created."
                ((ibupCounter++))
                echo "$timestamp" > "$lastIncremenralBackupTimeStampFile"
                echo "Incremental backup completed"
            else
                logbackupDetails "Error creating $filename"
                echo "Incremental backup failed"
            fi
        else
            logbackupDetails "No changes-Incremental backup was not created"
        fi
        rm -f "$tempFile"
    fi
}

while true; do
    performBackup "complete"
    sleep 10

    performBackup "incrementalRound1"
    sleep 10

    performBackup "incrementalRound2"
    sleep 10

    performBackup "differential"
    sleep 10

    performBackup "incrementalRound3"
    sleep 10

done
