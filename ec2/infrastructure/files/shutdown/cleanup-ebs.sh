# stop madoc + unmount data drive
systemctl stop madoc.service
umount /opt/data
sed -i '/opt\\/data/d' /etc/fstab

# stop backups and unmount backup drive
systemctl disable madoc-backup.timer
systemctl disable madoc-db-backup-hourly.timer
systemctl disable madoc-db-backup-daily.timer
systemctl disable madoc-db-backup-weekly.timer
systemctl disable madoc-db-backup-monthly.timer
umount /mnt/backup
sed -i '/mnt\\/backup/d' /etc/fstab