FROM php:8.3-apache

RUN apt-get update \
  && apt-get install -y --no-install-recommends libcurl4-openssl-dev libonig-dev \
  && docker-php-ext-install curl mbstring mysqli pdo_mysql \
  && a2enmod headers rewrite \
  && rm -rf /var/lib/apt/lists/*

COPY apache-map.conf /etc/apache2/sites-available/000-default.conf
