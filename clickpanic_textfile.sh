#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__textfile_menu ()
{
  while true; do
    __menu \
    -t 'Text File' \
    -o 'Convert Dos file to Unix format' \
    -o 'Replace string in all files' \
    --back --exit

    case $REPLY in
      1) convert_dos2unix;;
      2) replace_all;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Conversion fichier DOS en fichier UNIX (suppression des ctrl M)
convert_dos2unix ()
{

  # saisie nom de fichier a convertir
  if [ $# -lt 1 ]
  then
    echo -n "Fichier(s) a convertir :"
    read F
  else
    F=$*
  fi

  # traitement fichiers
  for fic in $F
  do
    if [ ! -f $fic ]
    then
      echo "$fic n\'est pas un fichier valide"
      continue
    else
      typ=`file $fic|grep -i -E "text|shell"`
      if [ "${typ}a" = "a" ]
      then
        echo Fichier $fic Non ASCII
      else
        tr -d "\015\023" <$fic >${fic}.$$
        # aclget $fic | aclput ${fic}.$$
        mv ${fic}.$$ $fic
        echo "$fic converti"
      fi
    fi
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
replace_all () # replace_where
{
  where="$1"
  if [ "$where" == '' ]; then
    read -p'Enter path where to search : ' where
  fi

  search="$2"
  if [ "$search" == '' ]; then
    read -p'Enter string to search : ' search
  fi

  replace="$3"
  if [ "$replace" == '' ]; then
    read -p'Replace by : ' replace
  fi

  grep -lre "$search" "$where" | while read path; do
    sed -ir "s|$search|$replace|g" "$path"
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_where()
{

  search=$1
  if [ "$search" == '' ]; then
    read -p'Enter string to search : ' search
  fi

  from=$2
  if [ "$from" == '' ]; then
    read -p'Enter path where to search : ' from
  fi

  # Modifie chaque fichier contenant l'ancien chemin
  grep -lre "$search" "$from" | while read path; do
    editor $path &
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Text file management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"