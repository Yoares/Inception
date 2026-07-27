#!/bin/bash

# Exit script immediately if any command fails (Safety net)
set -e 

# --- 1. Environment Setup ---
mkdir -p /run/php
cd /var/www/html

# --- 2. WordPress Installation ---
if [ ! -f "wp-config.php" ]; then
    echo "[WordPress] Downloading core files..."
    wp core download --allow-root

    # Pause to ensure the MariaDB container is fully booted and accepting connections
    echo "[WordPress] Waiting for MariaDB to initialize..."
    sleep 5 

    echo "[WordPress] Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    echo "[WordPress] Installing core and setting up Admin..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    echo "[WordPress] Creating secondary author user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    # --- 3. Redis Integration ---
    echo "[Redis] Configuring Object Cache..."
    
    # MISSING LINE 1: Force WordPress to use the direct filesystem method
    wp config set FS_METHOD direct --type=constant --allow-root
    
    # 2. Tell WordPress where to find the Redis server
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    
    # 3. Download and activate the plugin
    wp plugin install redis-cache --activate --allow-root
    
    # MISSING LINE 2: Give www-data ownership BEFORE Redis tries to write the drop-in file
    chown -R www-data:www-data /var/www/html
    
    # 5. Deploy the object-cache.php drop-in
    wp redis enable --allow-rootdis-cache --activate --allow-root
    wp redis enable --allow-root

    echo "[Success] Initial setup complete!"
else
    echo "[Info] wp-config.php found. Skipping initialization."
fi

echo "[System] Setting strict directory permissions..."
# --- Fix Redis permissions ---
# 1. Give ownership of wp-content to the PHP user
chown -R www-data:www-data /var/www/html/wp-content

# 2. Give read/write/execute permissions to the owner and group
chmod -R 775 /var/www/html/wp-content

# --- 5. Daemon Handoff ---
# The -F flag binds PHP-FPM to the foreground so the Docker container doesn't exit.
echo "[System] Starting PHP-FPM (v7.4)..."
exec /usr/sbin/php-fpm7.4 -F