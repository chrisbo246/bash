#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__base_menu ()
{
  while true; do
    __menu \
    -t 'Base menu' \
    -o 'Install desktop' \
    -o 'Install French translations' \
    -o 'Install basic utilities' \
    -o 'Set keybord to French' \
    -o 'Install user encrypted directory' \
    -o 'Change user directory' \
    -o 'Show config' \
    -o 'Update Distribution' \
    --back --exit

    case $REPLY in
      1) install_desktop;;
      2) translate_fr;;
      3) install_basics;;
      4) set_fr;;
      5) install_user_private_dir;;
      6) change_user_dir;;
      7) show_config;;
    esac
  done
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_desktop ()
{

  # Once you have completed installation of your Ubuntu server, you can add a Ubuntu desktop to it.

  #  Create a root user password
  sudo passwd root

  # Update your server
  __package_cp update
  __package_cp upgrade

  menu_title="Ubuntu Version"
  declare -a menu_items
  -o 'Ubuntu Gnome desktop' \
  -o 'Kubuntu KDE desktop' \
  -o 'Xubuntu light weight' \
    --back --exit
  menu_text="Enter your choice : "

  menu

  echo "Desktop installation may take more than an houre, depending of your network connection, so be patient..."

  case $choice in
    4) __package_cp -u install ubuntu-desktop ;;
    1) __package_cp -u install kubuntu-desktop ;;
    2) __package_cp -u install xubuntu-desktop ;;
    3) __package_cp -u install edubuntu-desktop ;;
  esac

  reboot

  # When you get back to the command line prompt after installation is complete, reboot.

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
translate_fr ()
{

  sudo __package_cp remove --purge $(dpkg -l | awk '{print $2}' | egrep "language-pack|aspell-|gimp-help-|language-support-|myspell-|language-pack-gnome-|gimp-help-|thunderbird-locale-" | xargs)

  __package_cp update
  __package_cp upgrade

  sudo __package_cp -y -u install language-pack-fr-base # Traductions en français
  sudo __package_cp -y -u install language-pack-fr # Mises à jour des traductions en français
  # sudo __package_cp -y -u install language-pack-frm # translation updates for language French, Middle (ca. 1400-1600)
  # sudo __package_cp -y -u install language-pack-frm-base # translations for language French, Middle (ca. 1400-1600)

  sudo __package_cp -y -u install language-support-fr # méta-paquet pour la prise en charge du français
  sudo __package_cp -y -u install language-support-translations-fr # Méta-paquet de traductions supplémentaires pour le français
  sudo __package_cp -y -u install language-support-writing-fr # Méta-paquet d'aides à l'écriture pour le français

  # Gnome
  sudo __package_cp -y -u install language-pack-gnome-fr-base # Traductions de GNOME en français
  sudo __package_cp -y -u install language-pack-gnome-fr # Mises à jour des traductions de GNOME en français

  # KDE
  # sudo __package_cp -y -u install kde-i18n-fr # French (fr) internationalized (i18n) files for KDevelop and KDEWebDev
  # sudo __package_cp -y -u install kde-l10n-fr # French (fr) localisation files for KDE4
  # sudo __package_cp -y -u install language-pack-kde-fr # Mises à jour des traductions de KDE en français
  # sudo __package_cp -y -u install koffice-i18n-fr # Traductions pour KOffice en français (fr)
  # sudo __package_cp -y -u install language-pack-kde-fr-base # Traductions de KDE en français

  # Debian
  sudo __package_cp -y -u install doc-debian-fr # Manuels Debian, FAQ et d'autres documents en français
  sudo __package_cp -y -u install debian-faq-fr # The Debian FAQ, in French
  sudo __package_cp -y -u install debian-reference-fr # Debian system administration guide, French translation
  sudo __package_cp -y -u install developers-reference-fr # guidelines and information for Debian developers, in French
  sudo __package_cp -y -u install maint-guide-fr # French translation of Debian New Maintainers' Guide

  # Doc
  sudo __package_cp remove manpages
  sudo __package_cp -y -u install manpages-fr # Version française des pages de manuel sur l'utilisation de GNU/Linux
  sudo __package_cp -y -u install manpages-fr-dev # Version française des pages de manuel pour le développement
  sudo __package_cp -y -u install manpages-fr-extra # Version française des pages de manuel
  sudo __package_cp -y -u install doc-linux-fr-html # Linux docs in French: HOWTOs, MetaFAQs in HTML format
  sudo __package_cp -y -u install doc-linux-fr-text # Documentation Linux en français : HOWTO, MetaFAQ au format ASCII

  # Help
  sudo __package_cp -y -u install texlive-doc-fr # TeX Live: French documentation
  sudo __package_cp -y -u install kicad-doc-fr # Kicad help files (French)
  sudo __package_cp -y -u install aptitude-doc-fr # Manuel français pour aptitude, un gestionnaire de paquets en ligne de commande
  sudo __package_cp -y -u install openoffice.org-help-fr # Aide en français pour OpenOffice.org
  sudo __package_cp -y -u install gimp-help-fr # Documentation française pour GIMP
  sudo __package_cp -y -u install gosa-help-fr # French online help for GOsa

  # Dictionnary
  sudo __package_cp -y -u install dict-freedict-fra-deu # Dict package for French-German Freedict dictionary
  sudo __package_cp -y -u install dict-freedict-fra-eng # Dict package for French-English Freedict dictionary
  sudo __package_cp -y -u install dict-freedict-fra-nld # Dict package for French-Dutch Freedict dictionary
  sudo __package_cp -y -u install dict-freedict-nld-fra # Dict package for Dutch-French Freedict dictionary
  sudo __package_cp -y -u install dict-freedict-deu-fra # Paquet dict pour le dictionnaire Freedict allemand/français
  sudo __package_cp -y -u install dict-freedict-eng-fra # Paquet dict pour le dictionnaire Freedict anglais/français
  # sudo __package_cp -y -u install aspell-fr # Dictionnaire français pour aspell
  # sudo __package_cp -y -u install myspell-fr # Dictionnaire français pour myspell (version Hydro-Québec)
  # sudo __package_cp -y -u install myspell-fr-gut # Dictionnaire français pour myspell (version GUTenberg)
  # sudo __package_cp -y -u install hunspell-fr # French dictionary for hunpell
  # sudo __package_cp -y -u install apertium-fr-ca # Apertium linguistic data to translate between French and Catalan
  # sudo __package_cp -y -u install apertium-fr-es # Apertium linguistic data to translate between French and Spanish
  # sudo __package_cp -y -u install sword-language-pack-fr # Sword modules for the French language
  # sudo __package_cp -y -u install tesseract-ocr-fra # tesseract-ocr language files for French text
  # sudo __package_cp -y -u install gcompris-sound-fr # Fichiers sons en français pour GCompris

  # Translation
  sudo __package_cp -y -u install openoffice.org-hyphenation
  sudo __package_cp -y -u install openoffice.org-l10n-fr # Paquet linguistique français pour OpenOffice.org
  sudo __package_cp -y -u install thunderbird-locale-fr # Paquet de langue Française pour Thunderbird
  sudo __package_cp -y -u install sunbird-locale-fr # sunbird French language/region package
  sudo __package_cp -y -u install lightning-extension-locale-fr # French language package for lightning-extension
  # sudo __package_cp -y -u install childsplay-alphabet-sounds-fr # French sounds for childsplay's alphabet game
  # sudo __package_cp -y -u install childsplay-lfc-names-fr # Fichiers français pour le jeu Letter Flash Cards
  sudo __package_cp -y -u install fortunes-fr # Fichiers de données françaises pour fortune
  # sudo __package_cp -y -u install kile-i18n-fr # Traductions françaises (fr) pour Kile
  # sudo __package_cp -y -u install acheck-rules-fr # Règles françaises pour acheck
  # sudo __package_cp -y -u install texlive-lang-french # TeX Live: français
  # sudo __package_cp -y -u install asterisk-prompt-fr # French voice prompts for Asterisk
  # sudo __package_cp -y -u install asterisk-prompt-fr-armelle # French voice prompts for Asterisk by Armelle Desjardins
  # sudo __package_cp -y -u install asterisk-prompt-fr-proformatique # French voice prompts for Asterisk
  # sudo __package_cp -y -u install enigmail-locale-fr # French language package for Enigmail

  sudo __package_cp -y autoremove

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_basics ()
{

  __package_cp update
  __package_cp upgrade

  # Formats d'archives supplémentaires pour file-roller
  __package_cp -u install p7zip-full rar unrar

  # Environnement de developpement LAMP
  # __package_cp -u install apache2 apache2-doc mysql-server php5 libapache2-mod-php5 php5-mysql phpmyadmin

  # (recommended) Install the Adobe Flash plugin.
  wget -c -P ${TMPDIR}/ http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_10_linux.deb
  sudo dpkg -i ${TMPDIR}/install_flash_player_10_linux.deb
  # (optional) Install the Java plugin:
  __package_cp -u install sun-java6-plugin

  # Download and install the Adobe Reader package using gdebi:
  wget -c -P ${TMPDIR}/ http://ardownload.adobe.com/pub/adobe/reader/unix/8.x/8.1.2/enu/AdobeReader_enu-8.1.2_SU1-1.i386.deb
  gdebi-gtk ${TMPDIR}/AdobeReader_enu-8*.deb

  # Navigateur Web
  # __package_cp -u install firefox-3.0 firefox-3.0-gnome-support latex-xft-fonts
  #__package_cp -u install midori

  # Install Thunderbird:
  __package_cp -u install thunderbird
  # (recommended) Make Thunderbird the preferred email client:
  gconftool --type string --set /desktop/gnome/url-handlers/mailto/command "thunderbird %s"

  sudo __package_cp -y autoremove

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_home ()
{

  # Drop to single-user mode
  init 1
  # Change directories to /home and copy files
  cd /home
  cp -ax * /mnt/newpart

  # Use the new partition (when old /home is a partition)
  #Unmount the old partition by typing:
  cd /
  umount /home
  # Then, unmount and remount the new partition:
  umount /mnt/newpart
  mount /dev/??? /home

  # Important: After the system starts up normally, log in as root and edit ${config_path}fstab so that /dev/??? is now mounted automatically at /home instead of your old partition. For example, change this line:
  #/dev/hda3	/home	ext2	defaults	1	2
  #/dev/???	/home	ext2	defaults	1	2

  cd /
  mv /home /home.old
  mkdir /home
  mount /dev/??? /home

  # Now, leave single user mode by pressing CTRL-D. When the system is back up and running, edit ${config_path}fstab and add a line like the following:
  #/dev/???	/home	ext2	defaults	1	2

  reboot

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Use home previously installed on an other partition.
# Important: This only applies if you had put the /home directory on another partition during a previous installation, and you now want to use that partition's /home directory.

use_previous_home ()
{

  # 1. Copy your /home directory to the desired partition.
  # where $PARTITION is name of the partition containing the /home directory that you want to switch to

  ls /media
  ask_var 'home_partition' 'Enter the partition to receive HOME directory : '
  sudo cp -pr /home/* "${media_dir}${home_partition}/"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rename_user_dir ()
{

  # If your current username is different from the username you used in the other partition's /home directory, you might have to change the name and ownership of the user directory.
  # where
  #      * $CURRENT_USERNAME is the username of a user who used a different username in the other partition's /home directory
  #      * $OLD_USERNAME is the old username used by that user in the other partition's /home directory
  #      * $PARTITION is name of the partition containing the /home directory that you want to switch to
  su $CURRENT_USERNAME
  cd /media/$PARTITION/home
  sudo mv $OLD_USERNAME $USER
  sudo chown -r $USER:$USER $USER

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_user_config ()
{

  # 2. If you are on a newer version of Ubuntu than you were when you were using /home directory on the other partition, you probably need to copy all configuration files and directories to the old /home directory for each user.
  # where
  #     * $CURRENT_USERNAME is the username of a user whose configuration files you want to migrate
  su $CURRENT_USERNAME
  mkdir /media/$USER/old_config_files
  mv /media/$USER/.* /media/$USER/old_config_files/
  cp -pr ~/.* /media/$USER/

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Switch to an existing /home on another partition
mount_to_home ()
{

  # 3. Set the desired partition's mount point to /home:
  # where
  #     * $PARTITION is name of the partition containing the /home directory that you want to switch to
  # Save the file and quit the editor. (For Nano, press CTRL+O and then CTRL+X. For Vim, press ESC, type :q and press ENTER.)
  sudo cp ${config_path}fstab ${config_path}fstab.backup
  echo "
  # Change
  # /dev/$PARTITION
  UUID=... /media/$PARTITION ...
  # to
  # /dev/$PARTITION
  UUID=... /home ...
  "
  sudo editor ${config_path}fstab

  # 4. Reboot. After rebooting, your /home directory will be located in the new partition.
  echo "After rebooting, your /home directory will be located in the new partition"

  pause

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add or change a default application

change_default_app ()
{

  # 1.
  cp ~/.local/share/applications/mimeapps.list ~/.local/share/applications/mimeapps.list.backup
  echo "
  Add/change appropriate line to:

      [Added Associations]
      $MIME_TYPE=$NEW_APP.desktop;
  "
  editor ~/.local/share/applications/mimeapps.list

  # To figure out what $NEW_APP should be (if necessary):
  ls /usr/share/applications/*.desktop | sed -e "s@/usr/share/applications/@@g" | less

  # To figure out what $MIME_TYPE should be (if necessary):
  find /usr/share/mime/ -mindepth 2 -maxdepth 2 -name "*" | sed -e "s@/usr/share/mime/@@g" -e "s@[.]xml@@g" | less

  # 2. Restart Nautilus:
  killall nautilus

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Encrypted Private directory

install_user_private_dir ()
{

  PRIVATE_DIRS=".mozilla .mozilla-thunderbird .purple"

  # 1. Set up your encrypted Private directory.
  __package_cp -u install ecryptfs-utils
  # You will be asked for your login passphrase and for a mount passphrase.
  # For the login passphrase, enter the password that you use for your Ubuntu login.
  # For the mount passphrase, I recommend just hitting Enter and letting the script pick a random passphrase for you.
  ecryptfs-setup-private

  # 2. (recommended) Migrate your Firefox, Thunderbird, and Pidgin user-directories to the Private directory so that they are encrypted on disk.
  for DIR in $PRIVATE_DIRS
  do
    mv ~/${DIR} ~/Private/
    ln -s ~/Private/${DIR} ~/
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# User directories and bookmarks
change_user_dir ()
{

  # You might have noticed that, upon installation, Ubuntu automatically created folders in your home directory called Desktop, Documents, Music, Pictures, Videos, and Templates. The instructions presented here allow you to change these defaults to use different directories for your desktop, documents, music, etc. This is useful if, for example, you like your directories to be lower-case (e.g., ~/desktop instead of ~/Desktop), or if you want a slightly different organization for your directories (e.g., ~/ instead of ~/Documents).

  # 1. To change the default user-directories, edit the XDG user-directories file:

  menu_title="Folder Type"
  declare -a menu_items
  -o 'Bureau' \
  -o 'Tlchargements' \
  -o 'Modles' \
  -o 'Public' \
  -o 'Documents' \
  -o 'Musique' \
  -o 'Images' \
  -o 'Vidos' \
  --back --exit
  menu_text="Enter Folder to modify : "

  $menu

  case $choice in
    1) key='XDG_DESKTOP_DIR' ;;
    2) key='XDG_DOWNLOAD_DIR' ;;
    3) key='XDG_TEMPLATES_DIR' ;;
    4) key='XDG_PUBLICSHARE_DIR' ;;
    5) key='XDG_DOCUMENTS_DIR' ;;
    6) key='XDG_MUSIC_DIR' ;;
    7) key='XDG_PICTURES_DIR' ;;
    8) key='XDG_VIDEOS_DIR' ;;
    default)
    return ;;
  esac

  folder_type=$choice

  current_dir=$(awk '/$key/ {print $2}' ~/.config/user-dirs.dirs)
  echo "current dir is $current_dir"

  read -p 'Enter new path : ' new_dir
  new_dir=$( check_dir )

  #sed -r "s%(^[ $'\t']*$key[ $'\t']*[=]?[ $'\t']*).*\$%\1$new_dir%" ~/.config/user-dirs.dirs -i
  editor ~/.config/user-dirs.dirs
  # For example, to set the default music directory to ~/audio/music instead of ~/Music, use the following line:
  # XDG_DESKTOP_DIR="$HOME/Bureau"

  # 2. Restart the Gnome Desktop Manager, but before you do so, make sure that the XDG_DESKTOP_DIR entry points to a valid directory; otherwise, your desktop will appear blank. (Even if you mess up, you can always fix this later by editing the ~/.config/user-dirs.dirs file.)

  # 3. To update the bookmarks in the Places menu, the Nautilus Bookmarks menu, and in various file choosers, edit the GTK bookmarks file:
  current_bookmark = $( check_dir "file://$current_dir" )
  new_bookmark     = $( check_dir "file://$new_dir" )
  #sudo sed "/$current_bookmark/$new_bookmark/"
  editor ~/.gtk-bookmarks

  # For example, to add a bookmark named "Music" pointing to /home/user/audio/music, use the following line:
  # file:///home/user/audio/music Music

  # 4. Finally, manually update the default directories in certain applications that store their own default directory information. For example:
  #       1. In OpenOffice.org, click on the Tools > Options menu, go to the OpenOffice.org > Paths item on the left, and change the My Documents entry appropriately.
  #       2. In Sound Juicer, click on the Edit > Preferences menu, and set the Music folder entry appropriately.

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_quanta ()
{

  __package_cp -u install quanta

  # FR translation
  __package_cp -u install kde-i18n-fr kde-l10n-fr language-pack-kde-fr language-pack-kde-fr-base
  cd ${TMPDIR}
  wget http://fxdarkplayer.free.fr/ubuntu/quanta.mo
  sudo cp quanta.mo /usr/share/locale/fr/LC_MESSAGES/ && rm quanta.mo

  # SSH
  __package_cp -u install kdebase-kio-plugins

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_emule ()
{

  echo "deb http://archive.bubuntu.net/bubuntu ${release} main" >> ${config_path}apt/sources.list

  # Puis ajoutez la clef du dépôt en exécutant les lignes suivantes dans un terminal :
  gpg --keyserver wwwkeys.eu.pgp.net --recv-keys AA82C25A36399439
  gpg --armor --export AA82C25A36399439 | sudo apt-key add --

  sudo __package_cp update
  __package_cp -u install emule

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_firefox_addon ()
{

  __package_cp -u install totem-mozilla mozilla-plugin-vlc
  __package_cp -u install realplay

  __package_cp -u install mozilla-mplayer
  # sudo cp /usr/lib/mozilla/plugins/mplayerplug-in-dvx.so /usr/lib/firefox/plugins/
  # sudo cp /usr/lib/mozilla/plugins/mplayerplug-in-dvx.xpt /usr/lib/firefox/plugins/

  # Shockwave
  # Prérequis
  # __package_cp -u install Wine mozplugger

  # Ajout de moteurs de recherche ( plus de liens sur http://mycroft.mozdev.org/ )

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Debian management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"