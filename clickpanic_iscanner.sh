#!/bin/bash

__install_iscanner()
{
  [ -z "$(which git)" ] && __package_cp -y install git-core
  [ -z "$(ruby -v)" ] && __package_cp -y install ruby

  cd ${TMPDIR}
  #http://cgit.compiz.org/
  git clone https://github.com/Goerik/site-security-scripts/tree/master/anti-virus/iscanner-0.7
  if [ ! -d ${TMPDIR}/ispconfig3_install/install/ ]; then
    wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
    tar xfz ISPConfig-3-stable.tar.gz
  fi
  cd ispconfig3_install/install/
  php -q install.php

  tar -zxvf iscanner.tar.gz
  #cp filesystem/usr/local/sbin
}

script_short_description='Iscanner management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

# If we want to scan a directory:
# iscanner -f /home/user
# If we want to scan a single file
# iscanner -F /home/user/file.php
# So now for cleaning up task we gonna apply the last command:
# iscanner -c infected.log