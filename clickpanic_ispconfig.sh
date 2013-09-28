#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__ispconfig_menu()
{
  while true; do
    __menu \
    -t 'ISPconfig' \
    -o 'Install ispconfig' \
    -o 'Update ispconfig' \
    -o 'Reconfigure ispconfig' \
    -o 'Uninstall ispconfig' \
    -o 'Reset ispconfig admin password' \
    -o 'Repair ispconfig mysql password' \
    -o 'Edit configurations' \
    --back --exit

    case $REPLY in
      1 ) install_ispconfig;;
      2 ) update_ispconfig;;
      3 ) reconfigure_ispconfig;;
      4 ) uninstall_ispconfig;;
      5 ) reset_ispconfig_admin_password;;
      6 ) repair_ispconfig_mysql_password;;
      7 ) edit_ispconfig_configs;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_ispconfig_configs()
{
read -d '' filenames <<EOF
${config_path}network/interfaces
${config_path}hosts
${config_path}hostname
${config_path}postfix/master.cf
${config_path}mysql/my.cnf
${config_path}apache2/mods-available/suphp.conf
${config_path}mime.types
${config_path}aliases
${config_path}default/pure-ftpd-common
${config_path}pure-ftpd/conf/TLS
${config_path}fstab
${config_path}cron.d/awstats
${config_path}fail2ban/jail.local
${config_path}fail2ban/filter.d/pureftpd.conf
${config_path}fail2ban/filter.d/dovecot-pop3imap.conf
${config_path}apache2/conf.d/squirrelmail.conf
${config_path}postfix/main.cf
EOF

  while true;  do
    local options=$(echo -e "$filenames" | sort)
    __menu -t 'Edit configuration' $(printf ' -o %s' $options) --back --exit

    [[ $REPLY -ge 1 && $REPLY -le ${#options[@]} ]] && [ -e "$VALUE" ] && editor "$VALUE"

  done
  restart_ispconfig_services
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# restart all services
restart_ispconfig_services()
{
  a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest actions fastcgi alias
  a2ensite default-ssl
  ${service_path}hostname.sh
  ${service_path}mysql restart
  ${service_path}apache2 restart
  ${service_path}postfix restart
  ${service_path}mailman start
  ${service_path}amavis restart
  ${service_path}pure-ftpd-mysql restart
  ${service_path}fail2ban restart
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ispconfig()
{

  # First of all, edit hostname
  sed -r -i 's|(127.0.0.1[ \t]+)(localhost)[ \t]*$|\1localhost.localdomain\t\2|' "${config_path}hosts"
  fqdn=$(hostname -f)
  ip=$(hostname -i)
  sed -r -i "s|^[ \t1-9\.\:\/]+([ \t]*$fqdn)|$ip\1|" "${config_path}hosts"
  echo "$(hostname -f)" > "${config_path}hostname"
  ${service_path}hostname.sh
  [[ $(hostname) != $(hostname -f) ]] && echo -e "hostname and hostname must return the same value.\nCheck ${config_path}hosts and ${config_path}hostname before retrying."  >&2&& return

  sed -r -i "s|^([ \t]*(deb\|deb-src).*debian.org/debian/?[ \t]+[^ \t]+).*|\1 main contrib non-free|" "${config_path}apt/sources.list"
  editor ${config_path}apt/sources.list
  __package_cp update
  __package_cp upgrade

  #echo "set bind9/different-configuration-file"  | debconf-communicate
  #echo "set bind9/run-resolvconf false"  | debconf-communicate
  #echo "set bind9/start-as-user bind"  | debconf-communicate
  #echo "set courier-base/webadmin-configmode false"  | debconf-communicate
  #echo "set debconf/frontend Dialog"  | debconf-communicate
  #echo "set debconf/priority medium"  | debconf-communicate
  #echo "set dictionaries-common/default-ispell francais GUTenberg (French GUTenberg)"  | debconf-communicate
  #echo "set dictionaries-common/default-wordlist francais (French)"  | debconf-communicate
  #echo "set grub2/linux_cmdline"  | debconf-communicate
  #echo "set grub-pc/install_devices /dev/disk/by-id/ata-WDC_WD2500BEVT-80A23T0_WD-WX11A30L5763"  | debconf-communicate
  #echo "set grub2/linux_cmdline_default quiet"  | debconf-communicate
  #echo "set keyboard-configuration/layout"  | debconf-communicate
  #echo "set keyboard-configuration/xkb-keymap fr(latin9)"  | debconf-communicate
  #echo "set keyboard-configuration/variant Français"  | debconf-communicate
  #echo "set keyboard-configuration/variantcode"  | debconf-communicate
  #echo "set keyboard-configuration/other"  | debconf-communicate
  #echo "set keyboard-configuration/optionscode"  | debconf-communicate
  #echo "set keyboard-configuration/modelcode pc105"  | debconf-communicate
  #echo "set keyboard-configuration/toggle No toggling"  | debconf-communicate
  #echo "set keyboard-configuration/compose No compose key"  | debconf-communicate
  #echo "set keyboard-configuration/switch No temporary switch"  | debconf-communicate
  #echo "set keyboard-configuration/altgr The default for the keyboard layout"  | debconf-communicate
  #echo "set keyboard-configuration/model PC générique 105 touches (intl)"  | debconf-communicate
  #echo "set keyboard-configuration/layoutcode fr"  | debconf-communicate
  #echo "set keyboard-configuration/store_defaults_in_debconf_db true"  | debconf-communicate
  #echo "set libpam-runtime/profiles unix, winbind, consolekit"  | debconf-communicate
  #echo "set locales/default_environment_locale fr_FR"  | debconf-communicate
  #echo "set locales/locales_to_be_generated fr_FR ISO-8859-1, fr_FR.UTF-8 UTF-8, fr_FR@euro ISO-8859-15"  | debconf-communicate
  #echo "set mailgraph/ignore_localhost false"  | debconf-communicate
  #echo "set mailgraph/mail_log /var/log/mail.log"  | debconf-communicate
  #echo "set mailgraph/start_on_boot true"  | debconf-communicate
  #echo "set man-db/install-setuid false"  | debconf-communicate
  #echo "set mysql-server/password_mismatch"  | debconf-communicate
  #echo "set ssh/use_old_init_script true"  | debconf-communicate
  #echo "set postfix/chattr false"  | debconf-communicate
  #echo "set postfix/root_address"  | debconf-communicate
  #echo "set postfix/destinations server1.clickpanic.com, localhost.clickpanic.com, , localhost"  | debconf-communicate
  #echo "set samba/run_mode daemons"  | debconf-communicate
  #echo "set tzdata/Zones/Etc UTC"  | debconf-communicate
  #echo "set tzdata/Zones/Europe Paris"  | debconf-communicate
  #echo "set tzdata/Areas Europe"  | debconf-communicate

  # Debconf preconfig
  __package_cp -y install debconf-utils
  echo "set postfix/main_mailer_type Internet Site" | debconf-communicate
  echo "set postfix/mailname $(hostname -f)" | debconf-communicate
  echo "set phpmyadmin/reconfigure-webserver apache2" | debconf-communicate
  echo "set phpmyadmin/dbconfig-install false" | debconf-communicate
  echo "set dash/sh false" | debconf-communicate

  
  # HTTP: Apache2 nginx
  # SMTP: Postfix
  # POP3/IMAP: Courier Dovecot
  # FTP: PureFTPd
  # DNS: BIND MyDNS
  # Database: MySQL
  # Statistics: Webalizer AWStats
  # Virtualization: OpenVZ
  
  # Install requiered packages
  __package_cp -y install task-dns-server task-mail-server task-ssh-server task-web-server
  #__package_cp -y install task-database-server task-file-server task-print-server
  #__package_cp -y install task-mail-server task-web-server task-dns-server task-ssh-server
  __package_cp -y install ssh openssh-server
  __package_cp -y install vim-nox
  __package_cp -y install ntp ntpdate
  __package_cp -y install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve sudo
  __package_cp -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl
  __package_cp -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
  __package_cp -y install php5-xcache
  __package_cp -y install libapache2-mod-fastcgi php5-fpm
  __package_cp -y install mailman
  __package_cp -y install pure-ftpd-common pure-ftpd-mysql quota quotatool
  __package_cp -y install bind9 dnsutils
  __package_cp -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl
  __package_cp -y install fail2ban
  __package_cp -y install squirrelmail

  # Auto-configuration  
  sed -r -i "s|#([ \t]*(submission\|smtps)[ \t]+inet)|\1|" "${config_path}postfix/master.cf"
  sed -r -i "s|#([ \t]*-o[ \t]+(syslog_name\|smtpd_tls_security_level\|smtpd_tls_wrappermode\|smtpd_sasl_auth_enable\|smtpd_client_restrictions))|\1|" "${config_path}postfix/master.cf"
  sed -r -i "s|^([ \t]*bind-address[ \t]+=)|#\1|" "${config_path}mysql/my.cnf"
  sed -r -i "s|^([ \t]*</FilesMatch>)|\1${IFS}\tAddType application/x-httpd-suphp .php .php3 .php4 .php5 .phtml|" "${config_path}apache2/mods-available/suphp.conf"
  sed -r -i "s|^([ \t]*<FilesMatch)|#\1|" "${config_path}apache2/mods-available/suphp.conf"
  sed -r -i "s|^([ \t]*SetHandler application/x-httpd-suphp)|#\1|" "${config_path}apache2/mods-available/suphp.conf"
  sed -r -i "s|^([ \t]*</FilesMatch>)|#\1|" "${config_path}apache2/mods-available/suphp.conf"
  sed -r -i "s|^([ \t]*application/x-ruby)|#\1|" "${config_path}mime.types"
  [ -e ${config_path}aliases -a -z "$(grep mailman ${config_path}aliases)" ] && cat >> ${config_path}aliases <<EOF
## mailman mailing list
mailman:              "|/var/lib/mailman/mail/mailman post mailman"
mailman-admin:        "|/var/lib/mailman/mail/mailman admin mailman"
mailman-bounces:      "|/var/lib/mailman/mail/mailman bounces mailman"
mailman-confirm:      "|/var/lib/mailman/mail/mailman confirm mailman"
mailman-join:         "|/var/lib/mailman/mail/mailman join mailman"
mailman-leave:        "|/var/lib/mailman/mail/mailman leave mailman"
mailman-owner:        "|/var/lib/mailman/mail/mailman owner mailman"
mailman-request:      "|/var/lib/mailman/mail/mailman request mailman"
mailman-subscribe:    "|/var/lib/mailman/mail/mailman subscribe mailman"
mailman-unsubscribe:  "|/var/lib/mailman/mail/mailman unsubscribe mailman"
EOF
  sed -r -i "s|^([ \t]*STANDALONE_OR_INETD[ \t]*=[ \t]*).*$|\1standalone|" "${config_path}default/pure-ftpd-common"
  sed -r -i "s|^([ \t]*VIRTUALCHROOT[ \t]*=[ \t]*).*$|\1true|" "${config_path}default/pure-ftpd-common"
  sed -r -i "s|^([ \t]*[^ \t]+[ \t]+/[ \t]+[^ \t]+[ \t]+[^ \t]+)|\1,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0|" "${config_path}fstab"
  sed -r -i "s|^([ \t]*[^#]+)|#\1|" "${config_path}cron.d/awstats"

  [ ! -e ${config_path}fail2ban/jail.local ] && cat > ${config_path}fail2ban/jail.local <<EOF
[pureftpd]
enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3

[dovecot-pop3imap]
enabled = true
filter = dovecot-pop3imap
action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
logpath = /var/log/mail.log
maxretry = 5

[sasl]
enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 3
EOF

  [ ! -e ${config_path}fail2ban/filter.d/pureftpd.conf ] && cat > ${config_path}fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

  [ ! -e ${config_path}fail2ban/filter.d/dovecot-pop3imap.conf ] && cat > ${config_path}fail2ban/filter.d/dovecot-pop3imap.conf <<EOF
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF

read -d '' content <<EOF
Options FollowSymLinks
<IfModule mod_php5.c>
  AddType application/x-httpd-php .php
  php_flag magic_quotes_gpc Off
  php_flag track_vars On
  php_admin_flag allow_url_fopen Off
  php_value include_path .
  php_admin_value upload_tmp_dir /var/lib/squirrelmail${TMPDIR}
  php_admin_value open_basedir /usr/share/squirrelmail:${config_path}squirrelmail:/var/lib/squirrelmail:${config_path}hostname:${config_path}mailname
  php_flag register_globals off
</IfModule>
<IfModule mod_dir.c>
  DirectoryIndex index.php
</IfModule>

# access to configtest is limited by default to prevent information leak
<Files configtest.php>
  order deny,allow
  deny from all
  allow from 127.0.0.1
</Files>
EOF
  sed -r -i "s|<Directory /usr/share/squirrelmail>.*<\Directory>|$content|" "${config_path}apache2/conf.d/squirrelmail.conf"

  [ -z "$(grep -P 'Alias\s+/squirrelmail' ${config_path}apache2/conf.d/squirrelmail.conf)" ] | echo "Alias /squirrelmail /usr/share/squirrelmail" >> ${config_path}apache2/conf.d/squirrelmail.conf
  [ -z "$(grep -P 'Alias\s+/webmail' ${config_path}apache2/conf.d/squirrelmail.conf)" ] | echo "Alias /webmail /usr/share/squirrelmail" >> ${config_path}apache2/conf.d/squirrelmail.conf

  #echo '
  #<VirtualHost 1.2.3.4:80>
  #  DocumentRoot /usr/share/squirrelmail
  #  ServerName webmail.example.com
  #</VirtualHost>
  #' > ${config_path}apache2/conf.d/squirrelmail.conf

  #
  newlist mailman
  newaliases
  ln -s ${config_path}mailman/apache.conf ${config_path}apache2/conf.d/mailman.conf
  echo 1 > ${config_path}pure-ftpd/conf/TLS
  mkdir -p ${config_path}ssl/private/
  openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout ${config_path}ssl/private/pure-ftpd.pem -out ${config_path}ssl/private/pure-ftpd.pem
  chmod 600 ${config_path}ssl/private/pure-ftpd.pem
  mount -o remount /
  quotacheck -avugmf
  quotaon -avug
  squirrelmail-configure
  cd ${config_path}apache2/conf.d/
  ln -s ../../squirrelmail/apache.conf squirrelmail.conf
  mkdir /var/lib/squirrelmail${TMPDIR}
  chown www-data /var/lib/squirrelmail${TMPDIR}

  ${service_path}spamassassin stop
  update-rc.d -f spamassassin remove

  # Manual check of auto-configured files
  edit_ispconfig_configs
  #restart_ispconfig_services

  # Install ISPconfig
  cd ${TMPDIR}
  if [ ! -d ${TMPDIR}/ispconfig3_install/install/ ]; then
    wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
    tar xfz ISPConfig-3-stable.tar.gz
  fi
  cd ispconfig3_install/install/
  if [ -d /usr/local/ispconfig ]; then
    php -q update.php
  else
    php -q install.php
  fi
  
  # Fix xcache for Wordpress
  filename=$(find ${config_path}php* -type f -name xcache.ini)
  [ -e "$filename" ] && sed -r -i "s|(xcache\.var_size[ \t]*=[ \t]*)[0a-zA-Z]+|\116M|" "$filename"
  
  # Fix bastille-firewall
  [[ $(which bastille-netfilter) ]] && mkdir -p /var/lock/subsys/bastille-firewall
  
  # Fix amavis
  [[ $(which amavisd-release) ]] && chown -R amavis:amavis /var/run/amavis
  
  # Custom debconf config
  #echo "set backup-manager/backup-repository /var/archives"  | debconf-communicate
  #echo "set backup-manager/directories /etc /home /var/www/clients /usr/local/bin" | debconf-communicate
  
  # openvz
  #if [[ $(which openvz) ]]; then
  #  VPSID=101
  #  for CAP in CHOWN DAC_READ_SEARCH SETGID SETUID NET_BIND_SERVICE NET_ADMIN SYS_CHROOT SYS_NICE CHOWN DAC_READ_SEARCH SETGID SETUID NET_BIND_SERVICE NET_ADMIN SYS_CHROOT SYS_NICE; do
  #    vzctl set $VPSID --capability ${CAP}:on --save
  #  done
  #fi
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reconfigure_ispconfig()
{
  cd ${TMPDIR}
  if [ ! -d ${TMPDIR}/ispconfig3_install/install/ ]; then
    wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
    tar xfz ISPConfig-3-stable.tar.gz
  fi
  cd ispconfig3_install/install/
  if [ -d /usr/local/ispconfig ]; then
    php -q update.php
  else
    echo "ISPconfig don't seem to be installed."
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_ispconfig()
{
  php -q /usr/local/ispconfig/server/scripts/ispconfig_update.php
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_ispconfig()
{
  #/root/ispconfig/uninstall

  #/root/42go/uninstall
  #rm -rf /root/ispconfig
  #rm -rf /home/admispconfig

  cd ${TMPDIR}
  if [ ! -d ${TMPDIR}/ispconfig3_install/install/ ]; then
    wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
    tar xfz ISPConfig-3-stable.tar.gz
  fi
  cd ispconfig3_install/install/
  php -q uninstall.php
  mysql -root -p -e "DELETE FROM mysql.user WHERE Host='localhost' AND User='ispconfig'"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
generate_ispconfig_certificat()
{
  echo "Enter password :"
  read password

  openssl genrsa -des3 -passout pass:$password -out /root/ispconfig/httpd/conf/ssl.key/server.key2 1024
  openssl req -new -passin pass:$password -passout pass:$password -key /root/ispconfig/httpd/conf/ssl.key/server.key2 -out /root/ispconfig/httpd/conf/ssl.csr/server.csr -days 365
  openssl req -x509 -passin pass:$password -passout pass:$password -key /root/ispconfig/httpd/conf/ssl.key/server.key2 -in /root/ispconfig/httpd/conf/ssl.csr/server.csr -out /root/ispconfig/httpd/conf/ssl.crt/server.crt -days 365
  openssl rsa -passin pass:$password -in /root/ispconfig/httpd/conf/ssl.key/server.key2 -out /root/ispconfig/httpd/conf/ssl.key/server.key
  chmod 400 /root/ispconfig/httpd/conf/ssl.key/server.key
  ${service_path}ispconfig_server restart
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ispconfig_signed_certificat()
{
  #cat /usr/local/ispconfig/interface/ssl/ispserver.csr
  # Create a free class1 certificat from https://www.startssl.com/
  #mv /usr/local/ispconfig/interface/ssl/ispserver.crt /usr/local/ispconfig/interface/ssl/ispserver.crt.bak
  # Copy to
  #editor /usr/local/ispconfig/interface/ssl/ispserver.crt
  echo ""
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reset_ispconfig_admin_password()
{
mysql -u root -p <<EOF
use dbispconfig;
UPDATE sys_user SET passwort=md5('admin') WHERE username='admin';
quit;
EOF
  echo "You can now login to ISPconfig using user 'admin' / password 'admin'."
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
repair_ispconfig_mysql_password()
{
  password=$(grep -P "$conf\['db_password'\]\s?=" /usr/local/ispconfig/server/lib/config.inc.php | sed -r "s|^[^=]+=\h*'([^']+)'.*$|\1|")
mysql -u root -p <<EOF
use mysql;
update user set Password=PASSWORD('$password') WHERE user='ispconfig';
EOF
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='ISPconfig management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"