#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
menu_openerp ()
{

  menu_title="ERP softwares"
  declare -a menu_items
  -o 'Install OpenERP server' \
  -o 'Install OpenERP client' \
  -o 'Install OpenERP Web interface' \
  -o 'Uninstall OpenERP' \
  -o 'Configure OpenERP' \
  menu_text="Enter your choice : "

  while true
  do
    menu

    case $choice in
      1) install_openerp_server ;;
      2) install_openerp_client ;;
      3) install_openerp_web ;;
      4) uninstall_openerp ;;
      5) config_openerp ;;
    esac
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_openerp_client()
{

  __package_cp -u install python python-gtk2 python-glade2 \
  python-matplotlib python-egenix-mxdatetime python-xml python-hippocanvas

  __package_cp -u install openerp-client

  #wget 'http://www.oscommerce.com/redirect.php/go,44' -O 'oscommerce.zip'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_openerp_web()
{

  __package_cp -u install python-setuptools
  sudo easy_install TurboGears==1.0.8
  tg-admin info

  sudo easy_install -U openerp-web

  ask_var 'openerp_server' 'Enter OpenERP server (ex: localhost) : '

  # Locate the config/default.cfg in the installed EGG, and make appropriate changes, especially:
  # [openerp]
  set_confvar 'config/default.cfg' 'server' "$openerp_server"
  set_confvar 'config/default.cfg' 'port' '8070'
  set_confvar 'config/default.cfg' 'protocol' 'socket'
  editor 'config/default.cfg'

  # Now start the web server with start-openerp-web command:
  start-openerp-web

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_openerp_server()
{

  __package_cp -u install build-essential python2.5 python2.5-dev
  sudo __package_cp remove --purge python-xml
  __package_cp -u install python-setuptools
  sudo easy_install-2.5 PyXML

  # Install Python
  __package_cp -u install python-psycopg2 python-reportlab \
  python-egenix-mxdatetime python-tz python-pychart \
  python-pydot python-lxml python-libxslt1 python-vobject

  __package_cp -u install openerp-server

  # Création de la base de données
  __package_cp -u install postgresql

  read -p"Enter Postgresql database password : " postgres_password
  ask_var 'postgres_username' 'Enter new Postgres user name (ex: openuser) : '

  # Add a user
  # The default superuser for PostgreSQL is called postgres.
  # We will use it below as an example. If you wish to use it as well, you may need to login as this user first.
  sudo su - postgres
  createuser -U $postgres_username --createdb --no-createrole --no-adduser -P $postgres_password
  exit

  # Éditez ensuite le fichier ${config_path}default/tinyerp-server pour y mettre le mot de passe de la base de données que vous venez de définir :
  # Specify the database password (Default: not set).
  # sudo set_confvar ${config_path}default/tinyerp-server 'DATABASE_PASSWORD' "'$password'"

  # Redémarrage du serveur
  # ${service_path}tinyerp-server restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uninstall_openerp()
{

  sudo __package_cp autoremove --purge openerp-client openerp-server

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_openerp()
{

  editor 'config/default.cfg'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='OpenERP management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"