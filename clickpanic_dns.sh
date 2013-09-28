#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_nameservers()
{
  [[ $(which resolvconf) ]] && echo "The resolv.conf file will be overwrited by resolvconf program so it should no be edit."  >&2&& return
  filename=/etc/resolv.conf
  editor "$filename" && resolvconf -u
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fix_dns()
{
  filename=/etc/resolv.conf
  [ -z "$(grep -P '\s*nameserver\s+((?!192\.168\.)[^\s])+' "$filename")" ] && echo "$filename do not contain any external nameserver"
  
  filename=/etc/network/interfaces
  [[ $(which resolvconf) && -z "$(grep -P '\s*dns-nameservers\s+[^\s]+' "$filename")" ]] && echo -e "Main network interface should have a dns-nameservers declaration\nYou can use Google public DNS by adding 'dns-nameservers 8.8.8.8,8.8.4.4' to $filename."

  filename=$(find /etc/ -type f -regex '/etc/dhcp\d?/dhclient.conf' | head -n1)
  #prepend domain-name-servers 8.8.8.8, 8.8.4.4;
  
  #nameserver 8.8.8.8
  #nameserver 8.8.4.4
  #nameserver 2001:4860:4860::8888
  #nameserver 2001:4860:4860::8844
  #nameserver 212.27.40.240
  #nameserver 212.27.40.241
  #nameserver 192.168.0.254
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='DNS management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"