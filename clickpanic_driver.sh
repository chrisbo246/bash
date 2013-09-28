#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__driver_menu ()
{
  while true; do
    __menu \
    -t 'Drivers' \
    -o 'Install Printer (CANON MP390)' \
    -o 'Install Webcam (Hercule Deluxe)' \
    -o 'Install PPC' \
    --back --exit

    case $REPLY in
      1) install_printer;;
      2) install_webcam;;
      3) install_ppc;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# its default configuration (see /lib/udev/rules.d/80-drivers.rules) it executes /lib/udev/firmware.agent in response.

# Where are firmware stored?
# firmware.agent is a simple shell script that tries to locate a firmware before sending it back to the kernel through a sysfs entry. It looks into the following directories:
# /lib/firmware/$(uname -r)
#/lib/firmware
#/usr/local/lib/firmware
#/usr/lib/hotplug/firmware

# apt-cache search d101m_ucode.bin
# firmware-linux-nonfree - Binary firmware for various drivers in the Linux kernel
# apt-file search d101m_ucode.bin
# firmware-linux-nonfree: /lib/firmware/e100/d101m_ucode.bin
#If the above commands return nothing, you probably need to enable the “non-free” repository in your ${config_path}apt/sources.list

# How do I install all firmware just to be sure I don’t miss any?
#apt-file --package-only search /lib/firmware/
#atmel-firmware

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
available_firmwares()
{
  __package_cp update
  if [ $1 != '' ]; then
    apt-cache search .*firmware.* | grep --color -i $1
  else
    apt-cache search .*firmware.*
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
detect_hardware()
{

  # Detect Intel Wireless (IWLwifi)
  interface_name=$( lspci | grep -Pi ".*(intel).*(wireless|wifi).*" )
  if [ $interface_name == "" ]; then
    interface_name=$( lspci | grep -Pi ".*(intel).*(wireless|wifi).*" )
  fi
  if [ $interface_name != "" ]; then
    echo -e "${interface_name} detected${IFS}IWLwifi drivers could probably be use."
    read -p"Do you want to install IWLwifi drivers ? [y/n] : " answer
    [ "$answer" == "y" ] && install_iwlwifi
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clé USB Wifi TP-link TL-WN821N
# driver ar9170
install_ar9170()
{

  # Add a "non-free" component to ${config_path}apt/sources.list
  current_dir=$(dirname "$0" )'\'
  . "${current_dir}apt.sh"
  add_source "http://ftp.us.debian.org/debian squeeze main contrib non-free"

  # Update the list of available packages and install the firmware-atheros and wireless-tools packages
  __package_cp -u install firmware-atheros wireless-tools

  # As the driver may already be loaded, reinsert the module to access installed firmware:
  modprobe -r ar9170usb ; modprobe ar9170usb

  # Verify your device has an available interface:
  iwconfig

  # Raise the interface to activate the radio, for example:
  ifconfig wlan0 up

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Configurer le daemon wpa_supplicant pour le lancement automatique de la connexion
#-c Fichier de configuration wpa_supplicant créé précédement
#-i Interface eth0
#-D Driver pour la clé Sagem XG-76NA 802.11bg
#-dd Affichage des messages
#-B Daemon pour le lancement automatique

#sudo wpa_supplicant -c${config_path}wpa_supplicant/wpa_supplicant.conf -iwlan0 -Dnl80211 -dd -B

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Intel PRO/Wireless 3945 and WiFi Link 4965 devices (iwlwifi)
# http://wiki.debian.org/iwlwifi
install_iwlwifi()
{

  release="$(lsb_release -cs)"
  echo -e "${IFS}deb http://ftp.us.debian.org/debian $release main contrib non-free" >> ${config_path}apt/sources.list
  __package_cp update

  __package_cp -u install firmware-iwlwifi wireless-tools

  modprobe iwl3945
  modprobe iwlagn

  # Verify your device has an available interface
  iwconfig

  # Raise the interface to activate the radio
  read -p"Select wifi interface to activate (eg. wlan0) interface"
  if [ $interface == "" ]; then
    $interface="wlan0"
  fi
  ifconfig $interface up

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ati()
{

  . "apt.sh"
  . "service.sh"

  release=$( lsb_release -cs )
  #headers_mode=$( uname -r | sed 's,[^-]*-[^-]*-,,' )
  #headers_version=$( uname -r | sed 's,^\([0-9]*.[0-9]*\).*,\1,' )

  # Add a "non-free" component to ${config_path}apt/sources.list, for example:
  add_source "deb http://ftp.fr.debian.org/debian ${release} main contrib non-free"

  # Install the relevant linux-headers, fglrx-control and fglrx-driver packages:
  headers_version=$( uname -r|sed 's,.[0-9]*-[0-9]*,,' )
  if [ "$release" == "squeeze" ]; then
    __package_cp -u install linux-headers-${headers_version} fglrx-control fglrx-driver
  else
    __package_cp -u install fglrx-modules-${headers_version} fglrx-control fglrx-driver
  fi

  # This will also install fglrx-glx, fglrx-modules-dkms and other recommended packages. DKMS will build the fglrx module for your system.

  # If the X Window System is running, exit your desktop environment or window manager.
  # If a display manager is in operation, switch to a virtual console and stop it.
  #invoke-rc.d gdm3 stop
  #invoke-rc.d kdm stop
  stop_x

  # Unload the radeon and drm modules:
  modprobe -r radeon drm

  echo -e <<EOF
A minimal ${config_path}X11/xorg.conf example is shown below:
Section "Device"
    Identifier  "ATI"
    Driver      "fglrx"
EndSection

Section "Screen"
    Identifier "Default Screen"
    DefaultDepth     24
EndSection
EOF

  # If this command failed with error: Module radeon is in use then you should reboot the system. (It may be necessary when framebuffer uses radeon driver.)
  # Create or amend ${config_path}X11/xorg.conf to include a Device section and request use of the fglrx driver:
  # This command creates and configure automatically a xorg.conf file to use the ATI proprietary driver:
  aticonfig --initial

  # You can otherwise edit it by yourself:
  editor ${config_path}X11/xorg.conf

  # Start the X Window System (startx) as a regular user, or start your display manager. For example:
  # invoke-rc.d gdm3 start
  # invoke-rc.d kdm start
  start_x

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_nvidia_free()
{

  __package_cp install xserver-xorg-video-nouveau

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_nvidia()
{
  read -p"Do you vant to use free nvidia drivers ? [y/N] : " answer
  [ $answer == "y" ] && install_nvidia_free
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_webcam ()
{

  # Webcam hercule Deluxe
  #rmmod ov511
  #__package_cp -u install ov51x-jpeg-source module-assistant
  #module-assistant a-i ov51x-jpeg

  cd ~
  lsusb
  # Bus 001 Device 005: ID 05a9:4519 OmniVision Technologies, Inc.
  __package_cp -u install linux-headers-`uname -r`
  __package_cp -u install gcc
  wget http://www.rastageeks.org/downloads/ov51x-jpeg/ov51x-jpeg-1.5.8.tar.gz
  tar xzvf ov51x-jpeg-1.5.8.tar.gz
  cd ov51x-jpeg-1.5.8
  make
  sudo make install
  sudo depmod
  sudo modprobe ov51x

  #Pour que le module soit chargé automatiquement au démarrage, on rajoute simplement une ligne ov51x dans le fichier ${config_path}modules (ou ${config_path}modprobe.conf pour certaines distributions autres qu'Ubuntu).
  #install ov51x-jpeg /sbin/modprobe -r ov51x-jpeg; /sbin/modprobe ov51x-jpeg force_palette=13;

  deb http://blognux.free.fr/ubuntu hardy main
  easycam2-gtk

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Imprimante Canom Smartbase MP390
install_printer ()
{

  # Installation du scanner
  # A utiliser avec xsane ou kooka

  __package_cp -u install libtiff4 build-essential xsane
  # Alumer le scaner

  # Installation des pilotes Pixma
  # wget http://home.arcor.de/wittawat/pixma/mp150-0.13.1.tar.bz2
  wget http://home.arcor.de/wittawat/pixma/mp150-0.12.2.tar.bz2
  sudo tar xjf mp150-0.12.2.tar.bz2 -C /usr/src
  cd /usr/src/mp150-0.12.2/
  sudo make
  ./scan -L

  # Vérifier la présence du scanner
  # editor ${config_path}udev/rules.d/45-libsane.rules

  # Aller sur xsane et constater que... son scanner n'est pas proposé
  sudo cp libsane-pixma.so /usr/lib/sane/libsane-pixma.so.1.0.13
  sudo mv /usr/lib/sane/libsane-pixma.so.1 /usr/lib/sane/libsane-pixma.so.2
  sudo ln -s /usr/lib/sane/libsane-pixma.so.1.0.13 /usr/lib/sane/libsane-pixma.so.1

  ${service_path}udev restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ppc ()
{
  # Installation
  __package_cp -u install librra0 librra0-tools librapi2-tools libsynce0
  __package_cp -u install synce-dccm synce-multisync-plugin synce-serial
  __package_cp -u install libmultisync-plugin-evolution libmultisync-plugin-backup multisync

  # Configuration de la liaison USB

  # Brancher le pocketpc
  sudo lsusb                             # liste les périphériques branchés: Code:
  # repérer la ligne correspondant au pocket pc:
  # Bus 002 Device 016: ID 0bb4:0a07 High Tech Computer Corp.
  # Dans ID, la première valeur correspond a  vendor Ÿ et la deuxième à  product Ÿ
  gksudo editor ${config_path}modprobe.d/synce     # Créer alors le fichier suivant:

  # copier le texte suivant en remplaçant les valeurs de vendor et product par celles obtenues précédement:
  options ipaq vendor=0bb4 product=0a07

  # Débrancher le PocketPC

  # Tester la connexion:

  dccm                                         # Lance la configuration de la connexion
  # Brancher le PocketPC puis:
  # modeprobe                                  # (quand le PDA demarre) pour connaitre le numero du périphérique USB
  sudo synce-serial-config ttyUSB0             # Configuration du port série (si ça ne marche pas essayez avec ttyUSB0,1,2,3 ou 4...)
  sudo synce-serial-start                      # Connexion
  synce-pstatus                                # Si ça marche on obtient des infos sur le pocketpc dont le niveau de charge de la batterie
  sudo synce-serial-abort                      # Pour la déconnexion il faut faire
  # puis débrancher le pocketpc

  # connexion automatique du PocketPC

  editor ${config_path}udev/rules.d/10-ipaq.rules    # Copier/Coller le script suivant:

  # udev rules file for SynCE
  BUS!=="usb", ACTION!=="add", KERNEL!=="ttyUSB*", GOTO=="synce_rules_end"
  # Establish the connection
  RUN+="/usr/bin/synce-serial-start"
  LABEL="synce_rules_end"

  ${service_path}udev restart                 # relancer udev

  # Tester en lançant dccm
  dccm
  # puis en branchant le pocketpc
  #puis essayer synce-pstatus ...
  synce-pstatus
  # Pour arrêter il suffit de débrancher le pocketpc...
  # Vous pouvez ajouter dccm au démarrage de la session dans le menu Système>Préférences>Session

  # Synchronisation Evolution

  # Connecter le PocketPC puis
  synce-matchmaker create 1      # créer un partenariat (en cas d'erreur remplacer 1 par 2 )
  # synce-matchmaker replace 1   # Pour supprimer un partenariat existant et en créer un nouveau

  # Lancer multisync (Applications>accessoire>multisync)
  # choisir les plugins evolution (choisir les choses à synchroniser) et synce puis lancer une synchronisation.
  # Vérifier le résultat dans Evolution et le PocketPC.
  # Penser à quitter multisync proprement après la synchro avant de débrancher le PocketPC

  # Dorénavant pour n'avez plus qu'a brancher le pocketpc puis lancer multisync pour que tout se fasse automagiquement

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"