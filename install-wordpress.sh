#!/bin/bash

# Args:
#	$1 domain name (example.com)
#	$2 mysql root password


if [ "$(id -u)" != "0" ]; then
	echo ""
	echo "Script must be run as root."
	echo ""
	exit 1
fi

if [ $# != 2  ]; then
	echo ""
	echo "Incorrect number of arguments, 2 required."
	echo "1: domain name to install Wordpress to. (e.g. example.com)"
	echo "2: MySQL root password (to create databases)"
	echo ""
	exit 2
fi
randpass() {
    CHAR="[:alnum:]"
    RET=`cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-16}`
}

#Sanitize domain name to take out periods
DOMAIN_NAME=$(echo $1 | sed "s/\./__/")

#Generate all required random passwords/salt/hashes
randpass
DB_PASS=$RET
randpass
USER_PASS=$RET

#Make user and group
useradd -m $DOMAIN_NAME
echo $USER_PASS > tmp
echo $USER_PASS >> tmp
passwd $DOMAIN_NAME < tmp
rm tmp


INSTALL_DIR="/home/$DOMAIN_NAME/wordpress"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

#Get latest version, delete old version
rm latest.*
wget http://wordpress.org/latest.tar.gz

#Extract to web directory
tar xf latest*
mv wordpress/* /home/$DOMAIN_NAME/wordpress/
rm -rf wordpress/

#change permissions (not necessary so far)

#Create Database and Database user
echo "CREATE DATABASE $DOMAIN_NAME;
GRANT ALL PRIVILEGES ON $DOMAIN_NAME.* TO "$DOMAIN_NAME"@"localhost" IDENTIFIED BY '"$DB_PASS"';
FLUSH PRIVILEGES;
EXIT;" > input
mysql --user=root --password=$2 < input
rm input

#Make config.php file
echo "<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '$DOMAIN_NAME');

/** MySQL database username */
define('DB_USER', '$DOMAIN_NAME');

/** MySQL database password */
define('DB_PASSWORD', '$DB_PASS');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/** The FTP settings. These settings are assumed, and if using 
the ServerCobra set of scripts, it will work automagically */
/*  WordPress FTP Information (For removing the constant password request on plugin install and removal) */

define("FTP_HOST", "$1");
define("FTP_USER", "$DOMAIN_NAME");
define("FTP_PASS", "$USER_PASS");

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */" > wp-config.php

wget https://api.wordpress.org/secret-key/1.1/salt/
cat index.html >> wp-config.php

echo "/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix  = 'wp_';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress.  A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de.mo to wp-content/languages and set WPLANG to 'de' to enable German
 * language support.
 */
define ('WPLANG', '');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

#Cleanup, or the index.html file will be displayed right away, along with all
# the security keys.
rm index.html

#Make sure no one can read this file, since it has all the passwords and such
chmod 770 $DOMAIN_NAME wp-config.php

#Installation is now complete..

echo "////////////////////////////////////////////////////////////////////////////////"
echo "Install completed successfully!"
echo "Please visit http://$1/wp-admin/install.php to finalize your installation."
echo ""
echo "Your new wordpress username is: $DOMAIN_NAME"
echo "with password: $USER_PASS"
echo "and your MySQL username is: $DOMAIN_NAME"
echo "with password: $DB-PASS"
echo ""
echo "You can also find these in wp-config.php"
