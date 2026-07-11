#!/bin/sh
set -e

cd /app/nocobase

echo "[custom] === NETWORK DIAGNOSTICS ==="
echo "[custom] hostname:" $(hostname 2>/dev/null || echo "N/A")
echo "[custom] DB_HOST=$DB_HOST"
echo "[custom] DB_PORT=$DB_PORT"
echo "[custom] DB_USER=$DB_USER"
echo "[custom] DB_DATABASE=$DB_DATABASE"
echo "[custom] testing DNS resolution of $DB_HOST..."
getent hosts "$DB_HOST" 2>/dev/null || nslookup "$DB_HOST" 2>/dev/null || echo "[custom] DNS lookup failed"
echo "[custom] testing TCP connection to $DB_HOST:$DB_PORT..."
timeout 5 sh -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>&1 && echo "[custom] TCP connection SUCCESS" || echo "[custom] TCP connection FAILED"

echo "[custom] === POSTINSTALL ==="
yarn nocobase postinstall 2>&1

echo "[custom] === TESTING PG CONNECTION WITH NODE ==="
node -e "
const { Client } = require('pg');
const c = new Client({
  host: process.env.DB_HOST || 'postgres.railway.internal',
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'promptandpause',
  database: process.env.DB_DATABASE || 'railway',
  ssl: { rejectUnauthorized: false }
});
c.connect().then(() => c.query('SELECT 1 as test').then(r => { console.log('PG direct connect OK:', JSON.stringify(r.rows)); process.exit(0); })).catch(e => { console.error('PG direct connect FAILED:', e.message); process.exit(1); });
" 2>&1 || echo "[custom] PG direct connect attempt failed"

echo "[custom] === DB:AUTH ==="
timeout 30 yarn nocobase db:auth 2>&1 || echo "[custom] db:auth timed out or failed"

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
