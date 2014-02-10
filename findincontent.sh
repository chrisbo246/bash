#!/bin/bash
#
#   "@(#)$Id: $0,v 0.9 2012/10/04 07:00:00 Christophe Boisier $"
#
usage="
Return the name of files containing a string from current path.\n
\n
Usage: `basename $0 .sh` [-{r|V}] 'string'\n
\n
-r search recursively in subfolders\n
-V print version number\n
"
version=$( echo "`basename $0 .sh`: Version $Revision: 0.9 $ ($Date: 2012/10/03 07:30:00 $)" )

shift $(($OPTIND - 1))
case $# in
2)
  case $1 in
    -[r] ) r='-r'; echo 'r';;
    *)  echo -e $usage 1>&2; exit 1;;
  esac;;
1)
  case $1 in
    -[V] ) echo -e $version >&2; exit 0;;
  esac;;
*)
  echo -e $usage 1>&2; exit 65
	;;
esac

find . -name "*.*" -type f -exec grep -Hn "$1" {} \;
#find . -name "*.[ch]" -exec grep -i -H "search pharse" {} \;

