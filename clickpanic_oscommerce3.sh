#!/bin/bash
# ------------------------------------------------------------------------------
install_oscommerce ()
{

  #oscommerce_version='3.0a5'
  ask_var 'oscommerce_release' 'Enter Oscommerce release (stable/unstable) : '

  # Install PHP Extensions
  $install_cmd php5-mysqli php5-gd php5-curl php5-openssl

  # Edit PHP Settings
  set_confvar '$php_config' 'register_globals' 'Off'
  set_confvar '$php_config' 'magic_quotes' 'Off'
  set_confvar '$php_config' 'file_uploads' 'On'
  set_confvar '$php_config' 'session.auto_start' 'Off'
  set_confvar '$php_config' 'session.use_trans_sid' 'Off'
  $edit_cmd '$php_config'

  # Download oscommerce release
  cd '${TMPDIR}'
  case $oscommerce_release in
    unstable) # 3.0A5
      # wget 'http://www.oscommerce.com/redirect.php/go,45' -O 'oscommerce'
      wget 'http://oscommerce.sunsite.dk/downloads/oscommerce-3.0a5.zip' -O 'oscommerce.zip'
      wget 'http://www.oscommerce.com/community/contributions,6615/download,24311' -O 'oscommerce_fr_language.zip'
      web_dir=''
    ;;
    default) # 2.2RC2A
      # wget 'http://www.oscommerce.com/redirect.php/go,44' -O 'oscommerce.zip'
      wget 'http://www.oscommerce.com/ext/oscommerce-2.2rc2a.zip'  -O 'oscommerce.zip'
      wget 'http://www.oscommerce.com/community/contributions,1372/download,23770' -O 'oscommerce_fr_language.zip'
      web_dir='catalog/'
    ;;
  esac

  # Create Apach project
  create_apache_project
  /etc/init.d/apache2 force-reload

  # install Oscommerce
  unzip oscommerce-*
  mv oscommerce*/oscommerce/* "${project_path}${project_name}"
  rm -rf oscommerce*

  cd "${project_path}${project_name}"

  echo "Close Wab navigator when configuration is ended..."
  firefox "http://$local_ip:$port/$web_dir"

  sudo rm -rf 'install'
  sudo chmod 000 'includes/configure.php'

}
# ------------------------------------------------------------------------------

script_short_description='OScommerce CMS management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"