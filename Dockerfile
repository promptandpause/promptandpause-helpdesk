FROM nocobase/nocobase:latest-full

RUN mkdir -p /etc/nginx/sites-enabled /etc/nginx/conf.d

COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

CMD ["/app/docker-entrypoint.sh"]
