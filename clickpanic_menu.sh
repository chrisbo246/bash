#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__menu_menu()
{

  while true; do
    __menu \
    -t 'CLICKPANIC' \
    -o '*>> Manage Installation' \
    -o '*>> Manage system' \
    -o '*>> Manage network' \
    -o '*>> Manage multimedia' \
    -o '*>> Manage Web server' \
    -o '> Manage backups' \
    -o '> Manage Text File' \
    -o '> Manage mail server' \
    -o '> Manage ERP softwares' \
    -o '*>> Manage Hardware' \
    -o 'Logs' \
    -o 'Debug' \
    -o 'Website' \
    --back --exit

    case $REPLY in
      1) install_menu;;
      2) system_menu;;
      3) network_menu;;
      4) multimedia_menu;;
      5) web_menu;;
      6) include_once "${file_prefix}"backup.sh; backup_menu;;
      7) include_once "${file_prefix}"textfile.sh; textfile_menu;;
      8) include_once "${file_prefix}"mail.sh; mail_menu;;
      9) include_once "${file_prefix}"openerp.sh; openerp_menu;;
      10) hardware_menu;;
      11) include_once "${file_prefix}"log.sh; log_menu;;
      12) include_once "${file_prefix}"debug.sh; debug_menu;;
      13) source "${file_prefix}"website.sh; website_menu;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__install_menu ()
{
  while true; do
    __menu \
    -t 'Installation' \
    -o '> Install system' \
    -o '> Install drivers' \
    -o '> Install PS3' \
    --back --exit

    case $REPLY in
      1) include_once "${file_prefix}"base.sh; base_menu;;
      2) include_once "${file_prefix}"driver.sh; driver_menu;;
      3) include_once "${file_prefix}"ps3.sh; ps3_menu;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__system_menu ()
{
  while true; do
    __menu \
    -t 'System' \
    -o '> Manage APT' \
    -o '> Manage Debconf packages' \
    -o '> Manage DVB' \
    -o '> Manage Hardware' \
    -o '> Manage Disks' \
    -o '> Manage Users and groups' \
    -o '> Kill service' \
    -o '> List service' \
    --back --exit

    case $REPLY in
      1) include_once "${file_prefix}"deb.sh; deb_menu;;
      2) include_once "${file_prefix}"debconf.sh; debconf_menu;;
      3) include_once "${file_prefix}"dvb.sh; dvb_menu;;
      4) include_once "${file_prefix}"hardware.sh; hardware_menu;;
      5) include_once "${file_prefix}"disk.sh; disk_menu;;
      6) include_once "${file_prefix}"user.sh; user_menu;;
      7) kill_service;;
      8) list_service;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__multimedia_menu ()
{
  while true; do
    __menu \
    -t 'Multimedia' \
    -o '> Manage Media Center' \
    -o '> Manage Multimedia' \
    --back --exit

    case $REPLY in
      1) menu_mediacenter;;
      2) include_once "${file_prefix}"player.sh; player_menu;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__network_menu ()
{
  while true; do
    __menu \
    -t 'Network' \
    -o '> Manage Lan' \
    -o '> Manage Samba share' \
    -o '> Manage SSH host' \
    -o '> Manage LDAP host' \
    -o '> Manage FTP server' \
    -o '> Manage VPN' \
    -o '> Manage OpenLDAP' \
    --back --exit

    case $REPLY in
      1) include_once "${file_prefix}"lan.sh; lan_menu;;
      2) include_once "${file_prefix}user.sh"
      include_once "${file_prefix}"samba.sh; samba_menu;;
      3) include_once "${file_prefix}"ssh.sh; ssh_menu;;
      4) include_once "${file_prefix}"ldap.sh; ldap_menu;;
      5) include_once "${file_prefix}"ftp.sh; ftp_menu;;
      6) include_once "${file_prefix}"vpn.sh; vpn_menu;;
      7) include_once "${file_prefix}"openldap.sh; openldap_menu;;
    esac
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__web_menu ()
{
  while true; do
    __menu \
    -t 'Web Server' \
    -o '> Manage Apache Web project' \
    -o '> Manage MySQL Database' \
    -o '> Manage PHP' \
    --back --exit

    case $REPLY in
      1) include_once "${file_prefix}lan.sh"; include_once "${file_prefix}"apache.sh; apache_menu;;
      2) include_once "${file_prefix}"mysql.sh; mysql_menu;;
      3) include_once "${file_prefix}"php.sh; php_menu;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__hardware_menu ()
{
  while true; do
    __menu \
    -t 'Hardware' \
    -o 'Hardware' \
    -o 'Driver' \
    --back --exit

    case $REPLY in
      1) include_once "${file_prefix}"hardware.sh;;
      2) include_once "${file_prefix}"driver.sh; driver_menu;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__mediacenter_menu ()
{
  while true; do
    __menu \
    -t 'Media Center' \
    -o '> Manage FreePlayer' \
    --back --exit
    -o '> Manage Mediatomb media (transcoder) server' \
    -o '> Manage uShare media server' \
    --back --exit

    case $REPLY in
      1) include_once "${file_prefix}"freeplayer.sh; freeplayer_menu;;
      2) include_once "${file_prefix}"mediatomb.sh; mediatomb_menu;;
      3) include_once "${file_prefix}"ushare.sh; ushare_menu;;
    esac
  done
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__backup_menu ()
{
  while true; do
    __menu \
    -t 'Backup' \
    -o 'List installed .DEB' \
    -o 'Backup file list' \
    -o 'Backup all Web Projects' \
    -o 'Uninstall a Soft and all associated debs' \
    -o 'Restore DEBs' \
    -o 'Restore file list' \
    -o 'Restore original config files' \
    -o 'Restore a Web project' \
    -o 'Restore a Web project Database' \
    -o 'Purge old backups' \
    -o 'Backup distinct file list' \
    --back --exit

    case $REPLY in
      1) list_deb;;
      2) backup_filelist;;
      3);;
      4) hard_uninstall;;
      5) restore_deb;;
      6);;
      7);;
      8);;
      9);;
      10) purge_backup;;
      11) backup_distinct_filelist;;
    esac
  done
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='management functions';
script_version='0.0.1'
[[ ! $(declare -Ff __menu) ]] && include_once "${file_prefix}helpers.sh"
