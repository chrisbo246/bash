#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__service_menu ()
{
  while true; do
    local options=$(ls ${service_path} | sort)
    #local options=$(compgen -s | sort | awk '!x[$0]++')

    __menu -t 'Service' $(printf ' -o %s' $options) --back --exit

    [[ $REPLY -ge 1 && $REPLY -le ${#options[@]} ]] && select_service_action $VALUE;
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_service_action()
{
  while true; do
    local options=$("${service_path}$1" -h | sed -r "s|^.*[\[\{\( ]+([a-z\|-]+)[\]\}\) ]+.*$|\1|" | tr "|" "${IFS}")
    menu -t 'Service' $(printf ' -o %s' $options) --back --exit

    [[ $REPLY -ge 1 && $REPLY -le ${#options[@]} ]] && service $1 $VALUE;
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Service management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
