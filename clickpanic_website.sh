#!/bin/bash

#   How to add your own configuration
#
#   1) Add an ID (your CMS name in lower case) to the $compatible_website_types variable.
#   2) Add a case to the __find_websites() function by copying an existing one.
#     Try to locate the main configuration file of your CMS (or another distinct file) then handle the path to math site root.
#   3) Add a case to the __custom_securisation() function.
#   At this point, you can call commands as if you where cd in site root.
#   By default, a secure chmod will be apply to files, directories,
#   .htaccess, php.ini, php.cgi, php5.cgi, etc... so add only specific tasks.
#   - chmod specific directories
#   - Do NOT set write permissions for most files as they are already set by default
#   - Set group permissions even if you don't need, they will be removed with remove_group_permissions=0
#   - Use symbolic mode chmod with $httpd_users"+w" for files that should be writable by CMS
#   chmod "[ugo][+-=][rwx],ug+w"
#   - Add php_flag / php value strings
#   - Use .ini syntaxe even for .htaccess
#   - Think to add ${IFS} at the end of each lines exept last one.
#   - Try to get CMS version if needed by your config


# Default configuration
# Don't change this values. You can edit them via the configuration menu
# or by copying this lines to the .cnf file.

# The website list like directory;type
# You can generate the list from "Update website list" menu
read -d "" website_directories <<EOF
EOF

#read -d "" website_types <<EOF
#EOF

# Global sites path
# You can use /var/www if you don't have a strict directory structure.
# You can also speed up site detection providing a more complete path
# using wildcards (e.g. like /var/www/sites/*/*/subdomains/*/html)
find_from_path='/var/www'

# Accurate filter using regular expression.
# Don't forget wildcard at the end if you want to search in subdirectories.
website_directory_pattern='/var/www/.*'

# The owner directory (pattern) having the user:group defined.
# It should be something like /var/www/clients/client[0-9]+/web[0-9]+/web
# The same owner will be apply to all files.
owner_directory_pattern='/var/www'

# Default file owner
# You can use root / www-data for Apache server.
# If the owner_directory_pattern is define, you can leave this values empty.
website_owner_user=
website_owner_group=

# Allow HTTP updates / installation / edition
# '0' = Only FTP updates will be possible (more secure but)
# '1' = Give write permission to the web process (your CMS)
allow_http_updates=1

# Remove group permissions
# '0' = Use group permissions as usual
# '1' = You can disable group permissions(g-rwx) if user is also the web process (more secure)
remove_group_permissions=0

# Some sites running with sbox_ausf
# 0 = No (default)
# 1 = Will chmod +x *.php and replace "localhost" by "127.0.0.1"
sbox_ausf_mode=0

# Predefined profils
admin_panel=

case $admin_panel in
  dtc )
    find_from_path='/var/www/sites/*/*/subdomains*/*/html'
    website_directory_pattern='/var/www/sites/[^\/]+/[^\/]+/subdomains[^\/]+/[^\/]+/html/.*'
    owner_directory_pattern='/var/www/sites/[^\/]+/[^\/]+/subdomains[^\/]+/[^\/]+/html'
    website_owner_user=dtc
    website_owner_group=dtcgrp
    remove_group_permissions=1
    sbox_ausf_mode=1
  ;;
  ispconfig )
    find_from_path='/var/www/clients/client*/web*/web'
    website_directory_pattern='/var/www/clients/client[0-9]+/web[0-9]+/web/.*'
    owner_directory_pattern='/var/www/clients/client[0-9]+/web[0-9]+/web'
    website_owner_user=
    website_owner_group=
    remove_group_permissions=0
    sbox_ausf_mode=0
  ;;
esac

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__website_menu()
{
  while true; do
    __menu \
    -t 'Website' \
    -o 'Select a website to securise' \
    -o 'Securize all websites' \
    -o 'Update website list' \
    -o 'Edit settings' \
    --back --exit

    case $REPLY in
      1 ) select_website;;
      2 ) securize_all_websites;;
      3 ) update_website_list;;
      4 ) select_website_setting;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_website_setting()
{
  while true; do
    __menu \
    -t 'Configuration' \
    -o 'Find from path' \
    -o 'Site directory pattern' \
    -o 'Owner directory pattern' \
    -o 'File owner user' \
    -o 'File owner group' \
    -o 'Allow http updates' \
    -o 'Remove group permissions' \
    -o 'Make sbox_ausf complient' \
    --back --exit

    case $REPLY in
      1 ) edit_var -p 'Site directory pattern' -v "$find_from_path" -q "'" --text --save 'find_from_path';;
      2 ) edit_var -p 'Site directory pattern' -v "$website_directory_pattern" -q "'" --text --save 'website_directory_pattern';;
      3 ) edit_var -p 'Owner directory pattern' -v "$owner_directory_pattern" -q "'" --text --save 'owner_directory_pattern';;
      4 ) edit_var -p 'File owner user' -v "$website_owner_user" --text --save 'website_owner_user';;
      5 ) edit_var -p 'File owner group' -v "$website_owner_group" --text --save 'website_owner_group';;
      6 ) edit_var -p 'Allow http updates' -v "$allow_http_updates" --text --save 'allow_http_updates';;
      7 ) edit_var -p 'Remove group permissions' -v "$remove_group_permissions" --text --save 'remove_group_permissions';;
      8 ) edit_var -p 'Make sbox_ausf complient' -v "$sbox_ausf_mode" --text --save 'sbox_ausf_mode';;
      #1 ) edit_var -p 'Admin panel' -v "$admin_panel" --text --save 'admin_panel';;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_website()
{

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Find website installation directories for a CMS type

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-t|--type]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -t, --type
        CMS ID.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "+t:h" -l "+type:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -t|--type) shift; type="${1:-$type}"; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  if [ -n "$website_directories" ]; then
    while true; do
      local options
      count=$(echo -e "$website_directories" | wc -l)
      #count=${#website_directories[@]}
      for value in $website_directories; do
        options+=$(echo "$value" | awk -F';' '{print $1}')
      done
      options+=$('ALL')
      
      __menu -t 'Directories' $(printf ' -o %s' $options) --back --exit

      if [[ $REPLY -ge 1 && $REPLY -le $count+1 ]]; then
        local i=0
        for item in $website_directories; do
          ((++i))
          if [[ $REPLY -eq $count+1 || $REPLY -eq $i ]]; then
            [[ $REPLY -eq $count+1 ]]&& echo -e "${IFS}$i/$count"
            directory=$(echo "$item" | awk -F';' '{print $1}')
            type=$(echo "$item" | awk -F';' '{print $2}')
            securize_website --path "$directory" --type "$type" --user "$website_owner_user" --group "$website_owner_group"
          fi
        done
      fi
    done
  else
    echo -e "There are no registered directories. Have you updated the list of sites?"
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#select_website_type()
#{
#  __website_config
#
#  if [ -n "$website_directories" ]; then
#    while true; do
#      unset options
#      for value in $website_types; do
#        options="${options} -o $value"
#      done
#      __menu -t 'Compatible Website types' $options
#
#      [[ $REPLY -ge 1 && $REPLY -le ${#options[@]} ]] && select_website -t "$VALUE"
#    done
#  else
#    echo -e "There are no registered types. Have you updated the list of sites?"
#  fi
#}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__website_config()
{

  [ -v "$FUNCNAME" ]  >&2&& return || declare -i $FUNCNAME=1

  # CHMOD alias
  web_process='ug'
  public='o'
  config_file_mod=$web_process'=r,o='
  writable_mod=$web_process'+w'

  # chmod options
  # -f = silent
  # -v = verbose
  chmod_options='-f'

  # find options
  find_options='-P'

  # Server-side scripts
  # Files with following extensions can be hide to public.
  # Do not include both server / client side scripts like js
  # Read more at http://en.wikipedia.org/wiki/Server-side_scripting
  server_side_scripts="asp|avfp|aspx|cfm|jsp|lp|op|cgi|inc|ipl|pl|php|py|rb|rbw|smx|ssjs|lasso|dna|tpl|r|w"

read -d '' admin_panels <<EOF
apache
dtc
ispconfig
EOF

read -d '' compatible_website_types <<EOF
colabtive
dokuwiki
dolibarr
drupal
elgg
gallery
joomla
magento
moodle
opencart
oxwall
prestashop
seo-panel
wordpress
EOF

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_website_list()
{
  __website_config

  # Delete directories that don't exists anymore
  for item in $website_directories; do
    directory=$(echo "$item" | awk -F';' '{print $1}')
    if [ ! -d "$directory" ]; then
      echo "$directory don't exists an had been removed from website list."
      search=$(printf "%s${IFS}" "$directory" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
      website_directories=$(echo -e "$website_directories" | sed 's/'"$search"'//g')
    fi
  done

  # Search website directories for each type
  local i=0
  for type in $compatible_website_types; do     
    #echo -ne "Searching for ${type}\033[0K websites...\r"  
    progress_bar $(wc -l <<<"${compatible_website_types}") $((i++))
    __find_websites "$type"
  done
  #echo -ne "\033[2K"
  #echo "${#website_directories[@]} websites found"
  #echo "$(echo -e $website_directories | wc -l) websites found"
  
  # Save values
  __save_variable --save "website_directories" "$website_directories"
  #__save_variable -k "website_types" -v "$website_types" --save

  # convert line breaks
  website_directories=$(echo -e $website_directories)
  #website_types=$(echo -e $types)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Detect CMS install directories
__find_websites()
{
  [ $# -ne 1 ] && echo "Usage: $FUNCNAME 'website_type'"  >&2 && exit 65

  case $1 in
    colabtive )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/config/standard/*" -name "config.php" -exec sh -c 'grep -ls "$db_host" {} | sed "s/\/[^\/]*\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    dokuwiki )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/conf/*" -name "local.php" -exec sh -c 'grep -lsi "Dokuwiki" {} | sed "s/\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    dolibarr )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/htdocs/conf/*" -name "conf.php" -exec sh -c 'grep -ls "$dolibarr_main_url_root" {} | sed "s/\/[^\/]*\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    drupal )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/sites/*" -name "settings.php" -exec sh -c 'grep -ls "$hash_salt" {} | sed "s/\/[^\/]*\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    elgg )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/sites/*" -name "settings.php" -exec sh -c 'grep -ls "Elgg.Core" {} | sed "s/\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    gallery )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/application/config/*" -name "config.php" -exec sh -c 'grep -ls "gallery" {} | sed "s/\/[^\/]*\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    joomla )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/*" -name "configuration.php" -exec sh -c 'grep -ls "JConfig" {} | sed "s/\/[^\/]*$//"' \;)
    ;;
    magento )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/app${config_path}*" -name "local.xml" -exec sh -c 'grep -ls "Magento" {} | sed "s/\/[^\/]*\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    moodle )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/*" -name "config.php" -exec sh -c 'grep -ls "moodledata" {} | sed "s/\/[^\/]*$//"' \;)
    ;;
    oxwall )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/ow_includes/*" -name "config.php" -exec sh -c 'grep -ls "OW_URL_HOME" {} | sed "s/\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    opencart )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/admin/*" -name "config.php" -exec sh -c 'grep -ls "HTTP_CATALOG" {} | sed "s/\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    prestashop )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/config/*" -name "settings.inc.php" -exec sh -c 'grep -ls "_PS_VERSION_" {} | sed "s/\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    seo-panel )
      list=$(find $find_options $find_from_path -type f -regex "$website_directory_pattern" -path "${find_from_path%/}*/config/*" -name "sp-config.php" -exec sh -c 'grep -ls "SP_INSTALLED" {} | sed "s/\/[^\/]*\/[^\/]*$//"' \;)
    ;;
    wordpress )
      list=$(find $find_options $find_from_path -type f -path "${find_from_path%/}*/*" -name "wp-config.php" -exec sh -c 'grep -ls "AUTH_KEY" {} | sed "s/\/[^\/]*$//"' \;)
    ;;
    * )
      list=$(find $find_options $find_from_path -maxdepth 1 -type d -regex "$website_directory_pattern" -path "${find_from_path%/}*/*")
      type='unknow'
    ;;
  esac

  # Add found websites to global list
  if [ -n "$list" ]; then
    echo -e "$list"
    [ -z "$type" ] && type=$1
    for directory in $list; do
      website_directories=${website_directories:+"$website_directories${IFS}"}"$directory;$type"
    done
    #website_types=${website_types:+"$website_types${IFS}"}"$type"
  fi

  # Sort and remove empty lines and duplicate values
  website_directories=$(echo $website_directories | sort | sed '/^$/d' | awk '!x[$0]++')
  #website_types=$(echo $website_types | sort | sed '/^$/d' | awk '!x[$0]++')

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Apply custom configuration depending of given CMS type
__custom_securisation()
{
  [ $# -ne 1 ] && echo "Usage: $FUNCNAME 'website_type'"  >&2 && exit 65

  # Reset variables
  unset php_flags php_values

  # Add your custom config here.
  case $1 in

    'colabtive' )
      #website_version=$(grep -m 1 -Eos "define\(\s*[\'\"]+VERSION[\'\"]+\s*,\s*[\'\"]+.*+[\'\"]+\s*\)" 'config/standard/config.php' | grep -Pos "([0-9.]*)")

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'config/standard/config.php'
      #mod=$web_process'=rx'
      #chmod $chmod_options -R $mod 'files'
    ;;

    'dokuwiki')

      website_version=$(grep -m 1 -Eos "[$]+updateVersion+\s*=\s*[0-9.]+" 'doku.php' | grep -Pos "([0-9.]*)")

      rm -f 'install.php'

      mod=$web_process'=rx'
      chmod $chmod_options -R $mod 'data'
      chmod $chmod_options -R $mod 'data${TMPDIR}'
      chmod $chmod_options -R $mod 'lib/plugins'

      mod=$public'+rx'
      chmod $chmod_options -R $mod 'lib'

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'conf/local.php'
      chmod $chmod_options $mod 'conf/users.auth.php'
      chmod $chmod_options $mod 'conf/acl.auth.php'
      chmod $chmod_options $mod 'conf/plugins.local.php'
    ;;

    'dolibarr' )
      if [ ! -e 'install.lock' ]; then echo '' > 'documents/install.lock'; fi
      mod=$web_process"=r"
      chmod $chmod_options $mod 'documents/install.lock'
      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'htdocs/conf/conf.php'
    ;;

    'drupal' )
      website_version=$(grep -m 1 -Eos "define\(\s*[\'\"]+VERSION[\'\"]+\s*,\s*[\'\"]+.*+[\'\"]+\s*\)" 'includes/bootstrap.inc' | grep -Pos "([0-9.]*)")

      # upload last version
      # wget  http://ftp.drupal.org/files/projects/$(wget -O- http://drupal.org/project/drupal | egrep -o 'drupal-[0-9\.]+.tar.gz' | sort -V  | tail -1)

      if [ ! -d 'sites/default/files' ]; then mkdir 'sites/default/files'; fi

      #mod=$web_process'=rx'
      #find $find_options . -type d -path "*/sites/*/files/*" -exec chmod $chmod_options -R $mod {} \;
      mod=$config_file_mod','$writable_mod
      find $find_options . -type f -path "*/sites/*" -name "settings.php" -exec chmod $chmod_options $mod {} \;

      read -d '' php_flags <<EOF
magic_quotes_gpc = Off
magic_quotes_sybase = Off
register_globals = Off
session.auto_start = Off
mbstring.encoding_translation = Off
EOF

      __set_php_config "php_flag" "$php_flags" ".htaccess"

read -d '' php_values <<EOF
mbstring.http_input = pass
mbstring.http_output = pass
EOF

      __set_php_config "php_value" "$php_values" ".htaccess"
    ;;

    'elgg' )

      #website_version=$(grep -m 1 -Eos "[$]+release\s*=\s*[\'\"]+[0-9.]+[\'\"]+" 'version.php' | grep -Pos "([0-9.]*)")

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'engine/settings.php'

read -d '' php_flags <<EOF
safe_mode = Off
register_globals = Off
EOF

      __set_php_config "php_flag" "$php_flags" ".htaccess"

      a2enmod rewrite
    ;;
    'gallery' )
      #mod=$public'=rx'
      #chmod $chmod_options $mod 'install'
      #chmod $chmod_options $mod 'upgrade'
    ;;

    'joomla' )
      #string=$(find $find_options . -path "*/libraries/*" -type f -name version.php -exec grep -Pos '[$]+REL\EASE\s*=\s*[\'"]+[0-9.]+[\'"]+' "{}" \;)
      #website_version=$(echo "$string" | head -n 1 | grep -Pos "([0-9.]*)")

      rm -rf 'installation'

      #mod=$public'=r'
      #find $find_options . -type f -exec chmod $chmod_options $mod {} \;
      #mod=$public'=rx'
      #find $find_options . -type d -exec chmod $chmod_options $mod {} \;

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'configuration.php'

      mod=$writable_mod
      chmod $chmod_options $mod 'administrator/components'
      find $find_options 'administrator/language' -type d -exec chmod $chmod_options $mod {} \;
      find $find_options 'administrator/manifests' -type d -exec chmod $chmod_options $mod {} \;
      chmod $chmod_options $mod 'administrator/modules'
      chmod $chmod_options $mod 'administrator/templates'
      chmod $chmod_options $mod 'components'
      find $find_options 'images' -type d -exec chmod $chmod_options $mod {} \;
      find $find_options 'language' -type d -exec chmod $chmod_options $mod {} \;
      chmod $chmod_options $mod 'libraries'
      chmod $chmod_options $mod 'media'
      chmod $chmod_options $mod 'modules'
      chmod $chmod_options $mod 'plugins'
      find $find_options 'plugins' -maxdepth 1 -type d -exec chmod $chmod_options $mod {} \;
      chmod $chmod_options $mod 'templates'
      chmod $chmod_options $mod 'cache'
      chmod $chmod_options $mod 'administrator/cache'
      chmod $chmod_options $mod 'logs'
      chmod $chmod_options $mod 'tmp'
      # J1.5
      chmod $chmod_options $mod 'plugins/content'
      chmod $chmod_options $mod 'plugins/editors'
      chmod $chmod_options $mod 'plugins/editors-xtd'
      chmod $chmod_options $mod 'plugins/search'
      chmod $chmod_options $mod 'plugins/system'
      chmod $chmod_options $mod 'plugins/user'
      chmod $chmod_options $mod 'plugins/xmlrpc'
      #chmod $chmod_options -R $mod 'images/stories'
      #chmod $chmod_options $mod 'images/banners'
      #chmod $chmod_options $mod 'administrator/backups'
      #chmod $chmod_options $mod 'language/pdf_fonts'

read -d '' php_flags <<EOF
safe_mode = Off
display_errors = Off
file_uploads = On;
magic_quotes_runtime = Off
magic_quotes_gpc = Off
register_globals = Off
output_buffering = Off
session.auto_start = Off
zlib = On
zlib.output_compression = On
xml = On
EOF

      __set_php_config "php_flag" "$php_flags" ".htaccess"

read -d '' php_values <<EOF
post_max_size = 2M
upload_max_filesize = 2M
EOF

      __set_php_config "php_value" "$php_values" ".htaccess"

read -d '' php_admin_flags <<EOF
upload_tmp_dir = ${TMPDIR}
EOF

      __set_php_config "php_admin_flag" "$php_admin_flags" "php.ini"
    ;;

    'magento' )
      # Version
    ;;

    'moodle' )
      website_version=$(grep -m 1 -Eos "[$]+version+\s*=\s*[0-9.]+" 'includes/bootstrap.inc' | grep -Pos "([0-9.]*)")

      #mod=$web_process'=rx'
      #chmod $chmod_options -R $mod 'moodledata'

    ;;

    'oxwall' )

      website_version=$(grep -m 1 -Eos "<version>.*<\/version>" 'ow_version.xml' | grep -Pos "([0-9.]*)")

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'ow_includes/config.php'
      mod=$writable_mod
      chmod $chmod_options -R $mod 'ow_logs/*'
      chmod $chmod_options -R $mod 'ow_pluginfiles/*'
      chmod $chmod_options -R $mod 'ow_plugins/*'
      chmod $chmod_options -R $mod 'ow_static/*'
      chmod $chmod_options -R $mod 'ow_smarty/template_c/*'
      chmod $chmod_options -R $mod 'ow_themes/*'
      chmod $chmod_options -R $mod 'ow_updates/*'
      chmod $chmod_options -R $mod 'ow_userfiles/*'

read -d '' php_flags <<EOF
register_globals = Off
safe_mode = Off
suPHP = Off
suApache = Off
suhosin = Off
EOF

      __set_php_config "php_flag" "$php_flags" ".htaccess"

      read -d '' php_extensions <<EOF
extension = pdo.so
extension = dom.so
extension = mnstring.so
extension = zip.so
extension = zlib.so
extension = ftp.so
extension = json.so
EOF

      __set_php_config "php_extension" "$php_extensions" ".htaccess"

      a2enmod rewrite

    ;;

    'opencart' )
      website_version=$(grep -m 1 -Eos "define\(\s*[\'\"]+VERSION[\'\"]+\s*,\s*[\'\"]+.*+[\'\"]+\s*\)" 'index.php' | grep -Pos "([0-9.]*)")
    ;;

    'prestashop' )

      website_version=$(grep -m 1 -Eos "define\(\s*[\'\"]+_PS_VERSION_[\'\"]+\s*,\s*[\'\"]+.*+[\'\"]+\s*\)" 'config/settings.inc.php' | grep -Pos "([0-9.]*)")

      rm -rf 'installation'
      #mv admin admin12345

      mod=$writable_mod
      chmod $chmod_options $mod -R 'config'
      chmod $chmod_options $mod -R 'cache'
      chmod $chmod_options $mod -R 'log'
      chmod $chmod_options $mod -R 'img'
      chmod $chmod_options $mod -R 'mails'
      chmod $chmod_options $mod -R 'modules'
      chmod $chmod_options $mod -R 'themes/default/lang'
      chmod $chmod_options $mod -R 'themes/default/pdf/lang'
      chmod $chmod_options $mod -R 'themes/default/cache'
      chmod $chmod_options $mod -R 'translations'
      chmod $chmod_options $mod -R 'upload'
      chmod $chmod_options $mod -R 'download'
      chmod $chmod_options $mod 'sitemap.xml'

read -d '' php_flags <<EOF
extension = php_mysql.dll
extension = php_gd2.dll
allow_url_fopen = On
register_globals = Off
magic_quotes_gpc = Off
allow_url_include = Off
EOF

      #__set_php_config "php_flag" "$php_flags" "php.ini"
      #gzip = On;${IFS}
      #mcrypt = On;${IFS}
      #dom = On;${IFS}
      #pdo = On;${IFS}

    ;;

    'seo-panel' )

      website_version=$(grep -m 1 -Eos "define\(\s*[\'\"]+SP_INSTALLED[\'\"]+\s*,\s*[\'\"]+.*+[\'\"]+\s*\)" 'config/sp-config.php' | grep -Pos "([0-9.]*)")

      rm -rf 'install'

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'config/sp-config.php'

      mod=$writable_mod
      chmod $chmod_options -R $mod 'tmp'

      #mod=$web_process'+x'
      #chmod $chmod_options $mod 'cron.php'
      #chmod $chmod_options $mod 'siteauditorcron.php'
      #chmod $chmod_options $mod 'directorycheckercron.php'

read -d '' php_flags <<EOF
allow_url_fopen = On
short_open_tag = On
EOF

      __set_php_config "php_flag" "$php_flags" ".htaccess"

    ;;

    'wordpress' )
      # http://codex.wordpress.org/Changing_File_Permissions

      if [ ! -d 'wp-content/languages' ]; then mkdir 'sites/default/files'; fi

      mod=$writable_mod
      chmod $chmod_options -R $mod 'wp-content'

      mod=$config_file_mod','$writable_mod
      chmod $chmod_options $mod 'wp-config.php'

      mod=$writable_mod
      chmod $chmod_options $mod '.htaccess'

      #mod='u+x'
      #chmod $chmod_options $mod 'wp-cron.php'

read -d '' php_flags <<EOF
file_uploads = On
EOF

      __set_php_config "php_flag" "$php_flags" ".htaccess"

read -d '' php_values <<EOF
post_max_size = 2M
upload_max_filesize = 2M
max_execution_time = 120
EOF

      __set_php_config "php_value" "$php_values" ".htaccess"

      a2enmod deflate
      a2enmod env
      a2enmod expires
      a2enmod headers
      a2enmod mime
      a2enmod rewrite
      a2enmod setenvif
      ${service_path}apache2 reload
    ;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Securize
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
securize_website()
{
  __website_config

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Fix website file permissions and apply custom rules depending of CMS type.

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-p|--path path] [-t|--type type] [--user user] [--group group]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS

    -g, --group
        File owner group. If not set, --path owner will be used.
    -p, --path
        Root path of the website.
    -t, --type
        On of the compatible website type.
$(echo -e "$compatible_website_types" | sort | sed -r 's/^(.*)/        - \1/g')
        If not set, a standard securisation will be apply.
    -q, --quiet
        Display no output.
    -u, --user
        File owner user.  If not set, --path owner will be used.
    -h, --help
        Print this help screen and exit.

EXAMPLES
    ${BASH_SOURCE##*/} ${FUNCNAME} -p "/var/www/sites/exemple.com/www" -t joomla -u root -g www-data

VERSION
    Version: 0.5.7

$global_help
EOF

  local ARGS=$(getopt -o "+g::p:t:u::qh" -l "+group::,path:,type:,user::,quiet,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -g|--group) shift; local group="${1:-$website_owner_group}"; shift;;
      -p|--path) shift; local path="$1"; shift;;
      -t|--type) shift; local type="$1"; shift;;
      -u|--user) shift; local user="${1:-$website_owner_user}"; shift;;
      -q|--quiet) shift; local quiet=1;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  if [ $UID != 0 ]; then
    printf "\e[31mThis script must be run as root.\e[0m${IFS}"
    return 1
  fi

  path=${path%/}
  #if [ -z "$(find $find_options $find_from_path -maxdepth 0 -type d)" ]; then
  if [ ! -d "$path" ]; then
    printf "\e[31m$path is not a valid path !\e[0m${IFS}"
    return 1
  fi

  if [ -n "$user" -a "$(id -un $user 2> /dev/null)" != "$user" ]; then
    printf "\e[31m$user is not a valid user.\e[0m${IFS}"
    return 1
    #if [ -n "$website_owner_group" -a -z "$(egrep -i '^'$website_owner_group':+' ${config_path}group)" ]; then
    if [ -n "$group" -a "$(id -gn $user 2> /dev/null)" != "$group" ]; then
      printf "\e[31m$group is not a valid group for user $user.\e[0m${IFS}"
      return 1
    fi
  fi

  # Check if path is a valid directory and cd in
  if [ -d "$path" ]; then
    previous_path=$(readlink -f .)
    cd "$path"
  else
    echo -e "\e[33m$path is not a directory !\e[0m"
  fi

  realpath=$(readlink -f .)
  if [[ ! $quiet ]]; then
    cat <<EOF
===============================================================================
$realpath
===============================================================================
EOF
  else
    echo "$realpath"
  fi

  # Use root directory owner if not set
  owner_directory=$(echo $(readlink -f .) | grep -Po "$owner_directory_pattern")
  [[ ! $user ]] && user=$(stat -c %U "$owner_directory")
  [[ ! $group ]] && group=$(stat -c %G "$owner_directory")

  # Set owner/group
  if [ -n "$user" -a -n "$group" ]; then
    [[ ! $quiet ]] && echo -e "Set owner to $user:$group on every files and directories."
    chown -R $user:$group * .*
  fi

  # Standard web chmod
  # Do not add write permissions here
  mod=$web_process'=r,'$public'='
  [[ ! $quiet ]] && echo "Apply $mod permissions to files"
  find $find_options . -type f -exec chmod $chmod_options $mod {} \;

  mod=$web_process'=rx,'$public'='
  [[ ! $quiet ]] && echo "Apply $mod permissions to directories"
  find $find_options . -type d -exec chmod $chmod_options $mod {} \;

  mod=$public'='
  [[ ! $quiet ]] && echo "Apply $mod permissions to .htaccess files"
  find $find_options . -type f -name ".htaccess" -exec chmod $chmod_options $mod {} \;

  mod=$public'='
  [[ ! $quiet ]] && echo "Apply $mod permissions to .htpasswd files"
  find $find_options . -type f -name ".htpasswd" -exec chmod $chmod_options $mod {} \;

  mod=$public'='
  [[ ! $quiet ]] && echo "Apply $mod permissions to php.ini files"
  find $find_options . -type f -name "php.ini" -exec chmod $chmod_options $mod {} \;

  mod=$public'='
  [[ ! $quiet ]] && echo "Apply $mod permissions to php and other server-side scripts"
  find $find_options . -type f -regextype posix-extended -regex ".*\.("$server_side_scripts")[0-9]?$" -exec chmod $chmod_options $mod {} \;

  mod=$web_process'+x'
  [[ ! $quiet ]] && echo "Apply $mod permissions to cgi files"
  find $find_options . -type f -regextype posix-extended -regex ".*\.(cgi)$" -exec chmod $chmod_options $mod {} \;

  if [ $sbox_ausf_mode -eq 1 ]; then
    mod=$public'+x'
    [[ ! $quiet ]] && echo "Apply patch for sbox_ausf_mode"
    #find $find_options . -type f -regextype posix-extended -regex ".*/index\.(php|htm|html|asp)+[0-9]?$" -exec chmod $chmod_options $mod {} \;
    find . -iname '*.php' -exec chmod $chmod_options $mod {} \;
    #find $find_options . -iname '*conf*.php' -exec sed -i "s/localhost/127.0.0.1/" {} \;
  fi

  # Apply a custom tasks depending on website type
  if [[ -n "$type" ]]; then
    [[ ! $quiet ]] && echo "Apply $type custom settings"
    __custom_securisation "$type"
    [[ $website_version ]] && echo "$type $website_version detected"
  fi

  # Make all files writable for auto updates
  if [ $allow_http_updates -eq 1  ]; then
    mod=$writable_mod
    [[ ! $quiet ]] && echo "Apply $mod recursive permissions on all files to allow updates"
    chmod -R $chmod_options $mod * .*
  fi

  # Remove group permissions if no needed
  if [ $remove_group_permissions -eq 1  ]; then
    mod='g='
    [[ ! $quiet ]] && echo "Apply $mod recursive permissions to disable group permissions"
    chmod -R $chmod_options $mod * .*
  fi

  # Restore path
  cd $previous_path

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
securize_all_websites()
{

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Securize all websites

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [q|quiet]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

$global_help
EOF

  local ARGS=$(getopt -o "+qh" -l "+quiet,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -q|--quiet) shift; quiet=1;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  if [[ ! $quiet ]]; then
    read -n1 -p "Are you really sure to process all detected websites without confirmation ? (y/N) "
    [[ $REPLY != [yY] ]] && return
  fi

  for item in $website_directories; do
    directory=$(echo "$item" | awk -F';' '{print $1}')
    type=$(echo "$item" | awk -F';' '{print $2}')
    securize_website --path "$directory" --type "$type" --user "$website_owner_user" --group "$website_owner_group"
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helpers
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__check_php_version()
{
  [ $# -ne 1 ] && echo "Usage: $FUNCNAME 'version'"  >&2 && exit 65

  php_version=$(php -r 'echo(floatval(PHP_VERSION));')

  echo "PHP required $1 / running $php_version"
  if [ $php_version < $1 ]; then
    echo "This site require PHP $1 but current PHP version is $php_version"
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#__install_php_extension()
#{
#  [ $# -ne 3 ] && echo "Usage: $FUNCNAME 'extension'"  >&2 && exit 65
  #php -m
  #pecl install pdo
  #extension=pdo.so
  #pecl install pdo_mysql
  #extension=pdo_mysql.so
#  __package_cp install "$1"
#  __set_php_config extension
#}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__set_php_config()
{
  [ $# -ne 3 ] && echo "Usage: $FUNCNAME 'type' 'items' 'file'"  >&2 && exit 65

  local type=$1
  local items=$2
  local file=$3

  # Add EOF characters if last line don't have line break
  echo -e "${IFS}" >>"$file"
  #EOF=$(tail -n1 "$file" | tail -c4)
  #if [ -z $(tr -cd "${IFS}" < "$file") ]; then echo -e "${IFS}" >>"$file"; fi
  #if [ "$EOF" != "${IFS}" ]; then echo -e "${IFS}" >>"$file"; fi
  #if [ "$EOF" != "${IFS}" ]; then echo "add" fi
  #echo "add: EOL:"$(echo -e ${IFS} | od -x)"EOF:"$(echo -e $EOF | od -x); fi
  #if [ -z $(tail -n1 "$file") ]; then echo -e "${IFS}" >>"$file"; fi

  while read item; do
    if [[ $item ]]; then
      local count=0

      # Extract name / value
      #name=$(echo $item | sed "s|\s.*$||; s|\s||g")
      #value=$(echo $item | sed "s|^.*\s||; s|[\s;]||g")
      item=$(echo "$item" | sed -r 's/(^\s*|\s*$)//')
      name=${item%%[= ]*}
      value=${item##*[= ]}; value=${value%%[; ]}
      #value=$(echo $item | sed "s|^.*\s||; s|[\s;]||g" | tr [:upper:] [:lower:])

      # Extract active value
      if [ "$type" == 'php_extension' ]; then
        current_value=$(php -r 'echo extension_loaded("${value%.*}") ? "${value%.*}" : "";')
        #if [[ "$is_loaded" == 0 ] && __package_cp install "$extension"
      else
        current_value=$(php -r 'echo ini_get("'$name'");')
      fi

      # Convert On/Off values to 1/0
      value=$(echo "$value" | sed 's/on/1/i; s/off/0/i')
      current_value=$(echo "$current_value" | sed 's/on/1/i; s/off/0/i')

      # Check if value need to be changed
      shopt -s nocasematch
      if [ "$current_value" != "$value" ]; then

        if [[ "$type" == "php_admin_flag" ]]; then
          echo -e "\e[33mphp_admin_flag flags are not allowed in a local configuration.\n'$type $item' flag should be add to the PHP configuration of the vhost.\e[0m"
          continue
        fi

        # Try to change value dynamically
        if [ "$type" == 'php_extension' ]; then
          changed_value='' # Cheat because dl php function is no longer available
        else
          php -r 'ini_set("'$name'","'$value'");'
          changed_value=$(php -r 'echo ini_get("'$name'");')
        fi

        if [[ "$changed_value" != "$value" ]]; then
          #echo -e "\e[33m$name flag can't be changed in your local $file.${IFS}Add a $item record to your vhost configuration.\e[0m"
          echo -e "\e[33m'$item' flag should be add to the PHP configuration of the vhost.\e[0m"
        else

          # Convert string for .htaccess usage
          if [ $(basename "$file") == '.htaccess' ]; then
            item=$type' '$(echo $item | sed "s|;||g; s|\s*=\s*| |; s|extension=||")
          fi

          # Extract variable name
          key=$(echo $item | sed "s|\s*[^\t ]*\s*$||")

          # Check if output file exist, so search flag name
          if [ -e "$file" ]; then
            pattern=$(echo $key | sed "s|[ ]\{1,\}|\\\s+|g")
            count=$( grep -Pc "^[^#]*$pattern" "$file" )
          fi

          # If flag count=0, add new line to the end of the file
          if [ $count -eq 0 ]; then
            echo "Insert '$item' in $file"
            echo "$item" >>$file
          else
            pattern=$(echo $item | sed "s|[ ]\{1,\}|\\\s+|g")
            count=$( grep -Pci "^[^#]*$pattern" "$file" )

            # Update flag only if value is not good
            if [ $count -eq 0 ]; then
              echo "Update '$item' in $file"
              pattern=$(echo $key | sed "s|[ ]\{1,\}|\\\s\\\{1,\\\}|g")
              sed -i.bak "s|^[^#]*$pattern.*$|$item|g" "$file"
            fi

          fi

        fi

      else
        echo "'$item' flag is active."
      fi
      shopt -u nocasematch
    fi
  done < <(echo "$items")
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Website security functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"

#COLLABTIVE
# http://collabtive.o-dyn.de/
#
# PHP 5.2 OK
# config.php est accessible en écriture  OK
# files est accessible en écriture OK
# templates_c est accessible en écriture OK
# Extension mb_string activée  OK

# DOKUWIKI
# https://www.dokuwiki.org/install:permissions

# DOLIBARR
#Vérification de prérequis:
#Ok Version PHP 5.4.4-14+deb7u3 (Plus d'information)
#Ok Ce PHP supporte bien les variables POST et GET.
#Ok Ce PHP supporte les sessions.
#Ok Ce PHP supporte les fonctions graphiques GD.
#Ok Ce PHP supporte les fonctions UTF8.
#Ok Votre mémoire maximum de session PHP est définie à 128M. Ceci devrait être suffisant.
#Ok Le fichier de configuration htdocs/conf/conf.php existe.
#Ok Le fichier htdocs/conf/conf.php est modifiable.

# DRUPAL
# http://drupal.org/node/244924

# ELGG
# http://docs.elgg.org/wiki/Installation/Requirements

# JOOMLA
# faire une récursion en 644 pour tout
# puis une récursion en 755 seulement pour les dossiers
# quelques répertoires doivent absolument être ouvert en écriture totale par CHMOD 777,
# comme les caches, dossiers images, etc.
# Les autres tels components, modules, plugins, templates, etc. peuvent être repassé à 765,
# CHMOD par défaut infomaniak, s'il n'y a plus rien à installer.
# Selon les extensions, les fichiers devant pouvoir être modifiés
# (tels des fichiers de configuration) doivent rester en 777.

# find . -type f -exec chmod 644 {} \;
# find . -type d -exec chmod 755 {} \;
# chmod 707 images
# chmod 707 images/stories
# chown apache:apache cache

# Joomla! 2.5 /libraries/cms/version/version.php : public $RELEASE = '3.0';
# Joomla! 1.5 /libraries/joomla/version.php : var $RELEASE = '1.5'
# Joomla! 1.0 /includes/version.php

# JOOMLA 3.0
# Pré-installation
# Version de PHP >= 5.3.1  Oui
# Magic Quotes GPC Off   Oui
# Register Globals   Oui
# Support de la compression zlib   Oui
# Support de XML   Oui
# Bases de données supportées : (mysqli, pdo, mysql, sqlite)   Oui
# Directive Mbstring langage par défaut   Oui
# Directive Mbstring overload désactivée   Oui
# INI Parser Support   Oui
# Support JSON   Oui
# configuration.php Modifiable
#
# Paramètres recommandés :
# Directive  Recommandé   Actuel
# Safe Mode  Désactivé   Désactivé
# Afficher les erreurs   Désactivé   Désactivé
# Transfert de fichiers  Activé   Activé
# Magic Quotes Runtime   Désactivé   Désactivé
# Output Buffering   Désactivé   Désactivé
# Session Auto Start   Désactivé   Désactivé
# Support ZIP natif  Activé   Activé

# OXWALL
# http://docs.oxwall.org/install:manual_installation
# http://www.oxwall.org/hosting

# PRESTASHOP
# http://doc.prestashop.com/display/PS14/System+Administrator+Guide#SystemAdministratorGuide-PHPconfiguration
# PHP 5.1.2 ou plus est installé ?
# Upload de fichiers autorisée ?
# Création de fichiers et dossiers autorisée ?
# Librairie GD installée ?
# MySQL est installé ?
# Ouverture des URLs externes autorisée ?
# Option PHP register_global désactivée (recommandé) ?
# Compression GZIP activée (recommandé) ?
# Extension Mcrypt installée (recommandé) ?
# Option PHP magic_quotes désactivée (recommandé) ?
# Extension DOM installée ?
# Extension PDO MySQL installée ?
# supprimé le dossier /install
# renommé le dossier /admin (ex. : /admin123345)

# MOODLE
# version.php $version  = 2012062501.02;

# OXWALL
# Pour l'installation:
# Droit d'écriture sur ow_pluginfiles/, ow_userfiles/, ow_static/, ow_smarty/template_c

# SEO PANEL
# http://www.seopanel.in/install/
#
# PHP version >= 4.0.0  Yes ( PHP 5.3.3-7+squeeze14 )
# MySQL Support Yes
# CURL Support  Yes ( CURL 7.21.0 )
# PHP short_open_tag  Enabled
# GD graphics support Yes ( GD 2.0 )
# /config/sp-config.php Found, Writable
# ${TMPDIR}  Found, Writable

# WORDPRESS
# http://codex.wordpress.org/Changing_File_Permissions
# http://codex.wordpress.org/Hardening_WordPress
