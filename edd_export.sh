#!/bin/bash

read -d '' sources <<-EOF
/usr/local/bin/clickpanic_.*\.sh
/var/www/clients/client1/web1/web/subdomains/blog/wp-content/themes/twentytwelve_postit
EOF

read -d '' dests <<-EOF
/var/www/clients/client1/web1/web/subdomains/blog/wp-content/uploads/edd
EOF

while read dest; do
  while read source; do
    while read filename; do
      basename=$(basename "$filename")
      name=${basename%.*}
      if [ -d "$filename" ]; then
        cd $(dirname "$filename")
        zip -r "$name" $(basename "$filename")
      else
        zip -j "$name" "$filename"
      fi
      mv "$name.zip" "${dest%/}/"
    done < <(find / -regex "$source")
  done < <(echo -e "$sources")    
done < <(echo -e "$dests")
