**Backup Automation Script**

This repository contains a Bash script that automates the process of taking complete, incremental, and differential backups of a specified root directory. The script is designed to be flexible, allowing users to specify file extensions to be included in the backups, and runs indefinitely with a configurable interval between each backup type.

**Features**
Complete Backup: Captures all files in the root directory, excluding hidden files and the backup directory itself.
Incremental Backup: Performs two rounds of incremental backups:
The first round includes files modified after the last complete backup.
The second and third rounds include files modified after the previous incremental backup or differential backup, respectively.
Differential Backup: Captures files modified after the last complete backup.
Customizable File Extensions: Users can specify up to three file extensions to include in the backup process.
Logging: All backup activities are logged with timestamps for easy tracking.

**Script Workflow**
Directory Setup: Creates necessary directories for storing complete, incremental, and differential backups.
Timestamp Management: Initializes and updates timestamp files to track the time of the last backup.
Backup Process:
Complete Backup: Backs up all files in the root directory.
Incremental Backup: Backs up files modified since the last complete or previous incremental backup.
Differential Backup: Backs up files modified since the last complete backup.
Looping: The script runs indefinitely, performing backups in the following order: Complete, Incremental Round 1, Incremental Round 2, Differential, Incremental Round 3. It waits for 120 seconds between each backup type.
