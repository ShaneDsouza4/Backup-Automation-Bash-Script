#!/bin/bash

ROOT="/home/dsouza56"
LOG_DIR="$ROOT/backup"
CBUP_DIR="$LOG_DIR/cbup24s"
IBUP_DIR="$LOG_DIR/ibup24s"
LOG_FILE="$LOG_DIR/backup.log"

# Check if the backup directory exists, if not, create it
if [ ! -d "$CBUP_DIR" ]; then
    mkdir -p "$CBUP_DIR"
fi

if [ ! -d "$IBUP_DIR" ]; then
    mkdir -p "$IBUP_DIR"
fi

cbupCounter=1

# Check to allow user to enter max 3 arguments or min 1 arguments
if [ $# -gt 3 ]; then
    echo "Please specify up to 3 file extensions, example: backup24.sh .c .txt .pdf"
    echo "Extension can be skipped to consider all file types"
    exit 1
fi

logbackupDetails() {
    local filename=$1
    echo "$(date +"%a %d %b%Y %I:%M:%S %p %Z") $filename was created" >> "$LOG_FILE"
}

# Backup
performBackup() {
    # Determine prefix and filename based on backup type
    if [[ $1 == "complete" ]]; then
        filename="cbup24s-${cbupCounter}.tar"
        echo $filename

        shift
        
        # Handle backup for all file types
        if [ $# -eq 0 ]; then
            tar --exclude=".*" -cvf "$CBUP_DIR/$filename" -C "$ROOT" . >/dev/null 2>&1
            logbackupDetails "$filename"
            ((cbupCounter++))
        else
            find "$ROOT" -type f \( -name "*${2}" -o -name "*${3}" -o -name "*${4}" \) -print0 | tar --exclude=".*" --null -cvf "$CBUP_DIR/$filename" -T - >/dev/null 2>&1
            logbackupDetails "$filename"
            ((cbupCounter++))
        fi
    fi
}

while true; do
    performBackup "complete" "$@"
    sleep 120
done
