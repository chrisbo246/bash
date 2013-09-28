#!/bin/bash
#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__postfix_menu ()
{
  while true; do
    __menu \
    -t 'Mail server' \
    -o 'Install Postfix' \
    -o 'Uninstall Postfix' \
    -o 'Configure Postfix' \
    -o 'Authentify Postfix' \
    -o 'Try to repair mail server' \
    -o 'Check mail ports' \
    --back --exit

    case $REPLY in
      1) install_postfix;;
      2) uninstall_postfix;;
      3) config_postfix;;
      4) auth_postfix;;
      5) repair_mail;;
      6) check_mail_ports;;
    esac
  done
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__mail_menu()
{
  while true; do
    echo -e "${IFS}Mail${IFS}"
    PS3="Select action :"
    exit='[EXIT]'
    back='[BACK]'
    select action in "install_postfix" "config_postfix" "repair_mail" "check_mail_ports" "auth_postfix" "$exit"; do
      case $action in
        "$exit" ) break 100;;
        "install_postfix" ) install_postfix; break;;
        "config_postfix" ) config_postfix; break;;
        "repair_mail" ) repair_mail; break;;
        "check_mail_ports" ) check_mail_ports; break;;
        "auth_postfix" ) auth_postfix; break;;
      esac
    done
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_postfix()
{

  __package_cp -u install libdb4.7 postfix procmail sasl2-bin # libdb4-util

  # postfix doit être membre du groupe sasl. Pour ajouter l'utilisateur postfix au groupe sasl, tapez :
  sudo adduser postfix sasl

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_postfix()
{

  # Pour configurer postfix, tapez :
  sudo dpkg-reconfigure postfix

  ask_var 'host_name' 'Enter host name '

  postconf -e 'smtpd_sasl_local_domain ='
  postconf -e 'smtpd_sasl_auth_enable = yes'
  postconf -e 'smtpd_sasl_security_options = noanonymous'
  postconf -e 'broken_sasl_auth_clients = yes'
  postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
  postconf -e 'inet_interfaces = all'

  echo 'pwcheck_method: saslauthd' >> ${config_path}postfix/sasl/smtpd.conf
  echo 'mech_list: plain login' >> ${config_path}postfix/sasl/smtpd.conf

  mkdir ${config_path}postfix/ssl
  cd ${config_path}postfix/ssl/
  openssl genrsa -des3 -rand ${config_path}hosts -out smtpd.key 1024
  chmod 600 smtpd.key
  openssl req -new -key smtpd.key -out smtpd.csr
  openssl x509 -req -days 3650 -in smtpd.csr -signkey smtpd.key -out smtpd.crt
  openssl rsa -in smtpd.key -out smtpd.key.unencrypted
  mv -f smtpd.key.unencrypted smtpd.key
  openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650

  postconf -e 'smtpd_tls_auth_only = no'
  postconf -e 'smtp_use_tls = yes'
  postconf -e 'smtpd_use_tls = yes'
  postconf -e 'smtp_tls_note_starttls_offer = yes'
  postconf -e 'smtpd_tls_key_file = ${config_path}postfix/ssl/smtpd.key'
  postconf -e 'smtpd_tls_cert_file = ${config_path}postfix/ssl/smtpd.crt'
  postconf -e 'smtpd_tls_CAfile = ${config_path}postfix/ssl/cacert.pem'
  postconf -e 'smtpd_tls_loglevel = 1'
  postconf -e 'smtpd_tls_received_header = yes'
  postconf -e 'smtpd_tls_session_cache_timeout = 3600s'
  postconf -e 'tls_random_source = dev:/dev/urandom'
  postconf -e "myhostname = $host_name"

  # Puis redémarrez le serveur Postfix :
  ${service_path}postfix restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
repair_mail()
{

  if [ -d "/var/vmail" ]; then
    find /var/vmail -maxdepth 2 -type d -path "/var/vmail/*/*" -exec chmod 700 {} \; #711
    chown -R vmail:vmail /var/vmail
  fi

  repair_dovecot

  #check_mail_ports

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
repair_dovecot()
{

  if [ -n "$(which dovecot)" ]; then
    [ -z "$(grep 'mail_location = mbox:~/mail:INBOX=/var/mail/%u' ${config_path}dovecot/dovecot.conf)" ] && sed -r -i "s|(protocol imap \{)|\1${IFS}  mail_location = mbox:~/mail:INBOX=/var/mail/%u|" ${config_path}dovecot/dovecot.conf
    ${service_path}dovecot restart
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check_mail_ports()
{
  outgoing_host=$(hostname -d)

  while read line; do
    port=$(echo "$line" | awk '{print $2}' | sed -r 's/\/.*$//')
    protocol=$(echo "$line" | awk '{print $2}' | sed -r 's/^.*\///')
    program=$(echo "$line" | awk '{print $1}')

    case "$protocol" in
      tcp|tcp6 ) options='';;
      udp|udp6) options='-u';;
    esac
    nc -z $options $outgoing_host $port

    if [ $? -eq 0 ]; then
      incomming_status="\033[32mopen\033[0m"
    else
      incomming_status="\033[31mclosed\033[0m"
    fi
    echo -e "Port $port $protocol ($program) is $incomming_status to incomming connections."

  done < <(cat ${config_path}services | grep -P "(smtp|imap|pop)")
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Authentification

auth_postfix()
{

  # L'authentification utilise saslauthd.
  # Il est possible de changer quelques détails pour le faire fonctionner proprement. Postfix exécutant "chroot" dans /var/spool/postfix nous devons faire :
  mkdir -p /var/spool/postfix/var/run/saslauthd
  rm -fr /var/run/saslauthd

  # Maintenant éditez ${config_path}default/saslauthd pour y activer saslauthd.
  # Pour ce faire décommentez la ligne START=yes
  enable_confvar ${config_path}default/saslauthd 'START'

  # et modifiez la derniere ligne OPTIONS="-c -m /var/run/saslauthd" comme cela: OPTIONS="-m /var/spool/postfix/var/run/saslauthd"
  set_confvat ${config_path}default/saslauthd 'OPTIONS' '"-m /var/spool/postfix/var/run/saslauthd"'

  editor ${config_path}default/saslauthd

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____configure_postfix()
{
  #seeing how many active emails are in the Postfix queue and what domain they are going to
  #qshape active
  # Display mail queue
  # postqueue -p
  # Delete all mails in queue
  # postsuper -d ALL

  postconf -e 'smtpd_sasl_local_domain ='
  postconf -e 'smtpd_sasl_auth_enable = yes'
  postconf -e 'smtpd_sasl_security_options = noanonymous'
  postconf -e 'broken_sasl_auth_clients = yes'
  postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
  postconf -e 'inet_interfaces = all'
  echo 'pwcheck_method: saslauthd' >> ${config_path}postfix/sasl/smtpd.conf
  echo 'mech_list: plain login' >> ${config_path}postfix/sasl/smtpd.conf
  mkdir ${config_path}postfix/ssl
  cd ${config_path}postfix/ssl/
  openssl genrsa -des3 -rand ${config_path}hosts -out smtpd.key 1024
  chmod 600 smtpd.key
  openssl req -new -key smtpd.key -out smtpd.csr
  openssl x509 -req -days 3650 -in smtpd.csr -signkey smtpd.key -out smtpd.crt
  openssl rsa -in smtpd.key -out smtpd.key.unencrypted
  mv -f smtpd.key.unencrypted smtpd.key
  openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650
  postconf -e 'smtpd_tls_auth_only = no'
  postconf -e 'smtp_use_tls = yes'
  postconf -e 'smtpd_use_tls = yes'
  postconf -e 'smtp_tls_note_starttls_offer = yes'
  postconf -e 'smtpd_tls_key_file = ${config_path}postfix/ssl/smtpd.key'
  postconf -e 'smtpd_tls_cert_file = ${config_path}postfix/ssl/smtpd.crt'
  postconf -e 'smtpd_tls_CAfile = ${config_path}postfix/ssl/cacert.pem'
  postconf -e 'smtpd_tls_loglevel = 1'
  postconf -e 'smtpd_tls_received_header = yes'
  postconf -e 'smtpd_tls_session_cache_timeout = 3600s'
  postconf -e 'tls_random_source = dev:/dev/urandom'
  postconf -e 'myhostname = server1.example.com'
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Postfix management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"