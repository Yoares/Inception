# 1. Choose the operating system
FROM debian:bullseye

# 2. Update the system and install PHP and tools
RUN apt-get update -y && \
    apt-get install -y php7.4-fpm php7.4-mysql curl tar

# 3. Create the folder where our website files will live
RUN mkdir -p /var/www/html

# 4. Copy our setup script into the container
COPY ./tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# 5. Open the port for PHP-FPM
EXPOSE 9000

# 6. Run the setup script
CMD ["/usr/local/bin/setup.sh"]