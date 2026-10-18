#!/bin/sh
set -eu
: "${BASIC_AUTH_USER:?Set BASIC_AUTH_USER in Railway Variables}"
: "${BASIC_AUTH_HASH:?Set BASIC_AUTH_HASH to a bcrypt password hash}"
: "${OPENSEO_UPSTREAM:?Set OPENSEO_UPSTREAM to the private app hostname and port}"
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
