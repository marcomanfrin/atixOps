#!/bin/bash
# Bootstrap script: obtain the first Let's Encrypt certificate for job.atix.it
# Run ONCE before the first HTTPS launch: chmod +x init-letsencrypt.sh && ./init-letsencrypt.sh

set -e

DOMAIN="job.atix.it"
EMAIL="marco.manfrin04@gmail.com"   # change if needed
STAGING=0                            # set to 1 to test against Let's Encrypt staging servers

# Paths inside the letsencrypt volume (accessed via a temporary container)
LIVE_DIR="/etc/letsencrypt/live/$DOMAIN"

echo "### Creating dummy certificate for $DOMAIN ..."
docker compose run --rm --entrypoint /bin/sh certbot \
  -c "mkdir -p $LIVE_DIR && openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout $LIVE_DIR/privkey.pem \
    -out $LIVE_DIR/fullchain.pem \
    -subj '/CN=localhost'"

echo "### Starting nginx with dummy certificate ..."
docker compose up -d nginx

echo "### Waiting for nginx to be ready ..."
sleep 5

echo "### Removing dummy certificate ..."
docker compose run --rm --entrypoint /bin/sh certbot \
  -c "rm -rf /etc/letsencrypt/live/$DOMAIN /etc/letsencrypt/archive/$DOMAIN /etc/letsencrypt/renewal/$DOMAIN.conf"

echo "### Requesting Let's Encrypt certificate for $DOMAIN ..."
STAGING_FLAG=""
if [ "$STAGING" -eq 1 ]; then
  STAGING_FLAG="--staging"
fi

docker compose run --rm --entrypoint "\
  certbot certonly \
    $STAGING_FLAG \
    --webroot \
    --webroot-path /var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN" certbot

echo "### Reloading nginx with real certificate ..."
docker compose exec nginx nginx -s reload

echo ""
echo "Done! HTTPS is now active for https://$DOMAIN"
echo "Run 'docker compose up -d' to start all services."
