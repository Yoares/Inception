#!/bin/bash

# 1. Modify MariaDB to listen to the network, not just localhost
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mysql/mariadb.conf.d/50-server.cnf

# 2. Start the MariaDB service temporarily in the background
service mariadb start
sleep 2

# 3. Create the database and users using our .env variables
mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
mysql -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -e "FLUSH PRIVILEGES;"

# 4. Shut down the temporary background service
mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown

# 5. Start MariaDB in the foreground safely
exec mysqld_safe