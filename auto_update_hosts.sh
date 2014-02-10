#!/bin/bash

. global.sh


if [ ! $(id -u) = 0 ]; then
  echo "Il faut être root"
  zenity --question --title "Hosts" --text "$@ \  Il faut passer en root"
  exit 1
fi
# -----------------------------------------------------------------------------
lancement ()
{
  rm /tmp/hosts
  rm /tmp/hosts.txt
  echo "127.0.0.1     localhost.localdomain localhost hostname # *********************************************************#" >> /tmp/hosts
  wget http://www.mvps.org/winhelp2002/hosts.txt -O /tmp/hosts.txt
  
  cat /tmp/hosts.txt >> /tmp/hosts
  
  cp /tmp/hosts /etc/hosts
}
# -----------------------------------------------------------------------------
(echo ""; lancement) | zenity --progress --title "Hosts" --text="Téléchargement en cours" --pulsate

## Si on clic sur Annuler...
if [ $? -ne 0 ]
then
  exit 0
fi

zenity --question --title "Hosts" --text "$@ \
script terminé ."
## Si on clic sur Annuler...
if [ $? -ne 0 ]; then
  exit 0
fi