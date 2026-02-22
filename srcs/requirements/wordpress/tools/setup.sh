#!/bin/bash

# Move into our magic portal folder
cd /var/www/html

# We use an 'if' statement so we don't reinstall if the container restarts
if [ ! -f wp-config.php ]; then
    
    # 1. Download WP-CLI (the WordPress command line tool)
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    # 2. Download the WordPress core files
    wp core download --allow-root

    # 3. Create the config file connecting to MariaDB
    wp config create --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER --dbpass=$MYSQL_PASSWORD --dbhost=mariadb --allow-root

    # 4. Install WordPress and create the main administrator
    wp core install --url=$DOMAIN_NAME --title="Inception" --admin_user=$WP_ADMIN_USER --admin_password=$WP_ADMIN_PASSWORD --admin_email=$WP_ADMIN_EMAIL --allow-root

    # 5. Create the mandatory second user
    wp user create $WP_USER $WP_USER_EMAIL --role=author --user_pass=$WP_USER_PASSWORD --allow-root

fi

# 6. Tell PHP-FPM to listen on port 9000
sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf

# 7. Create the folder PHP needs to run
mkdir -p /run/php

# 8. Start PHP-FPM in the foreground
exec /usr/sbin/php-fpm7.4 -F