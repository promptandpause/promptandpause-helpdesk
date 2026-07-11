FROM nocobase/nocobase:latest-full

ENV APP_PORT=13000
ENV NOCOBASE_PROXY_PROVIDER=nginx

RUN mkdir -p /etc/nginx/sites-enabled /etc/nginx/conf.d && \
    rm -f /etc/nginx/conf.d/default.conf

WORKDIR /app/nocobase

EXPOSE 13000

CMD yarn nocobase postinstall && yarn nocobase db:auth && yarn start --quickstart
