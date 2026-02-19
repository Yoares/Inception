#!/bin/bash

# Check if wp-config.php exists
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    mkdir -p /var/www/wordpress
    cd /var/www/wordpress

    # Download WP-CLI
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    # Download WordPress
    wp core download --allow-root

    # Create Configuration
    # We read secrets from the Docker Secret files
    DB_PASS=$(cat /run/secrets/db_password)

    wp config create \
        --dbname=$SQL_DATABASE \
        --dbuser=$SQL_USER \
        --dbpass=$DB_PASS \
        --dbhost=$SQL_HOST \
        --allow-root

    # Install WordPress
    wp core install \
        --url=$DOMAIN_NAME \
        --title="Inception" \
        --admin_user=$SQL_USER \
        --admin_password=$DB_PASS \
        --admin_email="admin@student.42.fr" \
        --allow-root

    # Create User 2 (Author)
    wp user create author author@42.fr --role=author --user_pass=$DB_PASS --allow-root
fi

# Start PHP-FPM
exec /usr/sbin/php-fpm7.4 -F