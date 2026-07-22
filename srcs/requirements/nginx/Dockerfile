FROM debian:bullseye

RUN apt update && apt install -y nginx openssl

#to store certificate
RUN mkdir -p etc/nginx/ssl

RUN openssl req \
    -x509 \
    -nodes \
    -out /etc/nginx/ssl/inception.crt \
    -keyout /etc/nginx/ssl/inception.key \
    -subj "/C=MA/ST=Rehamna/L=BenGuerir/O=42/OU=1337/CN=ykhoussi.42.fr/UID=ykhoussi"

COPY conf/nginx.conf \
     /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]