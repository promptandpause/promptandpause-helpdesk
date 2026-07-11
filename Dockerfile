FROM nocobase/nocobase:latest-full

ENV APP_PORT=13000

RUN mkdir -p /etc/nginx/sites-enabled /etc/nginx/conf.d && \
    chmod 755 /app/docker-entrypoint.sh

EXPOSE 13000
