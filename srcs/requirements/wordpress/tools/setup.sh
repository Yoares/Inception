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
    
    # Read the secret password directly from the Docker secrets mount
    DB_PASS=$(cat /run/secrets/db_password)
    
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASS}" \
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

    # Force WordPress to use direct file access
    wp config set FS_METHOD direct --type=constant --allow-root

    # Configure Redis host and port
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root

    # Install and enable plugin
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root

    echo "[Success] Initial setup complete!"
else
    echo "[Info] wp-config.php found. Skipping initialization."
fi

# --- 4. Strict Permissions Fix ---
# Ensures www-data owns the directory so PHP-FPM can manage object-cache.php
echo "[System] Setting strict directory permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

# --- 5. Daemon Handoff ---
echo "[System] Starting PHP-FPM (v7.4)..."
exec /usr/sbin/php-fpm7.4 -F