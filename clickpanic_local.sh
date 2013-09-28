#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change_console_keyboard_layout
reconfigure_shell()
{
  dpkg-reconfigure console-setup
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
reconfigure_locales()
{
  dpkg-reconfigure locales
  locale-gen
  ${service_dir}apache2 restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
reconfigure_keyboard()
{

  select mapfile in 'en' 'fr'; do
    loadkeys $mapfile
  done
  #section inputdevice
  #str="XkbLayout"
  #sudo sed -i -e "s/$str/$str fr/" ${config_path}X11/xorg.conf

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Local management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"