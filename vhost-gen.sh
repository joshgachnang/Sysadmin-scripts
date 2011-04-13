#Exit statuses:
#  1: Incorrect arguements
#  2: Vhost already exists

#Follows the Gachnang Username Standard (haha)
# 1. Usernames for websites will be the web address.
# 1a. All periods will be replaced by double underscores.
# 1b. Username cannot exceed 16 characters, so they can be used in MySQL.
# 1c. Web address will be in the form example.com or sub.example.com

#Makes the script exit if anything is evaluated as false or a variable
#isn't set properly. Robust!!
#set -uo

#The directory in which the vhost files will be stored. Default is
# '/etc/apache2/sites-available/' in Debian/Ubuntu. Make sure it ends in a "/"
APACHE_DIR='/etc/apache2/sites-available/'

#Random Password Generator Script originally from jbreland
#http://legroom.net/2010/05/06/bash-random-password-generator

# Generate a random password
PASS=`cat /dev/urandom | tr -cd [:alnum:] | head -c ${1:-16}`

#Check for subdomain. Only works for singlur subdomain.
if [[ $1 == *.*.* ]]; then
  #Domain is a subdomain
  SUBDOMAIN=1
  DOMAIN=${1#*.}
else
  #Not subdomain
  SUBDOMAIN=0
fi

#Removes the periods in the domain name and replaces them with double
#underscores (for usernames and database names)
if [ ${#name} -gt 16 ]; then
  USERT=$(echo $1 | sed "s/\./__/" | cut -c1-16)
else
  USERT=$(echo $1 | sed "s/\./__/")
fi


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


if [ ! -d /home/$USER ]; then
  #User doesn't exist, doesn't consider users without home directories
  USERDIR="/home/$USERTRUNC"
  #Create user and user directory
  useradd -m -d $USERDIR -U $USERT
  #Set password
  echo $PASS | passwd $USERT --stdin
else
  echo "User already exists"
fi

mkdir /home/$USERT/$1/
mkdir /home/$USERT/$1/htdocs
mkdir /home/$USERT/$1/logs
touch /home/$USERT/$1/logs/access.log
touch /home/$USERT/$1/logs/error.log


#Write the vhost file to the Apache vhost directory
echo "<VirtualHost *:80>
        ServerAdmin $2
        ServerName  $1
        ServerAlias www.$1

        DocumentRoot /home/$USERT/$1/htdocs/
        <Directory /home/$USERT/$1/htdocs/>
                Options Indexes FollowSymLinks ExecCGI
                AllowOverride All
                Order allow,deny
                Allow from all
        </Directory>

        # Logfiles
        ErrorLog  /home/$USERT/$1/logs/error.log
        CustomLog /home/$USERT/$1/logs/access.log combined

        SuexecUserGroup $USERT $USERT

        ScriptAlias /php-fastcgi/ /home/$USERT/$1/php-fastcgi/
        FCGIWrapper /home/$USERT/$1/php-fastcgi/wrapper .php
        AddHandler fcgid-script .php
        Options ExecCGI Indexes
</VirtualHost>
" > $APACHE_DIR$1

#Enable the new vhost
a2ensite $APACHE_DIR$1

#Make Apache aware of the new VHost file.
/etc/init.d/apache2 reload
