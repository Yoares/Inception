# 1. Choose the operating system
FROM debian:bullseye

# 2. Install MariaDB (added -y to avoid hanging)
RUN apt update && apt install mariadb-server -y

# 3. Copy custom configuration to allow network connections
COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY ./tools/script.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 3306

CMD ["/usr/local/bin/setup.sh"]