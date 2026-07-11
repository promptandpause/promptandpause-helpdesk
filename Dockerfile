FROM nocobase/nocobase:latest-full

ENV APP_PORT=13000

COPY docker-entrypoint.sh /app/docker-entrypoint-custom.sh
RUN chmod +x /app/docker-entrypoint-custom.sh && \
    mkdir -p /etc/nginx/sites-enabled /etc/nginx/conf.d

EXPOSE 13000

CMD ["/app/docker-entrypoint-custom.sh"]
