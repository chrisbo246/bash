#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__debconf_menu()
{
  while true; do
    __menu \
    -t 'Debconf menu' \
    -o 'Select a debconf owner' \
    -o 'Export debconf database' \
    --back --exit

    case $REPLY in
      1) select_debconf_owner;;
      2) export_debconf_database;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_debconf_owner()
{
  while true; do
    options=$(debconf-show --listowners | sort)
    __menu -t 'Debconf owners' $(printf ' -o %s' $options) --back --exit
    select_debconf_action "$VALUE"
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_debconf_action()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit
  [ -z "$(which debconf-show)" ] && __package_cp install debconf-utils

  while true; do
    __menu \
    -t "$1 actions" \
    -o 'Reconfigure' \
    -o 'Show configuration' \
    -o 'Show configuration (ready-to-use)' \
    --back --exit

    case $REPLY in
      1) dpkg-reconfigure $1;;
      2) debconf-show $1;;
      3) debconf-show $1 | sed -r "s|^[ \t\*]*([^:]+):(.*)$|echo 'set \1\2' \| debconf-communicate|g";;
    esac
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
export_debconf_database()
{
  [ -z "$(which debconf-get-selections)" ] && __package_cp install debconf-utils
  default_filename="${file_prefix}preseed_$(hostname -f).cfg"
  read -p "Enter filename [$default_filename]:" filename  
  debconf-get-selections > "${filename:-$default_filename}"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='Debconf package functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

##echo "__package_cp -q install debconf-utils" >> restore.sh
#list=$(ls /var/lib/dpkg/info/*.templates | xargs -n 1 basename | sed -e "s/.templates$//")
#for package in $list; do
  #debconf-show $package | grep -P "^\*" | sed -r "s|\* ([^ ]+):([ ]?)(.*)?$|echo \"set \1\2\3\"  \| debconf-communicate|" >> "$filename"
#done  

#debconf-get-selections (--installer) generated preseed.cfg
#owner key/subkey value
#debconf                 debconf-communicate     debconf-escape          debconf-get-selections  debconf-mergetemplate   debconf-show
#debconf-apt-progress    debconf-copydb          debconf-getlang         debconf-loadtemplate    debconf-set-selections
