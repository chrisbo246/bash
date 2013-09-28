#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__mysql_menu ()
{
  while true; do
    __menu \
    -t 'MySQL Database' \
    -o 'Install MySQL' \
    -o 'Install PHPMyAdmin' \
    -o 'Uninstall MySQL' \
    -o 'Move Data directory' \
    -o 'Use previous data directory' \
    -o 'Change root password' \
    -o 'Backup Databases' \
    -o 'Reset Root password' \
    -o 'Configure MySQL' \
    -o 'Securize MySQL' \
    -o 'Set MySQL remotely accessible' \
    -o 'Set MySQL localy accessible' \
    --back --exit

    case $REPLY in
      1) install_mysql;;
      2) install_phpmyadmin;;
      3) uninstall_mysql;;
      4) move_mysql_data_dir;;
      5) set_mysql_data_dir;;
      6) change_mysql_root_pwd;;
      7) backup_mysql_databases;;
      8) reset_mysql_pwd;;
      9) configure_mysql;;
      10) install_secure_mysql;;
      11) set_mysql_remote;;
      12) set_mysql_local;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__mysql_config()
{
  #mysql_config=$( find / -type f -name "my.cnf" -exec grep -l "bind-address" {} \; )
  #mysql_service=$( find / -type f -path "*/init.d/*" -name "mysql" )

  #running_test
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_mysql ()
{

  echo "Uninstall MySQL..."

  ${service_path}mysql stop
  pgrep -u mysql mysqld > sudo kill

  sudo __package_cp -f install
  sudo __package_cp -fy --purge mysql-server mysql-client mysql-common libdbd-mysql-perl

  sudo rm -rfv ${config_path}mysql/*

  sudo __package_cp update

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_mysql ()
{

  #${service_path}mysql reset-password  # Réinitialise me mot de passe root vide

  __package_cp -u install mysql-server mysql-client mysql-common libdbd-mysql-perl libapache2-mod-auth-mysql
  #sudo __package_cp -y install mysql-doc-5.0
  sudo dpkg --configure -a

  # Réinitialise la configuration d'apparmor
  # sudo sed "s|^[ \t]*(.*)mysql.sock rw|/var/lib/mysql/mysql.sock rw\$|" "${config_path}apparmor.d/abstractions/mysql"
  # sudo sed "s||/var/lib/mysql/ r,|" "${config_path}apparmor.d/usr.sbin.mysqld"
  # sudo sed "s||/var/lib/mysql/** rwk,|" "${config_path}apparmor.d/usr.sbin.mysqld"

  sudo mkdir -p ${config_path}mysql/conf.d/
  if [ -e ${config_path}mysql/conf.d/old_passwords.cnf ];
  then
    echo "
# created by debconf
[mysqld]
old_passwords = false
    " | sudo tee ${config_path}mysql/conf.d/old_passwords.cnf
  fi

  echo "Replace MySQL data directory by default value (/var/lib/mysql/) in followed files"
  editor "${config_path}apparmor.d/abstractions/mysql"
  editor "${config_path}apparmor.d/usr.sbin.mysqld"

  # Sécurise l'installation
  mysql_secure_installation

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_postgres()
{

  __package_cp -u install postgresql libapache2-mod-auth-pgsql

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_mysql_data_dir()
{

  # Select current data dir
  current_data_dir=$( get_confvar '$mysql_config' 'datadir' )
  echo "MySQL data dir is set to $current_data_dir
  Press ENTER if correct or enter the real data dir"
  read real_data_dir
  if [ "real_data_dir" != '' ]; then
    current_data_dir=$( check_dir $real_data_dir )
  fi

  # Select new data dir
  echo 'Enter new data path (ex: /var/lib/mysql/) : '
  read mysql_data_dir
  new_data_dir=$( check_dir $mysql_data_dir )

  search=$( echo "$current_data_dir" | sed 's|/$||' )
  replace=$( echo "$new_data_dir" | sed 's|/$||' )

  #Enregistrez ce fichier sous ${config_path}mysql/conf.d/datadir.cnf (le nom du fichier doit obligatoirement se terminer par .cnf). Ce fichier ne sera pas écrasé lors d'une mise à jour de MySQL et les directives qu'il contient prennent le pas sur celles du fichier de configuration global $mysql_config
  # créer un nouveau fichier avec les droits du super-utilisateur (gksudo gedit) et y placer les lignes suivantes :
  #echo "
  #[mysqld]
  #datadir = $replace
  ## chroot = $replace
  #" | sudo tee -a ${config_path}mysql/conf.d/datadir.cnf
  #editor ${config_path}mysql/conf.d/datadir.cnf

  # Edit the MySQL configuration file with the command
  gksu set_confvar '$mysql_config' 'datadir' "$replace"
  gksu set_confvar '$mysql_config' 'chroot' "$replace"
  # gksu editor $mysql_config

  # Si vous avez *apparmor* activé vous devez modifier sa configuration et recharger les règles avant de relancer mysqld.
  sudo sed -ir "s|$search|$replace|g" ${config_path}apparmor.d/usr.sbin.mysqld
  sudo rm ${config_path}apparmor.d/usr.sbin.mysqld~

  ${service_path}mysql stop

  read -p"Do you want to move datas from '$current_data_dir' to '$new_data_dir' ? (y/N) : " choice
  case $choice in
    y,Y,yes,YES)

      # Copy the existing data directory (which is located in /var/lib/mysql) using the command
      sudo cp -R -p $search $replace

      # All you need are the data files. Delete the others with the command
      #(You will get a message about not being able to delete some directories, but do not care about them)
      sudo rm $replace
      # Supprimer les fichiers copiés ib_logfile0, ib_logfile1, etc. :
      # sudo rm $replace/ib*

      # Réattribuer les fichiers à l'utilisateur mysql :
      # sudo chown -R mysql: $replace

    ;;
    default)
      echo "Keep datas at '$new_data_dir'"
  esac

  # Reload the AppArmor profiles with the command
  ${service_path}apparmor reload
  # Restart MySQL with the command
  ${service_path}mysql restart

}

move_mysql_data_dir2 ()
{

  set_mysql_data_dir

  echo "MySQL data dir is set to $current_data_dir
  Press ENTER is correct or enter the real data dir"
  read current_data_dir
  if [ "current_data_dir" != '' ]; then
    new_data_dir=$( check_dir $mysql_data_dir )
  fi

  ${service_path}mysql stop

  # Déplace le dossier
  sudo mkdir -p "$new_data_dir"
  sudo chown -R mysql:mysql "$new_data_dir"

  # Via lien symbolique
  # ln -s /var/lib/mysql/mysql "$new_data_dir"
  #sudo service mysql reload

  sudo cp -R -p "$current_data_dir" "$new_data_dir"
  sudo chown -R mysql:mysql "$new_data_dir"

  # Déplacer les données
  #echo "Move data directory..."
  #sudo cp -a "$current_data_dir*" "$new_data_dir"
  #sudo rm -rf "$current_data_dir"

  sudo service mysql start

  echo 'You must reboot to take effect.'
  read -p'Do you want to reboot now ? (y/N)' choice
  case $choice in
    y,Y,yes,YES)
    reboot ;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Move data dir from old path to defined path

set_mysql_data_dir()
{

  # Valeur par defaut: /var/lib/mysql/
  current_data_dir=$( get_confvar '$mysql_config' 'datadir' )

  echo 'Enter new data path (ex: /var/lib/mysql/) : '
  read mysql_data_dir
  new_data_dir=$( check_dir $mysql_data_dir )

  search=$( echo "$current_data_dir" | sed 's|/$||' )
  replace=$( echo "$new_data_dir" | sed 's|/$||' )

  # Modifie chaque fichier contenant l'ancien chemin
  # grep -lre "$search" "${config_path}" | while read path; do
  #   sed -ir "s|$search|$replace|g" "$path"
  #   editor $path
  # done

  # Pour personnaliser l'emplacement des bases de données, modifier la variable datadir:
  set_confvar '$mysql_config' 'datadir' "$new_data_dir"
  set_confvar '$mysql_config' 'chroot' "$new_data_dir"
  enable_confvar '$mysql_config' 'chroot'
  #sudo sed -ir "s|mysql:*$search*$|$replace|g" ${config_path}passwd

  sudo sed -ir "s|$search|$replace|g" ${config_path}passwd
  sudo sed -ir "s|$search|$replace|g" ${config_path}passwdr
  sudo sed -ir "s|$search|$replace|g" ${config_path}passwd-

  # Configuration pour Apparmor
  sudo sed -ir "s|$search|$replace|g" ${config_path}apparmor.d/abstractions/mysql
  sudo sed -ir "s|$search|$replace|g" ${config_path}apparmor.d/abstractions/mysqlr
  sudo sed -ir "s|$search|$replace|g" ${config_path}apparmor.d/usr.sbin.mysqld
  sudo sed -ir "s|$search|$replace|g" ${config_path}apparmor.d/usr.sbin.mysqldr

  sudo service apparmor reload
  sudo service mysql reload

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set / change / reset the MySQL root password on Ubuntu Linux.

reset_mysql_pwd ()
{

  # Perte du mot de passe mysql
  # ${service_path}mysql reset-password  # Réinitialise me mot de passe root vide
  read -p"Enter new mysql password : " password

  # Stop the MySQL Server.
  ${service_path}mysql stop
  pgrep -u mysql mysqld > sudo kill
  #kill_service mysql

  echo "UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root'; FLUSH PRIVILEGES;" | sudo tee /root/mysql.reset.sql

  mysqld_safe --init-file=/root/mysql.reset.sql &

  sudo killall mysqld
  ${service_path}mysql start

  # Start the mysqld configuration.
  # sudo mysqld --skip-grant-tables &
  # Login to MySQL as root.
  # mysql -u root mysql; UPDATE user SET Password=PASSWORD('$password') WHERE User='root'; FLUSH PRIVILEGES; exit;

  # Ou reconfiguration
  # sudo dpkg-reconfigure mysql-server-5.0

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
configure_mysql ()
{

  sudo dpkg-reconfigure mysql-server-5.0     # On peu par la suite modifier le mot de passe MySQL

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Par défaut, on peut accéder aux bases de données MySQL avec le login « root » et sans mot de passe (ou mot de passe demandé à l'installation).
# Création d'un nouvel utilisateur et suppression de l'utilisateur "root"

install_secure_mysql ()
{
  sudo -i mysql_secure_installation

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Pour se connecter à la base à distance

set_mysql_remote ()
{

  # Décommentez la ligne suivante:
  set_confvar "$mysql_config" "bind-address" "127.0.0.1"
  enable_confvar "$mysql_config" "bind-address"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set_mysql_local ()
{

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_phpmyadmin ()
{

  echo "Install PHPmyAdmin..."

  __package_cp -u install phpmyadmin                                                 # Instaler PHPmyAdmin et mcrypt
  sudo ln -sf /usr/share/phpmyadmin/ ${project_path}phpmyadmin  # Créer un lien symbolique à la racine du
  sudo chmod 644 /usr/share/phpmyadmin/config.inc.php           # Modifier les modes d'accès du fichier

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
create_mysql_backup_user()
{

  read -p"MySQL user name : " username
  read -p"$username password : " password

  mysql --user=root -p mysql -u[user] -p[pass] <<EOF
CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';
GRANT SELECT, RELOAD, SHOW DATABASES, LOCK TABLES ON *.* TO '$username'@'localhost'
EOF

  #    CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';
  #  GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost'
  #  WITH GRANT OPTION;
  #  CREATE USER '$username'@'%' IDENTIFIED BY '$password';
  #  GRANT ALL PRIVILEGES ON *.* TO '$username'@'%'
  #  WITH GRANT OPTION;
  #  CREATE USER 'admin'@'localhost';
  #  GRANT RELOAD,PROCESS ON *.* TO 'admin'@'localhost';
  #  CREATE USER 'dummy'@'localhost';

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Executer avec nohup pour éviter les problemes de déconnexion
# nohup batch_script.sh

# CREATE USER user [IDENTIFIED BY [PASSWORD] 'password'
# mysql -uroot -p -e"SELECT, RELOAD, SHOW DATABASES, LOCK TABLES"

# 1. Create a MySQL user, e.g. "backup", with:
# - Host: localhost (only)
# - Global privilege: RELOAD (maybe you need to activate this at Tools - Preferences - Administrator before)
# - Scheme privileges (for the DB you want to backup): SELECT, LOCK_TABLES
#
# 2. Go to Tools - Preferences:
# - General Options: Store connection passwords: yes, Store Method: Obscured
# - Connections - Add Connection:
# - Name: backup
# - User: backup (the one we have just created)
# - Password: <enter the password>
# - Hostname and port, normally localhost and 3306
#
# 3. Backup - New Project:
# - Backup-Project:
# - Name: <whatever>
# - Database: (the DB we want do backup)
# - Advanced settings:
# - Lock all tables: yes
# - Backup whole DB: yes
# - Schedule Backup:
# - Select period, time, target and prefix
# - Connection name: backup (we have created that before)
# - Save and wait until the backup starts (or execute manually)
#
# I experienced, that the message "Backup error: Cannot flush tables with read lock" occurs, when you do not select the option "Store connection passwords: yes".
#
# The message "Cannot load specified connection" occurred, when running the mabackup as a user that has no subdirectory called ".mysqlgui" in his home directory. In this directory MySQL saves the connection information. I created a symbolic link from the home directory of the user to the .mysqlgui directory - that worked for me.
#
# Additional information:
# - I have no system user with the same name as the MySQL backup user
# - It also worked with different names for the backup user and the backup project
# - I can start the mabackup as a different user than root
# - The user who is running the mabackup, needs write privileges at the target (path to your backup file)
# - If you activate "Store connection passwords: yes", also the password for root will be stored and permit other users to login as root (if you start the MySQL Administrator GUI, the root password is already entered). To avoid this, I created another connection (Tools - Preferences - Connections - Add Connection) called "root", with the user root but no password, and deleted the other connections where the user is root and the password was entered (there is a folder called "history").

backup_mysql_databases ()
{

  ask_var 'mysql_user' 'Enter a MySQL user allowed to dump database: '
  ask_var 'mysql_pass' 'Enter MySQL user password : '
  ask_var 'mysql_backup_dir' 'Choose a directory to store database dumps : '
  mysql_backup_dir=$( check_dir mysql_backup_dir )
  ask_var 'mysql_keep_backup' 'How many days do you want to keep backups : '

  #Suppression des anciennes sauvegardes
  old_date=$(date --date "${mysql_keep_backup} days ago" +%Y-%m-%d)
  echo "["$(date +%F\ %X)"] Suppress dumps older than $old_date days"
  find $mysql_backup_dir -ctime +$mysql_keep_backup -exec rm -rf {} \;

  #mémorisation de la date du jour et de la date d'il y a 7 jours
  date=$(date +%Y-%m-%d)
  backup_dir="${mysql_backup_dir}/${date}"
  sudo mkdir -p $backup_dir
  cd $backup_dir

  # récupération de la liste des bdd, "tail -n +2" est présent pour ne pas récupérer le titre "Databases" renvoyé par mysql
  databases=$(mysql --user=$mysql_user --password=$mysql_pass --exec="SHOW DATABASES;" |  tail -n +2)

  #dump de chaque base dans un fichier
  echo "["$(date +%F\ %X)"] Dump at "$date
  for database in $databases
  do
    echo -e "${IFS}["$(date +%F\ %X)"] Dump database $database${IFS}"

    # Dump all tables in the same file
    # mysqldump --user="$mysql_user" --password="$mysql_pass" "$database" | gzip > "$backup_dir"/"$database".sql.gz
    # echo "["$(date +%F\ %X)"] Dump compressé dans "$backup_dir"/"$database".sql.gz"

    # Crée un dossier par base pour stocker chaque tables
    mkdir -p "${database}"

    # Récupère la liste des tables
    tables=$( mysql --user=$mysql_user --password=$mysql_pass --database=$database --exec='show tables' | egrep -v 'Tables_in_' )

    echo "Dump each tables in ${backup_dir} directory : "
    for table in $tables;
    do
      echo -n "$table "
      # mysqldump --opt -Q $database $table > $table.sql
      mysqldump --user="$mysql_user" --password="$mysql_pass" -Q $database $table > "${database}/${table}.sql"
      #bzip2 $table.sql
    done
    echo " "

    # Zip les tables
    echo "Compress ${backup_dir}/${database} to ${backup_dir}/${database}.sql.gz"
    tar -zcf "${database}.tar.gz" --remove-files "${database}"
    #bzip2 "${backup_dir}/${database}"

  done
  echo "["$(date +%F\ %X)"] Fin de la sauvegarde"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
transfert_mysql()
{
  [[ ! "$declare -Ff 'menu'" ]] && . $ echo `dirname   #. global.sh

  `/ ${file_prefix}helpers.sh  # local
  mysql_user='root'
  web_directory='/var/www'
  mail_directory='/var/mail'

  # remote
  remote_mysql_user='root'
  remote_web_directory='/var/www'
  remote_mail_directory='/var/mail'

  #remote_hostname='192.168.0.2'
  read -p "Remote hostname : " remote_hostname

  # Le serveur distant est la : source | destination
  remote_is='destination'

  stty -echo
  read -p "Local MySQL password for '$mysql_user' user : " mysql_pass
  echo
  read -p "Remote MySQL password for '$remote_mysql_user' user : " remote_mysql_pass
  stty echo

  mysql_local_options="--user=$mysql_user --password=$mysql_pass"
  mysql_remote_options="--host $remote_hostname --user=$remote_mysql_user --password=$remote_mysql_pass"

  echo "To allow remote access to mysql, bind-address must allow '$remote_hostname' in ${config_path}mysql/my.cnf"

  case $remote_is in

    # La base de données est située sur ce serveur
    destination)

      # récupération de la liste des bdd, "tail -n +2" est présent pour ne pas récupérer le titre "Databases" renvoyé par mysql
      databases=$( mysql $mysql_local_options --exec="SHOW DATABASES;" |  tail -n +2 )

      # Liste les bases de données
      for database in $databases
      do
        echo -e "${IFS}Transfert de la base '$database${IFS}"
        #mysqladmin -h $remote_hostname --user=$remote_mysql_user --password=$remote_mysql_pass create $database
        mysql $mysql_remote_options create $database
        mysqldump $mysql_local_options $database | mysql $mysql_remote_options $database
      done

      # reloads the grant table information.
      mysqladmin $mysql_remote_options flush-privileges
    ;;

    # La base de données est sur un serveur distant
    source)

      # récupération de la liste des bdd, "tail -n +2" est présent pour ne pas récupérer le titre "Databases" renvoyé par mysql
      databases=$( mysql $mysql_remote_options --exec="SHOW DATABASES;" |  tail -n +2 )

      # Liste les bases de données
      for database in $databases
      do
        echo -e "${IFS}Transfert de la base $database${IFS}"
        mysqladmin $mysql_local_options create $database
        mysqldump $mysql_remote_options --compress $database | mysql $mysql_local_options $database
      done

      # reloads the grant table information.
      mysqladmin $mysql_local_options flush-privileges

  esac

  echo "Fin du transfert"

}

script_short_description=MySQL management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"