#! /bin/bash
BACKUP_FOLDER="/mnt/backup/files"
mkdir -p $BACKUP_FOLDER
echo "Syncing files to $BACKUP_FOLDER"

rsync -a /opt/data/files/ $BACKUP_FOLDER