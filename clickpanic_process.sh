#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
kill_service()
{

  service=$1
  if [ "$service" == '' ]; then
    read -p'Enter service to kill : ' service
  fi

  pid=$( ps -ef | awk '{print $1 " " $2}' | grep "$service" | awk '{print $2}' )

  if [ "$pid" > 0 ]; then
    kill $pid
    #  else
    #    menu_title="Running services"
    #    menu_items=( $( ls $apache_conf_dirsites-available/ | grep -v "default\|default-ssl\|~" ) )
    #    menu_text="Select service to kill : "
    #    select_list_menu
    #    pid=$choice
  fi

  # sudo lsof | grep $DEVICE_NAME | awk '{print $2}' -exec kill -KILL {} \;

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
list_service()
{

  read -p'Enter service to kill : ' service
  #service=$1
  menu_title="Running services"
  menu_items=( $( ps -ef | awk '{print $1 " " $2}' | grep "$service" | awk '{print $1}' ) )
  menu_text="Select service to kill : "
  select_list_menu

  service=$choice

  echo "Kill service $service..."
  kill_service $service

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stop a list of services

stopped_daemon ()
{

  if [ $# > 0 ];
  then

    for var in $*
    do
      if [[ $var ]];
      then
        test=$( sudo ps -A | grep $var )
        if [ ! $test ];
        then
          echo "$var"
        fi
      fi
    done
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start a list of services arg

start_service ()
{

  if [ $# > 0 ];
  then
    for service in $*
    do
      file=${service_path}$service"
      if [ -e "$file" ];
      then
        $( "$file start" )
      else
        echo "Service $service don't exists"
      fi
    done
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Start X environment
start_x()
{
  # invoke-rc.d gdm3 start
  # invoke-rc.d kdm start
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# stop X environment
stop_x
{
  #invoke-rc.d gdm3 stop
  #invoke-rc.d kdm stop

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List total number of running process

getNumberOfRunningProcess(){
  [ "$OS" == "FreeBSD" ] && echo "$($PS -aux | $GREP -vE "^USER|ps -aux"|$WC -l)"
  [ "$OS" == "Linux" ] && echo "$($LSMOD | $GREP -vE "^Module" | $WC -l)"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Process management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"