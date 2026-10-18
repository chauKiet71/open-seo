FROM caddy:2-alpine
COPY deploy/railway/gateway/Caddyfile /etc/caddy/Caddyfile
COPY deploy/railway/gateway/start.sh /usr/local/bin/start-gateway
CMD ["sh", "/usr/local/bin/start-gateway"]
