#!/bin/bash

stty -echo
read -p "MySQL root password :" pwd
stty echo
echo ""

databases=$( mysql -root -p$pwd -e"SHOW DATABASES;" |  tail -n +2 )
tables=$( mysql -root -p$pwd -e"SHOW TABLES;" | egrep -v 'Tables_in_' )

echo $databases
read -p "Database : " database

echo $tables
read -p "Table : " table


fields=$( mysql -uroot -p$pwd -D$database -e"SHOW COLUMNS FROM $table" | awk -F' ' '{print $1}' )

for field in $fields;
do
  # echo $field
  # image180Height
  # int(11)
  # NO
  # NULL
  #i=0
  #for f in $field;
  #do
  # $i++
  # echo "$f[$i]"
  #done
  
  fieldname=$field
  values=$( mysql -uroot -p$pwd -D$database -e"SHOW COLUMNS FROM $table" )
  fieldname=$( echo -n $field | awk -F" " '{print $1}' )
  #fieldtype=$( echo -n $field | awk -F" " '{print $2}' )
  #fieldname=$field[0]
  #fieldtype=$field[1]
  
  fieldtype=$( mysql -uroot -p$pwd -D$database -e"SHOW COLUMNS FROM $table WHERE field='$fieldname'" | awk -F' ' '{print $2}' )
  
  maxlength=$( mysql -uroot -p$pwd -D$database -e"SELECT MAX(LENGTH($fieldname)) AS len FROM $table" | tail -n +2 )
  #maxlength=$( mysql -uroot -p$pwd -D$database -e"SELECT $fieldname, length($fieldname) FROM $table WHERE LENGTH($fieldname)=(SELECT MAX(LENGTH($fieldname)) FROM $table)" )
  if [ $maxlenght > 0 ]; then
    comment=""
  fi
  #echo "Max length : $maxlength"
  echo "$fieldname : $fieldtype / max length : $maxlength"
done
