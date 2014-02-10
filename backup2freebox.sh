#!/bin/bash

default_host='192.168.0.254'
default_mysql_user='root'
default_ftp_user='freebox'
default_directory='/Disque dur/Sauvegardes/'$(hostname -s)'/mirror'

read -p "MySQL user [$default_mysql_user]:" mysql_user
read -s -p "MySQL password:" mysql_password ; echo
read -p "Freebox IP [$default_host]:" host
read -p "Freebox FTP user [$default_ftp_user]:" ftp_user
read -s -p "Freebox FTP password:" ftp_password ; echo
read -p "Freebox backup directory ['$default_directory']:" directory

#mysqlcheck -u"${mysql_user:-$default_mysql_user}" -p"$mysql_password" --all-databases --optimize --auto-repair --silent 2>&1
echo 'Dump MySQL database...'
mysql_backup=/var/backup/mysql-databases.sql
#mysqldump --user="${mysql_user:-$default_mysql_user}" --password="$mysql_password" --all-databases > "$mysql_backup"

echo 'Mirror partition...'
[[ ! $(which lftp) ]] && apt-get install lftp
lftp -u ${ftp_user:-$default_ftp_user},${ftp_password:-$default_ftp_password} ${host:-$default_host} <<EOF
mirror --reverse --delete --exclude /tmp --exclude '.*/backups?.*' --include "$mysql_backup" / "${directory:-$default_directory}"
quit 0
EOF

rm "$mysql_backup"