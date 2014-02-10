#!/bin/bash
if [ $# -ne 1 ]; then echo "Usage: `basename $0` [component]"; exit 65; fi

files=$(find . -type f -ipath "*language*" -iname "*$1*.ini")
for file in $files; do
  echo "$file"
  for word in $(grep -Po "^([a-zA-Z0-9_]*)" $file); do
  test=$(find . -type f -ipath "*$1*" \( -iname "*.php" -o -iname "*.xml" \) -exec grep -PHn "['\">]+$word['\"<]+" {} \;)
  if [ -z "$test" ]; then
    sed -i "s/^\s*\("$word"\s*=.*\)$/;\1/g" $file
    echo "[disabled] $word"
  else
    sed -i "s/^\s*[;]?\s*\("$word"\s*=.*\)\s*$/;\1/g" $file
    echo "$word"
  fi
done
