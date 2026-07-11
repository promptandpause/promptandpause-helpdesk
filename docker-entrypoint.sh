#!/bin/sh
set -e

echo "=== ENTRYPOINT STARTED ==="

echo "COMMIT_HASH: $(cat /app/commit_hash.txt 2>/dev/null || echo 'no-commit-hash')"

if [ ! -d "/app/nocobase" ]; then
  mkdir nocobase
fi

if [ ! -f "/app/nocobase/package.json" ]; then
  echo "Missing /app/nocobase/package.json"
  exit 1
fi

echo "=== Running postinstall ==="
cd /app/nocobase && yarn nocobase postinstall || echo "postinstall failed but continuing"

echo "=== Running db:auth ==="
cd /app/nocobase && yarn nocobase db:auth || echo "db:auth failed but continuing"

echo "=== Running generate-instance-id ==="
cd /app/nocobase && yarn nocobase generate-instance-id || echo "generate-instance-id failed but continuing"

echo "=== Running create-nginx-conf ==="
cd /app/nocobase && yarn nocobase create-nginx-conf || echo "create-nginx-conf failed but continuing"

echo "=== Creating nginx dirs ==="
mkdir -p /etc/nginx/sites-enabled /etc/nginx/conf.d

NGINX_CONF_PATH="/app/nocobase/storage/nocobase.conf"

if [ -f "${NGINX_CONF_PATH}" ]; then
  echo "=== Starting nginx ==="
  rm -f /etc/nginx/conf.d/nocobase.conf
  ln -s "${NGINX_CONF_PATH}" /etc/nginx/conf.d/nocobase.conf 2>&1 || echo "symlink failed"
  nginx 2>&1 || echo "nginx start failed"
  echo '=== nginx started ==='
else
  echo "=== nginx config not found at ${NGINX_CONF_PATH} ==="
fi

echo "=== Starting NocoBase app ==="
cd /app/nocobase && yarn start --quickstart 2>&1 || echo "start failed"

echo "=== ENTRYPOINT COMPLETED ==="
sleep infinity
