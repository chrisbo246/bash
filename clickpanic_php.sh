#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__php_menu ()
{
  while true; do
    __menu \
    -t 'Apache Web server' \
    -o 'Install PHP' \
    -o 'Uninstall PHP' \
    -o 'Install Webalizer' \
    -o 'Install ProFTPD' \
    -o 'Edit PHP configuration' \
    -o 'Update all pear aplications' \
    -o 'Install PHP pear adds' \
    -o 'Make doc for selected project' \
    -o '> Manage Symfony Framework' \

    case $REPLY in
      1) install_php;;
      2) uninstall_php;;
      3) install webalizer;;
      4) install_proftpd;;
      5) edit_php_conf;;
      6) update_pear;;
      7) install_pear_php;;
      8) make_php_doc;;
      9)
        . "${file_prefix}lan.sh"
        . "${file_prefix}apache.sh"
      . "${file_prefix}"symfony.sh -m;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__php_config()
{
  # $php_config
  php_config=$( find / -type f -path "*/apache?/*" -name "php.ini" -exec grep -li "apache" {} \; )
  php_service=$( find / -type f -path "*/init.d/*" -name "php?" )
  apache_service=$( find / -type f -path "*/init.d/*" -name "apache?" )
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_php ()
{

  echo "Install PHP and modules..."

  # Installation
  sudo __package_cp -y install php5-common php5 php5-cli
  sudo __package_cp -y install libapache2-mod-php5 libapache2-mod-auth-mysql
  sudo __package_cp -y install php5-mysql php5-sqlite
  sudo __package_cp -y install php5-xsl php5-dev php5-gd php-pear php5-mcrypt

  echo "
Si votre navigateur vous demande de télécharger le fichier « phpinfo.php », cela peut venir d'un problème de module mal chargé.
Dans ce cas, vous pouvez tenter de résoudre cette « erreur » en activant le module PHP5 :
sudo a2enmod php5
$apache_service restart
puis videz le cache de votre navigateur (Ctrl+Maj+Suppr sous firefox)
  "

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_php ()
{

  sudo __package_cp autoremove php5*

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_proftpd ()
{

  sudo __package_cp -y install proftpd proftpd-doc

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_webalizer ()
{

  echo "Install WebAlizer..."
  sudo __package_cp -y install webalizer

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_php_conf ()
{

  editor $php_config
  sudo service php restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Met à jour toutes les aplis utilisant pear

update_pear()
{

  # Vous pouvez aussi choisir de mettre à jour toutes les applications PEAR:
  sudo pear update-channels
  sudo pear upgrade-all

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_pear_php()
{

  # Remarque: Si vous souhaitez disposer de la création automatisée de la documentation, installez PhpDocumentor :
  sudo pear install PhpDocumentor
  #
  sudo pear install XML_Beautifier
  # Ensuite, on installe phing au besoin :
  sudo pear install --alldeps http://phing.info/pear/phing-current.tgz

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

make_php_doc()
{

  ask_var 'project_path' 'Enter project_path : '
  select_apache_vhost

  # Générer la documentation
  # Si vous avez installé PhpDocumentor, vous pouvez générer la documentation de votre projet avec la ligne de commande :
  phpdoc -d $project_path$project_name -t $project_path$project_name/doc

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='PHP management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"