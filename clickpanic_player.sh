#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__player_menu ()
{
  while true; do
    __menu \
    -t 'DVB Satelite / TNT' \
    -o 'Install codecs' \
    -o 'Install converters' \
    -o 'Install Kaffeine player' \
    -o 'Install Totem player' \
    --back --exit

    case $REPLY in
      1) install_multimedia_codecs;;
      2) install_multimedia_converters;;
      3) install_kaffeine;;
      4) install_totem;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_multimedia_codecs ()
{

  __package_cp update
  __package_cp upgrade

  # Lecteur audio
  #__package_cp -u install amarok libxine1-ffmpeg
  # Codecs audio
  # deb http://fr.archive.ubuntu.com/ubuntu dapper main multiverse

  # Install the GStreamer back-end which can play DVDs but does not yet support DVD menus.
  __package_cp -u install gstreamer0.10-ffmpeg
  __package_cp -u install gstreamer0.10-plugins-ugly gstreamer0.10-plugins-ugly-multiverse
  __package_cp -u install gstreamer0.10-plugins-bad gstreamer0.10-plugins-bad-multiverse

  # Install the xine back-end which can play DVDs with full DVD menu suport.
  __package_cp -u install totem-xine

  # Lecteur Video
  __package_cp -u install vlc

  # Codecs multimedia
  __package_cp -u install ubuntu-restricted-extras

  # Adobe flash plugin pour Firefox et Seamonkey
  __package_cp -u install adobe-flashplugin

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_multimedia_converters ()
{

  # Convertion Audio / Video
  __package_cp -u install soundconverter mencoder

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_kaffeine ()
{

  sudo __package_cp update
  __package_cp -u install kaffeine

  # Traduction Française
  __package_cp -u install language-pack-kde-fr

  # Ajouter les sources de medibuntu
  echo "
  # Dépôts Medibuntu
  deb http://packages.medibuntu.org/ intrepid free non-free
  " | sudo tee -a ${config_path}apt/sources.list
  editor ${config_path}apt/sources.list
  wget -q http://fr.packages.medibuntu.org/medibuntu-key.gpg -O- | sudo apt-key add -

  # Lecture des DVD commerciaux
  __package_cp -u install libdvdcss2
  # Codecs suplémentaires
  __package_cp -u install w32codecs non-free-codecs
  #
  __package_cp -u install libxine1-ffmpeg libxine1-all-plugins #libxine-extracodecs
  # TNT
  __package_cp -u install dvb-utils

  # Multidec
  __package_cp -u install libxine liblame0 libssl

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Totem

install_totem ()
{

  # Totem is a great media player that comes installed by default. I recommend installing both the xine and GStreamer backends.

  # 1. You can find Totem in the Applications > Sound & Video menu under the name Move Player.
  # 2. (optional) Enable DVD playback.
  __package_cp -u install libdvdread3
  /usr/share/doc/libdvdread3/install-css.sh

  # 3. (alternative) If the above doesn't work, you can try the following.
  # wget -c -P ${TMPDIR}/ http://debian-multimedia.org/pool/main/libd/libdvdcss/libdvdcss2_1.2.10-0.2_i386.deb
  # sudo dpkg -i ${TMPDIR}/libdvdcss2*.deb
  # sudo __package_cp -f install

  __package_cp -u install totem-gstreamer

  # 6. To run Totem with a particular back-end, run either totem-gstreamer or totem-xine. You can select between GStreamer and xine as default back-end to use for when you run totem.
  sudo update-alternatives --config totem
  sudo update-alternatives --config gnome-video-thumbnailer

  and select the appropriate defaults.
  # 7. (recommended) Make Totem the preferred multimedia player.
  gconftool --type string --set /desktop/gnome/applications/media/exec "totem"

  # 8. (recommended) Make Totem the default media player for various file types.
  mkdir -p ~/.local/share/applications
  cp /usr/share/applications/totem.desktop ~/.local/share/applications/totem-enqueue.desktop
  editor ~/.local/share/applications/totem-enqueue.desktop
  echo "
      Change the following lines

      Name=Movie Player
      ...
      Exec=totem %U
      ...

      to

      Name=Movie Player (Enqueued)
      ...
      Exec=totem --enqueue %U
      NoDisplay=true
      ...

      Save and close the file.
  "

  mkdir -p ~/.local/share/applications

  echo "
      Add the following lines.

      [Added Associations]
      application/ogg=totem.desktop;totem-enqueue.desktop;
      application/vnd.rn-realmedia=totem.desktop;totem-enqueue.desktop;
      application/x-extension-m4a=totem.desktop;totem-enqueue.desktop;
      application/x-extension-mp4=totem.desktop;totem-enqueue.desktop;
      application/x-flac=totem.desktop;totem-enqueue.desktop;
      application/x-flash-video=totem.desktop;totem-enqueue.desktop;
      application/x-matroska=totem.desktop;totem-enqueue.desktop;
      application/x-ogg=totem.desktop;totem-enqueue.desktop;
      application/x-shockwave-flash=totem.desktop;totem-enqueue.desktop;
      audio/mpeg=totem.desktop;totem-enqueue.desktop;
      audio/mpegurl=totem.desktop;totem-enqueue.desktop;
      audio/vnd.rn-realaudio=totem.desktop;totem-enqueue.desktop;
      audio/x-flac=totem.desktop;totem-enqueue.desktop;
      audio/x-m4a=totem.desktop;totem-enqueue.desktop;
      audio/x-mod=totem.desktop;totem-enqueue.desktop;
      audio/x-mp3=totem.desktop;totem-enqueue.desktop;
      audio/x-mpeg=totem.desktop;totem-enqueue.desktop;
      audio/x-mpegurl=totem.desktop;totem-enqueue.desktop;
      audio/x-ms-asf=totem.desktop;totem-enqueue.desktop;
      audio/x-ms-asx=totem.desktop;totem-enqueue.desktop;
      audio/x-ms-wax=totem.desktop;totem-enqueue.desktop;
      audio/x-ms-wma=totem.desktop;totem-enqueue.desktop;
      audio/x-pn-aiff=totem.desktop;totem-enqueue.desktop;
      audio/x-pn-au=totem.desktop;totem-enqueue.desktop;
      audio/x-pn-realaudio-plugin=totem.desktop;totem-enqueue.desktop;
      audio/x-pn-realaudio=totem.desktop;totem-enqueue.desktop;
      audio/x-pn-wav=totem.desktop;totem-enqueue.desktop;
      audio/x-pn-windows-acm=totem.desktop;totem-enqueue.desktop;
      audio/x-real-audio=totem.desktop;totem-enqueue.desktop;
      audio/x-s3m=totem.desktop;totem-enqueue.desktop;
      audio/x-vorbis+ogg=totem.desktop;totem-enqueue.desktop;
      audio/x-wav=totem.desktop;totem-enqueue.desktop;
      audio/x-xm=totem.desktop;totem-enqueue.desktop;
      image/vnd.rn-realpix=totem.desktop;totem-enqueue.desktop;
      misc/ultravox=totem.desktop;totem-enqueue.desktop;
      video/dv=totem.desktop;totem-enqueue.desktop;
      video/mp4=totem.desktop;totem-enqueue.desktop;
      video/mpeg=totem.desktop;totem-enqueue.desktop;
      video/msvideo=totem.desktop;totem-enqueue.desktop;
      video/quicktime=totem.desktop;totem-enqueue.desktop;
      video/vnd.rn-realvideo=totem.desktop;totem-enqueue.desktop;
      video/x-anim=totem.desktop;totem-enqueue.desktop;
      video/x-avi=totem.desktop;totem-enqueue.desktop;
      video/x-flc=totem.desktop;totem-enqueue.desktop;
      video/x-fli=totem.desktop;totem-enqueue.desktop;
      video/x-mpeg=totem.desktop;totem-enqueue.desktop;
      video/x-ms-asf=totem.desktop;totem-enqueue.desktop;
      video/x-msvideo=totem.desktop;totem-enqueue.desktop;
      video/x-ms-wmv=totem.desktop;totem-enqueue.desktop;
      video/x-nsv=totem.desktop;totem-enqueue.desktop;
      video/x-theora+ogg=totem.desktop;totem-enqueue.desktop;
      x-content/audio-cdda=totem.desktop
      x-content/audio-dvd=totem-xine.desktop
      x-content/audio-player=totem.desktop
      x-content/video-dvd=totem-xine.desktop
      x-content/video-vcd=totem-xine.desktop
      x-content/video-svcd=totem-xine.desktop
      x-content/video-blueray=totem-xine.desktop
      x-content/video-hddvd=totem-xine.desktop
      application/x-cd-image=totem-xine.desktop;totem.desktop;totem-enqueue.desktop;

      Save and close the file, and then restart Nautilus.
  "
  editor ~/.local/share/applications/mimeapps.list
  killall nautilus

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Player management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
