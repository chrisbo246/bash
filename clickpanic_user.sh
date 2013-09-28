#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
menu_user ()
{
  while true; do
    __menu \
    -t 'User' \
    -o 'Create user' \
    -o 'Select user' \    
    -o 'Create group' \
    -o 'Select group' \    
    --back --exit

    case $REPLY in
      1) create_user;;
      2) select_user;;
      3) add_samba_share;;
      4) select_group;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_user()
{
  while true; do
    options=$(compgen -A user | sort)
    __menu -t 'Defined users' $(printf ' -o %s' $options) --back --exit
    select_user_action "$VALUE"    
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_user_action ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit

  while true; do
    __menu \
    -t "$1 actions" \
    -o 'Rename user' \    
    -o "Change $1 home directory" \
    -o "Change $1 password" \    
    -o "Delete $1 password" \
    -o 'Change user uid' \
    -o "Delete $1 user" \
    --back --exit
    
    case $REPLY in
      1) rename_user "$1";;      
      2) change_user_dir "$1";;      
      3) change_user_password "$1";;
      4) delete_user_password "$1";;
      5) change_user_uid;;
      6) delete_user "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_group()
{
  while true; do
    options=$(compgen -A group | sort)
    __menu -t 'Defined groups' $(printf ' -o %s' $options) --back --exit
    select_group_action "$VALUE"    
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_group_action ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit

  while true; do
    __menu \
    -t "$1 actions" \
    -o 'Rename user' \    
    --back --exit
    
    case $REPLY in
      #1) rename_user "$1";;      
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_user_name()
{
  #cut -d: -f1 ${config_path}passwd
  #awk -F':' '{ if ( $3 >= 500 ) print $1 }' ${config_path}passwd
  match=( $( cut -d: -f1 ${config_path}passwd | grep "^$user_name$" ) )
  if [[ $match == $user_name && $user_name != "" ]]; then
    echo "bon !"
  else
    ask_user_name
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ask_user_name ()
{

  menu_title="User list"
  menu_items=( $( cat ${config_path}passwd | grep /home | cut -d: -f1 | grep -v "syslog\|klog\|saned" ) )
  menu_text="Select user : "

  select_list_menu

  user_name=$choice

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_user ()
{

  # Le groupe de l'utilisateur doit exister ...
  groupadd "${USER_LOGIN}"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rename_user ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit

  local usermod_options
  
    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Select menu

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-l|--login [string]]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

DESCRIPTION
    Return $REPLY (the number) and $VALUE (the option text).

OPTIONS
    -l, --login
        New user login. You will be prompt to enter the new value if empty.
    -u, --uid
        New user ID. You will be prompt to enter the new value if empty.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "l:u:h" -l "login::,uid::,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -l|--login)
        shift
        $new_login=$1
        [[ -z $new_login ]] && read -p "Enter a new user login [$login]:" new_login
        [[ -n $new_login && ! $(getent passwd $new_login) ]] && usermod_options+=("-l $new_login")
        shift
        ;;
      -u|--uid)
        shift
        $new_login=$1
        [[ -z $new_login ]] && read -p "Enter a new user ID [$user_name]:" new_login
        [[ -n $new_login && ! $(getent passwd $new_login) ]] && usermod_options+=("-u $new_login")
        shift
      ;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done
  
  user_name=$1
  if [[ -z $user_name ]]; then
    select_user
    user_name=$VALUE
  fi
  
  if [[ $(getent passwd $user_name) ]]; then
    read -p "Enter new user name [$user_name]:" new_user_name
    [[ -n $new_user_name && ! $(getent passwd $new_user_name) ]] && usermod $(printf ' %s' $usermod_options) $user_name && return 0
  else
    return 1
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_user_uid ()
{
  [ ! $# -eq 1 ] && echo "${BASH_SOURCE##*/} ${FUNCNAME} line $LINENO : Function wait for an argument."  >&2 && exit
  
  user_name=$1
  if [[ -z $user_name ]]; then
    select_user
    user_name=$VALUE
  fi

  read -p'Enter new user ID (ex: 10000) : ' user_id

  id $user_name
  usermod -u $user_id $user_name
  id $user_name

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_user_dir ()
{

  # ask_user_name
  get_user_name

  read -p'Enter new user home directory (eg: /var/www) : ' user_dir

  id $user_name
  usermod -d $user_dir $user_name
  chown $user_dir $user_name
  id $user_name

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
delete_user ()
{

  # ask_user_name
  get_user_name

  read 'Do you want to remove user directory ? (y/N) : ' choice
  case $choice in
    y,Y,yes,YES)
      #  Files in the user's home directory will be removed along with the home directory itself and the user's mail spool.
      # Files located in other file systems will have to be searched for and deleted manually.
      options='--remove'
  esac

  userdel $options $user_name

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
delete_user_password ()
{

  # ask_user_name
  get_user_name

  passwd --delete $user_name
  usrmod -s /sbin/nologin $user_name

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_user_password ()
{

  # ask_user_name
  get_user_name

  read -p"Enter new password" USER_PASSWORD

  # activer le mot de passe
  echo "${USER_LOGIN}":"${USER_PASSWORD}" | chpasswd

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_user_group ()
{
  echo ""
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# return group of a directory
dirgroup()
{
  if [ -d $1 ]; then
    directory=$1
    dirname $directory | ls -l | grep $( basename $directory ) | awk '{print $3}'
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# adduser - build a useradd string and a password for passwd
# by typedeaF
# grep -v '^#' thisfile.sh | less to strip the comments
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Make a semi-random password using an array of user-friendly characters

function mkpass() {
  PASS=""
  PASSLEN=8
  array1=( q w e r t y u i o p a s d f g h j k l z x c v b n m
    Q W E R T Y U I O P A S D F G H J K L Z X C V B N M
    1 2 3 4 5 6 7 8 9 0 \! \@ \# \$ \% \^ \& \* \( \)
  )
  MODNUM=${#array1[*]}

  count=0
  while [ ${count:=0} -lt $PASSLEN ]
  do
    number=$(($RANDOM%$MODNUM))
    PASS="$PASS""${array1[$number]}"
    ((count++))
  done

  echo $PASS
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Determines if user is root or not, return true (zero) value if user is root
# else return nonzero value

isRootUser(){
  [ "$($ID -u)" == "0" ]  >&2&& return $YES || return $NO
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Returns true if user account exists in ${config_path}passwd

isUserExist(){
  [ "$1" == "" ] && exit 999 || u="$1"
  $GREP -E -w "^$u" $PASSWD_FILE >/dev/null
  [ $? -eq 0 ] && return $YES || return $NO
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List total number of users logged in (both Linux and FreeBSD)

getNumberOfLoggedInUsers(){
  [ "$OS" == "FreeBSD" -o "$OS" == "Linux" ] && echo "$($W -h | $WC -l)" || :
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set_root() {
  if [[ $UID != 0 ]]; then
    #   echo "Il faut être root"
    #zenity --question --title "Hosts" --text "$@ \
    #Il faut passer en root"
    #echo "You must be root to continue"
    sudo -s
    exit 1
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
