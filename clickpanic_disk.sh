#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__drive_menu ()
{
  while true; do
    __menu \
    -t 'Device' \
    -o 'Mount a device' \
    -o 'Unmount a device' \
    -o 'Change device mont name' \
    -o 'Change device label' \
    --back --exit

    case $REPLY in
      1) mount_device;;
      2) unmount_device;;
      3) change_device_mount;;
      4) change_device_label;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mount
mount_device ()
{

  # To list the devices for the various partitions:
  # where
  #      * $DEVICE is the device to be mounted
  #      * $DEVICE_NAME is the directory where you want the device to be mounted

  #select_device_type

  select_device
  #read -p"Enter the device to be mounted (ex: sda1)" DEVICE
  read -p"Enter the new device name (Ex: Multimedia): " DEVICE_NAME

  ask_var 'media_dir' 'Enter mount directory (Ex: /media/) : '
  media_dir=$( check_dir $media_dir )

  case $DEVICE_TYPE in
    1)
      # 1. ReiserFS partition:
    sudo mount /dev/$DEVICE ${media_dir}$DEVICE_NAME -t reiserfs -o notail ;;
    2)
      # 2. ext3 partition:
    sudo mount /dev/$DEVICE ${media_dir}$DEVICE_NAME -t ext3 ;;
    3)
      # 3. NTFS partition:
    sudo mount /dev/$DEVICE ${media_dir}$DEVICE_NAME -t ntfs -o nls=utf8 ;;
    4)
      # 4. FAT32 partition or USB drive:
    sudo mount /dev/$DEVICE ${media_dir}$DEVICE_NAME -t vfat -o iocharset=utf8 ;;
    5)
      # 5. CD/DVD:
    sudo mount /dev/$DEVICE ${media_dir}$DEVICE_NAME -t iso9660 -o unhide,ro ;;
    6)
      # 6. ISO file:
      sudo modprobe loop
    sudo mount $DEVICE ${media_dir}$DEVICE_NAME -t iso9660 -o loop,unhide,ro ;;
    7)
      # 7. Samba
      __package_cp -u install gvfs-bin
    sudo gvfs-mount "smb://$DEVICE/$DEVICE_NAME" ;;
    #sudo mount -t cifs //$DEVICE/$DEVICE_NAME ${media_dir}$MOUNT_NAME -o username=winusername,password=winpassword,iocharset=utf8,file_mode=0777,dir_mode=0777
    8)
      __package_cp -u install gvfs-bin
    sudo gvfs-mount "ftp://$DEVICE/$DEVICE_NAME" ;;
    9)
      __package_cp -u install gvfs-bin
    sudo gvfs-mount "ssh://$DEVICE/$DEVICE_NAME" ;;
    10)
      # Samba (permanant)
      sudo mkdir ${media_dir}$DEVICE_NAME
      echo "//$DEVICE/$DIR ${media_dir}$DEVICE_NAME smbfs username=$username,password=$password,defaults,auto,rw,users,exec,uid=1000,gid=1000 0 0" | tee -a ${config_path}fstab
      editor ${config_path}fstab
    mount -a ;;
    11)
      # SATA (permanant)
      sudo mkdir ${media_dir}$DEVICE_NAME
      UUID=$( get_device_uuid $DEVICE )
      echo "UUID=$UUID ${media_dir}$DEVICE_NAME ntfs-3g force defaults,auto,rw,users,exec,uid=1000,gid=1000 0 0" | tee -a ${config_path}fstab
      editor ${config_path}fstab
    mount -a ;;
    default)
    return;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
device_info ()
{

  echo "Device           : $DEVICE"
  echo "Device ID        : $DEVICE_ID"
  echo "Device label     : $DEVICE_LABEL"
  echo "Device uuid      : $DEVICE_UUID"
  echo "Device mount dir : $DEVICE_NAME"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_device_type ()
{

  menu_title="Device type"
  declare -a menu_items
  -o 'ReiserFS partition' \
  -o 'ext3 partition' \
  -o 'NTFS partition' \
  -o 'FAT32 partition or USB drive' \
  -o 'CD/DVD' \
  -o 'ISO file' \
  -o 'Samba Shared directory' \
  -o 'FTP Shared directory' \
  -o 'SSH Shared directory' \
  menu_text="Enter your choice : "

  $menu

  DEVICE_TYPE=$choice

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_device ()
{
  menu_title="Disk"
  declare -a menu_items
  menu_items=$( ls -lah /dev/disk/by-id | egrep -v 'part[0-9]+$' )
  menu_text="Enter your choice : "

  $menu

  DEVICE_LIST=$( ls -AClh /dev/disk/by-uuid | egrep -v 'part[0-9]+$' | nawk -F"-" '{$1=$1; print $4}' )
  DEVICE=$DEVICE_LIST["$choice"]

}
____select_device ()
{

  #sudo fdisk -l
  #dmesg | grep hd[a-z]

  menu_title="Device"
  #menu_items=( $( ls $media_dir | grep -v "cdrom\|~" ) )
  #set -a menu_items
  menu_items=( $( ls -AC /dev/disk/by-id | grep -Pv "(-part[0-9]{1,2})$"  ) ) #| grep -v "..\|."
  menu_text="Select a device : "

  select_list_menu

  DEVICE_LIST=$( ls -AC /dev/disk/by-id | grep -Pv "(-part[0-9]{1,2})$" ) # | grep -v "..\|."
  DEVICE=$DEVICE_LIST["$choice"]

  DEVICE_ID=$( get_device_id $DEVICE )
  DEVICE_LABEL=$( get_device_label $DEVICE )
  DEVICE_UUID=$( get_device_uuid $DEVICE )

  DEVICE_NAME=$choice

  print_device_info

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_device_mount ()
{

  select_device_label

  read -p"Enter the new device name : " NEW_DEVICE_NAME

  sudo umount $DEVICE_NAME
  sudo mv "${media_dir}$DEVICE_NAME" "${media_dir}$NEW_DEVICE_NAME"
  #sed -r "s|${media_dir}$DEVICE_NAME|${media_dir}$NEW_DEVICE_NAME|" $${config_path}fstab -i

  #Modifie tous les fichiers faisant référence à ce montage
  sed -r "s|${media_dir}Multimedia||g" | sudo grep -r -l "${media_dir}Multimedia" "/etc" | grep '[^~]$'

  mount -a
  ${service_path}samba restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Unmount
unmount_device ()
{

  select_device_name
  kill_device $DEVICE_NAME
  sudo umount $DEVICE_NAME

  # Force unmount (if previous step doesn't work):
  sudo umount -l $DEVICE_NAME

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
kill_device ()
{

  DEVICE_NAME=$1
  sudo lsof | grep $DEVICE_NAME | awk '{print $2}' -exec kill -KILL {} \;

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_device_uuid ()
{
  DEVICE=$1
  ls -lah /dev/disk/by-uuid | awk "\$10==\"../../$DEVICE\" {print \$8}"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_device_label ()
{
  DEVICE=$1
  ls -lah /dev/disk/by-label | awk "\$10==\"../../$DEVICE\" {print \$8}"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_device_id ()
{
  DEVICE=$1
  ls -lah /dev/disk/by-id | awk "\$10==\"../../$DEVICE\" {print \$8}"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_disk_id ()
{
  DEVICE=$1
  ls -lah /dev/disk/by-id | awk "\$10==\"../../$DEVICE\" {print \$8}" | grep '-part[0-9]+$'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_device_type ()
{
  DEVICE=$1
  ls -lah /dev/disk/by-uuid | awk "\$10==\"../../$DEVICE\" {print \$8}" | nawk -F"-" '{$1=$1; print $1}'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_device_partition ()
{
  DEVICE=$1
  ls -lah /dev/disk/by-uuid | awk "\$10==\"../../$DEVICE\" {print \$8}" | nawk -F"-" '{$1=$1; print $4}'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List number of mounted file system partition

getNumberOfParittions() {
  if [ "$OS" == "FreeBSD" ]; then
    tmp="$($DF -aHt nonfs,nullfs,devfs| $GREP -vE "^Filesystem" | $AWK '{ print $1 " " }')"
    echo "$($DF -aHt nonfs,nullfs,devfs| $GREP -vE "^Filesystem" |$WC -l) ($tmp)"
    elif [ "$OS" == "Linux" ]; then
    tmp="$($DF -aHt ext3 -t ext2|$GREP -vE "^Filesystem" |$AWK '{ print $1 " " }')"
    echo "$($DF -aHt ext3 -t ext2|$GREP -vE "^Filesystem" |$WC -l) ($tmp)"
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List total number of SCSI/IDE disks connected to FreeBSD/Linux box
# along with device name includes CDROM, IDE/SCSI hard disk drive
# Example 3 (ad0 ad1 acd0)

getDiskDrives(){
  if [ "$OS" == "FreeBSD" ]; then
    t="$($IOSTAT -d| $HEAD -1)"
    c="$(echo $t | $WC -w)"
    elif [ "$OS" == "Linux" ]; then
    :
  fi
  echo "$c ($t)"
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Drive management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
