#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__deb_menu ()
{
  while true; do
    __menu \
    -t 'DEB menu' \
    -o 'Add DEB sources' \
    -o 'Update Distribution' \
    -o 'Update a source key' \
    -o 'Update All source key' \
    --back --exit

    case $REPLY in
      1) add_sources;;
      2) update_distrib;;
      3) update_source_key;;
      4) update_all_source_key;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
configure_apt()
{

  dpkg-reconfigure debconf

  cd ${config_path}apt/

  # Télécharger le paquet netselect-apt et rsync:
  add_source "deb http://ftp.fr.debian.org/debian/ stable main"
  #fi [ grep -e "deb http://ftp..*.debian.org/debian" ./sources.list ]; then
  #  echo "deb http://ftp.fr.debian.org/debian/ stable main" >> ${config_path}apt/sources.list
  #fi

  __package_cp update
  __package_cp -u install netselect-apt rsync

  # Configuration de netselect-apt pour votre version de Debian :
  # Il faut remplacer <release> par stable, testing, unstable, experimental, woody, sarge et sid.
  # Ajouter l'option -n si vous voulez inclure les paquets non-free :
  # ou l'option -f si vous voulez choisir uniquement les miroirs ftp.
  # netselect-apt vous créera donc un source.list personnalisé dans le dossier courant qu'il vous faudra copier vers votre sources.list actuel :

  mv sources.list sources.list.old
  netselect-apt -n $release
  editor ${config_path}apt/sources.list

  #update_all_source_key
  rsync -az --exclude=removed-* --progress keyring.debian.org::keyrings/keyrings/ .
  # rsync -qcltz --block-size=8192 --partial --progress --exclude=emeritus-* --exclude=removed-* keyring.debian.org::keyrings/keyrings/* ~/.debian-keyring
  # __package_cp -u install debian-keyring

  apt-key add *.gpg
  gpg --list-keys

  sudo __package_cp update

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_reconfigure()
{

  # configure-debian --list
  # grep Owners /var/cache/debconf/config.dat /var/cache/debconf/passwords.dat | cut -f2- -d' ' |sed -e "s/, /${IFS}/g" |sort |uniq
  # apt-cache rdepends debconf |wc -l
  echo ""
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_sources ()
{

  release=$( lsb_release -cs )



  #backup_file ${config_path}apt/sources.list
  #echo "


  #" | sudo tee -a ${config_path}apt/sources.list
  #editor ${config_path}apt/sources.list

  # Importer les clés d'authentification (clé GPG)
  #import_gpg < gpg.list

  # SCENARI
  #gpg --keyserver subkeys.pgp.net --recv 57137EFADFD726C0
  #gpg --export --armor 57137EFADFD726C0 | sudo apt-key add -

  echo "Retrouvez l'ensemble des sources sur http://sources-list.ubuntu-fr-secours.org/"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add or uncomment apt source in sources.list
add_source()
{
  if [ $# -ne 0 ]; then
    for source in $*; do
      if [ grep -ne $source ${config_path}apt/sources.list ]; then
        echo -e "${IFS}$source" >> ${config_path}apt/sources.list
      else
        sed "s|^[ #'\t']$source.*|$source|" ${config_path}apt/sources.list -i
      fi
    done
    return true
  else
    echo -e "Syntaxe: add_source source1 source2 [...]"
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_all_source_key ()
{

  __package_cp -u install curl

  for i in `cat ${config_path}apt/sources.list | grep "deb http" | grep ppa.launchpad | grep "$(lsb_release -cs)" | cut -d/ -f4`; do
    curl `curl https://launchpad.net/~$i/+archive/ppa | grep "http://keyserver.ubuntu.com:11371/pks/" | cut -d'"' -f2 ` | grep "pub  " | cut -d'"' -f2 >> keyss
  done

  for j in `cat keyss` ; do
    curl "http://keyserver.ubuntu.com:11371$j" | grep -B 99999 END |grep -A 9999 BEGIN > keyss2
    sudo apt-key add keyss2
    rm keyss2
  done

  rm keyss

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_source_key ()
{

  menu_title="Source Key"
  menu_items=( `cat ${config_path}apt/sources.list | grep "deb http" | grep ppa.launchpad | grep "$(lsb_release -cs)" | cut -d/ -f4` )
  menu_text="Select a key : "

  select_list_menu
  source_key=$choice

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# If __package_cp complains about an unknown key, please import our stable repository key:

import_gpg()
{
  url=$1

  cd ${TMPDIR}
  wget -q $url -O - | sudo apt-key add -
  #gpg --import key.gpg && gpg --fingerprint
  #rm key.gpg

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

update_source_key ()
{

  # Sélection de la clé à mettre à jour
  select_source_key

  # Réception de la clé
  gpg --keyserver hkp://keyserver.ubuntu.com:11371 --recv-key $source_key
  # Mise à jour de la clé
  gpg -a --export $source_key  | sudo apt-key add -


  # GET http://mozilla.debian.net/archive.asc | gpg --import
  # gpg --check-sigs --fingerprint --keyring /usr/share/keyrings/debian-keyring.gpg 06C4AE2A
  # gpg --export -a 06C4AE2A | sudo apt-key add -

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_distrib ()
{

  # Update, upgrade and dist-upgrade
  sudo __package_cp clean
  sudo __package_cp update
  sudo __package_cp -y upgrade
  sudo __package_cp -y dist-upgrade

  # and check if reboot is required: /usr/local/bin/cron_update
  find /var/cache/apt/archives/linux-image* -exec /sbin/reboot {} \;

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____update_distrib ()
{

  # To upgrade from Ubuntu 8.10 on a desktop system
  # press Alt+F2 and type in "update-manager -d" (without the quotes) into the command box.
  # Update Manager should open up and tell you: New distribution release '9.04' is available.
  # Click Upgrade and follow the on-screen instructions.

  # To upgrade from Ubuntu 8.10 on a server system:
  # install the update-manager-core package if it is not already installed;
  __package_cp -u install update-manager-core

  # edit ${config_path}update-manager/release-upgrades and set Prompt=normal;
  set_confvar "${config_path}update-manager/release-upgrades" "Prompt" "normal"

  # launch the upgrade tool with the command
  sudo do-release-upgrade

  # and follow the on-screen instructions.

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test si un paquet .deb est installé et retourne la version
# $1 Nom du paquet

deb_installed_version()
{

  apt-cache policy $1 | grep Install | awk "/Install/ {print\$2}"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Debian package managment functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"