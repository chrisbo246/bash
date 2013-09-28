#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mkdirf() {

  # usage: fnc <file_prefix> <file>

  [ -d $1 ] && { echo "${NAME_}: skipping ${2} - dir ${1} already exist" ; continue; }
  #echo $1
  mkdir $1
  #    [[ $verbose ]] && echo "${NAME_}: unpacking "$2
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_getDirname() {

  local _dir="${1%${1##*/}}"
  [ "${_dir:=./}" != "/" ] && _dir="${_dir%?}"
  echo "$_dir"

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#

file_getBasename() {

  local _name="${1##*/}"
  echo "${_name%$2}"

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Return running script path

script_path ()
{

  # path=`echo "$0" | sed -e "s/[^\/]*$//"`
  path=`dirname $0`
  echo "$path/"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check if path is linux format and anding with "/"

check_dir ()
{

  dir=$1
  if [ "$dir" != "" ]; then
    dir=$( echo $dir | sed 's/%/\\\%/g'| sed 's|/$||g' )
    #dir=$( echo "$dir/" | sed 's|/$||g' )
    dir="$dir/"
  fi

  echo $dir

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dirsize ()
{
  dir=$1
  echo du -s "$dir" |awk '{print $1}'

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_info ()
{
  FILENAME="$1"

  if [ -f $FILENAME ]; then
    echo "Size is $(ls -lh $FILENAME | awk '{ print $5 }')"
    echo "Type is $(file $FILENAME | cut -d":" -f2 -)"
    echo "Inode number is $(ls -i $FILENAME | cut -d" " -f1 -)"
    echo "$(df -h $FILENAME | grep -v Mounted | awk '{ print "On",$1", \
    which is mounted as the",$6,"partition."}')"
  else
    echo "File does not exist."
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_size()
{
  FILENAME="$1"
  echo "$(ls -lh $FILENAME | awk '{ print $5 }')"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_type()
{
  FILENAME="$1"
  echo "$(file $FILENAME | cut -d":" -f2 -)"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_inode()
{
  FILENAME="$1"
  echo "$(ls -i $FILENAME | cut -d" " -f1 -)"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_partition()
{
  FILENAME="$1"
  echo "$(df -h $FILENAME | grep -v Mounted | awk '{ print "On",$1", \
  which is mounted as the",$6,"partition."}')"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test if the command (param) exists
command_exists()
{
  if command -v $1 &>/dev/null
  then
    # echo " Yes, command :$1: was found."
    return 1
  else
    # echo " No, command :$1: was NOT found."
    return 0
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='File management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
