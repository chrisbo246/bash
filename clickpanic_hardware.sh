#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__hardware_menu ()
{
  while true; do
    __menu \
    -t 'Device' \
    -o 'Hardware infos' \
    --back --exit

    case $REPLY in
      1) hardware_info;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hardware_info()
{

  menu_title="Device"
  declare -a menu_items
  -o 'Processor' \
  -o 'Memory' \
  -o 'PCI' \
  -o 'Disk' \
  -o 'USB' \
  -o 'Network' \
  -o 'Wifi' \
  -o 'Interrupt' \
  -o 'IO ports' \
  menu_text="Enter your choice : "

  while true
  do
    menu

    case $choice in
      1)
        echo -e "${IFS}Processor -------------------------------------------------------------"
        cat /proc/cpuinfo
      ;;
      2)
        echo -e "${IFS}Memory ----------------------------------------------------------------"
        cat /proc/meminfo
      ;;
      3)
        echo -e "${IFS}PCI -------------------------------------------------------------------"
        lspci
      ;;
      4)
        echo -e "${IFS}Disk ------------------------------------------------------------------"
        sudo fdisk -l
      ;;
      5)
        echo -e "${IFS}USB -------------------------------------------------------------------"
        lsusb
      ;;
      6)
        echo -e "${IFS}Network ---------------------------------------------------------------"
        sudo lshw -C network
      ;;
      7)
        echo -e "${IFS}Wifi ------------------------------------------------------------------"
        iwconfig
      ;;
      8)
        echo -e "${IFS}Interrupts ------------------------------------------------------------"
        cat /proc/interrupts
      ;;
      9)
        echo -e "${IFS}IO ports --------------------------------------------------------------"
        cat /proc/ioports
      ;;
    esac
  done

  # liste des modules et des composant qui les utilisent
  #lsmod

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
list_hardware()
{
  echo "PCI -------------------------------------------------------------------"
  lspci | cut -d: -f2 | cut -b6-
  echo "USB -------------------------------------------------------------------"
  lsusb | cut -d: -f3 | cut -b6-
  echo "Disks -----------------------------------------------------------------"
  fdisk -l | grep -P "Disk /dev/" | cut -b11-

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"