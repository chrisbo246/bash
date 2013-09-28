#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mofifie la valeur d'une variable dans un fichier de configuration
# Séparateur = : ou espace
# Modifie également lorsque la ligne est précédée de #
# Attention !!! supprime les commentaires de fin de ligne
set_confvar ()
{

  filename=$1
  key=$2
  value=$3
  sed -r "s%(^[ #$'\t']*$key[ $'\t']*[ $'\t'=:]{1}[ $'\t']*)(.*)+([#]+.*)?\$%\1 $value \3%" $filename -i

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_confvar ()
{

  filename=$1
  key=$2

  value=$( awk "/$key/ {print \$2}" $filename )
  if [ "$value" = "=" ]; # || [ "$value"=":" ];
  then
    value=$( awk "/$key/ {print \$3}" $filename )
  fi
  echo $value

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Décommente une ligne correspondant à une variable dans un fichier de configuration
enable_confvar ()
{

  filename=$1
  key=$2

  sed "s|^[ #;$'\t']* $key|$key|" $filename -i

  #décommente une ligne
  # sed '/# bind-address/{:label;/^$/q;n;s/^#//;t label;}'

  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disable_confvar ()
{

  filename=$1
  key=$2
  sed -r "s|^[ $'\t']*$key([ =:$'\t']{1}.*)|# $key\1|" $filename -i
  return

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check that script run as root
if [[ $UID != 0 ]]; then
  printf "\e[31mThis script must be run as root.\e[0m"
  exit 1
fi

# Check system version
if [ $( lsb_release -cs ) != "wheezy" ]; then
  printf "\e[31mThis script is for Debian Wheezy only.\e[0m"
  exit 1
}

echo -e "${IFS}Configure The Network --------------------------------------------${IFS}"

cat > ${config_path}network/interfaces <<EOF
# The primary network interface
#allow-hotplug eth0
#iface eth0 inet dhcp
auto eth0
iface eth0 inet static
         address 192.168.0.100
         netmask 255.255.255.0
         network 192.168.0.0
         broadcast 192.168.0.255
         gateway 192.168.0.254
EOF
editor ${config_path}network/interfaces

echo server1.example.com > ${config_path}hostname
${service_path}hostname.sh start


${service_path}networking stop && ${service_path}networking start



echo -e "${IFS}Configure apt ----------------------------------------------------${IFS}"

editor ${config_path}apt/sources.list

# update the apt package database
__package_cp update

# install the latest updates
kernel=$( uname -v )
__package_cp upgrade
if [ $kerner != $( uname -v ) ]; then
  echo -e "Kernel has been update ans system need to reboot.${IFS}
  Run this script again after reboot."
  read -p"Press a key to continue..." answer
  reboot
fi


__package_cp install debconf-utils
#debconf-get-selections | grep ldap > ldap.seed
debconf-set-selections ./ldap.seed


echo -e "${IFS}Install The SSH Server -------------------------------------------${IFS}"
__package_cp install ssh openssh-server

echo -e "${IFS}Configure hosts --------------------------------------------------${IFS}"

echo "
auto eth0
# 127.0.0.1       localhost.localdomain   localhost
# 192.168.0.1   $servername.$domain     $servername
" > ${config_path}hosts

editor ${config_path}network/interfaces

echo server1.example.com > ${config_path}hostname
service hostname restart

hostname
hostname -f

echo -e "${IFS}Disable AppArmor -------------------------------------------------${IFS}"

echo "It is a good thing to disable apparmor for ISPconfig installation."
read -p"Uninstall apparmor y/n [n]" answer

if [ $answer == "y" ]; then
  service apparmor stop
  update-rc.d -f apparmor remove
  __package_cp remove apparmor apparmor-utils
fi

echo -e "${IFS}Synchronize the System Clock -------------------------------------${IFS}"

__package_cp install ntp ntpdate

echo -e "${IFS}Install Postfix --------------------------------------------------${IFS}"
echo -e "suggested anwers${IFS}
-> General type of mail configuration: Internet Site${IFS}
"

__package_cp install postfix postfix-mysql postfix-doc

echo -e "${IFS}Install Courier --------------------------------------------------${IFS}"

pat-get install courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl

echo -e "uring the installation, the SSL certificates for IMAP-SSL and POP3-SSL are created with the hostname localhost.${IFS}
To change this to the correct hostname (server1.example.com in this tutorial), delete the certificates...
Modify the following two files; replace CN=localhost with CN=server1.example.com (you can also modify the other values, if necessary):
"

cd ${config_path}courier

echo -e "Delete curent certificates"
rm -f ${config_path}courier/imapd.pem
rm -f ${config_path}courier/pop3d.pem

echo -e "Modify configuration"
set_confvar "${config_path}courier/imapd.cnf" "CN" "$servername.$domain"
editor ${config_path}courier/imapd.cnf
set_confvar "${config_path}courier/pop3d.cnf" "CN" "$servername.$domain"
editor ${config_path}courier/pop3d.cnf

echo -e "Recreate the certificates"
mkimapdcert
mkpop3dcert

echo -e "restart Courier-IMAP-SSL and Courier-POP3-SSL"
service courier-imap-ssl restart
service courier-pop-ssl restart

echo -e "${IFS}Install MySQL --------------------------------------------------${IFS}"

__package_cp install mysql-client mysql-server

echo "Comment line${IFS}
bind-address           = 127.0.0.1
"
disable_confvar "$mysql_config" "bind-address"
editor $mysql_config

service mysql restart

echo "Check that networking is enabled..."
netstat -tap | grep mysql


echo -e "${IFS}Install Saslauthd, MySQL, rkhunter, and binutils -----------------${IFS}"
echo -e "suggested anwers${IFS}
System mail name: server1.example.com${IFS}
Create directories for web-based administration? : No${IFS}
SSL certificate required : Ok${IFS}
"

__package_cp install libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin
__package_cp install libpam-mysql openssl getmail4 rkhunter binutils maildrop


echo -e "Install Amavisd-new, SpamAssassin, And Clamav ----------------------${IFS}"

__package_cp install zoo unzip bzip2 arj nomarch lzop cabextract

__package_cp install amavisd-new spamassassin
__package_cp install clamav clamav-daemon clamav-docs
__package_cp install apt-listchanges
__package_cp install libnet-ldap-perl libnet-ident-perl zip libnet-dns-perl
__package_cp install libauthen-sasl-perl daemon libio-string-perl libio-socket-ssl-perl


echo "The ISPConfig 3 setup uses amavisd which loads the SpamAssassin filter library internally, so we can stop SpamAssassin to free up some RAM"
#${service_path}spamassassin stop
#update-rc.d -f spamassassin remove

echo -e "Install PureFTPd And Quota -----------------------------------------${IFS}"

__package_cp install pure-ftpd-common pure-ftpd-mysql quota quotatool
set_confvar "${config_path}default/pure-ftpd-common" "STANDALONE_OR_INETD" "standalone"
set_confvar "${config_path}default/pure-ftpd-common" "VIRTUALCHROOT" "true"
#editor ${config_path}default/pure-ftpd-common

# If you want to allow FTP and TLS sessions, run
echo 1 > ${config_path}pure-ftpd/conf/TLS

mkdir -p ${config_path}ssl/private/
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout ${config_path}ssl/private/pure-ftpd.pem -out ${config_path}ssl/private/pure-ftpd.pem
chmod 600 ${config_path}ssl/private/pure-ftpd.pem
service pure-ftpd-mysql restart

echo -e "Edit ${config_path}fstab and add options usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0 to the partition with the mount point /${IFS}
/dev/mapper/server1-root /               ext4    errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0 0       1
"
#sed -r "s%(^[ #$'\t']*$key[ $'\t']*[ $'\t'=:]{1}[ $'\t']*)(.*)+([#]+.*)?\$%\1 $value \3%" $filename -i
editor ${config_path}fstab

# To enable quota, run these commands:
mount -o remount /
quotacheck -avugm
quotaon -avug

echo -e "${IFS}Install Jailkit --------------------------------------------------${IFS}"
echo "Jailkit is needed only if you want to chroot SSH users. It can be installed as follows ${IFS}(important: Jailkit must be installed before ISPConfig - it cannot be installed afterwards!):"

__package_cp install build-essential autoconf automake1.9 libtool flex bison debhelper

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.14.tar.gz
tar xvfz jailkit-2.14.tar.gz
cd jailkit-2.14
./debian/rules binary
cd ..
dpkg -i jailkit_2.14-1_*.deb
rm -rf jailkit-2.14*

echo -e "${IFS}Install fail2ban -------------------------------------------------${IFS}"

# This is optional but recommended, because the ISPConfig monitor tries to show the fail2ban log:
__package_cp install fail2ban
# To make fail2ban monitor PureFTPd, SASL, and Courier, create the file ${config_path}fail2ban/jail.local:

cat > ${config_path}fail2ban/jail.local <<EOF
[pureftpd]

enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3


[sasl]

enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 5


[courierpop3]

enabled  = true
port     = pop3
filter   = courierpop3
logpath  = /var/log/mail.log
maxretry = 5


[courierpop3s]

enabled  = true
port     = pop3s
filter   = courierpop3s
logpath  = /var/log/mail.log
maxretry = 5


[courierimap]

enabled  = true
port     = imap2
filter   = courierimap
logpath  = /var/log/mail.log
maxretry = 5


[courierimaps]

enabled  = true
port     = imaps
filter   = courierimaps
logpath  = /var/log/mail.log
maxretry = 5
EOF
editor ${config_path}fail2ban/jail.local


cat > ${config_path}fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF
editor ${config_path}fail2ban/filter.d/pureftpd.conf


cat > ${config_path}fail2ban/filter.d/courierpop3.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF
editor ${config_path}fail2ban/filter.d/courierpop3.conf


cat > ${config_path}fail2ban/filter.d/courierpop3s.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF
editor ${config_path}fail2ban/filter.d/courierpop3s.conf


cat > ${config_path}fail2ban/filter.d/courierimap.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF
editor ${config_path}fail2ban/filter.d/courierimap.conf


cat > vi ${config_path}fail2ban/filter.d/courierimaps.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF
editor vi ${config_path}fail2ban/filter.d/courierimaps.conf


# Restart fail2ban afterwards:
service fail2ban restart