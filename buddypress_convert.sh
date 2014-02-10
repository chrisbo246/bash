#!/bin/bash

get_templates()
{
  if [ -d "$1" ]; then
    while read subdir; do    
    if [ "$subdir" != "$1" ]; then
      #echo "Copying "$(readlink -f $subdir)
      cp -rfv "$subdir" .      
    fi
    done < <(find "$1" -maxdepth 1 -type d -print)
  fi  
}

replace_string()
{
  search=$(printf "%s\n" "$1" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
  replace=$(printf "%s\n" "$2" | sed 's/[][\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')
  grep -rl "$1" . |xargs sed -i -e "s/$search/$replace/g"
}

if [ -z "$(grep -ls 'Theme Name:' style.css)" ]; then
  echo "You must run this script from a working Wordpress (child) theme !"
  exit 65
fi 

if [ -z "$(grep -ls 'Theme Name:' ../../plugins/buddypress/bp-themes/bp-default/style.css)" ]; then
  echo "Can't find Buddypress default theme !"
  exit 65
fi 

get_templates '../../plugins/buddypress/bp-themes/bp-default/'
get_templates '../../plugins/buddypress-links/themes/bp-links-default/'
#get_templates '../../plugins/buddypress-media/templates/'
rm -rfv ./_inc


# Theme bp-default de Buddypress     Theme "untitled" by Automattic
# <     ...      >                   <div id="main" class="site-main">
#	 <div id="content">                  <div id="primary" class="content-area"> 
#    <div class="padder">                <div id="content" class="site-content" role="main">
echo "Adapting Buddypress template files"    
replace_string 'id="content"' 'id="primary" class="content-area"'
replace_string 'class="padder"' 'id="content" class="site-content" role="main"'


echo "Adapting buddypress.css"
cp -n "../../plugins/buddypress/bp-themes/bp-default/_inc/css/default.css" ./buddypress.css 
chmod a=r,u=rw ./buddypress.css
#sed -e -i "s|^.*(/\*[- \t\n\r]*[0-9-\.]+ - BuddyPress)|\1|g" ./buddypress.css
#[ -z "$(grep '@import url(\"buddypress.css\");' buddypress.css)" ] && sed -r -i "s|(@import[^\n\r]+)([^\n\r]+)|\1\2@import url(\"buddypress.css\")\;\2|" "./style.css"

sed -i "s|#content|#primary|g" "./buddypress.css"
sed -i "s|.padder|.site-content|g" "./buddypress.css"

cat <<DELIM

Just a few steps before complet:

-- Edit the following files and add a <div id="main" class="site-main">...</div> container like this. 

get_header( 'buddypress' ); ?>
<div id="main" class="site-main">
  <div id="primary">
    ...
  </div>
  <?php get_sidebar( 'buddypress' ); ?>
</div>
<?php get_footer( 'buddypress' ); ?>

$(grep -rl 'id="primary" class="content-area"' ./*/)

-- Edit buddypress.css and delete all the code before section 6.0.

Your template should be Buddypress compatible now :)
You can add "Tags: buddypress" tag in your style.css head
Think to share your modifications at christophe.boisier@live.fr
DELIM

