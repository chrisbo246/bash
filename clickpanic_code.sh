#/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__code_menu()
{

  source "${file_prefix}file.sh"

  while true; do
    __menu \
    -t 'Code menu' \
    -o 'Find HTML files' \
    -o 'Find PHP files' \
    -o 'Find CSS files' \
    -o 'Find Bash files' \
    -o 'Check & beautify bash files' \
    --back --exit

    case $REPLY in
      1 ) find_filtered_files --or --extension 'htm' --extension 'html';;
      2 ) find_filtered_files --or --extension 'php' --extension 'php3';;
      3 ) find_filtered_files --and --extension 'css';;
      4 ) find_filtered_files --and --extension 'sh' --mime-type text/x-shellscript;;
      5 ) fix_bash_files;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_code_action()
{
  while true; do
    __menu \
    -t 'Code' \
    -o 'Join script functions' \
    -o 'Beautify bash script' \
    -o 'Clean CSS' \
    --back --exit

    case $REPLY in
      1 ) join_script_functions "$1";;
      2 ) beautify_bash_script "$1";;
      4 ) clean_css "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fix_bash_files()
{
  
  source "${file_prefix}file.sh"
  
  # List .sh files with wrong header
  while read filename;do
    sed -i '1s/^/#\/bin\/bash${IFS}/' "$filename"
  done < <(find_filtered_file --and --extension 'sh' --mime-type 'text/plain')
  
  while read filename;do
    # Remove blank characters at line end
    sed -i 's/[ \t]+$//g' "$filename"
    # Remove duplicate blank lines
    sed -i 's/^(.*)('${IFS}'\1)+$/\1/g' "$filename"
    # Check end of line type    
    convert_line_endings "$filename"
    # Beautify code
    beautify_bash_script "$filename"
  done < <(find_filtered_files --and --extension 'sh' --mime-type 'text/x-shellscript')
  
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Return a list of functions defined in a script
extract_function_names()
{

  [ ! -f "$1" ] && echo "$1 do not exists."  >&2 && exit 1
  grep -Po '\h*(function\h+)?[a-zA-Z_-]+\h*\(\h*\)\h*{?' "$1" | sed 's/[ \t(){]//g; s/function//'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
join_script_functions()
{

  filename='functions.sh'
  insert='#/bin/bash'
  regex='.*\.sh'
  verbose=0

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Join functions from several files

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-f|--filename] [-i|--insert] [-r|--regex]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -f, --filename
        Functions will be copied to this file (default: '$filename').
    -i, --insert
        Insert one or more lines to the head of the file (default: '$insert').
    -r, --regex
        find script files using this regular expression (default: '$regex').
    -h, --help
        Print this help screen and exit.
    -v, --verbose
        Print details.

$global_help
EOF

  ARGS=$(getopt -o "+f:i:r:hv" -l "+filename:,insert:,regex:,help,verbose" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -f|--filename) shift; filename=${1:-$filename}; shift;;
      -i|--insert) shift; insert=${1:-$insert}; shift;;
      -r|--regex) shift; regex=${1:-$regex}; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      -v|--verbose) shift; verbose=1;;
      --) shift; break;;
    esac
  done

  [ -n "$insert" ] && echo -e "$insert" > "$filename"

  while read line; do
    beautify_bash_script "$line"
    if [[ $? == 0 ]]; then
      [[ $verbose == 1 ]] && echo "Copying functions from '$line' to '$filename'."
      echo -e "${IFS}${IFS}################################################################################${IFS}# ${line##*/}${IFS}################################################################################${IFS}${IFS}" >> "$filename"
      sed -n -r '/^[ \t]*(function[ \t]+)?[a-zA-Z_]+[ \t]*\([ \t]*\)/,/^}/p' "$line" >> "$filename"
    else
      [[ $verbose == 1 ]] && echo "Script '$line' contain errors and will be skipped'."
    fi
  done < <(find . -type f -regex "$regex")

  beautify_bash_script "$filename"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
beautify_bash_script()
{
  beautifier=$(find /usr/local -type f -name beautify_bash.py)
  if [ -f "$beautifier" ]; then
    [ -z "$(which python)" ] && __package_cp install python
  else
    beautifier='/usr/local/bin/beautify_bash.py'
    wget -O "$beautifier" http://arachnoid.com/python/python_programs/beautify_bash.py
  fi
  python "$beautifier" $@
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
beautify_xml_script()
{
  [[ ! $(which tidy) ]] && __package_cp install tidy
  tidy -xml -i -m $@
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clean_css()
{
read -d '' usage <<EOF
Clean CSS file.
Usage: `basename $0 .sh` 'filename'
EOF

  case $# in
    1);;
    *) echo -e $usage 1>&2; exit 65
  esac

  filename="$1"

  if [ ! -e "$filename" ]; then
    echo "$filename do not exists !"
    exit
  fi

  # Replace tabulations by 2 spaces
  sed -i -r "s#[ \t]+$#  #g" "$filename"
  # Remove most white spaces between code
  sed -i -r "s/[ \t]*(\{|\}|\]|\(|:|,|\!important|;| )[ \t]*/\1/g" "$filename"
  # Remove white spaces at line start / end
  sed -i -r "s#(^[ \t]*|^[ \t]*$)##g" "$filename"
  # Remove optional characters
  sed -i -r "s#[0]+(\.)#\1#g" "$filename"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print_envs()
{
read -d '' varnames <<EOF
PATH
MANPATH
LD_LIBRARY_PATH
TMPDIR
LANG
LC_CTYPE
LC_NUMERIC
LC_TIME
LC_COLLATE
LC_MONETARY
LC_MESSAGES
LC_PAPER
LC_NAME
LC_ADDRESS
LC_TELEPHONE
LC_MEASUREMENT
LC_IDENTIFICATION
LC_ALL
PAGER
EDITOR
VISUAL
BROWSER
DISPLAY
XDG_DATA_HOME
XDG_CONFIG_HOME
XDG_DATA_DIRS
XDG_CONFIG_DIRS
XDG_CACHE_HOME
NAUTILUS_SCRIPT_SELECTED_FILE_PATHS
NAUTILUS_SCRIPT_SELECTED_URIS
NAUTILUS_SCRIPT_CURRENT_URI
NAUTILUS_SCRIPT_WINDOW_GEOMETRY
LD_PRELOAD
CC
CFLAGS
CXXFLAGS
CPPFLAGS
LIBRARY_PATH
INCLUDE
CPATH
USERNAME
LOGNAME
HOME
PWD
SHELL
POSIXLY_CORRECT
HOSTALIASES
TZDIR
TZ
TERM
TERMCAP
COLUMNS
LINES
http_proxy
HTTP_PROXY
FUNCNAME
EOF

  printenv
  #envs=$(printenv)
  #echo "-------------------------------------"
  #varnames=$(echo -e "$varnames" | sort)
  #for varname in $varnames; do
  #  [ -n "${!varname}" -a -z "$(echo -e $envs | grep '^'$varname'=')" ] && echo "${varname}="${!varname}
  #done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Developer useful functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"