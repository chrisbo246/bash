#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__mediatomb_menu ()
{
  while true; do
    __menu \
    -t 'Mediatomb media server' \
    -o 'Install Mediatomb media server' \
    -o 'Uninstall Mediatomb' \
    -o 'Configure Mediatomb for PS3' \
    -o 'Configure Mediatomb with network interface' \
    -o 'Configure Mediatomb without network interface' \
    -o 'Configure Mediatomb for SQLite Database (Default)' \
    -o 'Configure Mediatomb for MySQL Database' \
    -o 'Enable Mediatomb autorun' \
    -o 'Disable Mediatomb autorun' \
    -o 'Goto Mediatomb interface' \
    --back --exit

    case $REPLY in
      1) install_mediatomb;;
      2) uninstall_mediatomb;;
      3) config_mediatomb_ps3;;
      4) config_mediatomb_lan_on;;
      5) config_mediatomb_lan_off;;
      6) config_mediatomb_sqlite;;
      7) config_mediatomb_mysql;;
      8) enable_mediatomb_autorun;;
      9) disable_mediatomb_autorun;;
      10) mediatomb_interface;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_mediatomb ()
{

  #selon la carte réseau que vous choisissez d'activer sur votre ordinateur ;
  # eth0, généralement si vous n'en avez qu'une, ou sur la première), ou laissez à vide (permettra de cibler toutes les interfaces de votre ordinateur - utile dans le contexte de portable :p )
  ask_var 'network_interface' 'Enter network interface to use (Ex: eth0) : '

  # Enregistrez la clé GPG : (key id: A2DCDB57; fingerprint: F1A6 C581 6BC1 AD55 80E9 EEFE 48AD 7164 A2DC DB57)
  wget http://apt.mediatomb.cc/key.asc -O- -q | sudo apt-key add -

  # Installer mediatomb
  __package_cp -u install mediatomb mediatomb-common mediatomb-daemon

  # Dans un premier temps, il faut modifier le fichier ${config_path}default/mediatomb, pour changer deux valeurs :
  backup_file ${config_path}default/mediatomb
  #sudo set_confvar ${config_path}default/mediatomb 'NO_START' '"no"'
  #sudo set_confvar ${config_path}default/mediatomb 'INTERFACE' "\"${network_interface}\""
  #editor ${config_path}default/mediatomb

  sudo sed 's|<transcoding enabled="no">|<transcoding enabled="yes">|' ~/.mediatomb/config.xml
  sudo sed 's|<transcoding enabled="no">|<transcoding enabled="yes">|' ${config_path}mediatomb/config.xml
  # ajouter la ligne pour la prise en charge des divx
  # <transcode mimetype="video/x-divx" using="video-common"/>

  # Puis, démarrez le serveur :
  ${service_path}mediatomb start

  # Sélection le fichier de configuration à lire
  # sudo mediatomb -c /home/$USER/.mediatomb/config.xml
  sudo mediatomb -d -c ${config_path}mediatomb/config.xml

  pause  "Une fois mediatomb installé, les ports suivant doivent être ouvert dans le pare-feu:
    * 49152 en TCP
    * 49152 en UDP
    *  1900 en UDP
  (Voir http://doc.ubuntu-fr.org/firestarter)
  "

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Il est possible de "lier" la PS3 avec le serveur Mediatomb :

config_mediatomb_ps3 ()
{

  # ligne 23, changez la valeur 'no' de l'attribut extend par 'yes' :
  # <protocolInfo extend="yes"/>
  sudo sed -i -e 's|<protocolInfo extend="no"/>|<protocolInfo extend="yes"/>|' ${config_path}mediatomb/config.xml

  # ligne 65, enlevez les commentaires html de la ligne, afin de ne plus avoir sur cette ligne que ce code :
  # <map from="avi" to="video/divx"/>
  sudo sed -i -e 's|<!-- <map from="avi" to="video/divx"/> -->|<map from="avi" to="video/divx"/>|' ${config_path}mediatomb/config.xml

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Il est possible de fonctionner avec MySQL !

config_mediatomb_mysql ()
{

  # Veuillez dans un premier temps installez le serveur mysql, si cela n'est pas déjà fait …
  # ensuite, il vous faut configurer celui-ci, en tant qu'administrateur toujours :

  mysql "CREATE DATABASE $mediatomb_db;"
  mysql "GRANT ALL ON $mediatomb_db.* TO '$mysql_user'@'$mediatomb_host' IDENTIFIED BY '$mysql_password';"

  # Changez 'user_mediatomb' par un nom utilisateur, tel que mediatomb, et 'passwd_mediatomb' par un mot de passe de votre choix … retenez-les !

  # Ensuite, il faut modifier le fichier ${config_path}mediatomb/config.xml :
  backup_file ${config_path}mediatomb/config.xml

  # ligne 14, paramétrer sqlite sur no : <sqlite3 enabled="no">
  sudo sed -i -e 's|<sqlite3 enabled="yes">|<sqlite3 enabled="no">|' ${config_path}mediatomb/config.xml

  # ligne 17, paramétrer mysql sur yes : <mysql enabled="yes">
  sudo sed -i -e 's|<mysql enabled="no">|<mysql enabled="yes">|' ${config_path}mediatomb/config.xml

  # ligne 18, laissez host sur localhost, si mediatomb est installé en local … : <host>localhost</host>
  sudo sed -i -e 's|<host>|<host>$mediatomb_host</host>|' ${config_path}mediatomb/config.xml

  # ligne 19, paramétrer le nom utilisateur MySQL, celui que vous avez donné ci-dessus. : <username>mediatomb</username>
  sudo sed -i -e "s|<username>mediatomb</username>|<username>$mysql_user</username>|" ${config_path}mediatomb/config.xml

  # ligne 20, paramétrer le nom de la base database sur db_mediatomb : <database>db_mediatomb</database>
  sudo sed -i -e "s|<database>|<database>$mysql_db</database>|" ${config_path}mediatomb/config.xml

  # ligne 21, paramétrer le mot-de-passe MySQL correspondant à l'utilisateur MySQL, ci-dessus. : <password>mediatomb</password>
  sudo sed -i -e "s|<password>|<password>$mysql_password</password>|" ${config_path}mediatomb/config.xml

  ${service_path}mediatomb restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_mediatomb_sqlite ()
{

  # Ensuite, il faut modifier le fichier ${config_path}mediatomb/config.xml :
  backup_file ${config_path}mediatomb/config.xml

  # ligne 14, paramétrer sqlite sur yes : <sqlite3 enabled="yes">
  sudo sed -i -e 's|<sqlite3 enabled="no">|<sqlite3 enabled="yes">|' ${config_path}mediatomb/config.xml

  # ligne 17, paramétrer mysql sur no : <mysql enabled="no">
  sudo sed -i -e 's|<mysql enabled="yes">|<mysql enabled="no">|' ${config_path}mediatomb/config.xml

  ${service_path}mediatomb restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Dans le contexte d'un environnement LAN, vous pouvez laisser l'interface graphique activée, tout en paramétrant la gestion de compte :

config_mediatomb_lan_on ()
{

  # ligne 4, laissez l'attribut enabled à yes.
  sudo sed -i -e 's|<ui enabled="no">|<ui enabled="yes">|' ${config_path}mediatomb/config.xml

  # ligne 5, paramétrer l'attribut enabled à yes :
  # <accounts enabled="yes" session-timeout="30">
  sudo sed -i -e 's|<accounts enabled="no" session-timeout="30">|<accounts enabled="yes" session-timeout="30">|' ${config_path}mediatomb/config.xml

  # ligne 6, paramétrer les attributs user et password …
  sudo sed -i -e "s|<account user|<account user=\"$mediatomb_user\" password=\"$mediatomb_password\"/>|" ${config_path}mediatomb/config.xml

  ${service_path}mediatomb restart

  return -code

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Dans un environnement non sécurisé, il est nécessaire de désactiver l'interface graphique :
#
# Le serveur a intégré un gestionnaire de fichier au-travers du navigateur internet.
# Configuré par défaut, il permet à n'importe qui de naviguer dans votre système de fichier et ainsi de télécharger n'importe quelle donnée.

config_mediatomb_lan_off ()
{

  # ligne 4, paramétrer l'attribut enabled à no :
  # <ui enabled="no" />
  sudo sed -i -e 's|<ui enabled="yes">|<ui enabled="no">|' ${config_path}mediatomb/config.xml

  ${service_path}mediatomb restart

  return -code

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
enable_mediatomb_autorun ()
{

  ${service_path}mediatomb start
  sudo update-rc.d -f mediatomb defaults

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disable_mediatomb_autorun ()
{

  ${service_path}mediatomb stop
  sudo update-rc.d -f mediatomb remove

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
deamon_mediatomb ()
{

  # Rajouter -m $HOME pour que le mode daemon fonctionne
  sudo sed 's|-g $GROUP|-g $GROUP -m $HOME|' '${service_path}mediatomb'

  __package_cp -u install mediatomb-daemon
  set_confvar ${config_path}default/mediatomb 'NO_START' 'yes'
  set_confvar ${config_path}default/mediatomb 'MT_ENABLE' 'true'

  ${service_path}mediatomb start
  update-rc.d mediatomb defaults
  #rc-update add mediatomb default

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mediatomb_interface ()
{

  firefox http://${mediatomb_host}:49152/

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Mediatomb management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"