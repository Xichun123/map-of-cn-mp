FROM php:8.3-apache

RUN apt-get update \
  && apt-get install -y --no-install-recommends libcurl4-openssl-dev libonig-dev libjpeg62-turbo-dev libpng-dev libwebp-dev \
  && docker-php-ext-configure gd --with-jpeg --with-webp \
  && docker-php-ext-install curl mbstring mysqli pdo_mysql gd exif \
  && a2enmod headers rewrite \
  && rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
  'upload_max_filesize=50M' \
  'post_max_size=55M' \
  'memory_limit=256M' \
  'max_file_uploads=20' \
  'date.timezone=Asia/Shanghai' \
  > /usr/local/etc/php/conf.d/uploads.ini

COPY apache-map.conf /etc/apache2/sites-available/000-default.conf
