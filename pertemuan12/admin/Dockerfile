FROM dunglas/frankenphp:1-php8.4

RUN install-php-extensions pdo_mysql intl zip opcache
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

WORKDIR /app

# Paket dipasang lebih dulu supaya layer ini di-cache.
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --no-scripts --no-autoloader

COPY . .
# Folder ini wajib ada agar artisan bisa jalan saat build.
RUN mkdir -p storage/framework/cache storage/framework/sessions \
             storage/framework/views storage/logs bootstrap/cache \
    && composer dump-autoload --optimize

EXPOSE 8080
CMD ["sh", "docker/start.sh"]