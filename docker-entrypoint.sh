#!/bin/sh
set -e

cd /app/nocobase

echo "[custom] postinstall"
yarn nocobase postinstall 2>&1

echo "[custom] checking DB connection"
yarn nocobase db:auth 2>&1

echo "[custom] generating instance id"
yarn nocobase generate-instance-id 2>&1 || echo "[custom] instance id exists"

echo "[custom] writing nginx config"
cat > /etc/nginx/conf.d/nocobase.conf << 'NGINX'
upstream nocobase_upstream {
  server 127.0.0.1:13000;
}

server {
  listen 80;
  server_name _;
  client_max_body_size 100M;

  location ~ ^/api/ {
    proxy_pass http://nocobase_upstream;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location ~ ^/storage/ {
    root /app/nocobase;
  }

  location / {
    proxy_pass http://nocobase_upstream;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
NGINX

echo "[custom] removing default nginx config"
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

echo "[custom] starting nginx"
nginx
echo "[custom] nginx started"

echo "[custom] starting nocobase"
yarn start --quickstart 2>&1
echo "[custom] nocobase exited with code $?"
