#!/bin/bash

read -d '' help <<-EOF
NAME
    ${0##*/} - Replace a string in all files containing it

SYNOPSIS
    ${0##*/} [search] [replace]
    ${0##*/} [-h|--help] 

DESCRIPTION
    Recursively search a string inside files from current position and replace it with new string.

OPTIONS
    -h, --help
        Display this help screen.

EXAMPLES
    ${0##*/} 'What'\''s up ?' 'I'\''m happy !!!'
    Note that strings must be quoted whit sigle quotes. If your strings contain a single quote, replace it by '\''.

AUTHOR
    Written by Christophe BOISIER.
    
REPORTING BUGS
    Report bugs to christophe.boisier@live.fr
    
COPYRIGHT
    Copyright (c) 2013 Christophe BOISIER License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
EOF

EXPECTED_ARGS=2
E_BADARGS=65
if [ $# -ne $EXPECTED_ARGS ]; then
  printf "\n$help\n\n"
  exit $E_BADARGS
fi

#search=$(printf "%s\n" "$1" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
#replace=$(printf "%s\n" "$2" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
search=$(printf "%s\n" "$1" | sed 's/[][\.*/]/\\&/g; s/[$]/\\&/g; s/[[:space:]]/\[\[:space:]]/g; s/$$/\\&/; s/^^/\\&/')
replace=$(printf "%s\n" "$2" | sed 's/[][\.*/]/\\&/g; s/[()$]/\\&/g; s/[[:space:]]/\[:space:]/g; s/$$/\\&/; s/^^/\\&/')
sed='s/'"$search"'/'"$replace"'/g'
echo $sed
grep -rlF "$1" . | xargs sed -i -e $sed