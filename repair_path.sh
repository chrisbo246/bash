#!/bin/bash

EXPECTED_ARGS=2
E_BADARGS=65
if [ $# -ne $EXPECTED_ARGS ]; then
cat <<DELIM
Find and replace a path string in files recursively from current position.
Usage: $0 "oldpath" "newpath"
       $0 "/var/www/sites/(.*)/(.*)/subdomains/(.*)/html" "/var/www/clients/\1/\2/web/subdomains/\3"
DELIM
  exit $E_BADARGS
fi

search=$(printf "%s\n" "$1" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
replace=$(printf "%s\n" "$2" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')

while read filename; do
  grep -E "$1" "$filename" | sed -e 's/'$search'/'$replace'/g'
done < <(grep -lrE "$oldpath")
#grep -lrE "$1" | xargs sed -e 's/'$search'/'$replace'/g'