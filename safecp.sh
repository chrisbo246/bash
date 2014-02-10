#!/bin/bash

usage="Make a safe copy of a folder and is content including hidden files and preserving informations.\n\n
Usage: `basename $0 .sh` [srcdir] [dstdir]\n"

case $# in
  2)
    if [ ! -d "$1" ]; then
      echo "$1 is not a directory"
      exit 65
    fi
    src=${1%/}
    dst=${2%/}
  ;;
  *)echo -e $usage 1>&2; exit 65;;
esac

if [ ! -d "$dst" ]; then
  mkdir -p "$dst"
fi

cp -rpfP "$src/"{*,.??*} "$dst"
