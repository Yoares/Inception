FROM debian:bullseye

RUN apt update && apt install -y \
    php-fpm \
    php-mysql \
    curl \
    wget

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY ./tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# 4. Copy our custom PHP-FPM configuration
COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

WORKDIR /var/www/html

# 7. Expose the port NGINX will use to talk to PHP
EXPOSE 9000

# 8. Run the setup script
CMD ["/usr/local/bin/setup.sh"]