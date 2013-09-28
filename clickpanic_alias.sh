#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__alias_menu ()
{
  while true; do
    __menu \
    -t 'Alias menu' \
    -o 'Select an alias (temporary or permanent)' \
    -o 'Select an alias alternative' \
    --back --exit
    
    case $REPLY in
      1) select_alias;;
      2) select_alternatives;;
      #1) select_alias_action "$(select v in $(compgen -a | sort); do [ -n "$v" ] && echo $v && break; done)";;
      #2) select_alternatives_action "$(select v in $(update-alternatives --get-selections | awk '{print $1}' | sort); do [ -n "$v" ] && echo $v && break; done)";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_alias_action ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} $LINENO : Function wait for an argument."  >&2 && exit 65
  while true; do
    __menu \
    -t "$1 actions" \
    -o "Delete '$1'" \
    --back --exit
    
    case $REPLY in
      1) delete_alias "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_alternatives_action ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit

  while true; do
    __menu \
    -t "$1 actions" \
    -o "Configure '$1'" \
    --back --exit
    
    case $REPLY in
      1) update-alternatives --config "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_alias()
{
  while true; do
    options=$(compgen -a | sort)  
    __menu -t 'Defined aliases' $(printf ' -o %s' $options) --back --exit
    select_alias_action "$VALUE"
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_alternatives()
{
  while true; do
    options=$(update-alternatives --get-selections | awk '{print $1}' | sort)  
    __menu -t 'Defined alternatives' $(printf ' -o %s' $options) --back --exit
    select_alternatives_action "$VALUE"
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
delete_alias()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit
  
  unalias "$1"
  
  # If this is a permanent alias, delete it
  for filename in ~/.bashrc ~/.bash_aliases; do
    if [ -f "$filename" -a -n "$(grep -P '^\s*alias +'"$1"'=' "$filename")" ]; then
      sed -r -i '/^\s*alias +'"$1"' *=.*$/d' "$filename"
    fi
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Alias managment functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

# Voir 
#update-alternatives --get-selections
#update-alternatives --config editor