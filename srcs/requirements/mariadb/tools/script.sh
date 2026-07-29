#!/bin/bash

#If the database folder doesn't exist, initialize MariaDB.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing the database..."
    service mariadb start 
    sleep 2

    # READ SECRETS DIRECTLY FROM THE FILES
    DB_PASS=$(cat /run/secrets/db_password)
    DB_ROOT_PASS=$(cat /run/secrets/db_root_password)

    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    
    # Use the local $DB_PASS variable
    mysql -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${DB_PASS}';";
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';";
    
    # Use the local $DB_ROOT_PASS variable
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';";
    
    mysql -e "FLUSH PRIVILEGES;"
        
    # Shut down using the secret password
    mysqladmin -u root -p"${DB_ROOT_PASS}" shutdown
else
    echo "Database already exists. Skipping initialization."
fi

echo "Starting MariaDB daemon..."
exec mysqld_safe