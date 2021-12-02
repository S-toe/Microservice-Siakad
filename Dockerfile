FROM php:8.0-fpm-alpine

# Arguments defined in docker-compose.yml
ARG user
ARG uid

RUN apk update && apk add\
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    libmcrypt-dev \
    libmemcached-dev \
    imagemagick-dev

# Clear cache
RUN rm -rf /var/lib/apt/lists/*

# add bash
RUN apk add --no-cache --upgrade bash

# install pgsql
RUN set -ex \
  && apk --no-cache add \
    postgresql-dev

# Install PHP extensions
RUN apk add --no-cache \
        $PHPIZE_DEPS \
        openssl-dev \
        oniguruma-dev

RUN apk update && apk add --no-cache libpq \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

RUN pecl install mcrypt redis memcached imagick
RUN docker-php-ext-enable mcrypt redis memcached imagick
RUN docker-php-ext-install mbstring exif pcntl bcmath gd xml

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# COPY ./auth.json /root/.composer/auth.json
# Create system user to run Composer and Artisan Commands
RUN adduser -D -G www-data -u $uid -h /home/$user $user
RUN addgroup $user root
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:www-data /home/$user && \
    chown -R $user:www-data /var/www

# Set working directory
WORKDIR /var/www

USER $user

