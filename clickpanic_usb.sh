#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Install automount program
install_usb()
{

  #__package_cp install autofs udev
  __package_cp install usbmount
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
configure_usb()
{

  #udevinfo -a -p /sys/block/sdb/sdb5/ | grep model
  udevadm info --query all --path /sys/block/sdb/sdb5/ --attribute-walk
  ATTRS{model}="Storage Device  "

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='USB management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

#find recently added ou removed device
#diff <(lsusb) <(sleep 3s && lsusb)