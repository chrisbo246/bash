#!/bin/sh

EXPECTED_ARGS=2
E_BADARGS=65
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Recusively rename files and directories matching with a string."
  echo "Usage: `basename $0` 'search' 'replace'"
  exit $E_BADARGS
fi


find . -depth -name "*$1*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$1'/'$2'}"; done' _ {} +
