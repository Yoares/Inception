#!/bin/bash

#If the database folder doesn't exist, initialize MariaDB.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing the database..."

    service mariadb start 

    sleep 2

    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

    # Create the user and grant privileges (Notice the '%' to allow network connections)
    mysql -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';";
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';";

    # Set the root password
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';";

    # Apply changes
    mysql -e "FLUSH PRIVILEGES;"
    
    # 4. Shut down the temporary service gracefully using the new root password
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

else
    echo "Database already exists. Skipping initialization."
fi

# 5. The PID 1 Handoff
# Replace the bash script process with the MariaDB daemon in the foreground
echo "Starting MariaDB daemon..."
exec mysqld_safe
