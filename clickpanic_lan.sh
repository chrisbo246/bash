#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__lan_menu ()
{
  while true; do
    __menu \
    -t 'LAN' \
    -o 'Print LAN Infos' \
    -o 'Run static Ethernet network' \
    -o 'Run DHCP Ethernet network' \
    -o 'Run Wifi network' \
    --back --exit

    case $REPLY in
      1) print_lan_info;;
      2) run_static;;
      3) run_dhcp;;
      4) run_wifi;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__lan_config()
{
  #. global.sh
  YES=0 # TRUE
  NO=1 # FALSE
  ERR=999 # DEFAULT VALUE OR ERROR CODE
  public_ip=$( get_public_ip )
  local_ip=$(hostname -i)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_interface()
{

  #for i in `cat /proc/net/dev | grep ':' | cut -d ':' -f 1`do  ifname=`echo $i | tr -d ' '`  echo "Interface : $i"done
  interfaces=$( awk -F':' 'NR>2 { print $1 }' /proc/net/dev | sort )

  echo "Select interface :"
  select interface in $interfaces; do
    #case $yn in
    #    Yes ) make install; break;;
    #    No ) exit;;
    #esac
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print_lan_info ()
{
  echo "Public IP : $public_ip"
  echo "Local IP  : $local_ip"
  echo "Hostname  : $hostname"
  pause

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_config ()
{

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Display hostname
# host (FQDN hostname), for example, vivek (vivek.text.com)

getHostName()
{
  [ "$OS" == "FreeBSD" ] && echo "$($HOSTNAME -s) ($($HOSTNAME))" || :
  [ "$OS" == "Linux" ] && echo "$($HOSTNAME) ($($HOSTNAME -f))" || :

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change host name on a running system
#uname -n
#hostname -a
#hostname -s
#hostname -d
#hostname -f
#hostname
# should return current host name
changeHostName()
{

  editor ${config_path}hostname

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
getFQDN()
{

  FQDN=$( hostname -f )

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configuration du réseau wifi avec clé USB Sagem XG-76NA 802.11bg sur interface eth0

install_wifi()
{

  read -p"Wifi interface (eg. wlan0): " interface
  read -p"IP address (eg. 192.168.0.1): " ip
  read -p"Gateway (eg. 192.168.0.254): " gateway
  read -p"DNS (eg. 212.27.40.240): " dns
  read -p"Wifi ID (eg. mywifi): " ssid
  read -p"Wifi password (eg. mypassword): " psk

  # Ajoute un exemple de configuration
  cat > ${config_path}network/interfaces <<EOF
  # The primary network interface
  auto $interface
  iface $interface inet static
          address $ip
          netmask 255.255.255.0
          network 192.168.0.0
          broadcast 192.168.0.255
          gateway $gateway
          wpa-conf ${config_path}wpa_supplicant/wpa_supplicant.conf
          dns-nameservers $dns
          dns-* options are implemented by the resolvconf package, if installed
EOF

  #Editer la config réseau pour l'interface wlan0
  editor ${config_path}network/interfaces
  ## ${service_path}networking stop && ${service_path}networking start
  # service

  # Créer le fichier de config wpa_supplicant
  cat > ${config_path}wpa_supplicant/wpa_supplicant.conf <<EOF
  ctrl_interface=/var/run/wpa_supplicant
  #ctrl_interface_group=wheel
  #fast_reauth=1
  #ap_scan=2
  #eapol_version=2

  network={
          ssid="$ssid"
          proto=WPA
          key_mgmt=WPA-PSK
          psk="$psk"
          #pairwise=TKIP
          #group=TKIP
          #scan_ssid=1
  	      #priority=0
          #auth_alg=OPEN
  }
EOF
  editor ${config_path}wpa_supplicant/wpa_supplicant.conf

  # Kill wpa_supplicant service if runing
  lsof | grep "wpa_supplicant" | awk '{print $2}' -exec kill -KILL {} \;

  # Configurer le daemon wpa_supplicant pour le lancement automatique de la connexion
  wpa_supplicant -c${config_path}wpa_supplicant/wpa_supplicant.conf -i$interface -Dnl80211 -dd -B

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_route()
{

  read -p"Wifi interface (eg. wlan0): " interface
  read -p"Gateway (eg. 192.168.0.254): " gateway

  # Supprime le routage par défaut
  route del default
  # Ajoute le nouveau routage par défaut
  route add default gw $gateway dev $interface
  # Affiche les routages
  route -n

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
enableWOL()
{

  # Il faut installer le paquet ethtool
  __package_cp -u install ethtool

  # Si par exemple l’interface réseau qui doit réveiller la machine est eth0
  # ajoutez cette ligne dans ${config_path}network/interfaces :
  #read -p"Select interface to listen to (ex: eth0) : " interface
  echo "Select interface to listen to (ex: eth0) : "
  select_interface
  echo "pre-down /usr/sbin/ethtool -s $interface wol g" >> ${config_path}network/interfaces

  # Il faut aussi ajouter cette ligne dans le fichier ${config_path}rc.local
  echo "usr/sbin/ethtool -s eth0 wol g" >> ${config_path}rc.local

  echo "Check that :"
  echo "UDP port 0, 7 or 9 is open on your router config"
  echo "S1 / WOL function is enabled in server bios"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List total number of ethernet interface

getNumberOfInterfaces()
{
  [ "$OS" == "FreeBSD" ] && echo "$($IFCONFIG | $GREP -Ew "\<UP" | $GREP -v lo0 | $WC -l)" || :
  [ "$OS" == "Linux" ] && echo "$($NETSTAT -i | $GREP -Ev "^Iface|^Kernel|^lo" | $WC -l)" || :

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script de lancement du reseau via ethernet

run_static ()
{

  sudo killall -9 dhclient
  sudo rm ${config_path}network/interfaces
  sudo ln -s ${config_path}network/interfaces.work ${config_path}network/interfaces
  sudo rm ${config_path}resolv.conf
  sudo ln -s ${config_path}resolv.conf.work ${config_path}resolv.conf
  ${service_path}networking stop && ${service_path}networking start

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script de lancement du reseau via ethernet

run_dhcp ()
{

  sudo rm ${config_path}network/interfaces
  sudo ln -s ${config_path}network/interfaces.maison ${config_path}network/interfaces
  sudo rm ${config_path}resolv.conf
  sudo ln -s ${config_path}resolv.conf.maison ${config_path}resolv.conf

  # changer ici pour mettre votre addresse IP réservée pour dhcp
  read -p"Enter local reserved IP (ex: 192.168.0.1) : " ETHERNET_ADDR

  # changer ici pour mettre l'adresse IP de votre routeur
  read -p"Enter router IP (ex: 192.168.0.254) : " ROUTER_ADDR

  # changer ici si votre interface Ethernet n'est pas eth0
  ask_var 'network_interface' 'Enter iface ethernet number (ex: eth0) : '
  ETHERNET_IFACE=$network_interface

  #get_config

  #e=$(iwconfig 2>/dev/null|grep "$WIFI_IFACE")
  #if [[ $e ]]
  #then
  #  echo "je supprime le lien d adresse IP (kill dhclient)"
  #  sudo killall -9 dhclient
  #  echo "ifconfig $WIFI_IFACE down"
  #  sudo ifconfig $WIFI_IFACE down
  #fi

  u=$(ifconfig|grep "$ETHERNET_IFACE")
  if [ ! $u ]
  then
    sudo killall -9 dhclient
    echo "ifconfig $ETHERNET_IFACE up"
    sudo ifconfig $ETHERNET_IFACE up
  fi

  a=$(ifconfig|grep "$ETHERNET_ADDR")
  if [ -z "$a" -o "$1" == "--force" ]
  then
    echo "Recherche d\'adresse IP."
    ${service_path}networking stop && ${service_path}networking start
  fi

  echo "veuillez patienter, test du ping..."
  b=$(ping -w 2 -c 1 $ROUTER_ADDR | grep "64 bytes from")
  c=$(ping -w 2 -c 1 google.com | grep "64 bytes from")
  if [ ! $b ]
  then
    echo "Echec du ping, mais on a une adresse IP."
    if [ "$1" == "--force" ]
    then
      echo "Soyez patient et retapez maison"
    else
      echo "je recommence"
      $0 --force
    fi
  else
    echo "succes du ping sur le routeur."
    if [ ! $c ]
    then
      echo "pas d\'acces internet"
      echo "essayez de rebooter le routeur"
    else
      echo "Acess internet O.K. Have fun !"
    fi
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script permetant de démarrer le réseau wifi

run_wifi ()
{

  sudo rm ${config_path}network/interfaces
  sudo ln -s ${config_path}network/interfaces.wifi ${config_path}network/interfaces
  sudo rm ${config_path}resolv.conf
  sudo ln -s ${config_path}resolv.conf.maison ${config_path}resolv.conf

  # changer ici pour mettre votre addresse IP réservée pour dhcp
  read -p"Enter local reserved IP (ex: 192.168.0.1) : " WIFI_ADDR

  # changer ici pour mettre l'adresse IP de votre routeur
  read -p"Enter router IP (ex: 192.168.0.254) : " ROUTER_ADDR

  # changer ici si votre interface wi-fi n'est pas rausb0
  ask_var 'wifi_interface' 'Enter iface number (ex: rausb0) : '
  WIFI_IFACE=$wifi_interface

  #get_config

  e=$(ifconfig|grep "$WIFI_IFACE")

  #if [[ $e ]]
  #then
  #  echo "ifconfig $ETHERNET_IFACE down"
  #  sudo ifconfig $ETHERNET_IFACE down
  #fi

  if [ "$1" == "--force" -o -z "$(ifconfig|grep "$WIFI_IFACE")" ]
  then
    echo "je supprime le lien d\'adresse IP (kill dhclient)"
    sudo killall -9 dhclient
    u=
  else
    u=$(iwconfig 2>/dev/null|grep "$WIFI_IFACE")
  fi

  if [ ! $u ]
  then
    echo "ifconfig $WIFI_IFACE up"
    sudo ifconfig $WIFI_IFACE up
    a=$(ifconfig|grep "$WIFI_ADDR")
  else
    a=$(ifconfig|grep "$WIFI_ADDR")
    if [ "$1" == "--force" ]
    then
      a=
    fi
  fi

  if [ -z "$(iwconfig 2>/dev/null | grep "$WIFI_IFACE")" ]
  then
    echo "Impossible de configurer $WIFI_IFACE. Probleme materiel ?"
    exit 0
  fi

  i=0
  if [ ! $a ]
  then
    echo "Veuillez patienter, recherche d\'adresse IP"
  else
    echo Adresse IP OK
  fi

  while [ -z "$a" -a $i -lt 4 ]
  do
    echo "restarting reseau"
    ${service_path}networking stop && ${service_path}networking start
    i=`expr $i + 1`
    a=$(sudo ifconfig|grep "$WIFI_ADDR")
  done

  if [ ! $a ]
  then
    echo "pas d adresse IP."
    echo "Esayez de rebooter le routeur ou relancez le script"
    exit 0
  fi

  echo "veuillez patienter, test du ping..."
  b=$(ping -w 2 -c 1 $ROUTER_ADDR | grep "64 bytes from")
  # ping example.com
  c=$(ping -w 2 -c 1 google.com | grep "64 bytes from")

  if [ ! $b ]
  then
    echo "Echec du ping, mais on a une adresse IP."
    if [ "$1" == "--force" ]
    then
      echo "Soyez patient et relancez le script (des fois attendre 1mn)"
    else
      echo "je supprime le processus"
      $0 --force
    fi
  else
    echo "succes du ping sur le routeur."
    if [ ! $c ]
    then
      echo "pas d\'acces internet"
      echo "essayez de rebooter le routeur"
    else
      echo "Access internet O.K. Have fun !"
    fi
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Modify your file ${config_path}hosts if the IP adress has changed after a reboot

update_ip ()
{

  # People who will be sent a mail if IP changes.
  # You can add people you want to be informed of the change in the $INFORMED
  # variable, just add the names (or e-mails) seperated by commas
  INFORMED="root $USER"

  # Variables you don't need to change.
  CURRENT_IP=`/sbin/ifconfig $network_interface | grep inet | cut -d ":" -f 2 | cut -d " " -f 1`
  REGISTERED_IP=`grep $HOSTNAME ${config_path}hosts | cut -f 1`

  # First we check if the interface is configured
  if ! /sbin/ifconfig $network_interface > /dev/null 2>&1 ; then
    echo "Network interface ${network_interface} not configured: aborting."
    exit
  fi

  # Definitions of the old and new IP adresses
  echo "Current IP: $CURRENT_IP."
  echo "Registered IP: $REGISTERED_IP."

  # Check if IP is modified, and if so, we update the ${config_path}hosts file
  # If the creation of the new ${config_path}hosts file fails, no modification is done
  if [ $CURRENT_IP != $REGISTERED_IP ] ; then
    echo -n "IP adress has changed: créating a new ${config_path}hosts file"
    sed -e "s/$REGISTERED_IP/$CURRENT_IP/g" ${config_path}hosts > ${config_path}hosts.new
    echo "."
    if [ -s ${config_path}hosts.new ] ; then
      echo -n "Creation of the new file succeeded: replacing ${config_path}hosts"
      backup_file ${config_path}hosts
      mv ${config_path}hosts.new ${config_path}hosts
      echo "."
      echo "Backup copy of the old ${config_path}hosts: ${config_path}hosts.bak."
    else
      echo "Error when creating file: ${config_path}hosts.new is empty, no update done."
      echo "Please modify ${config_path}hosts by yourself."
    fi
  else
    echo "IP adress hasn't changed: no update needed."
  fi

  # If the IP has changed, a mail is sent to people mentioned in the $INFORMED
  # variable above.
  if [ $CURRENT_IP != $REGISTERED_IP ] ; then
    echo "New IP adress: $CURRENT_IP" | mail $INFORMED -s "IP adress of $HOSTNAME has changed"
    echo "A mail has been sent to $INFORMED."
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_public_ip ()
{
  echo $(wget http://checkip.dyndns.org/ -O - -o /dev/null | awk '{ print  $6 }' | cut -d\< -f 1)

  #[ -z "$(which curl)" ] && __package_cp -y install curl
  #incomming_host=`curl -s ifconfig.me`
}

#external_ip ()
#{
#
#  curl version (e.g. OS X)
#  curl -s myip.dk |grep '"Box"' | egrep -o '[0-9.]+' \
    --back --exit
#  wget version (e.g. Linux)
#  wget -O - -q myip.dk |grep '"Box"' | egrep -o '[0-9.]+' \
    --back --exit
#  return
#}

#public_ip ()
#{
#  curl -s myip.dk |grep '"Box"' | egrep -o '[0-9.]+' \
    --back --exit
#  return
#
#}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_local_ip ()
{
  # local_ip="192.168.0.15"
  ask_var 'network_interface' 'Select a network interface (Ex: eth0) : '
  echo $(/sbin/ifconfig $network_interface | grep -Po 'adr:([0-9]{1,3}\.){3}[0-9]{1,3}' | cut -d: -f2)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_ip_nat()
{
  # $1 interface

  ## The -n option retrieves the Internet IP address
  ## if you are behind a NAT
  if [ "$1" = "-n" ]
  then
    ip=$(lynx -dump http://cfaj.freeshell.org/ipaddr.cgi)
  else
    if=$1   ## specify which interface, e.g. eth0, fxp0
    system=$(uname)
    case $system in
      FreeBSD) sep="inet " ;;
      Linux) sep="addr:" ;;
    esac
    temp=$(ifconfig $if)
    temp=${temp#*"$sep"}
    ip=${temp%% *}
  fi

  printf "%s${IFS}" "$ip"
  ### CFAJ ###

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_wol()
{
  incomming_host=`curl -s ifconfig.me`
  port=9

  __package_cp install wakeonlan
  sed -r -i 's/(NETDOWN[ \t]*=[ \t]*).*$/\1no/' ${service_path}halt
  nc -z $incomming_host $port
  [ ! $? -eq 0 ] && echo -e "\033[31mPort $port is closed.\033[0m\nAdd the following redirection to your router to enable WOL.\nPort $port TCP $(hostname -i)"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Lan management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"