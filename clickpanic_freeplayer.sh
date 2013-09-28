#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__freeplayer_menu ()
{
  while true; do
    __menu \
    -t 'Freeplayer' \
    -o 'Install Freeplayer' \
    -o 'Start Freeplayer' \
    -o 'Deamon Freeplayer' \
    --back --exit

    case $REPLY in
      1) install_freeplayer;;
      2) start_freeplayer;;
      3) deamon_freeplayer;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_freeplayer ()
{

  sudo __package_cp update
  # Prérequis
  __package_cp -u install vlc w32codecs

  # Le Freeplayer est disponible dans le dépôt multiverse :
  sudo aptitude install freeplayer

  # Pour lancer le Freeplayer
  /usr/bin/vlc-fbx

  local_ip=$( get_local_ip )
  pause "
  Pour terminer...
  Dans le panneau de configuration du routeur de la Freebox:
  - Activez le service Freeplayer
  - Ouvrir les ports en TCP 8080 et UDP 8080 du mode routeur
  - renseigner l'IP du freeplayer ($local_ip)
  "

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
start_freeplayer ()
{

  # Pour lancer le Freeplayer manuellement
  /usr/bin/vlc-fbx

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
deamon_freeplayer ()
{

  echo "
#!/bin/sh

### BEGIN INIT INFO
# Provides:        freeplayer
# Required-Start:  \$network \$remote_fs \$syslog
# Required-Stop:   \$network \$remote_fs \$syslog
# Default-Start:   2 3 4 5
# Default-Stop:    1
# Short-Description: Start freeplayer daemon
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
. /lib/lsb/init-functions

case \$1 in
        start)
                log_daemon_msg \"Starting freeplayer server\"
                # c'est cette ligne qui est importante !
                # on execute la tache (le serveur vlc) en tant que public parce que c'est son HOME qui contient les medias
                # on execute en demon parce qu'on a pas d'écran et que vlc il aime pas ça !
                # sinon, le reste, c'est les options du freeplayer
                su public -c'/usr/bin/vlc --daemon --extraintf=http --http-host=:8080 --http-charset=ISO-8859-1 --sout=\"#std\" --sout-standard-access=udp --sout-standard-mux=ts --sout-standard-dst=212.27.38.253:1234 --sout-ts-pid-video=68 --sout-ts-pid-audio=69 --sout-ts-pid-spu=70 --sout-ts-pcr=80 --sout-ts-dts-delay=400 --no-playlist-autostart --subsdec-encoding=ISO-8859-1 --sout-transcode-maxwidth=720 --sout-transcode-maxheight=576 --play-and-stop --http-src=\"/usr/share/freeplayer/http-fbx/\" --wx-systray --config=\"${config_path}freeplayer/vlcrc-fbx\" --open=\"\$1\" ' &
                ;;
        stop)
                log_daemon_msg \"Stopping freeplayer server\"
                killall -u public vlc
                ;;
        *)
                echo \"Usage: \$0 {start|stop}\"
                exit 2
                ;;
esac
  " | sudo tee ${service_path}freeplayer

  # Il y a un problème de version entre le freeplayer et VLC installé.
  release=$( get_release )
  if [ "$release" = "intrepid" ] ;
  then
    sudo sed 's| --wx-systray||g' '/usr/bin/vlc-fbx'
    __package_cp -u install libavcodec-unstripped-51
  fi

  # Une fois que votre script est fini, il vous faut le lier avec les niveaux d'éxecution corrects. Une commande existe pour celà : update-rc.d
  sudo update-rc.d freeplayer defaults
  # Une fois celà fait, votre demon sera lancé avec les autres serveurs au prochain reboot. Vous pouvez aussi le lancer manuellement :
  sudo sh ${service_path}freeplayer start

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Freeplayer management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"