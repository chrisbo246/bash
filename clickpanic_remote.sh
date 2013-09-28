#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Reboot (remotely) from Windows into Ubuntu

reboot_remote_ubuntu ()
{

  # NOTE: this assumes that you use GRUB to dual boot, and that Ubuntu is the first boot option in /boot/grub/menu.lst.

  # 1. If you are rebooting a remote computer, first Remote-desktop into the remote computer, and then follow the next step in the remote desktop.
  # 2. Go to Start > Run... and enter:
  shutdown /r /t 00

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * On the server (i.e., remote machine)
enable_remote_ubuntu_desktop_server ()
{

  # 1. Install OpenSSH Server on the server, and make sure that the SSH port is open to the client.

  # 2. Enable remote desktop and restrict access to localhost (via SSH tunneling):
  gconftool --type boolean --set /desktop/gnome/remote_access/local_only true
  gconftool --type boolean --set /desktop/gnome/remote_access/prompt_enabled false
  gconftool --type boolean --set /desktop/gnome/remote_access/view_only false
  gconftool --type boolean --set /desktop/gnome/remote_access/lock_screen_on_disconnect true
  gconftool --type boolean --set /desktop/gnome/remote_access/enabled true

  # 3. You can disable remote desktop whenever you want as follows:
  gconftool --type boolean --set /desktop/gnome/remote_access/enabled false

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remote desktop to an Ubuntu machine (securely!)
# * On the client

remote_ubuntu_desktop ()
{

  # 1. Start an SSH tunnel from the client's local port 5903 to the server's local port 5900:
  # Note that the "::1" in the above line is the IPv6 name for localhost.
  ssh -fN -L 5903:[::1]:5900 $SERVER

  # 2. Remote desktop to local port 5903 at the client (which is the client's end of the SSH tunnel):
  vinagre localhost:5903

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remote desktop to a Windows machine

direct_remote_windows_desktop ()
{

  # Note: The remote machine must be booted into Windows XP, so you may have to reboot remotely from Ubuntu to Windows first.

  # 1. If you can access the remote machine directly:
  #    where
  #        * $SERVER is the hostname or IP of the remote machine
  #        * $SYNC_DIR is a directory on the local machine to be shared with the remote machine
  rdesktop -r disk:sync=/home/$USER/$SYNC_DIR $SERVER:3389

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remote desktop to a Windows machine

tunnel_remote_windows_desktop ()
{

  # Note: The remote machine must be booted into Windows XP, so you may have to reboot remotely from Ubuntu to Windows first.

  # 2. If the remote machine is protected by a bastion host, you will need to create an SSH tunnel through which to access the server:
  #   where
  #       * $LOCAL_PORT is a port on the local machine through which you want to tunnel (e.g., 2001)
  #       * $SERVER is the hostname or IP of the remote machine
  #       * $BASTION is the hostname or IP of the bastion host
  #       * $SYNC_DIR is a directory on the local machine to be shared with the remote machine
  ssh -fN -L $LOCAL_PORT:$SERVER:3389 $BASTION
  rdesktop -r disk:sync=/home/$USER/$SYNC_DIR localhost:$LOCAL_PORT

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Remote management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
