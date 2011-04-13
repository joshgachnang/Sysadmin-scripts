#Exit statuses:
#  1: Incorrect arguements
#  2: Vhost already exists

#Makes the script exit if anything is evaluated as false or a variable
#isn't set properly. Robust!!
#set -uo

#The directory in which the vhost files will be stored. Default is
# '/etc/apache2/sites-available/' in Debian/Ubuntu. Make sure it ends in a "/"
APACHE_DIR='/etc/apache2/sites-available/'

#MySQL hostname. Change to "localhost" if Apache and MySQL are on the same
#server.
MYSQL_HOST="localhost"

#Removes the periods in the domain name and replaces them with double
#underscores (for usernames and database names)
WIKI=$(echo $1 | sed "s/\./__/")

#Random Password Generator Script originally from jbreland
#http://legroom.net/2010/05/06/bash-random-password-generator

# Generate a random password
PASS=`cat /dev/urandom | tr -cd [:alnum:] | head -c ${1:-16}`
WEB_PASS=`cat /dev/urandom | tr -cd [:alnum:] | head -c ${1:-16}`

#Print usage if no args.
if [ $# != "2" ]; then
  echo ""
  echo "Generates a VirtualHost file for the given hostname, to be used with"
  echo 'MindTouch multi-tenant installations. Must have "Include script-dir/*"'
  echo "in an enabled Apache site for this to work. Apache will then use every"
  echo "VHost file in that directory."
  echo ""
  echo "        Usage:"
  echo "        vhost-gen.sh hostname admin_email"
  echo ""
  exit 1
fi

#Check if VHost directory exists. If not, make it.
if [ ! -d $APACHE_DIR ]; then
	mkdir $APACHE_DIR
fi

if [ -f $APACHE_DIR$1 ]; then
  echo "VHost already exists"
  exit 2
fi

#Write the vhost file to the Apache vhost directory
#echo "<VirtualHost *:80>" >> $APACHE_DIR$1
#echo "  ServerName $1" >> $APACHE_DIR$1
#echo "  ServerAlias $1" >> $APACHE_DIR$1
#echo "  DocumentRoot /var/www/dekiwiki/" >> $APACHE_DIR$1 
#echo "</VirtualHost>" >> $APACHE_DIR$1

#Enable the new vhost
#a2ensite $APACHE_DIR$1

/var/www/dekiwiki/maintenance/createdb.sh --dbName $1 --dbAdminUser root --dbAdminPassword ThetHethE \
 --dbServer localhost --dbWikiUser $WIKI --wikiAdmin Admin \
 --wikiAdminPassword $PASS --wikiAdminEmail $2 \
 --storageDir /var/www/dekiwiki/attachments/$1 \
 --s3PublicKey AKIAJRNNTU7U2XLDXSXA \
 --s3PrivateKey s36seTXsQNKnIbfYW5NXm7jNGTTlAOSdhzM6H3Ao \
 --s3Bucket servercobra-mindtouch --s3Prefix $1 --s3Timeout 60\
 --storageDir /var/www/dekiwiki/$1 >> /tmp/createdb

#Adds to the mindtouch config file, using sed to go in the middle of the file.
# -i is to do in place editing, while creating a backup file (file.bak)
#Searches for string "/globalconfig" (note escaped /)
#Then appends the rest at the next line (a\ )
#Final line specifies config file location. Note double quotes to allow
#variables in sed strings.


sed -i.bak "
/\/globalconfig/ a\
  \        <config id=\"$1\">\
\n\          <host>$1</host>\
\n\          <db-server>localhost</db-server>\
\n\          <db-port>3306</db-port>\
\n\          <db-catalog>$WIKI</db-catalog>\
\n\          <db-user>$WIKI</db-user>\
\n\          <db-password>$PASS</db-user>\
\n\          <db-options>>pooling=true; Connection Timeout=5; Protocol=socket; Min Pool Size=2; Max Pool Size=50; Connection Reset=false;character set=utf8;$
\n\        </config>
" /etc/dekiwiki/mindtouch.deki.startup.xml

#Does the same as above, but modifies the LocalSettings.php file in
#the dekiwiki web directory. Not sure why there are two places for
#the same information though.

sed -i.bak "
/$wgWikis = array(/ a\
  \        '$1' => array(
\n\                'db-server' => 'localhost',
\n\                'db-port' => '3306',
\n\                'db-catalog' => '$WIKI',
\n\                'db-user' => '$WIKI',
\n\                'db-password' => '$PASS',
\n\                ),
" /var/www/dekiwiki/LocalSettings.php

#Make Apache aware of the new VHost file.
/etc/init.d/apache2 reload
#Restart Mindtouch for changes to take effect. This needs to be fixed
#eventually, because everyone's site goes down at the same time.
#MindTouch has an artice on how they fixed it, which may be of use.
#
#http://developer.mindtouch.com/Wik.is/EC2_Infrastructure
/etc/init.d/dekiwiki restart
