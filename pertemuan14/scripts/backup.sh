#!/bin/sh
# Mencadangkan database dan foto bukti ke folder backups/.
# Pemakaian:  sh scripts/backup.sh [berkas-compose] [berkas-env]
#   sh scripts/backup.sh                                       (pengembangan)
#   sh scripts/backup.sh docker-compose.prod.yml .env.prod     (produksi)
set -e
COMPOSE="docker compose --env-file ${2:-.env} -f ${1:-docker-compose.yml}"
WAKTU=$(date +%Y%m%d-%H%M%S)
mkdir -p backups

# --single-transaction: salinan konsisten tanpa mengunci tabel InnoDB.
$COMPOSE exec -T mysql sh -c 'exec mysqldump --single-transaction \
    --no-tablespaces -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip > "backups/db-$WAKTU.sql.gz"

$COMPOSE exec -T api tar -C /data -czf - uploads > "backups/uploads-$WAKTU.tar.gz"

echo "Cadangan tersimpan (WAKTU = $WAKTU):"
ls -lh "backups/db-$WAKTU.sql.gz" "backups/uploads-$WAKTU.tar.gz"