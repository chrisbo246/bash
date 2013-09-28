#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__backup_menu()
{
  while true; do
    __menu \
    -t 'Backup menu' \
    -o 'Full backup' \
    -o 'Backup MySQL databases' \
    --back --exit

    case $REPLY in
      1 ) full_backup -v;;
      2 ) backup_mysql_tables -v;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
full_backup()
{
  local dbuser=root
  
read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Make a full backup of your server

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-d|--directory directory] [--dbuser username] [--dbpass password]  [--remote-url url] [--remote-user user] [--remote-password password] [--expire]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

DESCRIPTION
    Use the folowing command to restore a backup.
    cd / && tar -xvpf fullbackup-xxx-xx-xx.tar

OPTIONS
     -d, --directory
        Local backup directory.
    --dbuser
        MySQL database root user.
    --dbpass
        MySQL database password.
    -u, --user
        Remote user.
    -m, --method
        Transfer method (default: $method)
    --host
        Remote host name.
    -p, --password
        Remote password.
    -s, --source
        Local folder (default: $source).
    -t, --target
        Remote folder (default: $target).
    --help -h
        This help screen.

EXAMPLES
   ${BASH_SOURCE##*/} ${FUNCNAME} -d="$directory" --db-user=$dbuser --db-password=password

$global_help
EOF

  local ARGS=$(getopt -o "+d:h" -l "+directory:,db-user:,db-password:,method:,host:,user:,password:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -d|--directory) shift; directory="${1:-$directory}"; shift;;
      --db-user) shift; dbuser="${1:-$dbuser}"; shift;;
      --db-password) shift; dbpass="${1}"; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; return;;
      -v|--verbose) shift; verbose=1;;
      --) shift; break;;
    esac
  done

  [[ $dbuser && ! $dbpass ]] && read -s -r -p "Database $dbuser password: " dbpass ; echo
  [[ $remote_user && ! $remote_password ]] && read -s -r -p "Remote password: " remote_password
     
  local backup_directory="$directory"
  
  # Ask confirmation before continue
  if [[ $verbose ]]; then
    echo "Full backup will process in $backup_directory in 20s."
    read -n 1 -t 20 -p "Do you want to continue ? [yN]:" reply ; echo ; [[ ! $reply =~ [[=y=]] ]] && return
  fi
  
  # Create a new backup directory and cd in
  [ -d "$backup_directory" ] && rm -Rf "$backup_directory"
  mkdir -p "$backup_directory"
  cd "$backup_directory" 
  
  # Create the restoration script
  echo "#!/bin/bash" > restore.sh
  echo 'cd "$(dirname $0)"' >> restore.sh
  chmod u+x restore.sh
  
  [[ $verbose ]] && echo "Backup main system files to $backup_directory." 
  backup_files -d "$backup_directory" --exclude "$directory"
  
  # Backup all databases
  [[ $verbose ]] && echo "Dump MySQL databases to ${backup_directory%/}/mysql."  
  if [[ $dbpass ]]; then
    #mysqldump --user="$dbuser" --password="$dbpass" --all-databases > "mysql-databases.sql"
    backup_mysql_tables -u "$dbuser" -p "$dbpass" -d "${backup_directory%/}/mysql"
  else
    #mysqldump --user="$dbuser" --password --all-databases > "mysql-databases.sql"
    backup_mysql_tables -u "$dbuser" -d "${backup_directory%/}/mysql"
  fi    
  echo "read -n 1 -p 'Do you want to restore MySQL databases ? [yN]:' reply ; echo ; [[ \$reply =~ [[=y=]] ]] && mysql -u='$dbuser' -p < '${backup_directory%/}/mysql/restore.sql'" >> restore.sh

  [[ $verbose ]] && echo "Backup debconf database." 
  backup_debconf_db
  
  [[ $verbose ]] && echo "Tidy up backups." 
  tidy_up_backups -d "$directory"   
  
  #if [[ $host ]]; then
  #  [[ $verbose ]] && echo "Upload $directory folder to $host$target." 
  #  sync_backups --source "$directory" --target "$target" \
  #  --method 'ftp' --host "$host" --user "$user" --password "$password"
  #fi
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
backup_mysql_tables()
{
  [ ! $(which mysqldump) ]  >&2&& return 1

  local backup_dir="$PWD"  
  
read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Backup MySQL databases / tables in separate SQL files.

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-u|--user user] [-p|--password password] [-c|--compress] [directory]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -c, --compress
        Create an archive for each database. 
    -u, --user
        A mySQL user allowed to run mysql_dump command.
    -p, --password
        MySQL user password.
    -h, --help
        Print this help screen and exit.
    -q, --quiet
        Don't prompt user.
    -v, --verbose
        Display some informations during backup.

EXAMPLES
    ${BASH_SOURCE##*/} ${FUNCNAME} -u root -p /var/backup --daily 7 --weekly 30 --monthly 365

$global_help
EOF

  local ARGS=$(getopt -o "u:p:chqv" -l "user:,password:,compress,quiet,verbose,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -c|--compress) shift; compress=1;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; return;;
      -p|--password) shift; mysql_pass="${1}"; shift;;      
      -q|--quiet) shift; quiet='--quiet';;
      -u|--user) shift; mysql_user="${1:-$mysql_user}"; shift;;
      -v|--verbose) shift; verbose=1;;
      --) shift; break;;
    esac
  done
  
  [ -n "$1" ] && local backup_dir="${1:-$backup_dir}" && shift 
  
  [ ! -d "$backup_dir" ] && mkdir -p "$backup_dir"
  
  #[[ ! $mysql_pass ]] && read -s -r -p "MySQL $mysql_user password: " mysql_pass ; echo
  local mysql_user="$(edit_var --text -p 'MySQL user' -v root --save $quiet mysql_user && echo $mysql_user)" 
  local mysql_pass="$(edit_var --password -p 'MySQL '$mysql_user' password' --save $quiet mysql_password && echo $mysql_password)"
  
  #echo -e "backup_dir:$backup_dir\nmysql_user:$mysql_user\nmysql_pass:$mysql_pass"  >&2; exit
  
  # Check all databases
  #mysqlcheck -u$mysql_user -p$mysql_pass --all-databases --optimize --auto-repair --silent 2>&1
  
  # Get database list
  local databases=$(mysql --user=$mysql_user --password=$mysql_pass --exec="SHOW DATABASES;" |  tail -n +2)
  for database in $databases; do
    
    [[ $verbose ]] && echo -e "${IFS}Dump database $database${IFS}"
    mkdir -p "${backup_dir}/${database}"

    [[ $verbose ]] && echo "Dump each tables in $backup_dir directory."
    tables=$( mysql -u$mysql_user -p$mysql_pass -D$database -e 'show tables' | egrep -v 'Tables_in_' )
    for table in $tables; do
      [[ $verbose ]] && echo -n "$table "
      # Dump table structures
      mysqldump --no-data --user="$mysql_user" --password="$mysql_pass" $database $table > "${backup_dir}/${database}/create_tables.sql"
      # Dump each table in a distinct .sql
      mysqldump --user="$mysql_user" --password="$mysql_pass" $database $table > "${backup_dir}/${database}/restore_${table}.sql"
      # Create a .sql for this database calling each dumps
      echo 'source "restore_'${table}'.sql"' >> "${backup_dir}/${database}/restore.sql"
    done
    [[ $verbose ]] && echo

    # Create a global .sql calling each database install script
    echo 'source "'${database}'/restore.sql"' >> "${backup_dir}/restore.sql"
    
    # Compress each database directories in a distinct archive
    if [[ $compress ]]; then
      [[ $verbose ]] && echo "Compress $backup_dir/${database} to $backup_dir/${database}.sql.gz"
      tar -zcf "${backup_dir}/${database}.tar.gz" --remove-files "${backup_dir}/${database}"
    fi
    
  done
  [[ $verbose ]] && echo "End of MySQL backup"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
backup_files()
{
  local backup_directory="$PWD"
  local exclude=()
  local tar_options='-zp'  

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Backup files and other stufs

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-d|--directory directory]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -d, --directory
        Local backup directory.
    -e, --exclude
        Exclude a file or directory.
    --help -h
        This help screen.

EXAMPLES
   ${BASH_SOURCE##*/} ${FUNCNAME} -d="$directory"

$global_help
EOF

  local ARGS=$(getopt -o "+d:e:h" -l "+directory:,exclude:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -d|--directory) shift; backup_directory="${1:-$backup_directory}"; shift;;
      -e|--exclude) shift; exclude+=("$1"); shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; return;;
      -v|--verbose) shift; verbose=1;;
      --) shift; break;;
    esac
  done

  [[ $verbose ]] && tar_options="$tar_options -v"  
  
  # Create the backup directory and cd in
  [ -d "$backup_directory" ] && rm -Rf "$backup_directory"
  mkdir -p "$backup_directory"
  cd "$backup_directory"  
  
  # Create the restoration script
  [ ! -e 'restore.sh' ] && echo "#!/bin/bash" > restore.sh && chmod u+x restore.sh
  
  [[ $verbose ]] && echo "Web backup..."
  filename="web_datas.tar.gz"
  tar $tar_options -c -f "${filename}" \
  --directory=/var/www \
  --exclude=*${TMPDIR}/* --exclude=*/cache/* --exclude=*/temp/* --exclude=*/session/* --exclude=*/backup/* \
  --exclude=*subdomains.aufs/* \
  --exclude="${backup_directory%/}" $(printf ' --exclude %s' $exclude) \
  .
  echo "read -n 1 -p 'Do you want to restore web files ? [yN]:' reply ; echo ; [[ \$reply =~ [[=y=]] ]] && tar -xf -zv --directory=/ '$filename'" >> restore.sh

   [[ $verbose ]] && echo "Mail backup..."
  filename="mail_datas.tar.gz"
  tar $tar_options -c -f "${filename}" \
  --directory=/var/mail \
  --directory=/var/vmail \
  --exclude="${backup_directory%/}" $(printf ' --exclude %s' $exclude) \
  .
  echo "read -n 1 -p 'Do you want to restore web files ? [yN]:' reply ; echo ; [[ \$reply =~ [[=y=]] ]] && tar -xf -zv --directory=/ '$filename'" >> restore.sh

  [[ $verbose ]] && echo "User files backup..."
  filename="users_datas.tar.gz"
  tar $tar_options -c -f "${filename}" \
  --directory=/root/ --directory=/home/ \
  --directory=/usr/local/bin/ \
  --exclude="${backup_directory%/}" $(printf ' --exclude %s' $exclude) \
  .
  echo "read -n 1 -p 'Do you want to restore user files ? [yN]:' reply ; echo ; [[ \$reply =~ [[=y=]] ]] && tar -xf -zv --directory=/ '$filename'" >> restore.sh
  
  [[ $verbose ]] && echo "System files backup..."
  filename="system_files.tar.gz"
  tar $tar_options -c -f "${filename}" \
  --directory=/etc/ \
  --exclude=/var/lib/mysql \
  --exclude=/var/backups --exclude=/var/cache \
  --exclude=/var/backup --exclude=/var/archives \
  --exclude=*.zip --exclude=*.tar --exclude=*.tar.gz \
  --exclude="${backup_directory%/}" $(printf ' --exclude %s' $exclude) \
  .
  echo "read -n 1 -p 'Do you want to restore system files ? [yN]:' reply ; echo ; [[ \$reply =~ [[=y=]] ]] && tar -xf -zv --directory=/ '$filename'" >> restore.sh 

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
backup_debconf_db()
{

  [[ ! $(which dpkg) ]] && return 1

  # Create the restoration script
  [ ! -e 'restore.sh' ] && echo "#!/bin/bash" > restore.sh && chmod u+x restore.sh
  
  [[ ! $(which debconf-get-selections) ]] && __package_cp -q install debconf-utils
  if [[ $(which debconf-get-selections) ]]; then
    echo "Debconf backup..."
    filename='debconf.seed'
    debconf-get-selections > "$filename"
    echo "cat '$filename' | debconf-set-selections" >> restore.sh   
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tidy_up_backups()
{
  local backup_dir="$PWD"
  local daily_expire=7
  local weekly_expire=31
  local monthly_expire=365
  local weekly_day='0'
  local monthly_day='01'
      
read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Manage daily, weekly and monthly backups.

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [--daily-expire integer] [--weekly-expire integer] [--monthly-expire integer] [--weekly-day integer] [--monthly-day integer] [directory]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    --daily-expire
        Daily backup older than n days will be delete (default: $daily-expire).
    --weekly-expire
        Weekly backup older than n days will be delete (default: $weekly-expire).
    --monthly-expire
        Monthly backup older than n days will be delete (default: $monthly-expire).
    --weekly-day
        The day of the week when backups will be keeped from 0 (sunday) to 6 (default: $weekly_day).
        You can provide several values with a | delimiter.
    --monthly-day
        The day of the month when backups will be keeped from 01 to 31 (default: $monthly_day).
        You can provide several values with a | delimiter.
    -h, --help
        Print this help screen and exit.

EXAMPLES
    ${BASH_SOURCE##*/} ${FUNCNAME} -u root -p /var/backup --daily 7 --weekly 30 --monthly 365

$global_help
EOF

  local ARGS=$(getopt -o "+d:h" -l "+daily-expire:,weekly-expire:,monthly-expire:,weekly-day:,monthly-day:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      --daily-expire) shift; daily_expire="${1:-$daily_expire}"; shift;;
      --weekly-expire) shift; weekly_expire="${1:-$weekly_expire}"; shift;;
      --monthly-expire) shift; monthly_expire="${1:-$monthly_expire}"; shift;;
      --weekly-day) shift; weekly_day="${1:-$weekly_day}"; shift;;
      --monthly-day) shift; monthly_day="${1:-$monthly_day}"; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; return;;
      --) shift; break;;
    esac
  done

  [ -n "$1" ] && local backup_dir="${1:-$backup_dir}" && shift  
  
  # Creates daily, weekly and monthly directories if they do not already exists
  [ ! -e "$backup_dir/daily" ] && mkdir -p "$backup_dir/daily"
  [ ! -e "$backup_dir/weekly" ] && mkdir -p "$backup_dir/weekly"
  [ ! -e "$backup_dir/monthly" ] && mkdir -p "$backup_dir/monthly"

  # Move files in root directory to a daily directory
  mkdir -p "$backup_dir/daily/"$(date +%Y-%m-%d)
  #find "$backup_dir" -mindepth 1 -maxdepth 1 ! -name daily ! -name weekly ! -name monthly $verbose -exec mv -f -t "$backup_dir/daily/"$(date +%Y-%m-%d) "{}" \;
  find "$backup_dir" -mindepth 1 -maxdepth 1 ! -name daily ! -name weekly ! -name monthly $verbose -exec sh -c 'mv -f -t "'$backup_dir'/daily/"$(date --rfc-3339 date -d @$(stat -c %Z "{}")) "{}"' \;
  
  # Move backups of the daily directory to monthly directory if they match month day 
  while read filename; do
    mv -f -t "$backup_dir/monthly/" "$filename"
  done < <(find "$backup_dir/daily/" -mindepth 1 -maxdepth 1 -type d -printf "%Td\t%p${IFS}" | grep -P '^('$monthly_day')' | cut -f 2-)
  
  # Move backups of the daily directory to monthly directory if they match week day
  while read filename; do
    mv -f -t "$backup_dir/weekly/" "$filename"
  done < <(find "$backup_dir/daily/" -mindepth 1 -maxdepth 1 -type d -printf "%Tw\t%p${IFS}" | grep -P '^('$weekly_day')' | cut -f 2-)
  
  # Delete expired backups
  find "$backup_dir/daily/" -mindepth 1 -maxdepth 1 -type d -mtime +$daily_expire $verbose -delete
  find "$backup_dir/weekly/" -mindepth 1 -maxdepth 1 -type d -mtime +$weekly_expire $verbose -delete
  find "$backup_dir/monthly/" -mindepth 1 -maxdepth 1 -type d -mtime +$monthly_expire $verbose -delete 
  
  # Moves old daily backups in the weekly folder
  #find "$backup_dir/daily/" -mindepth 1 -maxdepth 1 -type d -mtime +$daily_expire $verbose -exec mv -f -t "$backup_dir/weekly/" "{}" \;
  # Moves old weekly backups in the monthly folder
  #find "$backup_dir/weekly/" -mindepth 1 -maxdepth 1 -type d -mtime +$weekly_expire $verbose -exec mv -f -t "$backup_dir/monthly/" "{}" \;
  # Delete old backups
  #find "$backup_dir/daily/" -mindepth 1 -maxdepth 1 -type d -mtime +$daily_expire $verbose -delete 
  # Delete weekly backup excepted fo sunday  
  #rm -Rf  $verbose $(find "$backup_dir/weekly/" -mindepth 1 -maxdepth 1 -type d -printf "%Tw\t%p${IFS}" | grep -Pv '^('$weekly_day')' | cut -f 2-)
  # Delete monthly backups excepted the first day of the month 
  #rm -Rf  $verbose $(find "$backup_dir/monthly/" -mindepth 1 -maxdepth 1 -type d -printf "%Td\t%p${IFS}" | grep -Pv '^('$monthly_day')' | cut -f 2-)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sync_backups()
{

  local method=ftp
  local host user password
  local source=$PWD
  local target=/
 
read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Mirror local backups to a remote server

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-s|--source path] [-t|--target path] [-m|--method ftp] -h|--host username [-u|--user username] [-p|--password password]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -u, --user
        Remote user.
    -m, --method
        Transfer method (default: $method)
    --host
        Remote host name.
    -p, --password
        Remote password.
    -s, --source
        Local folder (default: $source).
    -t, --target
        Remote folder (default: $target).
    --help -h
        This help screen.

EXAMPLES
   (sudo) bash ${BASH_SOURCE##*/} ${FUNCNAME} -d="$directory" --dbuser=$dbuser --dbuser=password --remote-url="ftp://user:pass@ip/path/" --remote-user="user:pass" --e=$expire

$global_help
EOF

  local ARGS=$(getopt -o "+s:t:m:u:p:h" -l "+source:,target:,method:,host:,user:,password:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -s|--source) shift; source="${1:-$source}"; shift;;
      -t|--target) shift; target="${1:-$target}"; shift;;
      -m|--method) shift; method="${1:-$method}"; shift;;
      --host) shift; host="${1:-$host}"; shift;;
      -u|--user) shift; user="${1:-$user}"; shift;;
      -p|--password) shift; password="${1:-$password}"; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; return;;
      --) shift; break;;
    esac
  done
 
  case method in
    #curl-ftp)
    #  local url="ftp://${host%/}${target%/}/"
    #  if [ -z $(curl -I --stderr /dev/null "$url" | head -1 | cut -d' ' -f2) ]; then
    #    cd "$source"; find . -type f -exec curl --user "$user:$password" --ftp-create-dirs -T {} "${url%/}/$(basename $source)/"{} \;
    #    #cd /var/archives/ && wput --skip-existing . "ftp://freebox:pass@192.168.0.254/Disque dur/Sauvegardes/server1/backup-manager/"
    #  else
    #    echo -e "\e[31m$remote_url doesn't exists so download will not be transfered.\e[0m"
    #  fi
    #;;
    rsync)
      rsync "$source" "${user:+$user@}${host}${port:+:$port}${target}"
      ;;
    *|ftp )
      [[ ! $(which lftp) ]] && package_cp install lftp
      lftp -f <<EOF
open $host
user $user $pass
lcd $source
mirror --reverse --delete --verbose $source $target
bye
EOF
      ;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
safe_cp()
{
read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Make a safe copy of a folder and is content including hidden files and preserving informations.

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [source] [destination]

OPTIONS
    --help -h
        This help screen.

EXAMPLES
   (sudo) bash ${BASH_SOURCE##*/} ${FUNCNAME} /etc /var/backup

$global_help
EOF

  [[ $# != 2 ]] && echo "${IFS}${help}${IFS}"  >&2 && exit 65
  
  [[ ! -d $1 ]] && echo "'$1' is not a valid directory."  >&2 && exit 1

  src=${1%/}
  dst=${2%/}
  
  [ ! -d "$dst" ] && mkdir -p "$dst"
  cp -rpfP "${src%/}/"{*,.??*} "${dst%/}"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
usb_backup()
{
  local destination='/Sauvegardes/'$(hostname -s)'/mirror/'
  local source='/'
  local exclude_options='--exclude /bin --exclude /dev/pts --exclude /media \
  --exclude /mnt --exclude /proc --exclude /sys --exclude ${TMPDIR} \
  --exclude '"'"'^.*/backups?$'"'"
  
  # Ask user to select USB media
  local list=$(find /media -mindepth 1 -maxdepth 1 -path "/media/usb*" -not -empty -type d | sort)
  # Install usbmount if no USB media available
  if [ -z "$list" ]; then
    __package_cp install usbmount
    echo -e 'No USB drive detected.\nTry to reinsert USB device then try again.'
    return 1    
  fi
  echo 'Destination drive'
  local media=$(select v in $list; do [ -n "$v" ] && echo $v && break; done)
  destination="${media}${destination%/}"
 
  echo 'Checking free space...'
  source_size=$(du -s $exclude_options "$source" 2> /dev/null | awk '{print $1}')
  destination_space=$(df "$media" | tail -n+2 | awk '{print $4}')
  [[ $destination_space < $source_size ]] && echo "Try to free up $(( $source_size-$destination_space ))Ko on $media."  >&2&& return 1
  
  # Create backup directory
  if [ -d "$destination" ]; then
    echo "$destination already exists and will be deleted."
    read -n 1 -p "Do you want to continue ? [yN]:" reply ; echo ; [[ ! $reply =~ [[=y=]] ]] && return
    rm -Rf "$destination"
  else
    mkdir -p "$destination"
  fi
  
  [ ! -d "$destination" ] && echo "$destination can't be created.\n Try to run 'fsck $media' then reconnect the drive."  >&2&& return 1
  echo "Copy $source (${source_size}Ko) to $destination (${destination_space}Ko available)."
  rsync -a $exclude_options "$source" "$destination"
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_backup_manager ()
{

  __package_cp install backup-manager backup-manager-doc

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
configure_backup_manager ()
{

  editor ${config_path}backup-manager.conf

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#mirror_debian_machine()
#{
#  mysqldump --add-drop-table --extended-insert --force --log-error=error.log -uUSER -pPASS OLD_DB_NAME | ssh -C user@newhost "mysql -uUSER -pPASS NEW_DB_NAME"
#  remotehost 'dpkg --get-selections' | dpkg --set-selections && dselect install
#}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='Backup functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"