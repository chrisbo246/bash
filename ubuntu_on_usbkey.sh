#!/bin/sh

# In the first place, you need to plug your usb drive and check under which device it is associated. To find out the device, run:
echo "plug your usb drive and check under which device it is associated"
sudo fdisk -l
read -p"Enter device name (ex: sdb) :" device_name
device="/dev/$device_name"

# On my system, the device appears as being /dev/sdb, I will therefore use /dev/sdb as a reference for this tutorial, please replace it accordingly to your system (might be sda, sdc ...).
# Once you found your device, you are going to create the partitions.

# Using the wrong device name might destroy your system partition, please double check
# 2.2. Making the partitions

# Make sure every of your already mounted partition are unmounted:
sudo umount "${device}1"
sudo umount "/tmp/ubuntu-livecd"

# and then launch fdisk, a tool to edit partition under linux:

# We are going delete all the partition and then create 2 new partition: one fat partition of 750M which will host the files from the live CD iso, and the rest on another partition.
#  At fdisk prompt type d x where x is the partition number (you can simply type d if you only have one partition), then:
#    * n to create a new partition
#    * p to make it primary
#    * 1 so it is the first primary partition
#    * Accept the default or type 1 to start from the first cylinder
#    * +750M to make it 750 Meg big
#    * a to toggle the partition active for boot
#    * 1 to choose the 1 partition
#    * t to change the partition type
#    * 6 to set it to FAT16

sudo fdisk $device <<EOF
d
3
EOF

sudo fdisk $device <<EOF
d
2
EOF

sudo fdisk $device <<EOF
d
1
EOF

sudo fdisk $device <<EOF
n
p
1
1
+750M
a
1
t
6
w
EOF

#Now we have out first partition set up, let's create the second one:
#    * n to create yet again a new partition
#    * p to make it primary
#    * 2 to be the second partition
#    * Accept the default by typing Enter
#    * Accept the default to make your partition as big as possible
#    * Finally, type w to write the change to your usb pendrive

sudo fdisk $device <<EOF
n
p
2


w
EOF

# Partitions are now created, let's format them.
# 2.3. Formatting the partitions

# The first partition is going to be formated as a FAT filesystem of size 16 and we are going to attribute it the label "liveusb".
sudo mkfs.vfat -F 16 -n liveusb ${device}1

# The second partition is going to be of type ext2 with a blocksize of 4096 bytes and the label casper-rw. Mind that it has to be labeled as casper-rw otherwise the tutorial won't work!.
sudo mkfs.ext2 -b 4096 -L casper-rw ${device}2

# At this stage, our usb pendrive is ready to host the liveCD image. Now, let's copy the files to the usb bar.


# 3.1. Mounting Ubuntu liveCd image

# In the first place we need to mount our ubuntu iso. Depending if you have the .iso file or the CD, there is 2 different ways of mounting it.
# 3.1.1. Mounting from the CD

# People using Ubuntu or any other user-friendly distro, might just have to insert the cd and it will be mounted automatically. If this is not the case:
# sudo mount /media/cdrom

# should mount it.
# 3.1.2. Mounting from an .iso image file

# We will need to create a temporary directory, let say /tmp/ubuntu-livecd and then mount our iso (I will be using a feisty fawn iso).
#select_file

#select_file ()
#{
read -p"Enter ISO file path : " iso
if [ -f $iso ];
then
  mkdir /tmp/ubuntu-livecd
  sudo mount -o loop $iso /tmp/ubuntu-livecd
else
  echo "$iso don't exist !"
  exit 0
  #select_file
fi
#}

# Once the cd image is ready, it is time to mount the newly created usb bar partitions:
# 3.2. Mounting the usb bar partitions

# Same here, you might be able to get both your partition by simply replugging the usb pendrive, partition might appears as: /media/liveusb and /media/casper-rw. If this is not the case, then # you will need to mount them manually:
echo "Unplug then replug the usb pendrive and press ENTER"
read -p" " pause


sudo fdisk -l
echo "Check if your USB device is always associated with $device_name"
read -p"Enter curent device name (ex: sdd) :" device_name
device="/dev/$device_name"

mkdir /tmp/liveusb
sudo mount ${device}1 /tmp/liveusb

# All the partitions we need are now mounted, let's copy the files.
# 3.3. Copying the files to the usb bar

# Let positionned yourself on the CD image directory (in my case: /tmp/ubuntu-livecd , but it might be /media/cdrom , and copy at the root of your usb first partition:

#    * the directories: 'casper', 'disctree', 'dists', 'install', 'pics', 'pool', 'preseed', '.disk'
#    * The content of directory 'isolinux'
#    * and files 'md5sum.txt', 'README.diskdefines', 'ubuntu.ico'
#    * as well as files: 'casper/vmlinuz', 'casper/initrd.gz' and 'install/mt86plus'

cd /tmp/ubuntu-livecd
sudo cp -rf casper disctree dists install pics pool preseed .disk isolinux/* md5sum.txt README.diskdefines ubuntu.ico casper/vmlinuz casper/initrd.gz install/mt86plus /tmp/liveusb/

# It might complain about symbolic links not being able to create, you can ignore this.

# Now let's go to the first partition of your usb disk and rename isolinux.cfg to syslinux.cfg:
cd /tmp/liveusb
sudo mv isolinux.cfg syslinux.cfg

# change /tmp/liveusb according to your settings


# Edit syslinux.cfg so it looks like:
echo "
DEFAULT persistent
GFXBOOT bootlogo
GFXBOOT-BACKGROUND 0xB6875A
APPEND  file=preseed/ubuntu.seed boot=casper initrd=initrd.gz ramdisk_size=1048576 root=/dev/ram rw quiet splash --
LABEL persistent
  menu label ^Start Ubuntu in persistent mode
  kernel vmlinuz
  append  file=preseed/ubuntu.seed boot=casper persistent initrd=initrd.gz ramdisk_size=1048576 root=/dev/ram rw quiet splash --
LABEL live
  menu label ^Start or install Ubuntu
  kernel vmlinuz
  append  file=preseed/ubuntu.seed boot=casper initrd=initrd.gz ramdisk_size=1048576 root=/dev/ram rw quiet splash --
LABEL xforcevesa
  menu label Start Ubuntu in safe ^graphics mode
  kernel vmlinuz
  append  file=preseed/ubuntu.seed boot=casper xforcevesa initrd=initrd.gz ramdisk_size=1048576 root=/dev/ram rw quiet splash --
LABEL check
  menu label ^Check CD for defects
  kernel vmlinuz
  append  boot=casper integrity-check initrd=initrd.gz ramdisk_size=1048576 root=/dev/ram rw quiet splash --
LABEL memtest
  menu label ^Memory test
  kernel mt86plus
  append -
LABEL hd
  menu label ^Boot from first hard disk
  localboot 0x80
  append -
DISPLAY isolinux.txt
TIMEOUT 300
PROMPT 1
F1 f1.txt
F2 f2.txt
F3 f3.txt
F4 f4.txt
F5 f5.txt
F6 f6.txt
F7 f7.txt
F8 f8.txt
F9 f9.txt
F0 f10.txt
" | sudo tee /tmp/liveusb/syslinux.cfg


# Valeurs par défaut
# include menu.cfg
# default vesamenu.c32
# prompt 0
# timeout 300
# gfxboot bootlogo




# Woof, finally we have our usb disk almost usuable. We have a last thing to do: make the usb bootable.
# 3.4. Making the usb bar bootable.

# in order to make our usb disk bootable, we need to install syslinux and mtools:
sudo apt-get install syslinux mtools

# And finally unmount /dev/sdb1 and make it bootable:
cd
sudo umount /tmp/liveusb
sudo syslinux -f ${device}1

# Here we are :D , reboot, set your BIOS to boot from the usb bar and enjoy Ubuntu linux from a pendrive
# 4. Troubleshooting

# If you are having trouble booting on the usb bar, this might be due to your MBR being corrupted. In order to fix it up, you can use lilo (I installed lilo on my box only for thid purpose).
# will fix the MBR on device $device
sudo apt-get install lilo
sudo lilo -M $device


exit 0


