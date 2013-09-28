#/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__file_menu()
{
  while true; do
    __menu \
    -t 'File' \
    -o 'Convert line endings' \
    --back --exit

    case $REPLY in
      1 ) convert_line_endings "$1";;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
find_filtered_files()
{
  local find_options commands
  local path=.
  local onmatch='(( match++ ))'
  local onnotmatch='continue'
  local print_pattern='$filename $(file -b --mime-type $filename)'

read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Find files filtered by type

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-e|--extension ext]...
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -e, --extension
        Return only files with this extension (without dot).
    --mime-encoding
      Return only files with this mime-encoding.
    --mime-type
      Return only files with this mime-type.
    -p, --path
    --prefix
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local pattern='if [[ "%s" == "%s" ]]; then eval "$onmatch"; else eval "$onnotmatch"; fi;'

  ARGS=$(getopt -o "e:p:aoh" -l "extension:,mime-encoding:,mime-type:,permission:,path:,prefix:,and,or,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -a|--and) shift; onmatch='(( match++ ))'; onnotmatch='continue';;
      -e|--extension) shift; find_options="${find_options} -iname '*.$1'"; commands="${commands} "$(printf "$pattern" "$1" "\${filename##*.}"); shift;;
      --mime-type) shift; commands="${commands} "$(printf "$pattern" "$1" "\$(file -b --mime-type \$filename)"); shift;;
      --mime-encoding) shift; commands="${commands} "$(printf "$pattern" "$1" "\$(file -b --mime-encoding \$filename)"); shift;;
      --permission) shift; commands="${commands} "$(printf "$pattern" "$1" "\$(stat --format=%a \$filename)"); shift;;
      -o|--or) shift; onmatch='(( match++ ))'; onnotmatch='';;
      -p|--path) shift; path="${1:-$path}";;
      --prefix) shift; find_options="${find_options} -name '$1*'"; commands="${commands} "$(printf "$pattern" "$1" "\$(echo $(basename \$filename | sed -r 's/^("$1").*$/\1/')"); shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  while read filename; do
    #file_basename=$(basename "$filename") # ports.conf
    #file_dirname=$(dirname "$filename") # /etc/apache2
    #file_shortname=${file_basename%%.*} # ports
    #file_size=$(stat -c%s "$filename") # 742
    #file_owner=$(stat -c %U "$filename") # root
    #file_group=$(stat -c %G "$filename") # root
    #file_lines=$(wc -l <"$filename") # 23
    #file_words=$(wc -w <"$filename") # 104
    #file_max_line_length=$(wc -L <"$filename") # 75
   #echo $commands
    local match=0
    shopt -s nocasematch
    eval "$commands"
    shopt -u nocasematch
    [[ $match > 0 ]] && echo $(eval "$print_pattern")

  done < <(find $(readlink -f "$path") -type f $find_options)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# See also dos2unix mac2unix unix2dos
convert_line_endings()
{

  dst_type='LF'
  dst_file=$src_file
  #${IFS}

  ARGS=$(getopt -o "d:muwh" -l "destination:,mac,unix,windows,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -m|--mac) shift; dst_type='CR';;
      -u|--unix) shift; dst_type='LF';;
      -w|--windows) shift; dst_type='CR/LF';;
      -d|--destination) shift; destination=${1:-$dst_file}; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit;;
      --) shift; break;;
    esac
  done

  src_type="$(file "$1" | grep -Po '[A-Z/]+ line terminators' | sed 's/ .*$//')"

  case $src_type in
    'CR' )
      # Convert from legacy Mac-style CR line endings
      # to UNIX-style LF line endings for use with
      # command-line tools
      [ "$dst_type" == 'LF' ] && tr '\r' '\n' < $src_file > $dst_file
      break
    ;;
    'CRLF'|'LFCR'|'CR/LF'|'LF/CR' )
      # Convert from Windows-style CR/LF line endings (or
      # LF/CR line endings) to UNIX line endings
      [ "$dst_type" == 'CR/LF' ] && tr -d '\r' < $src_file > $dst_file
      break
    ;;
    *|'LF' )
      # Convert from UNIX-style LF to legacy Mac-style CR
      # line endings
      [ "$dst_type" == 'CR' ] && tr '\n' '\r' < $src_file > $dst_file
      # Convert from UNIX-style LF line endings to
      # Windows-style CR/LF line endings
      CR=$(printf "\r")
      [ "$dst_type" == 'CR/LF' ] && sed "s/$/$CR/" < unix_text_file > windows_text_file
      break
    ;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='File functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"