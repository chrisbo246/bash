#!/bin/bash
#. ${current_dir}conf/ushare.conf
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__ushare_menu ()
{
  while true; do
    __menu \
    -t 'uShare media server' \
    -o 'Install Ushare' \
    -o 'Uninstall Ushare' \
    -o 'Configure Ushare' \
    -o 'Start uShare' \
    -o 'Stop uShare' \
    -o 'Configure uShame to run at startup' \
    -o 'Disable uShame autorun' \
    --back --exit

    case $REPLY in
      1) install_ushare;;
      2) uninstall_ushare;;
      3) config_ushare;;
      4) start_ushare;;
      5) stop_ushare;;
      6) enable_ushare_autorun;;
      7) disable_ushare_autorun;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ushare ()
{

  #echo "deb http://www.geexbox.org/debian/ unstable main" | sudo tee -a "${config_path}apt/sources.list"
  #editor ${config_path}apt/sources.list

  __package_cp -u install ushare libdlna0 libdlna-dev

  echo 'USHARE_OPTIONS="-d -x"' | sudo tee -a ${config_path}ushare.conf #${service_path}ushare

  sudo sed -i -e 's/OVERRIDE_ICONV_ERR/USHARE_OVERRIDE_ICONV_ERR=yes/' ${config_path}ushare.conf
  sudo sed -i -e 's/ENABLE_WEB/USHARE_ENABLE_WEB=yes/' ${config_path}ushare.conf
  sudo sed -i -e 's/ENABLE_TELNET/USHARE_ENABLE_TELNET=yes/' ${config_path}ushare.conf
  sudo sed -i -e 's/ENABLE_XBOX/# USHARE_ENABLE_XBOX=no/' ${config_path}ushare.conf
  sudo sed -i -e 's/ENABLE_DLNA/USHARE_ENABLE_DLNA=yes/' ${config_path}ushare.conf

  config_ushare

  return -code 0

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_ushare ()
{

  sudo __package_cp remove --purge ushare

  return -code 0

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_ushare ()
{

  sudo dpkg-reconfigure ushare
  editor ${config_path}ushare.conf

  # Modifie les autorisations sur les dossiers
  ushare_dir=`awk -F"=" '/^USHARE_DIR/ { print $2 }' ${config_path}ushare.conf`
  dirs=$(echo $ushare_dir | sed "s/,/ /g")
  for i in $dirs ; do sudo chmod 755 $i ; done

  ${service_path}ushare restart

  sudo ifconfig $ushare_interface up
  sudo ushare -d -D

  return -code 0

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
start_ushare ()
{

  ushare -d -D

  return -code 0

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stop_ushare ()
{

  sudo killall ushare

  return -code 0

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
enable_ushare_autorun ()
{

  # Run uShare at PC startup
  sudo update-rc.d -f ushare remove
  sudo mv ${service_path}ushare ${service_path}ushare.sh
  sudo update-rc.d ushare.sh defaults 50

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disable_ushare_autorun ()
{

  sudo update-rc.d -f ushare remove

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Ushare management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

# Voir aussi...
#
# Fuppes - fuppes.ulrich-voelkel.de/
# MediaTomb - mediatomb.cc/
# MythTV - www.mythtv.org/

# http://www.rbgrn.net/blog/2007/08/how-to-choose-dlna-media-server-software-in-windows-mac-os-x-or-linux.html

# Free Transcoding
#Server 	  Price 	Windows 	Mac 	Linux 	Music 	Photo 	Video 	Transcoding
#Fuppes  	  Free  	X        	      X 	    X 	    X 	    X 	    X
#MediaTomb  Free  	          X 	  X 	    X 	    X 	    X 	    X
#MythTV  	  Free  	                X 	    X 	    X 	    X 	    X
#Tversity  	Free  	X  		                  X 	    X     	X     	X
#Win Media Connect  	Free  	X             X 	    X 	    X     	X

# Windows
#
#    * Allegro Media Server
#    * Cidero Internet Radio Station Server
#    * Cyber Media Gate
#    * Cyberlink Digital Home Enabler Kit
#    * Fuppes
#    * Musicmatch Jukebox
#    * Nero MediaHome
#    * On2Share
#    * Rhapsody
#    * SimpleCenter
#    * TVersity (free)
#    * TwonkyMedia
#    * Windows Media Connect (free)

# Linux
#
#    * Cidero Internet Radio Station Server
#    * Cyber Media Gate
#    * Fuppes
#    * Geexbox
#    * GMediaServer
#    * MediaTomb
#    * MythTV
#    * TwonkyMedia
#    * uShare

# http://ushare.geexbox.org/
#
#    *  Video files:
#        asf, avi, dv, divx, wmv, mjpg, mjpeg, mpeg, mpg, mpe, mp2p,vob, mp2t,
#        m1v, m2v, m4v, m4p, mp4ps, ts, ogm, mkv, rmvb, mov, qt, hdmov
#    * Audio files:
#        aac, ac3, aif, aiff, at3p, au, snd, dts, rmi, mp1, mp2, mp3,
#        mp4, mpa, ogg, wav, pcm, lpcm, l16, wma, mka, ra, rm, ram, flac
#    * Images files:
#        bmp, ico, gif, jpeg, jpg, jpe, pcd, png, pnm, ppm, qti, qtf, qtif, tif, tiff
#    * Playlist files:
#        pls, m3u, asx
#    * Subtitle files:
#        dks, idx, mpl, pjs, psb, scr, srt, ssa, stl, sub, tts, vsf, zeg
#    * Various text files:
#        bup, ifo
