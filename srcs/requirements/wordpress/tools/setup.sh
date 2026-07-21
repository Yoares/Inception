#!/bin/bash

# Create the directory for PHP-FPM's process ID file (required by Debian)
mkdir -p /run/php

# Navigate to the designated web directory
cd /var/www/html

# 1. The Safety Check: Does the configuration file exist?
if [ ! -f "wp-config.php" ]; then
    echo "Downloading WordPress core files..."
    
    # 2. The Download
    # The --allow-root flag is required because Docker runs scripts as the root user by default, 
    # and WP-CLI normally blocks root execution for security reasons.
    wp core download --allow-root

    # Wait for the MariaDB container to be fully ready before trying to connect
    sleep 5

    echo "Creating wp-config.php..."
    
    # 3. The Config Binding
    wp config create --dbname="${MYSQL_DATABASE}" \
                     --dbuser="${MYSQL_USER}" \
                     --dbpass="${MYSQL_PASSWORD}" \
                     --dbhost="mariadb" \
                     --allow-root

    echo "Installing WordPress and setting up the administrator..."
    
    # 4. The Core Install
    wp core install --url="${DOMAIN_NAME}" \
                    --title="Inception" \
                    --admin_user="${WP_ADMIN_USER}" \
                    --admin_password="${WP_ADMIN_PASSWORD}" \
                    --admin_email="${WP_ADMIN_EMAIL}" \
                    --allow-root

    echo "Creating the secondary user..."
    
    # 5. The Second User
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
                   --role=author \
                   --user_pass="${WP_USER_PASSWORD}" \
                   --allow-root

    echo "WordPress installation complete!"
else
    echo "WordPress is already installed. Skipping initialization."
fi

# 6. The PID 1 Handoff
# The -F flag tells PHP-FPM to run in the foreground, binding it to the container's lifecycle.
echo "Starting PHP-FPM daemon..."
exec /usr/sbin/php-fpm7.4 -F