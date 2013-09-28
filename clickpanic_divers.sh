#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mofifie la valeur d'une variable dans un fichier de configuration
# Séparateur = : ou espace
# Modifie également lorsque la ligne est précédée de #
# Attention !!! supprime les commentaires de fin de ligne
set_confvar ()
{

  filename=$1
  key=$2
  value=$3
  sed -r "s%(^[ #$'\t']*$key[ $'\t']*[ $'\t'=:]{1}[ $'\t']*)(.*)+([#]+.*)?\$%\1 $value \3%" $filename -i

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_confvar ()
{

  filename=$1
  key=$2

  value=$( awk "/$key/ {print \$2}" $filename )
  if [ "$value" = "=" ]; # || [ "$value"=":" ];
  then
    value=$( awk "/$key/ {print \$3}" $filename )
  fi
  echo $value

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Décommente une ligne correspondant à une variable dans un fichier de configuration
enable_confvar ()
{

  filename=$1
  key=$2

  sed "s|^[ #;$'\t']* $key|$key|" $filename -i

  #décommente une ligne
  # sed '/# bind-address/{:label;/^$/q;n;s/^#//;t label;}'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disable_confvar ()
{

  filename=$1
  key=$2
  sed -r "s|^[ $'\t']*$key([ =:$'\t']{1}.*)|# $key\1|" $filename -i

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
error_msg ()
{

  if [ "$PIPESTATUS" != "0" ]; then
    echo "Une erreur est survenue"
    echo "Une erreur est survenue "
    exit 100;
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Just reset the terminal to normal

function _quit() {
  reset -Q
  echo "Exiting Bye"
  exit 0
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# center the text on the screen by finding the horizontal center with max_lines
# max_lines divided by two becomes the center line(aka. line_num)
# use the max lenght of the line divided in half to find the center column
# subtract half the output string from the center to create the offset to indent

function center_txt() {
  PROMPT="$1"
  str_len=${#PROMPT}
  indent=$(( ((max_cols / 2)) - ((str_len / 2)) ))
  line_num=$(( max_lines / 2 ))
  tput cup ${line_num} ${indent}
  echo "$PROMPT"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# indent_txt is intended to be used AFTER center_txt
# indent_txt just prints on the current line and centers the text horizontally
# line_num is global, so main keeps track of incrementing it

function indent_txt() {
  PROMPT="$1"
  str_len=${#PROMPT}
  indent=$(( ((max_cols / 2)) - ((str_len / 2)) ))
  tput cup ${line_num} ${indent}
  echo "$PROMPT"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mk_prompt creates an input prompt for the the read function
# 'read -p "==> " variable' would work, but I like this better

function mk_prompt() {
  ((line_num+=2))
  tput cup $line_num 15
  PROMPT="==> "
  echo -n "${blink}${PROMPT}"
  echo -n ${offblink}
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ask_var ()
{
  varname=$1
  message=$2

  if [[ $$varname ]] ; then

  else
    echo -n "$message"
    $( echo "read $varname" )
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ask_password ()
{

  if [[ $2 ]] ; then
    prompt="Password:"
  else
    prompt=$2
  fi

  if [[ $1 ]] ; then

  else
    varname=$1
    read -s -p $prompt $varname
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Include all files in gived directory

include_dir ()
{

  if [ $# > 0 ];
  then
    for dir in $*
    do
      if [ -d $dir ];
      then
        # Charge les fichiers de configuration
        for i in $dir
        do
          if [ -x "$i" ] ;
          then
            . "$i"
          fi
        done
      else
        echo "fail to include files
        $dir is not a directory"
      fi
    done
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
replace_anywhere ()
{

  path=$1
  search=$2
  replace=$3

  grep -lre "$search" . | while read path; do
    sed -ir "s|$search|$replace|g" "$path"
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
explode ()
{
  string=$1
  if [ $string == '' ]; then
    read -p'Enter string : ' string
  fi

  separator=$2
  if [ $separator == '' ]; then
    read -p'Enter separator : ' separator
  fi

  $option

  case $option in
    "--skip-empty")
      # Skip empty values
    echo $string | nawk -F"$separator" '{$1=$1; print}' ;;
    default)
    echo $string | nawk -F"$separator" '{for(i=1;i<=NF;i++) print $i}' ;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Print runing script file

print_script ()
{

  more $0

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_distrib()
{

  found=0;
  if [ -e ${config_path}SuSE-release ]; then echo "suse"; export found=1; fi
  if [ -e ${config_path}redhat-release ]; then echo "redhat"; export found=1; fi
  if [ -e ${config_path}fedora-release ]; then echo "fedora"; export found=1; fi
  if [ -e ${config_path}debian-version ]; then echo "debian"; export found=1; fi
  if [ -e ${config_path}slackware-version ]; then echo "slackware"; export found=1; fi
  if ! [ $found = 1 ]; then echo "unknow"; fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
backup_file()
{

  file=$1

  if [ -e "$file" ]; then
    if [ ! -e "$file.org" ]; then
      cp "$file" "$file.org"
    fi
    cp "$file" "$file.bak"
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OuiNon -- Saisie réponse Oui/Non
# Appel:  $1 = Question
#         $2 = Réponse par défaut
# Status: 0  = Oui
#         1  = Non
#
# Utilisation de la fonction
# if OuiNon "Voulez vous affichez la date ? " Oui
#    then  date
#    else  echo "Dommage"
# fi

OuiNon()
{
  local qst def rep
  qst="${1:-'Oui ou Non ? '}"
  def="$2"
  while :
  do
    read -p "$qst" rep || exit 1
    case "$(echo "${rep:-$def}" | tr '[a-z]' '[A-Z]')" in
      O|OUI|Y|YES) return 0 ;;
      N|NON|NO)    return 1 ;;
      "" )          :        ;;
      *)           echo "Réponse invalide: $rep" ;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Menu - Affichage d'un menu
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Args : $1    = Titre du menu
#        $2n   = Fonction associée 'n' au choix
#        $2n+1 = Libellé du choix 'n' du menu
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Menu_test()
{
  local -a menu fonc
  local titre nbchoix

  # Constitution du menu

  if [[ $(( $# % 1 )) -ne 0 ]] ; then
    echo "$0 - Menu invalide" >&2
    return 1
  fi

  titre="$1"
  shift 1

  set "$@" "return 0" "Sortie"
  while [[ $# -gt 0 ]]
  do
    (( nbchoix += 1 ))
    fonc[$nbchoix]="$1"
    menu[$nbchoix]="$2"
    shift 2
  done

  # Affichage menu

  PS3="Votre choix ? "
  while :
  do
    echo
    [[[ $titre ]]] && echo -e "$titre${IFS}"
    select choix in "${menu[@]}"
    do
      if [[ ! $choix ]]
      then echo -e "${IFS}Choix invalide"
      else eval ${fonc[$REPLY]}
      fi
      break
    done || break
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Ask user before execute command passed in parameter
ask_command()
{
  if [ $1 -ne 0 ]; then
    command=$1
    select yn in "y" "N"; do
      case $yn in
        y ) echo `$command` >&2; return true;;
        n ) return false;;
      esac
    done
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remove left and right whitespace from a string
trim()
{
  trimmed=$1
  trimmed=${trimmed%% }
  trimmed=${trimmed## }

  echo $trimmed
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Divers helpers functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"