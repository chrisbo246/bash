#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Options:
#      -r, remove the compressed file after extraction
#      -v, verbose

unpack2dir ()
{

  NAME_="unpack2dir"

  # args check
  [ $# -eq 0 ] && { echo >&2 missing argument, type $NAME_ -h for help; exit 1; }

  # var init
  rmf=
  verbose=

  # option and argument handling
  while getopts vhlr options; do

    case $options in
      r) rmf=on ;;
      v) verbose=on ;;
      \?) echo invalid argument, type $NAME_ -h for help >&2; exit 1 ;;
    esac

  done
  shift $(( $OPTIND - 1 ))

  start_dir=$(pwd)

  for a in "$@"; do

    cd $start_dir
    fname=$(file_getBasename $a)
    dir=$(file_getDirname $a)
    cd $dir
    a=$fname

    case $a in

      # zip
      *.[zZ][iI][pP])
        mkdirf ${a/.[zZ][iI][pP]/} $a
        unzip -qq $a -d ${a/.[zZ][iI][pP]/}
        clean $? ${a/.[zZ][iI][pP]/}
      ;;

      # tar
      *.[tT][aA][rR])
        mkdirf ${a/.[tT][aA][rR]/} $a
        tar -xf $a -C ${a/.[tT][aA][rR]/}/
        clean $? ${a/.[tT][aA][rR]/}
      ;;

      # tgz
      *.[tT][gG][zZ])
        mkdirf ${a/.[tT][gG][zZ]/} $a
        tar -xzf $a -C ${a/.[tT][gG][zZ]/}
        clean $? ${a/.[tT][gG][zZ]/}
      ;;

      # tar.gz
      *.[tT][aA][rR].[gG][zZ])
        mkdirf ${a/.[tT][aA][rR].[gG][zZ]/} $a
        tar -xzf $a -C ${a/.[tT][aA][rR].[gG][zZ]/}/
        clean $? ${a/.[tT][aA][rR].[gG][zZ]/}
      ;;

      # tar.bz2
      *.[tT][aA][rR].[bB][zZ]2)
        mkdirf ${a/.[tT][aA][rR].[bB][zZ]2/} $a
        tar -xjf $a -C ${a/.[tT][aA][rR].[bB][zZ]2/}/
        clean $? ${a/.[tT][aA][rR].[bB][zZ]2/}
      ;;

      # tar.z
      *.[tT][aA][rR].[zZ])
        mkdirf ${a/.[tT][aA][rR].[zZ]/} $a
        tar -xZf $a -C ${a/.[tT][aA][rR].[zZ]/}/
        clean $? ${a/.[tT][aA][rR].[zZ]/}
      ;;

      *) echo "${NAME_}: $a not a compressed file or lacks proper suffix" ;;

    esac

  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Options:
#      -r, remove the input file after conversion

zipfile ()
{

  NAME_="zipfile"

  # args check
  [ $# -eq 0 ] && { echo >&2 missing argument, type $NAME_ -h for help; exit 1; }

  # var init
  rm_input=

  # option and arg handling
  while getopts hlr options; do

    case $options in
      r) rm_input=on ;;
      \?) echo invalid argument, type $NAME_ -h for help >&2; exit 1 ;;
    esac

  done
  shift $(( $OPTIND - 1 ))

  # main execution
  for a in "$@"; do

    if [ -f ${a}.[zZ][iI][pP] ] || [[ ${a##*.} == [zZ][iI][pP] ]]; then
      { echo skipping $a - already zipped; continue; }
    else
      [ -f $a ] && zip -9 ${a}.zip $a || { echo file $a does not exist; continue ;}
      [[ $rm_input ]] && rm -f -- $a
    fi

  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mkdirf() {
# file_getDirname() {
# file_getBasename() {
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clean() {

  # usage <exit_status> <dir_to_rm>

  [[ $1 != 0 ]] && rmdir $2 # remove empty dir if unpacking went wrong
  [[ $1 == 0 && $verbose ]] && echo "${NAME_}: unpacking " ${dir}/${a}
  [[ $rmf ]] && rm -f -- $a

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='Archive management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"