#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__clickpanic_menu()
{
  while true; do
    __menu \
    -t 'CLICKPANIC' \
    -o 'Reinstall all packages' \
    -o 'Reinstall all packages (purge all configs!)' \
    -o 'Find issues from logs' \
    --back --exit

    case $REPLY in
      1) reinstall_all_packages;;
      2) reinstall_all_packages --purge;;
      3 ) debug_from_logs;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reinstall_all_packages()
{
  local ARGS=$(getopt -o "+ph" -l "+purge,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -p|--purge) shift; purge=1; shift;;
      -h|--help) shift; echo -e "$help" 1>&2; exit 65;;
      -- ) shift; break;
    esac
  done

  #sudo __package_cp --reinstall install `dpkg --get-selections | grep install | grep -v deinstall | cut -f1 | egrep -v '(package1|package2)'`
  if [[ $purge==1 ]]; then
    sudo dpkg --get-selections | grep install | grep -v deinstall | cut -f1 | xargs __package_cp --reinstall --purge -y --force-yes install
  else
    sudo __package_cp --reinstall install `dpkg --get-selections | grep install | grep -v deinstall | cut -f1`
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
debug_from_logs()
{

  fix=0
  verbose=0
  no_fix_text="No automatic fix will be apply for the following issues."

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Read last logs and try to fix issues

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-f|--fix] [-v|--verbose]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -f, --fix
        Try to fix issues.
    -v, --verbose
        Display informations about issues.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "+fvh" -l "+fix,verbose,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -f|--fix) shift; fix=1;;
      -v|--verbose) shift; verbose=1;;
      -h|--help) shift; echo -e "$help" 1>&2; exit 65;;
      -- ) shift; break;
    esac
  done

  #echo "Searching logs..."
  logs=$(last_logs)
  #echo -e "Found:${IFS}$logs"

  case $logs in
    # Aug 23 15:10:01 server1 dovecot: pop3-login: Disconnected (no auth attempts in 0 secs): user=<>, rip=::1, lip=::1, secured, session=<2ZLUH53kiQAAAAAAAAAAAAAAAAAAAAAB>
    '.* server1 dovecot: [^ ]+-login: Disconnected \(no auth attempts in 0 secs\): user=[^ ]+, rip=[^ ]+, lip=[^ ]+, secured, session=[^ ]+' )
      matches=$(echo -e "$logs" | grep -P "$pattern")
      if [[ $matches ]]; then
      (( $verbose == 1 )) && echo -e <<EOF
$matches
Edit ${config_path}dovecot/dovecot.conf and set disable_plaintext_auth = no (for testing).
Read more at http://wiki2.dovecot.org/WhyDoesItNotWork
EOF
        if (( $fix == 1 )); then
          echo "$no_fix_text"
        fi
      fi
    ;;

    #Aug 23 18:08:08 server1 postfix/smtp[23523]: 5D6063E2328: to=<christophe.boisier@gmail.com>, relay=gmail-smtp-in.l.google.com[2a00:1450:400c:c05::1a]:25, delay=1.6, delays=0.01/0.03/0.54/0.99, dsn=5.7.1, status=bounced (host gmail-smtp-in.l.google.com[2a00:1450:400c:c05::1a] said: 550-5.7.1 [2a01:e35:8b88:a850:4a5b:39ff:fe49:16cd      16] The sender does not 550-5.7.1 meet basic ipv6 sending guidelines of authentication and rdns 550-5.7.1 resolution of sending ip. Please review 550 5.7.1 https://support.google.com/mail/answer/81126for more information. m1si228211wjz.122 - gsmtp (in reply to end of DATA command))
    #Aug 23 18:08:08 server1 postfix/qmgr[4080]: 5D6063E2328: removed
    '.* postfix/smtp[^ ]+: [^ ]+: to=<[^ ]+>, relay=[^ ]+, delay=[^ ]+, delays=[^ ]+, dsn=[^ ]+, status=bounced \(host [^ ]+ said: [^ ]+ \[.+\] The sender does not [^ ]+ meet basic ipv6 sending guidelines of authentication and rdns [^ ]+ resolution of sending ip. Please review .* more information. [^ ]+ - gsmtp \(in reply to end of DATA command\)' )
      matches=$(echo -e "$logs" | grep -P "$pattern")
      if [[ $matches ]]; then
      (( $verbose == 1 )) && echo -e <<EOF
$matches
Your mail server does not meet ipv6 sending guidelines of authentication and rdns resolution.
You should
- Add a AAAA record (IP v6)  to your DNS zones
- Add a PTR record (reverse DNS) to your DNS zones
- Add a TXT record with either SPF check or DKIM check
https://support.google.com/mail/answer/81126
EOF
        if (( $fix == 1 )); then
          echo "$no_fix_text"
        fi
      fi
    ;;

    # Aug 23 20:22:12 server1 postfix/trivial-rewrite[27850]: warning: do not list domain clickpanic.com in BOTH mydestination and virtual_mailbox_domain
    '.* postfix/smtp[^ ]+: [^ ]+: to=<[^ ]+>, relay=[^ ]+, delay=[^ ]+, delays=[^ ]+, dsn=[^ ]+, status=bounced \(host [^ ]+ said: [^ ]+ \[.+\] The sender does not [^ ]+ meet basic ipv6 sending guidelines of authentication and rdns [^ ]+ resolution of sending ip. Please review .* more information. [^ ]+ - gsmtp \(in reply to end of DATA command\)' )
      matches=$(echo -e "$logs" | grep -P "$pattern")
      if [[ $matches ]]; then
    (( $verbose == 1 )) && echo -e <<EOF
$matches
You can list $(hostname -d) either in virtual_mailbox_domains or in mydestination (but not in both) in ${config_path}postfix/main.cf.
EOF
        if (( $fix == 1 )); then
          #virtual_mailbox_domains ${config_path}postfix/main.cf
          #mydestination ${config_path}postfix/main.cf
          echo "$no_fix_text"
        fi
      fi
    ;;

    #apache2/error.log
    #[Fri Aug 23 20:55:02 2013] [error] [client ::1] client denied by server configuration: /var/www/clickpanic.com/

    #mail.warn
    #Aug 23 20:54:42 server1 postfix/smtpd[29080]: warning: database /var/lib/mailman/data/virtual-mailman.db is older than source file /var/lib/mailman/data/virtual-mailman
    #Aug 23 20:54:43 server1 postfix/cleanup[29088]: warning: database /var/lib/mailman/data/virtual-mailman.db is older than source file /var/lib/mailman/data/virtual-mailman

  esac
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fix_all()
{
  # Increase xcache var_size for Wordpress
  filename=$(find ${config_path}php* -type f -name xcache.ini)
  [ -e "$filename" ] && sed -r -i "s|(xcache\.var_size[ \t]*=[ \t]*)[0a-zA-Z]+|\116M|" "$filename"
  
  # Create missing bastille-firewall directory
  [[ $(which bastille-netfilter) ]] && mkdir -p /var/lock/subsys/bastille-firewall
  
  # Fix amavis directory owner
  [[ $(which amavisd-release) ]] && chown -R amavis:amavis /var/run/amavis
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='Debug functions'
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
