#!/bin/bash

replace()
{
  search=$(printf "%s\n" "$1" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
  replace=$(printf "%s\n" "$2" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
  grep -rl "$1" . |xargs sed -i -e 's/'$search'/'$replace'/g'
}
cd /var/www
replace "/var/www/sites/" ""
grep -rE "/var/www/sites/[^/]+/[^/]+/subdomains/" | xargs sed -e "s|/var/www/sites/\([^/]+\)/\([^/]+\)/subdomains/|/var/www/\1/|g"