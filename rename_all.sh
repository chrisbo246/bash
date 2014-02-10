#!/bin/sh
usage="Recusively rename files and directories matching with a string.\n\n
Usage: `basename $0 .sh` 'search' 'replace'\n"
case $# in
2) search=$1;replace=$2;;
*) echo -e $usage 1>&2; exit 65;;
esac

find . -depth -name "*$search*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$search'/'$replace'}"; done' _ {} +
