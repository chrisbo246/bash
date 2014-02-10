#!/bin/bash
#!/bin/bash -x for debuging

# Check params
EXPECTED_ARGS=2
E_BADARGS=65
if [ $# -ne $EXPECTED_ARGS ]
then
  echo 'Recursive search and replace old with new string inside files recursively from current position.'
  echo 'Usage: '$0' "oldstring" "newstring"'
  exit $E_BADARGS
fi

# Escape special characters for sed
search=$(printf "%s\n" "$1" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
replace=$(printf "%s\n" "$2" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')

# Replace srings
grep -rl "$1" . |xargs sed -i -e "s/$search/$replace/g"
