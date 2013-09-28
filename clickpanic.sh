#!/bin/bash

script_short_description='Helpers'
script_version='0.0.1'

#    echo '$BASH_SUBSHELL:'$BASH_SUBSHELL
#    echo '$SHLVL:'$SHLVL
#[[ "$(declare -Ff '__menu')" ]]  >&2&& return
#echo $(ps -e -o cmd | grep --color clickpanic)
#pgrep -f "/bin/\w*sh $BASH_SOURCE" | grep -vq $$  >&2&& return
#[[ $(pgrep -f "/bin/\w*sh $BASH_SOURCE") ]] && return
#echo "LOAD HELPERS"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__main_menu()
{

  while true; do
    escaped_prefix=$(escape_string --sed "${file_prefix}")
    options=$(find "$(dirname $0)" -type f -regex "${file_prefix}.*\.sh" | sed -r 's/^'"$escaped_prefix"'(.*).*\.sh$/\1/' | sort)
    
    __menu -t 'Helpers' $(printf ' -o %s' $options) --back --exit
    
    filename="${file_prefix}${VALUE}.sh"
    if [ -e "$filename" ]; then
      include_once "$filename"
      "__${VALUE}_menu"
    fi
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__install()
{
  # Install completion script  
  local filename=${config_path}bash_completion.d/$(basename "${BASH_SOURCE%.*}")
  cat > "$filename" <<EOF
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_clickpanic_complete()
{
    local cur prev opts
    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"
    opts=\$(grep -Po '^\h*(function\h+)?[a-zA-Z0-9_-]+\h*\(\h*\)\h*(\{|$|#)' "\$1" | sed 's/function[ \t]+//; s/[ \t(){#]//g' | grep -Pv '^_+' | sort)

    if [[ \${cur} == * && \${COMP_CWORD} -eq 1 ]] ; then
        COMPREPLY=( \$(compgen -W "\${opts}" -- \${cur}) )
        return 0
    fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for filename in \$(find $(dirname "$BASH_SOURCE") -maxdepth 1 -type f -name "$(basename ${BASH_SOURCE%.*})*.sh"); do
  basename=\$(basename "\$filename")
  eval '_'"\${basename%.*}"'() { _clickpanic_complete "'"\$filename"'"; };'
  eval 'complete -F _'"\${basename%.*}"' '"\$basename"
done
EOF
  chmod u+x "$filename"
  . "$filename"
  #exec bash
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
available_functions()
{
  local list=()
  for filename in $(find $(dirname "$BASH_SOURCE") -maxdepth 1 -type f -name "$(basename ${BASH_SOURCE%.*})*.sh"); do
    for funct in $(grep -Po '^\h*(function\h+)?[a-zA-Z0-9_-]+\h*\(\h*\)\h*(\{|$|#)' "$filename" | sed 's/function[ \t]+//; s/[ \t(){#]//g' | grep -Pv '^_+' | sort); do
      list+=( "$funct;$filename" )
    done
  done
  printf -- "%s${IFS}" "${list[@]}" | sort
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__uninstall()
{
  # Remove completion script
  local filename=${config_path}bash_completion.d/$(basename "${BASH_SOURCE%.*}")
  [[ -f "$filename" ]] && rm "$filename"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__menu()
{
  #[[ ! $menu_titles ]] && menu_titles=()
  local menu_options values
  local menu_prompt='Enter a number'
  local title='Menu '$((${#menu_titles[@]}+1))
  local back_level=2
  (( menu_level++ ))

  read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Select menu

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-t|--title string] [-o|--option string]... [-p|--prompt string] [--back [integer]] [--exit]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

DESCRIPTION
    Return $REPLY (the number) and $VALUE (the option text).

OPTIONS
    -t, --title
        Menu title.
    -o, --option
        The list of menu options.
    -p, --prompt
        A optionnal prompt text.
    --all
        Add an option to return all values.
    --back
        Add an option to go back to previous menu: You can provide an optional back level.
    --exit
        Add an option to exit all loops to reach the end of the script.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "t:o:p:h" -l "title:,options:prompt:,all,back::,exit,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -t|--title) shift; title=${1:-"$title"}; shift;;
      -o|--options) shift; values+=("$1"); menu_options+=("$1"); shift;;
      -p|--prompt) shift; menu_prompt="${1:-$menu_prompt}"; shift;;
      --back)
        shift
        if [[ $menu_level > 1 ]]; then
          menu_options+=('< BACK>')          
          local back_reply=${#menu_options[@]}          
        fi
        back_level=${1:-$back_level}
        shift
        ;;
      --exit) shift; menu_options+=('< EXIT >'); local exit_reply=${#menu_options[@]};;
      --all) shift; menu_options+=('< ALL >'); local all_reply=${#menu_options[@]};;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  echo
  menu_titles+=("$title")
  local delimiter=' > '; string=$(printf "%s$delimiter" "${menu_titles[@]}"); echo ${string%$delimiter}

  PS3="$menu_prompt [1-$((${#menu_options[@]}+2))]:"
  select VALUE in "${menu_options[@]}"; do
    case $REPLY in
    ( $((( $REPLY >= 1 && $REPLY <= ${#menu_options[@]} )) && echo $REPLY) ) break;;
    ( ${back_reply:-back} )
      unset menu_titles[${#menu_titles[@]}-1] menu_titles[${#menu_titles[@]}-1]      
      unset VALUE
      (( menu_level-- ))      
      break $back_level
      ;;
    ( ${all_reply:-all} ) VALUE=$values;;
    ( ${exit_reply:-exit} ) exit 65;;
    ( * ) echo "Invalid answer. Try another one."; continue;;
    esac
  done
  #( $(( ${#menu_options[@]}+${#more_options[@]}-1 )) ) unset menu_titles[${#menu_titles[@]}-1]; unset menu_titles[${#menu_titles[@]}-1]; $VALUE=''; break 2;;
  #( $(( ${#menu_options[@]}+${#more_options[@]})) ) exit 65;;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__package_cp()
{
  local options

    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Cross platform package managment

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-f|--force] { install | uninstall package... }
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -f, --force
        Try to resolve conflicts.
    -p, --purge

    -q, --quiet

    -qq

    -u, --show-upgraded

    -y, --yes
        Ask yes for all questions.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  # Supported package managers
  # The first available will be used so you can reorder the list to change priority.
  # Cross-platform managers should be at end.
  # http://en.wikipedia.org/wiki/List_of_software_package_management_systems
  # RPM http://pwet.fr/man/linux/administration_systeme/rpm
  local installers=(apt-get yum rpm dpkg) # pkg(ips) aptitude pacman
  local installer=$(echo -e "$(which ${installers[@]})" | head -n1 | grep -o '[^/]*$')

  local ARGS=$(getopt -o "fpqyh" -l "force,force-yes,purge,quiet,reinstall,show-upgraded,yes,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
      * ) options="${options} $1"
    esac
  done

  # The first argument should be the task
  [ -z "$1" ] && echo "${IFS}${help}${IFS}"  >&2 && exit 65
  local task="$1"
  shift

  case $task in
  clean )
    case $installer in
    apt-get ) apt-get $options clean;;
    #aptitude ) aptitude $options clean;;
    dpkg ) dpkg $options --clear-selections --set-selections;;
    #rpm ) ;;
    yum ) yum $options clean;;
    esac
    ;;
  configure )
    for package in "$@"; do
      case $installer in
      apt-get ) apt-get $options configure $package;;
      #aptitude ) ;;
      dpkg ) dpkg $options --configure $package;;
      #rpm ) ;;
      yum ) yum $options configure $package;;
      esac
    done
    ;;
  install)
    for package in "$@"; do
      case $installer in
      apt-get ) apt-get $options install $package;;
      aptitude ) aptitude $options install $package;;
      dpkg ) dpkg $options --install $package;;
      rpm ) rpm $options --install ${package}+;;
      yum ) yum $options install $package;;
      esac
    done
    ;;
  list_installed)
    for package in "$@"; do
      case $installer in
      #apt-get ) ;;
      aptitude ) aptitude search -F '%p' '~i';;
      dpkg ) dpkg --get-selections
        #test=$(dpkg-query --show --showformat=${Status}"${IFS}" $package | grep 'install ok installed')
      ;;
      #rpm ) rpm -q --queryformat '%{NOM}';;
      yum ) yum list installed;;
      esac
    done
    ;;
  is_installed)
    for package in "$@"; do
      case $installer in
      #apt-get ) ';;
      aptitude ) aptitude search -F '%p' '~i' | grep -P '^'$package'(\s+|^)';;
      dpkg ) dpkg --get-selections | grep -P '^'$package'\t+install$';;
      rpm ) rpm --print-package-info=$package;;
      yum ) yum list installed $package;;
      esac
    done
    ;;
  purge )
    for package in "$@"; do
      case $installer in
      apt-get ) apt-get $options --purge remove $package;;
      aptitude ) aptitude $options purge $package;;
      dpkg ) dpkg $options --purge $package;;
      #yum ) yum $options --purge remove $package;;
      esac
    done
    ;;
  reinstall )
    for package in "$@"; do
      case $installer in
      apt-get ) apt-get $options --reinstall install $package;;
      aptitude ) aptitude reinstall $package;;
      #dpkg ) dpkg $options --reinstall $package
      #rpm ) ;;
      #yum ) yum $options --reinstall install $package;;
      esac
    done
    ;;
  remove)
    for package in "$@"; do
      case $installer in
      apt-get ) apt-get $options remove $package;;
      aptitude ) aptitude $options remove $package;;
      dpkg ) dpkg $options --remove $package;;
      rpm ) rpm $options --uninstall ${package}+;;
      yum ) yum $options remove $package;;
      esac
    done
    ;;
  update )
    case $installer in
    apt-get ) apt-get $options update;;
    aptitude ) aptitude $options update;;
    dpkg ) dpkg $options update;;
    rpm ) rpm $options --rebuild;;
    yum ) yum $options update;;
    esac
    ;;
  upgrade )
    for package in "$@"; do
      case $installer in
      apt-get ) apt-get $options upgrade;;
      #aptitude ) aptitude $options update;;
      #dpkg ) dpkg $options update;;
      rpm ) rpm $options -U $package;;
      #yum ) yum $options update;;
      esac
      [ -z "$package" ] && break
    done
    ;;    
  esac
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____edit_configuration()
{
  while true;  do
    menu /
    -t 'Edit configuration'
    -o 'Network interfaces' \
    -o 'Hosts' \
    -o 'Hostname' \
    -o 'Portfix' \
    -o 'MySQL' \
    -o 'Apache available modules' \
    -o 'Mime types' \
    -o 'Aliases' \
    -o 'Pure-FTPd' \
    -o 'Pure-FTPd TLS' \
    -o 'Mount table' \
    -o 'AW stats' \
    -o 'Failban jail' \
    -o 'Fail2ban Pure-FTPd custom filter' \
    -o 'Fail2ban dovecote custom filter' \
    -o 'Squirrelmail' \
    -o 'Postfix' \
    -o 'Cron task' \
    --back --exit

    case $REPLY in
      1 ) editor ${config_path}network/interfaces; ${service_path}networking reload;;
      2 ) editor ${config_path}hosts;;
      3 ) editor ${config_path}hostname; ${service_path}hostname.sh reload;;
      4 ) editor ${config_path}postfix/master.cf; ${service_path}postfix reload;;
      5 ) editor ${config_path}mysql/my.cnf; ${service_path}mysql reload;;
      6 ) editor ${config_path}apache2/mods-available/suphp.conf; ${service_path}apache2 reload;;
      7 ) editor ${config_path}mime.types;;
      8 ) editor ${config_path}aliases;;
      9 ) editor ${config_path}default/pure-ftpd-common; ${service_path}pure-ftpd-mysql reload;;
      10 ) editor ${config_path}pure-ftpd/conf/TLS; ${service_path}pure-ftpd-mysql reload;;
      11 ) editor ${config_path}fstab; mount -o remount /; mount -a;;
      12 ) editor ${config_path}cron.d/awstats; a2ensite awstats;;
      13 ) editor ${config_path}fail2ban/jail.local; ${service_path}fail2ban reload;;
      14 ) editor ${config_path}fail2ban/filter.d/pureftpd.conf; ${service_path}fail2ban reload;;
      15 ) editor ${config_path}fail2ban/filter.d/dovecot-pop3imap.conf; ${service_path}fail2ban reload;;
      16 ) editor ${config_path}apache2/conf.d/squirrelmail.conf; ${service_path}apache2 reload;;
      17 ) editor ${config_path}postfix/main.cf; ${service_path}postfix reload;;
      17 ) crontab -e;;
      #${service_path}mailman
      #${service_path}amavis
    esac

    [[ $REPLY -ge 1 && $REPLY -le ${#options[@]} ]] && [ -e "$VALUE" ] && editor "$VALUE"

  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
escape_string()
{

  local type="ere"
  local s="/" #sed separator
  local q="'" #sed quote

    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Escape special characters

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-s|--sed|-g|--grep|-p|--perl|-b|--bre|-e|--ere]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

$global_help
EOF

  local ARGS=$(getopt -o "sgpbeh" -l "sed,grep,perl,bre,ere,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case $1 in
      -s|--sed) shift; type='sed';;
      -g|--grep) shift; type='grep';;
      -p|--perl) shift; type='perl';;
      -b|--bre) shift; type='perl';;
      -e|--ere) shift; type='perl';;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  [ -z "$*" ] && echo "${IFS}${help}${IFS}"  >&2 && exit 65;

  local bre_char='\^\.\*\[\$\\'
  local ere_char=$bre_char'\(\)\|\+\?\{'
  local escaped_characters

  case $type in
    'sed' ) escaped_characters=$bre_char'\\'$q'\\'$s;;
    'grep' ) escaped_characters=$bre_char'\\'$q;;
    'perl' ) escaped_characters=$ere_char'\\'$q'\\'$s;;
    'bre' ) escaped_characters=$bre_char'\\'$q;;
    * ) escaped_characters=$ere_char'\\'$q;;
  esac

  for value in "$@"; do
    echo "$value" | sed -e 's'$s'['"$escaped_characters"'&]'$s'\\&'$s'g'
  done

  #;delimiter='</ \>'; printf "%s$delimiter" "${array[@]}" | sed "s/$(echo "$delimiter" | sed -e 's/['"\^\.\*\[\$\\\'\/ "'&]/\\&/g')$//"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
progress_bar()
{
  [ ! $# -eq 2 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} $LINENO : Function wait for two arguments."  >&2 && exit 65
  
  # http://www.utf8-chartable.de/unicode-utf8-table.pl
  local progress_char='\u25a0' # \u2588 \u25FC
  local remaining_char='\u25a1' # \u2591 \u25FB
  local number=0
  local width=20
  
    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Display a progress bar

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [--progress_char char] [--remaining_char char] [-w|--width integer] count [number] 
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

$global_help
EOF

  local ARGS=$(getopt -o "c:n:w:h" -l "count:,progress_char:,remaining_char:,number:,width:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case $1 in
      #-c|--count) shift; count=${1}; shift;;      
      --progress_char) shift; progress_char=${1:-$progress_char}; shift;;
      --progress_char) shift; progress_char=${1:-$remaining_char}; shift;;
      #-n|--number) shift; number=${1:-$number}; shift;;
      -w|--width) shift; char1=${1:-$width}; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done  
  
  local count=$1
  shift
  local number=${1:-$number}
  shift

  local progress=$(echo "$width*(100/$count*$number)/100" | bc)
  printf "%0.s${progress_char}" $(seq 1 $progress)
  printf "%0.s${remaining_char}" $(seq 1 $(($width-$progress)))
  printf "%3d%%\r" $(echo "100/$count*$number" | bc)
  [[ $number==$count ]] && echo -ne "\033[2K"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____spinner()
{
  local pid=$1
  local delay=0.75
  sp='/-\|'
  printf ' '
  #while true; do
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
  #while [[ $(pgrep -u $pid) ]]; do
    printf '\b%.1s' "$sp"
    sp=${sp#?}${sp%???}
    sleep $delay
  done
  printf '\b%.1s' ""
}
spinner()
{
  local pid=$1
  local delay=0.75
  #local sp='|/-\'
  local sp='/-\|'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${sp#?}
    printf " [%c]  " "$sp"
    local sp=$temp${sp%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lstree()
{
  ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/ /' -e 's/-/|/'
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_var()
{
  local type='text'
  local file="$configuration_filename"
  local options

  read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Prompt user to edit a variable value

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-p|--prompt string] [-v|--value value] [-s|--save] [-q|--quote quote] [-f|--file filename] [-o|--option string]... [multiline|password|select|text] varname
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]
    
OPTIONS
    -v, --value
        The default value.
    -p, --prompt
        The text to append the input. Variable namer will be used by default.
    --quote
        Emclose value vith this quote type. You can use a single quote, double quote or an empty value (default).
    -f, --file
        The name of the file containing the variable definition. 
    -o, --option
        Some options for select type.
    --multiline
        Ask user to edit a multiline text.
    --password
        Ask user to type a password.
    --select
        Ask user to select a value from a list.
    --text
        Ask user to enter a string.
    -q, --quiet
        If variable already exists, use value instead prompt user.
    -s, --save
        Write value to the file.
    -h, --help
      Print this help screen and exit.
    
$global_help
EOF
  
  local ARGS=$(getopt -o "+f:hk:o:p:q:sv:" -l "+key:value:,option:,prompt:;quote:,quiet,file:,multiline,password,select,text,save,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in      
      --multiline) shift; local type='multiline';;
      --password) shift; local type='password';;
      --quote) shift; local quote=$1; shift;;
      --select) shift; local type='select';;
      --text) shift; local type='text';;
      -f|--file) shift; local file="${1:-$file}"; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      #-k|--key) shift; local key="$1"; local prompt=${prompt:-"$1"}; shift;;
      -o|--option) shift; type='select'; options+=("$1"); shift;;
      -p|--prompt) shift; local prompt="$1"; shift;;
      -q|--quiet) shift; local quiet=1;;
      -s|--save) shift; local save=1;;
      -v|--value) shift; local value="$1"; shift;;
      --) shift; break;;
    esac
  done

  if [ -n "$1" ]; then
    local key="$1"
    local prompt=${prompt:-"$1"}
    shift
  else
    echo "${IFS}${help}${IFS}"
    exit 1
  fi
  
  # If variable is already defined
  if [[ ${!key} ]]; then
    [[ $quiet ]] && return
    local value="${!key}"    
  fi  
  
  # Ask user answer
  # Save the new value to the configuration file if not empty
  # Or save default value
  case $type in
    'multiline' )
      read -p "$prompt :" VALUE
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" --multiline "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" --multiline "$key" "$value"
      fi
    ;;
    'password' )
      read -s -p "$prompt :" VALUE
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$value"
      fi
    ;;
    'select' )
      __menu -t "$prompt" $(printf ' -o %s' $options) --back --exit
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$value"
      fi
    ;;
    * )
      read -p "$prompt [$value]:" VALUE
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$value"
      fi
    ;;
  esac
  # Immediately activate the new value
  [ -n "$VALUE" ] && eval "${key}=${VALUE}"  

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
in_array() {
    local hay needle=$1
    shift
    for hay; do
        [[ $hay == $needle ]] && return 0
    done
    return 1
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include_once() {
    [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} $LINENO : Function wait for an argument."  >&2 && exit 65
    local src
    local filename=$(readlink -f "$1")
    [ ! -e "$filename" ] && return 1    
    #local sources=($(printf "%s${IFS}" "${BASH_SOURCE[@]}" | sort -u))
    
    for src in "${sources[@]}"; do
        [[ $(readlink -f "$src") = "$filename" ]] && echo "MATCH"  >&2&& return 1
    done
    
    sources+=("$filename")
    . "$filename"
    return 0
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
translate()
{
  wget -qO- "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=$1&langpair=$2|${3:-en}" | sed 's/.*"translatedText":"\([^"]*\)".*}/\1\n/'
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
calc ()
{
  #echo $(($*))
  echo "$*" | bc -l
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__save_variable()
{

    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Write a variable definition in a file

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-f|--file filename] [--m|--multiline] [-q|--quote] [-e|--enable] [-q|--disable] [key] [value]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

DESCRIPTION
    Return $REPLY (the number) and $VALUE (the option text).

OPTIONS
    -f, --file
        File to write.
    -f, --file
        File to write.
    -m, --multiline
        Replace a mutiline variable definition with read -d '' varname <<EOF.
    -q, --quote
        Quote to use with value.
    -e, --enable
        Remove comment character before variable definition if present.
    -d, --disable
        Add a comment character before variable definition.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "f:q:medh" -l "file:,quote:,multiline,enable,disable,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -f|--file) shift; local file=$1; shift;;
      -q|--quote) shift; local quote=$1; shift;;
      -m|--multiline) shift; local multiline=1;;
      -e|--enable) shift; local enable=1;;
      -d|--disable) shift; local disable=1;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  if [ -n "$1" ]; then
    local key="$1"; shift
  else
    echo "${IFS}${help}${IFS}" >&2; exit 65
  fi
  
  if [ -n "$1" ]; then
    local value="$1"; shift
  else
    echo "${IFS}${help}${IFS}" >&2; exit 65
  fi

  [ -z "$file" ] && echo "${IFS}${help}${IFS}"  >&2 && exit 65

  local s="/" #sed delimiters
  local q="'" #sed quotes

  [ ! -e "$file" ] && echo -e "#!/bin/bash${IFS}" > "$file"

  if [[ $multiline ]]; then
    test=$(grep -P 'read +-d +(""|'"''"') +'"$key"' *<<-?EOF' "$file")
    [ -z "$test" ] && echo -e 'read -d '"''"' '"$key"' <<EOF${IFS}EOF' >> "$file"

    sed -i -r '/read +-d +(""|'"''"') +'"$key"' *<<-?EOF/,/^EOF/{//!d}' "$file"
    while read line; do
      escaped_value=$(escape_string --sed "$line")
      sed -i -r -e '/read +-d +(""|'"''"') +'"$key"' *<<-?EOF/{:a;n;/^EOF/!ba;i'"$escaped_value" -e '}' "$file"
    done < <(echo -e $value)
  else
    test=$(grep -P '(^|;)(\h*)'"$key"'\s*=' "$file")
    [ -z "$test" ] && echo -e "$key"'=${IFS}' >> "$file"

    escaped_value=$(escape_string --sed "$quote$value$quote")
    sed -r -i 's'$s'(^|;)([ \t]*)'"$key"'\s*=.*$'$s'\1\2'"$key"'='"$escaped_value"''$s "$file"
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__get_config_value()
{

  local ARGS=$(getopt -o "+k:f:q:h" -l "+key:,file:,quote:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -k|--key) shift; key=$1; shift;;
      -f|--file) shift; file=$1; shift;;
      -q|--quote) shift; quote=$1; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  local var=$(grep -P -m 1 "(^|[;\t ]+)$key\s*=\s*" "$file")

  [ "$quote" == "'" ] && var="${var#*\'}" && var="${var%\'*}"
    [ "$quote" == '"' ] && var="${var#*\"}" && var="${var%\"*}"
    [[ ! $quote ]] && var=$(echo $var | sed -r "s|^.*$key\s*=\s*(\S*).*$|\1|")
    echo $var
  }
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
  
# Available functions:
# $(declare -F | cut -d" " -f3 | grep -v '^_.*$' | sort | sed -r 's/^(.*)/    - \1/g')

  #set -e
  #set -u

  [[ $UID != 0 ]] && echo -e "This script should be run by a superuser.\nTry 'sudo ${BASH_SOURCE##*/} ${FUNCNAME} $@'."  >&2 && exit 1

  #filename=$(readlink -f "$BASH_SOURCE")
  file_prefix=${BASH_SOURCE%.*}_
  #configuration_filename="${file_prefix}$(hostid).conf"
  configuration_filename="${HOME}/$(basename "${file_prefix}")$(hostid).conf"
  menu=${0#"$file_prefix"}
  menu=${menu#"$0"}
  menu=${menu%.*}

  #  Overwrite default configuration if a custom config file exists
  #+ or create the file
  if [ ! -e "$configuration_filename" ]; then
    echo "#!/bin/bash" > "$configuration_filename"
    chmod 0600 "$configuration_filename"
  else
    include_once "$configuration_filename"
  fi
  
# Be sure that default variables/alias are defined
[[ ! $UID ]] && UID=$(id -u)
[[ ! $PWD ]] && PWD=$(pwd -P)
[[ ! $HOME ]] && HOME=$(echo ~)
[[ ! $TMPDIR ]] && TMPDIR=/tmp
[[ ! $(alias -p | grep '^alias editor=') ]] && alias editor=$(which nano || which ed || which vi)

# Paths
# With ending /
# (/[a-zA-Z0-9_\.-]+)+/?
[[ ! $config_path && -d /etc ]] && config_path=/etc/
[[ ! $service_path && $(which service) ]] && service_path="service "
[[ ! $service_path && -d /etc/init.d ]] && service_path=/etc/init.d/
[[ ! $service_path && $(which invoke-rc.d) ]] && service_path="invoke-rc.d "

[[ $(which mysql) ]] && database_servers+=('mysql')
#[[ $(which postgresql) ]] && database_servers+=('postgresql')
#[[ $(which rpcbind) ]] && dns_servers+=('bind9')
#[[ $(which mydns) ]] && dns_servers+=('mydns')
[[ $(which nfsstat) ]] && file_servers+=('nfs') # nfs / samba
[[ $(which pure-ftpd-control) ]] && ftp_servers+=('pure-ftpd')
[[ $(which postfix) ]] && smtp_servers+=('postfix')
#[[ $(which exim4) ]] && smtp_servers+=('exim4')
#[[ $(which courier) ]] && imap_servers+=('courier')
[[ $(which dovecot) ]] && imap_servers+=('dovecot')
#[[ $(which rpcbind) ]] && print_servers+=('bind9')
[[ $(which rpcbind) ]] && ssh_servers+=('bind9')
#[[ $(which apache) ]] && web_servers+=('apache')
[[ $(which apache2) ]] && web_servers+=('apache2')
#[[ $(which nginx) ]] && web_servers+=('nginx')
[[ $(which squirrelmail-configure) ]] && webmail_apps+=('squirrelmail')
#[[ $(which roundcube) ]] && webmail_apps+=('roundcube')
#[[ $(which awstats) ]] && web_servers+=('awstats')
#[[ $(which webalizer) ]] && web_servers+=('webalizer')
#[[ $(which openvz) ]] && virtualization_servers+=('openvz')

varname_regex=[a-zA-Z_]+[a-zA-Z0-9_]*

  # I'd like to know if this script is useful.
  # Of course you can comment on these lines and contact me to let me know what you think.
  #[ -n "$(which curl)" ] && ip=$(curl -s ifconfig.me); mail -s "$(basename $0) $@" "stats@clickpanic.com" \
  #"The script has been executed from ${ip:-'an unknow IP address'} ($HOSTNAME)."; exit &

  read -d '' global_help <<EOF
AUTHOR
    Written by Christophe BOISIER.

REPORTING BUGS
    Report bugs or Skype me to christophe.boisier@live.fr

COPYRIGHT
    Copyright (c) 2013 Christophe BOISIER License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
EOF

read -d '' help <<EOF
NAME
    ${0##*/} - ${script_short_description:-One more script} by CLICKPANIC

SYNOPSIS
    ${0##*/} [-c|--configure] [-i|--interactive] [--install] [--purge] [--uninstall] [-V|--version] [-h|--help]
    ${0##*/} [$(declare -F | cut -d" " -f3 | grep -v '^_.*$' | sort | tr "${IFS}" '|' | sed 's/|$//')] [arg]... [-h|--help]

DESCRIPTION
    With this script you will no longer need to remember lots of commands.
    Run it with a select menu for live operations or from a script by calling one of the included functions.

OPTIONS
    -c, --configure
        Edit the configuration file with the default editor.
    -i, --interactive
        Run script in live mode with a select menu and asking sone questions to user.
    --install
        Install completion script, aliases and other stufs in user folder.
    --purge
        Delete current configuration file.
    --uninstall
        Remove tracks of this script in user folder (exepted config file).        
    -V, --version
        Print version information and exit successfully.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  
  #[[ $# = 0 ]] && echo "${IFS}${help}${IFS}" && exit
  
  ARGS=$(getopt -o "+icVh" -l "+interactive,configure,install,purge,uninstall,version,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -i|--interactive) shift; eval "__${menu:-main}_menu";;
      -c|--configure) shift; editor "$configuration_filename" < `tty` > `tty`;;
      --install) shift; __install;;
      --purge) shift; [[ -f "$configuration_filename" ]] && rm "$configuration_filename";;
      --uninstall) shift; __uninstall;;
      -V|--version) shift; echo "$script_version";;
      -h|--help) shift; pager <<<"${IFS}${help}${IFS}";;
      --) shift; break;;
    esac
  done

  [[ -n "$@" ]] && eval "$@"
