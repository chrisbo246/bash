#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__symfony_menu ()
{
  while true; do
    __menu \
    -t 'Symfony PHP Framwork' \
    -o 'Install Symfony' \
    -o 'Upgrade Symfony' \
    -o 'Create Symfony project' \
    -o 'Update Symfony project' \
    -o 'Insert Symfony data' \
    --back --exit

    case $REPLY in
      1) install_symfony;;
      2) update_symfony;;
      3) create_symfony_project;;
      4) update_symfony_project;;
      5) insert_symfony_data;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__symfony_config()
{
  [[ ! "$declare -Ff 'menu'" ]] && . $ echo `dirname . global.sh

  `/ ${file_prefix}helpers.sh. apache.sh
  . mysql.sh
  . php.sh
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Install Symfony framework
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_symfony ()
{

  # Vérifier la présence de pear
  pear list

  # La première étape consiste à installer un environnement GLUAP (GNU / Linux Ubuntu - Apache 2 - PHP). Pour ce faire, exécutez simplement la commande suivante :
  __package_cp -u install libapache2-mod-php5 php-pear php5-mysql php5-cli php5-xsl
  __package_cp -u install libgd2-xpm libmcrypt4 libt1-5 php5-gd php5-mcrypt
  #__package_cp -u install apache2 mysql-server php5 libapache2-mod-php5 php5-xsl php5-gd php-pear libapache2-mod-auth-mysql php5-mysql
  #__package_cp -u install  apache2-doc phpmyadmin php5-cli php5-dev

  # Pensez à activer le mod_rewrite de votre Apache 2 :
  sudo a2enmod rewrite
  # Pour installer Symfony, il faut augmenter la limite d'utilisation mémoire de la ligne de commande PHP. Pour ce faire, exécutez la commande :
  set_confvar ${config_path}php5/cli/php.ini     'memory_limit'     '64M'
  # De même pour l'utiliser sans soucis, il faut augmenter la limite d'utilisation mémoire pour Apache 2 :
  set_confvar '$php_config' 'memory_limit'     '128M'
  # Enfin, il vous faut désactiver les magic_quotes de PHP :
  set_confvar '$php_config' 'magic_quotes_gpc' 'Off'

  sudo service apache2 reload

  # inscrire le canal de Symfony à la configuration de PEAR :
  sudo pear channel-discover pear.symfony-project.com
  # Puis on installe le framework lui-même :
  sudo pear install symfony/symfony

  sudo symfony -V

  # php /usr/share/php/symfony/data/bin/check_configuration.php

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mise à jour de Symfony
update_symfony ()
{

  # Si par la suite, vous souhaitez mettre à jour Symfony, utilisez simplement les commandes suivantes :
  rm /usr/share/php/.registry/.channel.pear.symfony-project.com/symfony.reg

  sudo pear channel-update pear.php.net
  sudo pear upgrade --alldeps PEAR

  sudo pear channel-update pear.symfony-project.com
  sudo pear upgrade symfony/symfony

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a Symfony project
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
create_symfony_project ()
{

  # select_project
  web_dir='web/'
  create_apache_vhost
  unset web_dir

  #  echo "
  #  Alias /sf /usr/share/php/data/symfony/web/sf
  #  <Directory \"${project_path}${project_name}/${web_dir}\">
  #    AllowOverride All
  #  </Directory>
  #
  #</VirtualHost>
  #" | sudo tee "$apache_conf_dirsites-available/${project_name}"
  #editor "$apache_conf_dirsites-available/${project_name}"

  #${service_path}apache2 reload

  cd ${project_path}${project_name}/

  # create Symfony project, generates the default structure of directories and files needed for a symfony project
  sudo symfony generate:project ${project_name}

  # Configure Symfony
  sudo symfony configure:database "mysql:host=$mysql_host;dbname=$db_base" $mysql_user $mysql_pass

  # Create applications
  for application_name in $application_names
  do
    sudo symfony generate:app --escaping-strategy=on --csrf-secret=Unique$ecret ${application_name}
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_symfony_project ()
{

  select_apache_vhost

  # Enfin, pour chaque projet Symfony présent sur votre machine, exécutez (si nécessaire) :
  symfony upgrade symfony_version

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Insert Symfony data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
insert_symfony_data ()
{

  select_project

  echo "Edit database structure..."
  editor "config/schema.yml"

  echo "Create project classes and tables..."
  # Generate the SQL statements needed to create the database tables
  sudo symfony propel:build-sql
  # Create the tables in the database
  sudo symfony propel:insert-sql
  # Generates PHP classes that map table records to objects
  sudo symfony propel:build-model
  # Generate forms and validators for the Jobeet model classes:
  sudo symfony propel:build-all
  # Clear the symfony cache. As the propel:build-model has created a lot of new classes, let's clear the cache:
  sudo symfony cache:clear

  echo "Edit initial data file..."
  editor "data/fixtures/fixtures.yml"

  # Loading the initial data into the database
  sudo symfony propel:data-load

  # Automatically generate a module for a given model that provides basic manipulation features:
  sudo symfony propel:generate-module --with-show --non-verbose-templates frontend job JobeetJob

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Symfony framwork management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"