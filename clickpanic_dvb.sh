#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__dvb_menu ()
{
  while true; do
    __menu \
    -t 'DVB Satelite / TNT' \
    -o 'Install MythTV' \
    -o 'Install Me TV' \
    -o 'Install Kaffeine' \
    --back --exit

    case $REPLY in
      1) install_apache2;;
      2) uninstall_apache2;;
      3) create_apache_vhost;;
      4) rename_apache_vhost;;
      5) move_apache_vhost;;
      6) delete_apache_vhost;;
      7) edit_vhost;;
      8) install_user_web_dir;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_mythtv ()
{

  __package_cp -u install hwinfo
  hwinfo --dvb

  ls -l /dev/dvb/

  grep DVB /var/log/messages

  sudo __package_cp update
  __package_cp -u install mythtv mythtv-themes

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_metv ()
{

  __package_cp -u install me-tv

  # Scan les chaines
  __package_cp -u install dvb-utils
  scan  /usr/share/doc/dvb-utils/examples/scan/dvb-t/fr-$ville > ~/.me-tv/channels.conf

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='DVB management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"