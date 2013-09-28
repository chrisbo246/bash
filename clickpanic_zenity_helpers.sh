#!/bin/bash

. global.sh



# Select editor
update-alternatives --config editor
#if $EDITOR != "" ; then
#  editor=$EDITOR
#else command -v 'gedit' &>/dev/null ; then
#  editor='gedit'
#fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
menu ()
{

  #choix=`zenity --list --title "Backup" --radiolist --text="Choix du support de sauvegarde" --column "" --column "Support USB" --column "Capacité" --column "Description" TRUE "TONE" "16 Go" "Backup complet" FALSE "ScanDisk" "4 Go" "Backup partiel"`

  digit=$((${#menu_items[*]}/10+1))
  format="% ${digit}d"

  string="/usr/bin/zenity --list --radiolist --height=\"400\" --width=\"300\" \
  --title=\"${menu_title}\" --text=\"$menu_text\" \
  --column=\"\" --column=\"\" --column=\"Actions\" \
  --hide-column=\"2\" --separator=\" \" "

  for i in ${!menu_items[*]}
  do
    n=$( printf "% ${digit}s" $i )
    string="$string FALSE $n \"${menu_items[i]}\""
  done

  exec $string
  #echo `echo $a`
  #choice=`$string`

  choice=$PIPESTATUS[0]
  case $choice in
    x|X)  #  L'utilisateur a appuyé sur OK ou sur Fermer.
    exit ;;
    '<')  #	L'utilisateur a soit appuyé sur le bouton Annuler, soit fermé la boîte de dialogue.
      # $( echo "$back" )
    break ;;
    -1) #	Une erreur inattendue s'est produite.
    $PIPESTATUS[0] ;;
    5) 	# The dialog has been closed because the timeout has been reached.
    exit 0 ;;
  esac

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__select_list_menu ()
{

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
error_msg ()
{

  title="$1"
  text="$2"

  # if [ "$PIPESTATUS" != "0" ]; then
  zenity --error --title="$title" --text="$text"
  # fi
  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
info_msg ()
{

  title="$1"
  text="$2"

  zenity --info --title="$title" --text="$text"
  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $1 = question
question() {
  # zenity --question --title "$1" --text "$@ $1"
  zenity --question --text "$@ $1"

  if [ $? -ne 0 ]
  then
    exit 0
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
progress() {
  (echo ""; lancement) | zenity --progress --title "Hosts" --text="Téléchargement en cours" --pulsate
  ## Si on clic sur Annuler...
  if [ $? -ne 0 ]
  then
    exit 0
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

install_cmd="zenity --install"
edit_cmd=