#!/bin/sh
set -eu

if [ "$AUTH_MODE" != "$(cat /app/.railway-build-auth-mode)" ]; then
  echo 'AUTH_MODE changed after the image was built. Rebuild the Railway service.' >&2
  exit 1
fi

pnpm exec tsx scripts/selfhost-preflight.ts
# Railway mounts /app/.wrangler at runtime, not during build or pre-deploy.
# Restore build metadata hidden by the volume; keep database state intact.
mkdir -p /app/.wrangler/deploy
cp /app/.railway-deploy-config.json /app/.wrangler/deploy/config.json
pnpm run db:migrate:local
# Runtime variables must win even if tooling restores build-time .dev.vars.
rm -f /app/dist/server/.dev.vars /app/dist/open_seo_audit/.dev.vars
exec node scripts/selfhost-scheduler.mjs
