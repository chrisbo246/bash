#!/bin/bash

. global.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# menu permetant de selectionner parmis une liste de reponses
# select_menu ""
__select_menu()
{

  digit=$((${#menu_items[*]}/10+1))
  format="% ${digit}d"
  answers=[]
  values=[]

  echo "======================================================================="
  echo $menu_title
  echo "......................................................................."
  for i in ${!menu_items[*]}
  do
    n=$( printf "% ${digit}s" $i )

    answers=("${answers[@]}" $i)
    if [ menu_values[$i]: ]; then
      values=("${values[@]}" menu_values[$i])
    else
      values=("${values[@]}" $i)
    fi

    str="$n : ${menu_items[i]}"
    echo "$str"
  done
  echo "......................................................................."

  i='X'
  n=$( printf "% ${digit}s" $i )
  echo "$n : Exit"
  i='<'
  n=$( printf "% ${digit}s" $i )
  echo "$n : Back"
  echo "======================================================================="


  #read -p"$menu_text" choice
  select answer in $answers; do
    $choice=$values[$answer]
  done

  # Array len
  #${#arrayname[@]}
  # return key 3 and 2
  #echo ${Unix[@]:3:2}
  #Replace Ubuntu by SCO
  #echo ${Unix[@]/Ubuntu/SCO Unix}
  # Add Values to an array
  #Unix=("${Unix[@]}" "AIX" "HP-UX")
  # REmove
  #unset Unix[3]

  #trimmed=$1
  #  trimmed=${trimmed%% }
  #  trimmed=${trimmed## }

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
menu ()
{

  #digit=$((${#menu_items[*]}/10+1))
  #format="% ${digit}d"

  #echo "======================================================================="
  #echo $menu_title
  #echo "......................................................................."
  #for i in ${!menu_items[*]}
  #do
  #  n=$( printf "% ${digit}s" $i )
  #  str="$n : ${menu_items[i]}"
  #  echo "$str"
  #done
  #echo "......................................................................."

  #i='X'
  #n=$( printf "% ${digit}s" $i )
  #echo "$n : Exit"
  #i='<'
  #n=$( printf "% ${digit}s" $i )
  #echo "$n : Back"
  #echo "======================================================================="
  #read -p"$menu_text" choice
  #select choice in $*; do

  select_menu

  # $PIPESTATUS[0]
  case $choice in
    x|X)  #  L'utilisateur a appuyé sur OK ou sur Fermer.
    exit ;;
    '<')  #	L'utilisateur a soit appuyé sur le bouton Annuler, soit fermé la boîte de dialogue.
      # $( echo "$back" )
    break ;;
    -1) #	Une erreur inattendue s'est produite.
    $PIPESTATUS[0] ;;
  esac
  #done

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__select_list_menu ()
{

  digit=$((${#menu_items[*]}/10+1))

  echo "======================================================================="
  echo $menu_title
  echo "......................................................................."
  for i in ${!menu_items[*]}
  do
    n=$( printf "%0${digit}d" $i )
    echo "$n : ${menu_items[i]}"
  done
  echo "======================================================================="
  read -p"$menu_text" choice

  choice=${menu_items[choice]}

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
error_msg ()
{

  title="$1"
  text="$2"

  echo "[!] $title"
  echo "$text"
  read pause

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
info_msg ()
{

  title="[I] $1"
  text="$2"

  echo "$title"
  echo "$text"
  read pause

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
question() {

  if [ $# -ne 0 ]; then
    select answer in $*; do
      #case $answer in
      #    Yes ) make install; break;;
      #    No ) exit;;
      # esac
    done
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Select editor
update-alternatives --config editor

#if $EDITOR != "" ; then
#  editor=$EDITOR
#elif command -v 'nano' &>/dev/null ; then
# editor='nano'
#else
#  editor='vi'
#fi

#edit_cmd=editor
#service_path="service"