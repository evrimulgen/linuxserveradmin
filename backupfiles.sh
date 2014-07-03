#! /bin/bash
# Linux Server Backup Tool
# ilker Ozcan

# git init --bare (for remote git)
# git init (for local)
# git add .gitignore
# nano gitignore
# *.log
# administrator/Backup

# git remote add cosmos /path/to/usbstick/repo
# sudo git remote -v
# git commit -m 'limbo server git backup'
# git fetch usb --all (for recover)

mount -t cifs -o username=***,password=**** //****/Backups /mnt/Backups/

cd /home

git add .

git commit -a -m "auto commit by server"

git push cosmos --all

umount /mnt/Backups
