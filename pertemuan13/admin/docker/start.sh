#!/bin/sh
set -e

if [ ! -f vendor/autoload.php ]; then
  composer install --no-interaction --prefer-dist
fi
[ -f .env ] || touch .env
mkdir -p storage/framework/cache storage/framework/sessions \
         storage/framework/views storage/logs bootstrap/cache

echo "Menunggu tabel milik FastAPI (Alembic)..."
until php artisan db:table kategori >/dev/null 2>&1; do sleep 2; done

php artisan migrate --force   # hanya tabel milik Laravel (admins, sessions, cache, jobs)
php artisan db:seed --force   # akun admin pertama
php artisan filament:upgrade  # salin aset CSS/JS Filament ke public/

exec frankenphp php-server --root public/ --listen :8080