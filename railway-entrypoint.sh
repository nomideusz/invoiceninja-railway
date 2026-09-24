#!/bin/sh
set -eu

# Each queue worker holds ~90 MB. The image starts two; below 2 GB of plan memory
# one is plenty and leaves room for Chrome when it renders a PDF.
mem=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
if [ "$mem" != max ] && [ "$mem" -lt 2147483648 ]; then
  sed -i 's/^numprocs=2$/numprocs=1/' /etc/supervisor/conf.d/programs.conf
fi

# On a fresh deploy MariaDB may still be initializing, and the image's init.sh
# (migrations, first admin account) exits on the first failed query.
i=0
until MYSQL_PWD="$DB_PASSWORD" mariadb -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USERNAME" -e 'select 1' "$DB_DATABASE" >/dev/null 2>&1; do
  i=$((i + 1))
  [ "$i" -lt 90 ] || { echo "railway: database not reachable after 3 minutes"; exit 1; }
  sleep 2
done
exec /usr/local/bin/init.sh "$@"
