# 1. Choose the operating system
FROM debian:bullseye

# 2. Update the system and install MariaDB
RUN apt-get update -y && \
    apt-get install -y mariadb-server

# 3. Copy our custom setup script into the container
COPY ./tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# 4. Open the port for MariaDB
EXPOSE 3306

# 5. Run the setup script when the container starts
CMD ["/usr/local/bin/setup.sh"]