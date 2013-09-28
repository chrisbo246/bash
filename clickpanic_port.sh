#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__port_menu()
{
  while true; do
    echo -e "${IFS}Port manager${IFS}"
    PS3="Select action :"
    exit='[EXIT]'
    back='[BACK]'
    select action in "check_listened_ports" "scan_ports" "$exit"; do
      case $action in
        "$exit" ) break 100;;
        "check_listened_ports" ) check_listened_ports; break;;
        "scan_ports" ) scan_ports; break;;
      esac
    done
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check_listened_ports()
{

  local tcp_ports udp_ports

  #[ -z "$(which curl)" ] && __package_cp -y install curl
  #incomming_host=`curl -s ifconfig.me`
  local incomming_host=$(wget http://checkip.dyndns.org/ -O - -o /dev/null | awk '{ print  $6 }' | cut -d\< -f 1)
  local outgoing_host="portquiz.net"

  while read line; do

    local port=$(echo "$line" | awk '{print $1}')
    local protocol=$(echo "$line" | awk '{print $2}')
    
    case "$protocol" in
      tcp|tcp6 ) ports+=("T:$port");;
      udp|udp6) ports+=("U:$port");;
    esac

  done < <(netstat -tulnp | tail -n +3 | sed -r "s/^([a-z]{3})[0-9]*[ \t]+[0-9]+[ \t]+[0-9]+[ \t]+[0-9a-z.:\*]+[:]+([0-9]+)[ \t]+[0-9a-z.:\*]+[ \t]+([A-Z]*)[ \t]+[0-9]+\/(.+)$/\2\t\1\t\4\t\3/" | awk '!x[$0]++' | sort -g)
  
  
  #string=$(printf "%s$delimiter" "${udp_ports[@]}"); udp_ports=${string%$delimiter}
  #string=$(printf "%s$delimiter" "${tcp_ports[@]}"); tcp_ports=${string%$delimiter}
  delimiter=','; string=$(printf "%s$delimiter" "${ports[@]}"); string=${string%$delimiter}
  [ -z "$(which nmap)" ] && __package_cp -y install nmap
  nmap -sTU -p "$string" $incomming_host
  #nmap -sTU -p "U:$udp_ports,T:$tcp_ports" $incomming_host  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____check_listened_ports_old()
{

  local tcp_ports udp_ports outgoing_status incoming_status

  #[ -z "$(which curl)" ] && __package_cp -y install curl
  #incomming_host=`curl -s ifconfig.me`
  local incomming_host=$(wget http://checkip.dyndns.org/ -O - -o /dev/null | awk '{ print  $6 }' | cut -d\< -f 1)
  local outgoing_host="portquiz.net"

  while read line; do

    local port=$(echo "$line" | awk '{print $1}')
    local protocol=$(echo "$line" | awk '{print $2}')
    local program=$(echo "$line" | awk '{print $3}')
    local listen=$(echo "$line" | awk '{print $4}')

    case "$protocol" in
      tcp|tcp6 ) local options=''; tcp_ports+=($port);;
      udp|udp6) local options='-u -b'; udp_ports+=($port);;
    esac

    nc -i 2 -w 2 -z $options $outgoing_host $port
    if [ $? -eq 0 ]; then
      outgoing_status="\033[32mopen\033[0m"
    else
      outgoing_status="\033[31mclosed\033[0m"
    fi

    nc -z $options $incomming_host $port
    if [ $? -eq 0 ]; then
      incomming_status="open"
      if [ "$listen" == 'LISTEN' ]; then
        incomming_status="\033[32m$incomming_status\033[0m"
      else
        incomming_status="\033[32m$incomming_status\033[0m"
      fi
    else
      incomming_status="closed"
      if [ "$listen" == 'LISTEN' ]; then
        incomming_status="\033[31m$incomming_status\033[0m"
      else
        incomming_status="\033[31m$incomming_status\033[0m"
      fi
    fi

    echo -e "Port $port $protocol ($program $listen) is $outgoing_status to outgoing and $incomming_status to incomming connections."

  done < <(netstat -tulnp | tail -n +3 | sed -r "s/^([a-z]{3})[0-9]*[ \t]+[0-9]+[ \t]+[0-9]+[ \t]+[0-9a-z.:\*]+[:]+([0-9]+)[ \t]+[0-9a-z.:\*]+[ \t]+([A-Z]*)[ \t]+[0-9]+\/(.+)$/\2\t\1\t\4\t\3/" | awk '!x[$0]++' | sort -g)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
scan_ports()
{
  [ -z "$(which curl)" ] && __package_cp -y install curl
  ip=`curl -s ifconfig.me`
  [ -z "which nmap" ] && __package_cp install nmap
  nmap "$ip" -p0-65500
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Port management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"