# Pinned: a moving tag (:latest, :5) would rebase every deploy of this template at
# once. Bump deliberately; migrations run on the next boot.
FROM invoiceninja/invoiceninja-debian:5.13.43

# The official image is PHP-FPM only and expects a separate nginx container that
# shares the public/ and storage/ volumes. A Railway volume attaches to one
# service, so nginx runs in here, under the image's supervisord.
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx \
 && rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/* /var/log/nginx/*
COPY nginx.conf /etc/nginx/nginx.conf
RUN nginx -t 2>&1

# PHP-FPM on loopback only (the stock `listen = 9000` is reachable from every
# service in the project) and without its per-request access log (Railway has HTTP logs).
RUN printf '[www]\nlisten = 127.0.0.1:9000\naccess.log = /dev/null\n' > /usr/local/etc/php-fpm.d/zz-railway.conf

# OPcache in the CLI gives every queue worker, the scheduler and each artisan call
# its own 256 MB cache, filled by the preload script at start: ~210 MB of shared
# memory that can't be reclaimed, and PDF rendering got OOM-killed on a 512 MB plan.
# The long-running CLI processes gain nothing from it; PHP-FPM keeps it.
RUN echo 'opcache.enable_cli=0' > /usr/local/etc/php/conf.d/zz-railway.ini

COPY supervisor.conf /etc/supervisor/conf.d/railway.conf
COPY --chmod=0755 invoiceninja-backup invoiceninja-restore railway-entrypoint.sh /usr/local/bin/

# Fixed settings for this stack; the template's variables cover the rest.
# No Redis: queue in MariaDB (jobs survive restarts), cache and sessions on the volume.
# Logs go to Railway only; the default also appends to storage/logs/laravel.log on
# the volume, which nothing rotates.
ENV PORT=8080 APP_ENV=production APP_DEBUG=false IS_DOCKER=true REQUIRE_HTTPS=true \
    PDF_GENERATOR=snappdf PHANTOMJS_PDF_GENERATION=false FILESYSTEM_DISK=debian_docker \
    DB_CONNECTION=mysql QUEUE_CONNECTION=database CACHE_DRIVER=file SESSION_DRIVER=file \
    SCOUT_DRIVER=null LOG_CHANNEL=stderr

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
# Setting ENTRYPOINT clears the base image's CMD; init.sh only runs its setup for this exact command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
