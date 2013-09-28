#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__ftp_menu ()
{
  while true; do
    __menu \
    -t 'FTP server' \
    -o 'Install Proftpd' \
    -o 'Uninstall Proftpd' \
    -o 'Configure Proftpd' \
    -o 'Configure Proftpd active mode' \
    -o 'Configure Proftpd passive mode' \
    -o 'Display server info' \

    case $REPLY in
      1) install_proftpd;;
      2) uninstall_proftpd;;
      3) config_proftpd;;
      4) config_proftpd_active;;
      5) config_proftpd_passive;;
      6) info_proftpd;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_proftpd()
{

  echo "A la question « Lancer ProFTPd à partir d'inetd ou indépendamment ? », à moins de savoir ce que vous faites, répondez indépendamment."

  # Pour installer le package, rien de plus simple, vérifiez que vos dépôts Universe sont bien activés puis installez le paquet proftpd.
  #[ aptitude search '~i ^(proftpd)$' ] || __package_cp -u install proftpd
  #[ aptitude search '~i ^(ucf)$' ] || __package_cp -u install ucf
  __package_cp -u install proftpd ucf

  # pour utiliser la majorité des fonctions de proftpd sans trop de difficulté utilisez l'interface graphique
  if command -v 'zenity' &>/dev/null ; then

  else
    read -p'Do you want to intall graphical interface ? (y/n) : ' choice
    case $choice in
      y,Y,yes,YES)
        __package_cp -u install gproftpd
    esac
  fi

  # Evite le bug dans le cas ou le dossier n'existe pas
  [ -d /var/run/proftpd/ ] || sudo mkdir /var/run/proftpd/

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_proftpd()
{

  editor ${config_path}proftpd/proftpd.conf
  ${service_path}proftpd restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configuration pour le mode passif
# Le mode le plus simple est le transfert en mode actif, ou le port utilisé est le port 20 (le port 21 ne sert qu'à initier la connexion et envoyer des commandes)

config_proftpd_active()
{

  ${service_path}proftpd restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_proftpd_passive()
{

  # La deuxième méthode consiste à utiliser le mode passif : une plage de ports est utilisée, ces ports étant attribués selon la configuration du serveur et le nombre d'utilisateurs. Par défaut, la plupart des clients FTP transfèrent les fichiers en mode passif et il est donc utile de s'occuper de cette partie de la configuration.
  # Pour configurer la plage de ports utilisée on rajoute au fichier dans la partie générale :
  # Où 5000 représente le premier port utilisé et 5100 le dernier.
  # Il est déconseillé d'utiliser des numéros de ports trop bas (inférieurs à 1024) généralement réservés (HTTP, SSH etc…)
  set_confvar ${config_path}proftpd/proftpd.conf 'PassivePorts' '5000 5100'
  ${service_path}proftpd restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
info_proftpd()
{

  # Voir qui est connecté à votre serveur
  ftpwho
  # Voir les statistiques
  ftpstats

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='FTP management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"