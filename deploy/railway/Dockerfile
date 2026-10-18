# Build before container startup so Railway runtime RAM is reserved for the app.
FROM node:22

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.30.1 --activate
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches ./patches
RUN pnpm install --frozen-lockfile
COPY . .

# Railway passes service variables matching ARG names to the Docker build.
# Only self-host modes are supported by this image; hosted has additional
# client build settings and billing dependencies.
ARG AUTH_MODE=cloudflare_access
ENV AUTH_MODE=$AUTH_MODE
ENV VITE_SHOW_DEVTOOLS=false
ENV CLOUDFLARE_INCLUDE_PROCESS_ENV=true
RUN case "$AUTH_MODE" in cloudflare_access|local_noauth) ;; *) exit 1 ;; esac \
    && pnpm run build \
    && printf '%s' "$AUTH_MODE" > /app/.railway-build-auth-mode

# Vite exports build-time process.env into these files. Wrangler prioritizes
# .dev.vars over runtime process.env, which would hide Railway's runtime keys.
RUN rm -f /app/dist/server/.dev.vars /app/dist/open_seo_audit/.dev.vars

EXPOSE 3001
CMD ["sh", "deploy/railway/start.sh"]
