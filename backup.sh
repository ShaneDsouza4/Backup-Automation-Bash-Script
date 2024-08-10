#!/bin/bash

#PAth variables to create Directories
USERNAME="dsouza56"
ROOT="/home/$USERNAME"
mainBackUpDir="$ROOT/home/backup"
completeBackUpDir="$mainBackUpDir/cbup24s"
incrementalBackUpDir="$mainBackUpDir/ibup24s"
differentialBackUpDir="$mainBackUpDir/dbup24s"
logFile="$mainBackUpDir/backup.log"

# Checl if Backup directories not created, they are created using mkdir -p
if [ ! -d "$completeBackUpDir" ]; then
    mkdir -p "$completeBackUpDir"
fi
if [ ! -d "$incrementalBackUpDir" ]; then
    mkdir -p "$incrementalBackUpDir"
fi
if [ ! -d "$differentialBackUpDir" ]; then
    mkdir -p "$differentialBackUpDir"
fi

#Counter Variable to append the correct number of the filea
cbupCounter=1
ibupCounter=1
dbupCounter=1

# Files to add categrize timestamps
lastFullBackupTimeStampFile="$mainBackUpDir/.lastFullBackupTime"
lastIncrementalBackupTimeStampFile="$mainBackUpDir/.lastIncrementalBackupTime"
lastDifferentialBackupTimeStampFile="$mainBackUpDir/.lastDifferentialBackupTime"

# Initialize timestamp files if they don't exist
if [ ! -f "$lastFullBackupTimeStampFile" ]; then
    echo $(date +%s) > "$lastFullBackupTimeStampFile"
fi
if [ ! -f "$lastIncrementalBackupTimeStampFile" ]; then
    echo $(date +%s) > "$lastIncrementalBackupTimeStampFile"
fi
if [ ! -f "$lastDifferentialBackupTimeStampFile" ]; then
    echo $(date +%s) > "$lastDifferentialBackupTimeStampFile"
fi

# Checking length of user input
if [ $# -lt 0 ] || [ $# -gt 3 ]; then
    echo "Please specify up to 3 file extensions, example: backup24.sh .c .txt .pdf"
    echo "Extension can be skipped to consider all file types"
    exit 1
fi

# Add the user arguments to the fileExtToFnd array
fileExtToFind=("$@") 

# Function to log the relevant results to backup log file
# Will log the date time file created or the message if no file created.
logbackupDetails() {
    local result=$1
    echo "$(date +"%a %d %b%Y %I:%M:%S %p %Z") $result" >> "$logFile"
}

# Main function that will back up files based on key provided
backupFiles() {
    local key=$1

    #This is for Step 1, a complete backup is taken
    if [[ $key == "complete" ]]; then
        echo "Complete Backup Started. Visitng entire ROOT directory, may take some time. Please wait..."
        
        local timestamp=$(date +%s) #timestamp will be used for logging purposes
        local filename="cbup24s-${cbupCounter}.tar" #File with respected number will be used for backup and logging
        local tempFiles=$(mktemp) #Temporary dir with temp files created to add relevant files so tar speed can be optimized

        #Finding files in the Root directory
        if [ ${#fileExtToFind[@]} -eq 0 ]; then #If user has not mentioned any file types backup all
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$mainBackUpDir/*" -print0 > "$tempFiles"
        else #If user has entered file types like .c .txt only those will be searched for in the Root Directory
            for arg in "${fileExtToFind[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$mainBackUpDir/*" -print0 >> "$tempFiles"
            done
        fi
        
        #Backing up the files that we found and stored in the Temp Files
        tar --null -cvf "$completeBackUpDir/$filename" --files-from="$tempFiles" 2>/dev/null
        
        #Remove the temporary files as not needed further
        rm -f "$tempFiles"

        #Check if tar was succesfull
        if [ $? -eq 0 ]; then
            logbackupDetails "$filename was created." #Log backup details
            ((cbupCounter++)) #Increase the counter for the next file
            echo "$timestamp" > "$lastFullBackupTimeStampFile" #Update the time stamp
            echo "Complete Backup completed."
        fi
    fi

    #Step 2 will now intiate and consider finding and backing up thse files that were created or modified after STEP 1
    if [[ $key == "incrementalRound1" ]]; then
        echo "Incremental Backup Round 1 Started. Visitng entire ROOT directory, may take some time. Please wait..."
        
        #Reads timestamp in last FULL backup timestamp file, as will be used in the find
        local lastFullBackupTimestamp=$(cat "$lastFullBackupTimeStampFile") 
        local timestamp=$(date +%s) #timestamp will be used for logging purposes
        local filename="ibup24s-${ibupCounter}.tar" #File with respected number will be used for backup and logging
        local tempFiles=$(mktemp) #Temporary dir with temp files created to add relevant files so tar speed can be optimized

        #Finding files in the Root directory
        if [ ${#fileExtToFind[@]} -eq 0 ]; then #If user has not mentioned any file types backup all
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastFullBackupTimestamp" -print0 > "$tempFiles"
        else #If user has entered file types like .c .txt only those will be searched for in the Root Directory
            for arg in "${fileExtToFind[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastFullBackupTimestamp" -print0 >> "$tempFiles"
            done
        fi
        
        #If there are files found and were added to temp Files
        if [ -s "$tempFiles" ]; then
            #Backing up the files that we found and stored in the Temp Files
            tar --null -cvf "$incrementalBackUpDir/$filename" --files-from="$tempFiles" 2>/dev/null
            logbackupDetails "$filename was created." #Log backup details 
            ((ibupCounter++)) #Increase the counter for the next file
            echo "$timestamp" > "$lastIncrementalBackupTimeStampFile" #Update the time stamp
            echo "Incremental Backup Round 1 Completed"
        else #If no files were found, means no backup was needed to be done
            logbackupDetails "No changes-Incremental backup was not created"
            echo "Incremental Backup Round 1 Completed"
        fi

        #Remove the temporary files as not needed further
        rm -f "$tempFiles"
    fi

    #Step 3 will now intiate and consider finding and backing up thse files that were created or modified after STEP 3
    if [[ $key == "incrementalRound2" ]]; then
        echo "Incremental Round 2 Backup Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Reads timestamp in last INCREMENTAL backup timestamp file, as will be used in the find
        local lastIncrementalBackupTimeStamp=$(cat "$lastIncrementalBackupTimeStampFile")
        local timestamp=$(date +%s) #timestamp will be used for logging purposes
        local filename="ibup24s-${ibupCounter}.tar" #File with respected number will be used for backup and logging
        local tempFiles=$(mktemp) #Temporary dir with temp files created to add relevant files so tar speed can be optimized

        #Finding files in the Root directory
        if [ ${#fileExtToFind[@]} -eq 0 ]; then #If user has not mentioned any file types backup all
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastIncrementalBackupTimeStamp" -print0 > "$tempFiles"
        else #If user has entered file types like .c .txt only those will be searched for in the Root Directory
            for arg in "${fileExtToFind[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastIncrementalBackupTimeStamp" -print0 >> "$tempFiles"
            done
        fi

        #If there are files found and were added to temp Files
        if [ -s "$tempFiles" ]; then
            #Backing up the files that we found and stored in the Temp Files
            tar --null -cvf "$incrementalBackUpDir/$filename" --files-from="$tempFiles" 2>/dev/null
            logbackupDetails "$filename was created." #Log backup details 
            ((ibupCounter++)) #Increase the counter for the next file
            echo "$timestamp" > "$lastIncrementalBackupTimeStampFile" #Update the time stamp
            echo "Incremental Round 2 Backup Completed"
        else #If no files were found, means no backup was needed to be done
            logbackupDetails "No changes-Incremental backup was not created"
            echo "Incremental Round 2 Backup Completed"
        fi

        #Remove the temporary files as not needed further
        rm -f "$tempFiles"
    fi

    #Step 4 will now intiate and consider finding and backing up thse files that were created or modified after STEP 1
    if [[ $key == "differential" ]]; then
        echo "Differential Backup Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Reads timestamp in last FULL backup timestamp file, as will be used in the find
        local lastFullBackupTimestamp=$(cat "$lastFullBackupTimeStampFile")
        local timestamp=$(date +%s) #timestamp will be used for logging purposes
        local filename="dbup24s-${dbupCounter}.tar" #File with respected number will be used for backup and logging
        local tempFiles=$(mktemp) #Temporary dir with temp files created to add relevant files so tar speed can be optimized

        #Finding files in the Root directory
        if [ ${#fileExtToFind[@]} -eq 0 ]; then #If user has not mentioned any file types backup all
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastFullBackupTimestamp" -print0 > "$tempFiles"
        else #If user has entered file types like .c .txt only those will be searched for in the Root Directory
            for arg in "${fileExtToFind[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastFullBackupTimestamp" -print0 >> "$tempFiles"
            done
        fi

        #If there are files found and were added to temp Files
        if [ -s "$tempFiles" ]; then
            #Backing up the files that we found and stored in the Temp Files
            tar --null -cvf "$differentialBackUpDir/$filename" --files-from="$tempFiles" 2>/dev/null
            logbackupDetails "$filename was created." #Log backup details
            ((dbupCounter++)) #Increase the counter for the next file
            echo "$timestamp" > "$lastDifferentialBackupTimeStampFile" #Update the time stamp
            echo "Differential backup Completed"
        else #If no files were found, means no backup was needed to be done
            logbackupDetails "No changes-Differential backup was not created"
            echo "Differential backup Completed"
        fi

        #Remove the temporary files as not needed further
        rm -f "$tempFiles"
    fi

    #Step 5 will now intiate and consider finding and backing up thse files that were created or modified after STEP 4
    if [[ $key == "incrementalRound3" ]]; then
        echo "Incremental Backup Round 3 Started. Visitng entire ROOT directory, may take some time. Please wait..."

        #Reads timestamp in last DIFFERENTIAL backup timestamp file, as will be used in the find
        local lastDifferentialBackupTimeStamp=$(cat "$lastDifferentialBackupTimeStampFile")
        local timestamp=$(date +%s) #timestamp will be used for logging purposes
        local filename="ibup24s-${ibupCounter}.tar" #File with respected number will be used for backup and logging
        local tempFiles=$(mktemp) #Temporary dir with temp files created to add relevant files so tar speed can be optimized

        #Finding files in the Root directory
        if [ ${#fileExtToFind[@]} -eq 0 ]; then #If user has not mentioned any file types backup all
            find "$ROOT" -type f -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastDifferentialBackupTimeStamp" -print0 > "$tempFiles"
        else #If user has entered file types like .c .txt only those will be searched for in the Root Directory
            for arg in "${fileExtToFind[@]}"
            do
                find "$ROOT" -type f -name "*$arg" -not -path '*/\.*' -not -path "$mainBackUpDir/*" -newermt "@$lastDifferentialBackupTimeStamp" -print0 >> "$tempFiles"
            done
        fi

        #If there are files found and were added to temp Files
        if [ -s "$tempFiles" ]; then
            #Backing up the files that we found and stored in the Temp Files
            tar --null -cvf "$incrementalBackUpDir/$filename" --files-from="$tempFiles" 2>/dev/null
            logbackupDetails "$filename was created." #Log backup details
            ((ibupCounter++)) #Increase the counter for the next file
            echo "$timestamp" > "$lastIncrementalBackupTimeStampFile" #Update the time stamp
            echo "Incremental Backup Round 3 Completed"
        else #If no files were found, means no backup was needed to be done
            logbackupDetails "No changes-Incremental backup was not created"
            echo "Incremental Backup Round 3 Completed"
        fi

        #Remove the temporary files as not needed further
        rm -f "$tempFiles"
    fi
}

# Infinite loop to perform backup operations with the help of an array and a sleep duration of 120 seconds
backupTypes=("complete" "incrementalRound1" "incrementalRound2" "differential" "incrementalRound3")
sleepDuration=120

for (( ; ; )); do
    for backupType in "${backupTypes[@]}"; do
        backupFiles "$backupType"
        sleep "$sleepDuration"
    done
done
