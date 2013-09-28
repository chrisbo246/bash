#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__log_menu()
{
  while true; do
    __menu \
    -t 'Log files' \
    -o 'Last minute logs' \
    -o 'Find log files' \
    -o 'Delete old logs' \
    --back --exit

    case $REPLY in
      1 ) last_logs -v;;
      2 ) find_log_filenames;;
      3 ) clean_logs;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clean_logs()
{
  read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Remove old log archives, empty large log files and check disk space.

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME}

$global_help
EOF

  # Delete log archives older than
  days=180
  # Empty logs biger than
  size="10M"
  # Send an alert if disk space reach x%
  threshold=90
  # Send alert to
  email="webmaster@clickpanic.com"

  case $# in
    0);;
    *)echo -e $usage 1>&2; exit 65;;
  esac

  # Remove log archives older than $days
  find / -mtime "+$days" -type f -regextype posix-extended -regex ".*/logs?/.*\.(gz|[0-9]+)$" -name "*" -exec rm {} \;

  # Empty log files older than $days and biger than $size
  find / -size "+$size" -type f -regextype posix-extended -regex ".*/logs?/.*\.(log|txt)$" -name "*" -exec cat /dev/null > {} \;

  # Check disk space
  current=$(df / | grep / | awk '{print $4}' | sed 's/%//g')
  if [ "$current" -gt "$threshold" ] ; then
  mail -s 'Disk Space Alert' $email << EOF
Your root partition remaining free space is critically low. Used: $CURRENT%
EOF
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
export_log_patterns()
{
  local path=/
  local temp_filename="$(mktemp)"

  if [ -n "$1" ]; then
    local output_filename="$1"
  else
    echo "You must provide an output file name." >&2; exit
  fi

  # Empty output file
  echo '' > "$output_filename"

  # Join logs in a single temp file
  filenames=$(find_log_filenames -p "$path")
  while read filename; do
    echo "$filename"

    #Copy log file to a temp file
    #cat "$filename" > "$temp_filename"
    head "$filename" > "$temp_filename"

    # Replace some strings by wildcards
    #echo $LINENO;
    # Date Time
    # 04/Sep/2013:20:14:36 +0200
    echo $LINENO;sed -r -i 's/(([a-zA-Z]+( ))([0-9]{1,4}|[a-zA-Z]+) *(\/|-| ) *([a-zA-Z]+|[0-9]{1,2})( *(\/|-| ) *[0-9]{2,4})?)( *(:|,| ) *[0-9]{1,2}(:)[0-9]{1,2}((:)[0-9]{1,2})?)/{DATETIME}/g' "$temp_filename"
    # Date
    #echo $LINENO;sed -r -i 's/[0-9]{1,2}(\/)[0-9]{1,2}(\/)[0-9]{2,4}/{DATE}/g' "$temp_filename"
    # Time
    #echo $LINENO;sed -r -i 's/[0-9]{1,2}(:|h)[0-9]{1,2}(:|m)[0-9]{1,2}(s?)/{TIME}/g' "$temp_filename"
    # URL
    echo $LINENO;sed -r -i 's/([a-z]{3,5}:\/\/)[^\/]+(\/[^\? "(){}]*)?(\?[^ \"\(\)\[\]\{\}]+)?/\1{URL}/g' "$temp_filename"
    # URI
    echo $LINENO;sed -r -i 's/(\/[^\? "(){}]+)(\?[^ "(){}]+)?/\1{URI}/g' "$temp_filename"
    # URL param
    echo $LINENO;sed -r -i 's/\?(([a-zA-Z0-9_-]+=)[^\?& "(){}])/\1\2{VALUE}/g' "$temp_filename"
    # Paths
    echo $LINENO;sed -r -i 's/(\/[^\/\?"(){}]+)+/?)?/{PATH}/g' "$temp_filename"
    # Email
    echo $LINENO;sed -r -i 's/[a-zA-Z0-9_\.\/-]+@[a-zA-Z0-9_\.\/-]+/{EMAIL}/g' "$temp_filename"
    # IPV4
    echo $LINENO;sed -r -i 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/{IPV4}/g' "$temp_filename"
    # Integer
    #sed -r -i 's/[0-9]{5,}/{INTEGER}/g' "$temp_filename"
    # HEXA Number
    #echo $LINENO;sed -r -i 's/(#)?[A-Fa-F0-9]{4,}/{HEXA}/g' "$temp_filename"
    # Number
    #echo $LINENO;sed -r -i 's/(\+|\-)?[0-9\.]{2,}/{DOUBLE}/g' "$temp_filename"

    # Hostname
    echo $LINENO;sed -r -i 's/'"$(hostname -f)"'/{FQDN}/g' "$temp_filename"
    echo $LINENO;sed -r -i 's/'"$(hostname -s)"'/{HOSTNAME}/g' "$temp_filename"
    echo $LINENO;sed -r -i 's/'"$(hostname -d)"'/{DOMAIN}/g' "$temp_filename"

    # Sort, remove duplicate lines
    # and write temp file to the end of output file
    sort "$temp_filename" -o "$temp_filename"
    uniq < "$temp_filename" >> "$output_filename"
    #cat "$output_filename"; exit
  done < <(echo -e "$filenames")

  # Remove duplicate lines in output file
  sort "$output_filename" -o "$temp_filename"
  uniq < "$temp_filename" > "$output_filename"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
find_log_filenames()
{

  local path=/
  local mmin

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Search for log files
    Ports functions

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-p|--path path] [--mmin integer]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -p, --path
        Search for logs from this path (default=$path).
    --mmin
        Return log files modified during the n last minutes (default=$mmin).
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "+p:h" -l "+path:,mmin:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -p|--path) shift; path=${1:-$path}; shift;;
      --mmin) shift; mmin=${1:-$mmin}; shift;;
      -h|--help) shift; echo -e "$help" 1>&2; exit 65;;
      -- ) shift; break;
    esac
  done

  local options
  [[ $mmin > 0 ]] && options="${options} -mmin -"$mmin
  #filenames=$(find "$path" $options -type f -regex '.*/logs?/.*' ! regex '.*\.(\d+|gz)$' \( ! -iname '*.gz' \))
  filenames=$(find "$path" $options -type f -iregex '.*/logs?/.*' -and \( ! -iname '*.*' -or -iname '*.txt' -or -iname '*.err' -or -iname '*.notice' -or -iname '*.warn' -or -iname '*.info' \) -or -iname '*.log')
  #find / $options -type f ! -path '/media/*' -and -iregex '.*/logs?/.*' -and \( -iregex '' ! -iregex '.*\.[0-9]+$' ! -iname '*.gz' \) -or -iname '*.log'
  
  
  while read filename; do

    # Jump files that are not plain text files
    local file_type=$(file -b --mime-type "$filename")
    local list=('text/plain')
    [[ ! "$(declare -p list)" =~ '['([0-9]+)']="'$file_type'"' ]] && continue
    echo "$filename"

  done < <(echo -e "$filenames")

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
last_logs()
{

  local path=/
  local mmin=1
  local preview=2
  local menu=0
  local verbose=0

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Search for log files modified during the last minutes
    Ports functions

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-p|--path path] [--mmin integer] [-p|--preview] [-m|--menu] [-v|--verbose]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -p, --path
        Search for logs from this path (default=$path).
    --mmin
        Return log files modified during the n last minutes (default=$mmin).
    -p, --preview
        Display the n last lines of each logs (default=$preview).
    -v, --verbose
        Make results readable.
    -m, --menu
        Show a menu to edit detected files.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "+p:vmh" -l "+path:,mmin:,preview:,verbose,menu,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -p|--path) shift; path=${1:-$path}; shift;;
      --mmin) shift; mmin=${1:-$mmin}; shift;;
      --preview) shift; preview=${1:-$preview}; shift;;
      -v|--verbose) shift; verbose=1;;
      -m|--menu) shift; menu=1;;
      -h|--help) shift; echo -e "$help" 1>&2; exit 65;;
      -- ) shift; break;
    esac
  done

  #clear
  #find / -mmin "-$mmin" -type f -regex ".*/logs?/.*" -name "*" | while read line; do echo -e "${IFS}--> $line${IFS}"; echo '[TOP]'; head "-n$preview" $line; echo '...'; tail "-n$preview" $line; echo '[BOTTOM]'; done
  #find / -mmin "-$mmin" -type f -regex ".*/logs?/.*" -name "*" | while read line; do echo -e "${IFS}--> $line"; tail "-n$preview" $line; done

  (( $verbose == 1 )) && echo "Searching for files from $path in log* directories and modified the last $mmin minutes."

  local options
  [ $mmin -gt 0 ] && options="${options} --mmin "$mmin
  filenames=$(find_log_filenames -p "$path" $options)
#  & spinner $!

  while read filename; do
    (( $verbose == 1 )) && echo -e "${IFS}--> $filename"
    (( $preview > 0 )) && tail "-n$preview" "$filename"
  done < <(echo -e "$filenames")

  if (( $menu == 1 )); then
    while true;  do
      echo -e "${IFS}Edit log${IFS}"
      PS3="Select a file :"
      exit='[EXIT]'
      select filename in $(echo -e "$filenames" | sort) "$exit"; do
        case $filename in
          "$exit" ) break 100;;
          * ) [ -e "$filename" ] && editor "$filename"; break;
            #* ) [ -e "$filename" ] && more -d "$filename"; break;
        esac
      done
    done
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Log management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
