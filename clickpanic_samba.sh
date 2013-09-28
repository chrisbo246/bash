#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__samba_menu ()
{
  while true; do
    __menu \
    -t 'Samba share server' \
    -o 'Install Samba' \
    -o 'Uninstall Samba' \
    -o 'Create Samba user' \
    -o 'Create Samba share' \
    -o 'Edit Samba configuration' \
    --back --exit

    case $REPLY in
      1) install_samba;;
      2) uninstall_samba;;
      3) add_samba_user;;
      4) add_samba_share;;
      5) config_samba;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_samba ()
{

  __package_cp -u install samba smbfs winbind
  __package_cp -u install system-config-samba

  backup_file ${config_path}nsswitch.conf
  sed -i -e 's/^hosts:.*$/\0 wins/' ${config_path}nsswitch.conf
  editor ${config_path}nsswitch.conf

  # Start samba at startup
  # sudo ln -s ${service_path}samba ${config_path}rc2.d/S91samba

  # Now, we’ve created the directory and we’re going to add a bit to samba.conf to let the samba know what folder it should be sharing, and to who.

  #Find the line “security = usr” and replace it with:
  #security = user
  #username map = ${config_path}samba/smbusers
  backup_file ${config_path}samba/smb.conf
  sudo set_confvar ${config_path}samba/smb.conf 'security' 'user'
  sudo enable_confvar ${config_path}samba/smb.conf 'security'
  sudo set_confvar ${config_path}samba/smb.conf 'wins support' 'yes'
  sudo enable_confvar ${config_path}samba/smb.conf 'wins support'
  sudo set_confvar ${config_path}samba/smb.conf 'dns proxy' 'yes'
  sudo enable_confvar ${config_path}samba/smb.conf 'name resolve order'

  config_samba

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_samba ()
{

  sudo service samba stop
  sudo __package_cp -y remove samba smbfs winbind system-config-samba

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_samba()
{

  editor ${config_path}nsswitch.conf
  editor ${config_path}samba/smb.conf
  gksu editor ${config_path}samba/smbusers

  backup_file ${config_path}fstab
  gksu editor ${config_path}fstab

  # sudo pdbedit

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_samba_user ()
{

  # Now that we’ve got samba installed, let’s create a local user with which people can log in with.
  # Go to System-> Administration-> Users and Groups.

  # I created a new group (for this demonstration, I’ll call it newgroup) and a new user (let’s call it newuser).
  # Add the new user to the new group. I’m not going to go through every step of the gui as it’s very straightforward.

  #read -p"Enter the unix user name to associate with (ex: $USER) : " unix_username
  select_user

  # read -p"Enter a new samba user name : " samba_username
  samba_username=$unix_username

  # Now that you’ve got a group and user, let’s give them access to your samba share.
  sudo smbpasswd -a $samba_username

  # Now, in the smbusers file that you’r editing, add the following
  #username = “username”
  # Here, the first username represents the local user, and the second username, in quotes, represents the samba user. Save the file and exit editor.

  echo "$unix_username=\"$samba_username\"" | sudo tee -a "${config_path}samba/smbusers"
  editor ${config_path}samba/smbusers

  ${service_path}samba restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_samba_share ()
{

  read -p"Enter new share name : " share_name
  read -p"Enter the path to share ending winth / (ex: /home/ShareMe/) : " share_dir

  # Now you’ve got Samba installed and running, and are ready to create a folder to share. We’ll call this folder ShareMe for this example.
  sudo mkdir -p "$share_dir"
  sudo chmod -R 0777 "$share_dir"

  # Then add the following to the bottom of the file:
  backup_file ${config_path}smb/samba/smb.conf
  echo "

  [$share_name]
  comment = $share_name
  path = \"$share_dir\"
  public = yes
  writable = no
  create mask = 0777
  directory mask = 0777
  force user = nobody
  force group = nogroup
  " | sudo tee -a "${config_path}samba/smb.conf"
  editor ${config_path}samba/smb.conf

  #Now let’s restart Samba and give it a whirl.
  ${service_path}samba restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Samba management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"