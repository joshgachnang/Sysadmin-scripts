#!/bin/bash
VHOST_DIR='/etc/nginx/sites-available'
USER_DIR='/ebs/www'
USERNAME=''
USERPASS=''
DOMAIN=''
MSYQLPASS=''
USER_TRUNC=''
DOMAIN_TRUNC=''
DB_PASS=''

RET=''
function sanity_check {
    	if [ "$(id -u)" != "0" ]; then
        	echo "Script must be run as root."
        	exit 1
    	fi
	if [[ $1 != 2 ]]; then
		echo $1
		echo "Usage: nginx-vhost.sh username example.com"
		exit 4
	fi

	egrep "^$USERNAME:" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$USERNAME exists!"
		exit 3
	fi

}

function password {
	RET=$(cat /dev/urandom | tr -cd [:alnum:] | head -c ${1:-16})
}

function setup_user {
	useradd -m -d $USER_DIR/$USERNAME -U $USERNAME

	password
	PASSWORD=$RET
	echo "$USERNAME:$PASSWORD" | chpasswd

	mkdir -p $USER_DIR/$USERNAME/$DOMAIN/htdocs
	mkdir $USER_DIR/$USERNAME/$DOMAIN/logs
	touch $USER_DIR/$USERNAME/$DOMAIN/logs/access.log
	touch $USER_DIR/$USERNAME/$DOMAIN/logs/error.log
	chown -R $USERNAME $USER_DIR/$USERNAME
	chgrp -R $USERNAME $USER_DIR/$USERNAME

	echo "Create user: $USERNAME with password: $PASSWORD"
}
function php_pool {
	if [ ! -f /etc/php5/fpm/port ]; then
		echo "Cannot access /etc/php5/fpm/port"
		exit 2
	fi

	# Grab the port from file, and increment.
	PORT=$(cat /etc/php5/fpm/port)
	echo $(($PORT + 1)) > /etc/php5/fpm/port

	cp /etc/php5/fpm/pool.template /etc/php5/fpm/pools/$DOMAIN
	sed -i "s|example.com|$DOMAIN|" /etc/php5/fpm/pools/$DOMAIN

	sed -i "s|PORT|$PORT|" /etc/php5/fpm/pools/$DOMAIN
	sed -i "s|user = example|user = $USERNAME|" /etc/php5/fpm/pools/$DOMAIN
	sed -i "s|group = example|group = $USERNAME|" /etc/php5/fpm/pools/$DOMAIN
	echo "Added $DOMAIN to the PHP pool"
}
function nginx_vhost {
	cp /etc/nginx/vhost.template /etc/nginx/sites-available/$DOMAIN
	sed -i "s|example.com|$DOMAIN|g" /etc/nginx/sites-available/$DOMAIN
	sed -i "s|username|$USERNAME|g" /etc/nginx/sites-available/$DOMAIN
	sed -i "s|PORT|$PORT|g" /etc/nginx/sites-available/$DOMAIN
	# Should probably sed through and replace /ebs/www with $USER_DIR

	# Enable the site
	ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
	echo "Enabled $DOMAIN in the web server"
}
function server_reload {
	/etc/init.d/php5-fpm reload
	/etc/init.d/nginx reload
	echo "Servers reloaded"
}
function prepare_mysql {
	# Generate dbuser password
	password
	DB_PASS=$RET

	# Truncate username (15 chars max) and dbname (63 chars max)
	USER_TRUNC=$(echo $USERNAME | cut -c1-15)

	# This should be a separate user with only create perms.
	echo "CREATE DATABASE $USER_TRUNC;
GRANT ALL PRIVILEGES ON $USER_TRUNC.* to '$USER_TRUNC'@'localhost' IDENTIFIED BY '$DB_PASS';" > $USERNAME.sql
	mysql -u root -p$(cat /root/mysql) < $USERNAME.sql
	rm $USERNAME.sql
	echo "Created MySQL user: $USER_TRUNC password: $DB_PASS database: $DOMAIN_TRUNC"
}
function add_to_ftp {
	usermod -g proftpd $USERNAME
}
function install_wordpress {
	wget http://wordpress.org/latest.tar.gz
	tar xf latest.tar.gz
	mv wordpress/* $USER_DIR/$USERNAME/$DOMAIN/htdocs/
	cp $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config-sample.php $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
	sed -i "s|database_name_here|$USER_TRUNC|g" $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
	sed -i "s|username_here|$USERNAME|g" $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
	sed -i "s|password_here|$DB_PASS|g" $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php

	echo "	define(\"FTP_HOST\", \"$DOMAIN\");
	define(\"FTP_USER\", \"$USERNAME\");
	define(\"FTP_PASS\", \"$USERPASS\");" >> $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php

	# Add in salts from the wordpress salt generator
	wget https://api.wordpress.org/secret-key/1.1/salt/
	sed -i "s/|/a/g" index.html
#	cat index.html | while read line; do
 #   	sed -i "s|define('.*',.*'put your unique phrase here');|$line|" $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
#	sed 1d $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
#	done
	sed -i '/#@-/r index.html' $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
	sed -i "/#@+/,/#@-/d" $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php
	rm index.html
	rm latest.tar.gz

	# Add in FTP stuff, even though that's not defined yet..

	# Own these new files
	chown -R $USERNAME $USER_DIR/$USERNAME/$DOMAIN/htdocs/*
	chgrp -R $USERNAME $USER_DIR/$USERNAME/$DOMAIN/htdocs/*
	# Make sure no one else can read this file
	chmod 700 $USER_DIR/$USERNAME/$DOMAIN/htdocs/wp-config.php

	#echo "Wordpress for $DOMAIN installed."
	#echo "Visit http://$DOMAIN/wp-admin/install.php to complete installation"
}

##############################################################################
# Start of program
USERNAME=$1
DOMAIN=$2

sanity_check $#
setup_user
php_pool
nginx_vhost
server_reload
prepare_mysql
add_to_ftp
install_wordpress
exit 0
