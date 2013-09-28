#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__dtc_menu()
{
  while true;  do
    echo -e "${IFS}-> Domain Technologie Control (DTC)${IFS}"
    PS3="Select an action :"
    exit='[EXIT]'
    back='[BACK]'
    all='[ALL]'
    select type in "install_dtc" "reconfigure_dtc" "dtc_prepare_sbox_ausf" "$exit"; do
      case $type in
        "$exit" ) break 100;;
        "install_dtc" ) install_dtc; break;;
        "reconfigure_dtc" ) reconfigure_dtc; break;;
        "dtc_prepare_sbox_ausf" ) dtc_prepare_sbox_ausf; break;;
      esac
    done
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_dtc()
{
  $file="${config_path}apt/sources.list"
  $string="deb ftp://ftp.gplhost.com/debian stable main"
  if [ -n $(grep -P "[^#]+$string" "$file") ]; then
    echo "$string" >>"$file"
  fi
  __package_cp update
  __package_cp --purge remove exim4 exim4-base exim4-config exim4-daemon-light nfs-common portmap pidentd pcmcia-cs pppoe pppoeconf ppp pppconfig pidentd
  __package_cp install dtc-toaster
  /usr/share/dtc/admin/install/install
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reconfigure_dtc()
{

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
configure_dtc()
{

  dpkg-reconfigure dtc-postfix-courier
  # /usr/share/dtc/admin/install/install

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dtc_prepare_sbox_ausf()
{

  # Install sbox bootstrap
  cd /usr/share/dtc/admin
  ./create_sbox_bootstrap_copy
  ./update_sbox_bootstrap_copy

  # Make PHP files executable by all
  for i in /var/www/sites/*/*/subdomains/*/html ; do
    cd $i
    find . -iname '*.php' -exec chmod +x {} \;
  done

  #Remove old directories
  for i in /var/www/sites/*/*/subdomains/*/html ; do
    cd $i/.. ; rm -rf bin dev etc lib lib64 libexec sbin usr var
  done
  cd /var/www/sites
  rm -f */*/bin */*/dev */*/etc */*/lib */*/lib64 */*/sbin */*${TMPDIR} */*/usr */*/var
  rm -f */bin */dev */etc */lib */lib64 */sbin *${TMPDIR} */usr */var

  # Replace "localhost" by "127.0.0.1" in config files
  # find . -iname '*.php' -exec sed -i "s/localhost/127.0.0.1/" {} \;
  echo -e "You must manually replace 'localhost' by '127.0.0.1' in your config files.${IFS}Maybe you should try this files...${IFS}"
  find . -type f -name "*conf*.php" -exec grep -ls "localhost" {} \;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='DTC management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

# http://forums.gplhost.com/fudforum/t/3/-[read-this-first]-what-should-i-install-before-dtc?-