#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
menu_vpn ()
{

  menu_title="ERP softwares"
  declare -a menu_items
  -o 'Install Cisco VPN' \
  -o 'Install PPTP VPN' \
  -o 'Configure VPN' \
  menu_text="Enter your choice : "

  while true
  do
    menu

    case $choice in
      1) install_cisco_vpn ;;
      2) install_pptp_vpn ;;
      3) config_vpn ;;
    esac
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Cisco VPN
install_cisco_vpn()
{

  __package_cp -u install network-manager-vpnc
  #sudo mv /dev/random /dev/orandom
  #sudo ln /dev/urandom /dev/random

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_pptp_server()
{

  __package_cp -u install pptpd

  config_pptp_vpn

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_pptp_vpn_user()
{

  read -p'Enter user name : ' username
  read -p'Enter password : ' password

  backup_file ${config_path}ppp/chap-secrets
  echo "${username} pptpd ${password} \"*\"" | sudo tee -a ${config_path}ppp/chap-secrets
  editor ${config_path}ppp/chap-secrets

  # Kill the pptpd service and start it
  sudo killall pptpd
  sudo pptpd

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PPTP
install_pptp_vpn
{

  __package_cp -u install pptp-linux network-manager-pptp
  sudo NetworkManager restart
  echo 'You should open:
port 1723 TCP for PPTP
port 1701 UDP for L2TP
  then restart'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_pptp_vpn()
{

  mask=$( echo $local_ip | nawk -F'.' '{ print $1 "." $2 "." $3 }' )

  # Set current server IP
  backup_file ${config_path}pptpd.conf
  sudo sed "s|#localip |localip |"
  sudo sed "s|#remoteip |remoteip |"
  sudo sed "s|localip .*$|localip $local_ip|"
  sudo sed "s|remoteip .*$|remoteip ${mask}.234-238,${mask}.245|"
  editor ${config_path}pptpd.conf

  # Add user
  backup_file ${config_path}ppp/chap-secrets
  editor ${config_path}ppp/chap-secrets

  #echo "
  #pty \"pptp pptp.vpn.nixcraft.com --nolaunchpppd\"
  #name ${vpn_username}
  #remotename ${vpn_remotename}
  #require-mppe-128
  #file ${config_path}ppp/options.pptp
  #ipparam ${vpn_server}" | sudo tee ${config_path}ppp/peers/${vpn_server}
  #  editor ${config_path}ppp/peers/delhi-idc-01

  # To route traffic via PPP0 interface add following route command to ${config_path}ppp/ip-up.d/route-traffic
  # Append following sample code (modify NET an IFACE as per your requirments):
  #echo "
  #!/bin/bash. global.sh
  #NET=\"10.0.0.0/8\" # set me
  #IFACE=\"ppp0\" # set me
  #IFACE=\$1
  #route add -net \${NET} dev \${IFACE}" | sudo tee -a ${config_path}ppp/ip-up.d/route-traffic
  #editor ${config_path}ppp/ip-up.d/route-traffic

  # chmod +x ${config_path}ppp/ip-up.d/route-traffic

  sudo killall pptpd
  sudo pptpd

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='VPN management functions'
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
