#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__apache_menu ()
{
  while true; do
    __menu \
    -t 'Apache menu' \
    -o 'Install Apache Web server' \
    -o 'Uninstall Apache' \
    -o 'Create vhost' \
    -o 'Rename vhost' \
    -o 'Move project' \
    -o 'Delete vhost' \
    -o 'Manualy edit VHost config files' \
    -o 'Install user Web directory' \
    -o 'Move Apache directory' \
    -o 'Change project access port' \
    -o 'Select a vhost' \
    -o 'Select an enabled module' \
    --back --exit
    
    case $REPLY in
      1) install_apache2;;
      2) uninstall_apache2;;
      3) create_apache_vhost;;
      4) rename_apache_vhost;;
      5) change_apache_vhost_dir;;
      6) delete_apache_vhost;;
      7) edit_vhost;;
      8) install_user_web_dir;;
      9) move_apache_dir;;
      10) change_apache_vhost_port;;
      10) select_apache_vhost;;
      10) select_apache_enabled_module;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_apache_enabled_module()
{
  while true; do
    options=$(apachectl -M 2>&1 | tail -n+3 | grep -o '\S*_module' | sed 's/_module//' | sort)  
    __menu -t 'Enabled modules' $(printf ' -o %s' $options) --back --exit
    select_apache_module_action "$VALUE"
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_apache_module_action ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit

  while true; do
    __menu \
    -t "$1 actions" \
    -o "Disable '$1'" \
    --back --exit
    
    case $REPLY in
      1) a2dismod "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_apache_vhost_action ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit

  while true; do
    __menu \
    -t "$1 actions" \
    -o "Configure '$1'" \
    --back --exit
    
    case $REPLY in
      1) update-alternatives --config "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__apache_config()
{
  apache_config=$(find / -type f -name "apache?.conf" -exec grep -li "Timeout" {} \;)
  apache_service=$( find / -type f -path "*/init.d/*" -name "apache?" )
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_apache2 ()
{
  
  echo "Unistall Apache2..."
  
  $apache_service stop
  #sudo __package_cp -yqq remove --purge $(dpkg -l apache* | grep ii | awk '{print $2}') # Efface toute installation précédente
  sudo __package_cp -fyqq --purge remove apache2 apache2.2-common
  sudo rm -rfv ${config_path}apache2
  sudo rm -rfv /var/www/*
  #sudo __package_cp -qq clean
  sudo __package_cp -qq update
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_apache2 ()
{
  
  echo "Install Apache2..."
  
  __package_cp -u install apache2 apache2-utils apache2-mpm-prefork libapache2-mod-chroot libapache2-mod-auth-pam libapache2-mod-auth-sys-group
  __package_cp -u install apache2-doc libapache2-mod-proxy-html
  
  # Modifier le fichier de configuration:
  #echo "Modifier le fichier de configuration: ServerName www.monsite.com (ou 127.0.0.1 en local)"
  #editor $apache_conf_dirapache2.conf
  
  #Les jeux de caractères (encodages) du Serveur Web Apache2
  echo "
#La directive AddDefaultCharset remplace le jeu de caractères spécifié dans le corps du document Web via la balise META.
#Éditez le fichier $apache_conf_dirconf.d/charset :
#AddDefaultCharset off                  # Laisser le navigateur Web choisir l'encodage approprié
#AddDefaultCharset <le charset voulu>   # Décider du jeu de caractères à utiliser par défaut
#AddDefaultCharset UTF-8                # Jeu de caractère utilisé par défaut
  "
  
  # Autoriser l'utilisation de répertoires web personnels
  sudo a2enmod userdir                   # Donne accès à un dossier ~/public_html accessible via http://SERVER/~$USER/
  # Utiliser la réécriture d'URL (URL rewriting) et vos .htaccess
  sudo a2enmod rewrite                   # Activez le module rewrite
  
  #En cas d'erreur, vérifiez dans le fichier $apache_conf_dirsites-available/default (ou dans vos fichiers d'hôtes virtuels)
  # que la directive AllowOverride est : AllowOverride All (None par défaut)
  sudo sed -i -e "s/AllowOverride None/AllowOverride All/" $apache_conf_dirsites-available/default
  
  echo "ServerName 127.0.0.1" | sudo tee "$apache_conf_dirhttpd.conf"
  
  # Changer la racine du serveur
  # Via les liens symboliques
  #cd /var/www                         # Se placer à la racine du serveur
  
  project_path="/var/www"
  sudo chmod 755 $project_path
  sudo ln -sf $project_path             # Crée un lien vers le nouveau dossier
  sudo chown -R $USER $project_path     # Rend les fichiers accessible à $USER
  
  # Recharger Apache
  #${service_path}apache2 reload
  $apache_service force-reload
  
  echo <<EOF
Copier les fichiers PHP à la racine du serveur ( /var/www/ )

Le repertoire de développement de votre dossier personnel est maintenant accessible via ${project_path}

Accès à un dossier ~/public_html accessible via http://SERVER/~$USER/

La documentation apache est accessible via l'adresse http://localhost/manual

Pour pouvoir acceder au site de l'exterieur, il faut ouvrir le port 80 du routeur

Vous pouvez effectuer un test en vous rendant à l'adresse
http://localhost/ (en local)
http://127.0.0.1/ (en local)
http://IP_DU_SERVER/ (à distance)
http://NOM_DE_DOMAINE/ (à distance)
Si tout s'est bien passé, vous devriez voir une page Web dans laquelle l'index du répertoire Web apparait ainsi que le dossier « apache2-default »
EOF
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_apache_dir ()
{
  
  # Recherche le dossier courrant
  document_root=$( get_confvar "$apache_conf_dirsites-enabled/000-default" "DocumentRoot" )
  echo "Current DocumentRoot is \"$document_root\""
  ask_var 'new_document_root' 'Enter the new value : '
  new_document_root=$( check_dir $new_document_root )
  new_document_root="${new_document_root}${web_dir}"
  
  $apache_service start
  
  # Modifie chaque fichier de configuration
  #sudo sed "s|$document_root|$new_document_root|g" < sudo grep -rlh "$document_root" "${config_path}" | grep '[^~]$'
  search=$( echo $document_root | sed "s|/$||" )
  replace=$( echo $new_document_root | sed "s|/$||" )
  replace_all "${config_path}" $search $replace
  
  # Déplace le dossier
  sudo mv "$document_root" "$new_document_root"
  
  sudo mkdir -pv $new_document_root      # Crée le dossier devant contenir le site
  sudo chmod 755 $new_document_root
  sudo ln -sf $new_document_root         # Crée un lien vers le nouveau dossier
  sudo chown -R $USER $new_document_root # Rend les fichiers accessible à $USER
  
  $apache_service start
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____create_apache_vhost ()
{
  
  public_ip=$( get_public_ip )
  local_ip=$( get_local_ip )
  
  echo -n "Enter project name : "
  read vhost_name
  echo -n "Enter port number : "
  read port
  ask_var 'project_path' 'Enter apache project path (Ex: /home/user1/) : '
  project_path=$( check_dir $project_path )
  ask_var 'web_dir' 'Enter web directory (from project directory eg: www/) : '
  web_dir=$( check_dir $web_dir )
  
  server_name=${vhost_name}.localhost
  server_alias=${vhost_name}
  db_base=$vhost_name
  
  # Crée le dossier devant contenir le projet
  mkdir -pv ${project_path}${vhost_name}/${web_dir}
  
  # Change les autorisation
  sudo chmod 755 ${project_path}${vhost_name}/
  sudo chmod 755 ${project_path}${vhost_name}/${web_dir}
  sudo chown -R $USER $project_path
  
  # Crée la base
  mysqladmin -u$mysql_user -p$mysql_pass create $db_base
  
  # Crée une page d'accueil de test
cat > "${project_path}${vhost_name}/${web_dir}test.php" <<EOF
<h1> ${vhost_name}</h1>
Bienvenue sur la page d'accueil du projet <strong>${vhost_name}</strong>.
</br>Pour pouvoir <a href='http://$public_ip:$port/test.php'>acceder &agrave; votre site depuis l'exterieur</a> via votre r&eacute;seau local, vous devez configurer un Proxy dans votre navigateur.
</br>Vous devez &eacute;galement ouvrir le port <strong>$port</strong> de votre routeur / pare-feu.
EOF
  
  # $apache_conf_dirsites-available/
cat > "$apache_conf_dirsites-available/${vhost_name}" <<EOF
NameVirtualHost ${local_ip}:${port}

<VirtualHost ${local_ip}:${port}>

  DocumentRoot ${project_path}${vhost_name}/${web_dir}
  ServerName ${server_name}
  ServerAlias ${server_alias}
  DirectoryIndex index.php

  # <Location $location>
  #   ProxyPass http://$local_ip:$port/
  #   ProxyPassReverse http://$local_ip:$port/
  # </Location>

  Alias /sf /usr/share/php/data/symfony/web/sf
  <Directory \"${project_path}${vhost_name}/${web_dir}\">
    AllowOverride All
  </Directory>

</VirtualHost>
EOF
  editor "$apache_conf_dirsites-available/${vhost_name}"
  
  # $apache_conf_dirsites-enabled/000-default
cat >> "$apache_conf_dirsites-enabled/000-default" <<EOF
<VirtualHost *:${port}>
	ServerAdmin $server_admin

	DocumentRoot ${project_path}${vhost_name}/${web_dir}
	<Directory />
		Options FollowSymLinks
		AllowOverride All
	</Directory>
	<Directory ${project_path}${vhost_name}/${web_dir}>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory "/usr/lib/cgi-bin">
		AllowOverride All
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog /var/log/apache2/error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog /var/log/apache2/access.log combined

    Alias /doc/ "/usr/share/doc/"
    <Directory "/usr/share/doc/">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>

</VirtualHost>
EOF
  editor "$apache_conf_dirsites-enabled/000-default"
  
  # $apache_conf_dirports.conf
cat >> "$apache_conf_dirports.conf" <<EOF
# $vhost_name
NameVirtualHost *:$port
Listen *:$port
EOF
  editor "$apache_conf_dirports.conf"
  
  # ${config_path}hosts
  #echo "${local_ip} $server_name $server_alias" | sudo tee -a "${config_path}hosts"
  #editor "${config_path}hosts"
  
  sudo a2ensite $vhost_name
  
  $apache_service reload
  
  cat <<EOF
You can now test the job module in a browser at http://www.$vhost_name.com/frontend_dev.php/job
www-browser "http://${local_ip}:$port/test.php
EOF
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_apache_vhost()
{
  while true; do
    #options=$(apachectl -S 2>&1 | grep something)  
    options=$(find /etc/apache*/sites-available/ -type f -name '*.vhost' -printf "%f${IFS}" | sed 's/.vhost//' | sort)
    __menu -t 'Defined aliases' $(printf ' -o %s' $options) --back --exit
    select_apache_vhost_action "$VALUE"
  done
}
____select_apache_vhost ()
{
  
  menu_title="Apache projects"
  menu_items=( $( ls $apache_conf_dirsites-available/ | grep -v "default-ssl\|~" ) ) #grep -v "default\|default-ssl\|~"
  menu_text="Select project : "
  
  select_list_menu
  
  vhost_name=$choice
  get_confvar "$apache_conf_dirsites-available/$vhost_name" 'DocumentRoot'
  document_root=$( get_confvar "$apache_conf_dirsites-available/$vhost_name" 'DocumentRoot' )
  local_ip=$( get_confvar "$apache_conf_dirsites-available/$vhost_name" 'NameVirtualHost' | awk -F ':' '{ print $1 }' )
  port=$( get_confvar "$apache_conf_dirsites-available/$vhost_name" 'NameVirtualHost'| awk -F ':' '{ print $2 }' )
  server_name=$( get_confvar "$apache_conf_dirsites-available/$vhost_name" 'ServerName' )
  server_alias=$( get_confvar "$apache_conf_dirsites-available/$vhost_name" 'ServerAlias' )
  db_base=$vhost_name
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print_project_info ()
{
  
  echo "Project \"$vhost_name\" :"
  echo "DocumentRoot is set to \"$document_root\""
  echo "Local IP is set to \"$local_ip\""
  echo "Port is set to \"$port\""
  echo "ServerName is set to \"$server_name\""
  echo "ServerAlias is set to \"$server_alias\""
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_apache_vhost_dir ()
{
  
  select_apache_vhost
  
  echo "Curent DocumentRoot is $document_root"
  ask_var 'new_document_root' 'Enter the new DocumentRoot : '
  new_document_root=$( check_dir "$new_document_root" )
  
  $apache_service stop
  mv $document_root $new_document_root
  
  sudo sed -i -e 's/ProxyRequests = On/ProxyRequests = Off/' $php_config
  $apache_service reload
  
  #project_path=$new_project_path
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_apache_vhost_port ()
{
  
  select_apache_vhost
  
  echo "Port is set to \"$port\""
  read -p"Enter new value : " new_port
  
  set_confvar "$apache_conf_dirsites-available/${vhost_name}" "NameVirtualHost" "${local_ip}:${new_port}"
  sed "s|<VirtualHost|<VirtualHost ${local_ip}:${new_port}>|" "$apache_conf_dirsites-available/${vhost_name}"
  set_confvar "$apache_conf_dirsites-available/${vhost_name}" "ProxyPass"        "http://$local_ip:$new_port/"
  set_confvar "$apache_conf_dirsites-available/${vhost_name}" "ProxyPassReverse" "http://$local_ip:$new_port/"
  editor "$apache_conf_dirsites-available/${vhost_name}"
  
  sed "s|^<VirtualHost|<VirtualHost *:${new_port}>|" "$apache_conf_dirsites-enabled/000-default"
  editor "$apache_conf_dirsites-enabled/000-default"
  
  set_confvar "$apache_conf_dirports.conf" "NameVirtualHost" "*:$new_port"
  set_confvar "$apache_conf_dirports.conf" "Listen"          "$new_port"
  editor "$apache_conf_dirports.conf"
  
  pause "Don't forget to open this port in your firewall/Router"
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rename_apache_vhost ()
{
  
  select_apache_vhost
  
  echo "Current project name is \"$vhost_name\""
  read -p"Enter new value : " new_vhost_name
  
  new_server_name=${vhost_name}.localhost
  new_server_alias=${vhost_name}
  new_db_base=$vhost_name
  
  mv $vhost_name $new_vhost_name
  
  sudo rm -rfv "$apache_conf_dirsites-available/${vhost_name}"
  
  set_confvar "$apache_conf_dirsites-available/${vhost_name}" "DocumentRoot" "${project_path}${new_vhost_name}\/${web_dir}/"
  set_confvar "$apache_conf_dirsites-available/${vhost_name}" "ServerAlias" "${new_server_alias}/"
  sudo sed -i -e "s/${local_ip} $server_name $server_alias/${local_ip} $new_server_name $new_server_alias/" "${config_path}hosts"
  
  $apache_service reload
  
  mysqladmin -u$mysql_user -p$mysql_pass rename $db_base $new_db_base
  
  cd ${project_path}${vhost_name}
  
  set_confvar "${project_path}${new_vhost_name}/config/propel.ini" "propel.output.dir" "${project_path}${new_vhost_name}/"
  
  sudo symfony cc
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
delete_apache_vhost ()
{
  
  select_apache_vhost
  
  sudo rm -rfv "${project_path}${vhost_name}/"
  sudo a2dissite $vhost_name
  
  sudo rm -rfv "$apache_conf_dirsites-available/${vhost_name}"
  
  sudo sed -i -e "s/${local_ip} $server_name $server_alias//" ${config_path}hosts
  editor "${config_path}hosts"
  
  sudo sed -i -e "s/NameVirtualHost *:$port//" $apache_conf_dirports.conf
  sudo sed -i -e "s/Listen $port//" $apache_conf_dirports.conf
  editor "$apache_conf_dirports.conf"
  
  editor "$apache_conf_dirsites-enabled/000-default"
  
  $apache_service reload
  
  mysqladmin -u$mysql_user -p$mysql_pass drop $db_base
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_vhost ()
{
  
  select_apache_vhost
  
  editor "$apache_conf_dirsites-available/${vhost_name}"
  editor "$apache_conf_dirsites-enabled/000-default"
  editor "$apache_conf_dirports.conf"
  editor "${config_path}hosts"
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_user_web_dir ()
{
  
  # Edit apache2 config
  backup_file '$apache_conf_dirapache2.conf'
  echo "
<IfModule mod_userdir>
UserDir enabled
UserDir public_html
</IfModule>
  " | tee -a $apache_conf_dirapache2.conf
  editor $apache_conf_dirapache2.conf
  
  # Anable userdir module
  sudo a2enmod userdir
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Afiche la liste des champs avec la longueur maximum du contenu
# pour permetre d'optimiser la longueure du champ

optimise_fields_types()
{
  
  stty -echo
  read -p "MySQL root password :" pwd
  stty echo
  echo ""
  
  databases=$( mysql -root -p$pwd -e"SHOW DATABASES;" |  tail -n +2 )
  tables=$( mysql -root -p$pwd -e"SHOW TABLES;" | egrep -v 'Tables_in_' )
  
  echo $databases
  read -p "Database : " database
  
  echo $tables
  read -p "Table : " table
  
  fields=$( mysql -uroot -p$pwd -D$database -e"SHOW COLUMNS FROM $table" )
  
  for field in $fields;
  do
    # echo $field
    # image180Height
    # int(11)
    # NO
    # NULL
    
    fieldname=$( echo $field | awk -F" " '{print $1}' )
    fieldtype=$( echo $field | awk -F" " '{print $2}' )
    #fieldname=$field[0]
    #fieldtype=$field[1]
    
    maxlenght=$( mysql -uroot -p$pwd -D$database -e"SELECT MAX(LENGTH($fieldname)) FROM $table" )
    if [ $maxlenght > 0 ]; then
      comment=""
    fi
    echo "$fieldname $fieldtype : $maxlenght $comment"
  done
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Apache management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"