#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__ps3_menu ()
{
  while true; do
    __menu \
    -t 'Playstation 3' \
    -o 'Init DHCP network' \
    -o 'Init Wifi network' \
    -o 'Init mouse' \
    -o 'Config shared folder' \
    -o 'Install prerequish' \
    -o 'Config KBOOT Shell' \
    -o 'Config Video mode' \
    -o 'Reboot on PS3 system' \
    --back --exit

    case $REPLY in
      1) init_dhcp_network;;
      2) init_wifi;;
      3) init_mouse;;
      4) config_share;;
      5) install_pre;;
      6) kboot_shell;;
      7) config_video;;
      8) boot_on_ps3;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configure le reseau en DHCP
init_dhcp_network ()
{

  ask_var 'network_interface' 'Enter network interface to use (Ex: eth0) : '

  sudo ifconfig $network_interface up
  sudo dhclient $network_interface

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init_wifi ()
{

  # Affiche la configuration reseau
  cat ${config_path}network/interfaces
  lshw -C network
  iwconfig
  lsusb
  lspci

  editor ${config_path}network/interfaces
  auto lo
  iface lo inet loopback

  auto $wifi_interface
  iface $wifi_interface inet dhcp
  wireless-essid $wireless_essid #Livebox-2***
  wireless-key $wireless_key #XXXXXXXX..(23 caracteres)
  wireless-channel 10

  ${service_path}networking stop && ${service_path}networking start

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init_mouse ()
{

  # mousepad ${config_path}kboot.conf
  # feisty='/boot/vmlinux-feisty initrd=/boot/initrd.img-feisty root=/dev/sda1 quiet splash video=ps3fb:mode:37

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_share ()
{

  # http://minedekobalt.wordpress.com/2008/05/14/ubuntu-windows-server-2003/

  __package_cp -u install smbfs winbind

  #mount -t cifs //pc/share ./mntpoint
  echo "User : "
  read user
  echo "Password : "
  read password
  mount -t smbfs -o username="$user",password="$password",uid=1000,iocharset=iso8859-1,codepage=cp850 '\\chris-asus\\' /chris-asus

  sudo mkdir /media/partition1
  editor ${config_path}nsswitch.conf
  hosts: files wins dns #Modifie la ligne en ajoutant wis avan dns

  # Monte les disque réseaux
  sudo mkdir '/media/Vidéos'; sudo mount -t smbfs -o username="$user",password="$password",uid=1000,iocharset=iso8859-1,codepage=cp850 '\\chris-asus\D$' '/media/Vidéos'
  sudo mkdir '/media/Documents'; sudo mount -t smbfs -o username="$user",password="$password",uid=1000,iocharset=iso8859-1,codepage=cp850 '\\chris-asus\G$' '/media/Documents'
  sudo mkdir '/media/Temp'; sudo mount -t smbfs -o username="$user",password="$password",uid=1000,iocharset=iso8859-1,codepage=cp850 '\\chris-asus\E$' '/media/Temp'

  # Crée les liens dans le dossier perso
  cd ~/Vidéos/; ln -s /media/Vidéos/Chris/Videos 'Vidéos de Chris'; ln -s /media/Vidéos/Public/Videos 'Vidéos Public'
  cd ~/Documents/; ln -s /media/Documents/Chris/Documents 'Documents de Chris'; ln -s /media/Documents/Public/Documents 'Documents Public'
  cd ~/Musiques/; ln -s /media/Documents/Chris/Musiques 'Musiques de Chris'; ln -s /media/Documents/Public/Musiques 'Musiques Public'
  cd ~/Images/; ln -s /media/Documents/Chris/Images 'Images de Chris'; ln -s /media/Documents/Public/Images 'Images Public'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Config video resolution
config_video ()
{

  echo "
  # Résolution TV
  # TV        575 lignes
  # DVD EDTV  852 x  480   575p
  # HD Ready 1280 x  720p  720p
  # Wide XGA 1366 x  768         Progressive Scan
  # Full HD  1920 x 1080p 1080i

  # VESA
  # 1360 x 768 @ 60Hz
  # 1024 x 768 @ 60-70-75Hz
  #  800 x 600 @ 60-72-75Hz
  #  640 x 480 @ 72-75Hz
  # IBM
  #  640 x 480 @ 60Hz
  #  720 x 400 @ 70Hz

  # YUV 60Hz  1:480i  2:480p  3:720p  4:1080i  5:1080p
  # YUV 50Hz  6:576i  7:576p  8:720p  9:1080i 10:1080p
  # RGB 60Hz 33:480i 34:480p 35:720p 36:1080i 37:1080p
  # RGB 50Hz 38:576i 39:576p 40:720p 41:1080i 42:1080p
  # VESA 11:WXGA 12:SXGA 13:WUXGA
  "

  # Remplacer N par le mode souhaité
  str="start on runlevel 2 exec /usr/bin/ps3videomode"
  sudo sed -i -e "s/$str -v/$str -v 4/" $apache_conf_dirsites-available/default
  sudo sed -i -e "s/$str -h/$str -v 4/" $apache_conf_dirsites-available/default
  editor ${config_path}event.d/ps3videomode

  # linux='... video=ps3fb:mode:9 ...'
  str="video=ps3fb:mode:"
  sudo sed -i -e "s/${str}/${str}9/" ${config_path}kboot.conf
  editor ${config_path}kboot.conf

  #editor ${config_path}X11/xorg.conf

  # Essaye avec -h au lieu de -v
  # ps3videomode -v 36 -f

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
kboot_shell ()
{

  # Taper "sh" au kboot pour lancer le shell

  umount /mnt/root
  mount -t ext3 -w /dev/ps3da1 /mnt/root
  chroot /mnt/root bash

  # vim ${config_path}kboot.conf
  # editor ${config_path}kboot.conf

  # exit # Pour retourner au kboot (Ctrl+d)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
boot_on_ps3()
{

  sudo boot-game-os

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='PS3 management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"