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
#grep -rl $1 . |xargs sed -i -e 's/'$search'/'$replace'/g'
#find . -depth -name "*$1*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$search'/'$replace'}"; done' _ {} +


# Language strings
# Convert to upper case
s=$(echo $search | tr '[:lower:]' '[:upper:]')
r=$(echo $replace | tr '[:lower:]' '[:upper:]')
# Convert special characters to underscores
s=$(echo $s | sed 's/\(\s-\|[^A-Za-z0-9]\)/_/g')
r=$(echo $r | sed 's/\(\s-\|[^A-Za-z0-9]\)/_/g')
echo "Replace '$s' by '$r'"
grep -rl $s . |xargs sed -i -e 's/'$s'/'$r'/g'
find . -depth -name "*$s*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$s'/'$r'}"; done' _ {} +


# Convert to lower case for filenames and global vars
s=$(echo $search | tr '[:upper:]' '[:lower:]')
r=$(echo $replace | tr '[:upper:]' '[:lower:]')
echo "Replace '$s' by '$r'"
grep -rl $s . |xargs sed -i -e 's/'$s'/'$r'/g'
find . -depth -name "*$s*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$s'/'$r'}"; done' _ {} +


# First letter of each words to upper case
s=$(echo $search | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g')
r=$(echo $replace | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g')
# Remove special characters
s=$(echo $s | sed 's/\(\s-\|[^A-Za-z0-9]\)//g')
r=$(echo $r | sed 's/\(\s-\|[^A-Za-z0-9]\)//g')
echo "Replace '$s' by '$r'"
grep -rl $s . |xargs sed -i -e 's/'$s'/'$r'/g'
find . -depth -name "*$s*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$s'/'$r'}"; done' _ {} +


# Convert only first letter to lower case
s=$(echo $s | sed 's/^./\L&\E/')
r=$(echo $r | sed 's/^./\L&\E/')
echo "Replace '$s' by '$r'"
grep -rl $s . |xargs sed -i -e 's/'$s'/'$r'/g'
find . -depth -name "*$s*" -exec bash -c 'for f; do base=${f##*/}; mv -- "$f" "${f%/*}/${base//'$s'/'$r'}"; done' _ {} +
