# Railway Docker deployment

## Railway domain with password protection

Use two services in the same Railway project and environment:

Configure the settings below in the dashboard. There is deliberately no root
`railway.json`: a shared root config can override the Dockerfile-path variable
and make the gateway build the app image. Railway marks Config as Code as
deprecated; use the dashboard settings for both services.

| Setting                            | open-seo                    | open-seo-gateway                    |
| ---------------------------------- | --------------------------- | ----------------------------------- |
| `RAILWAY_DOCKERFILE_PATH` variable | `deploy/railway/Dockerfile` | `deploy/railway/gateway/Dockerfile` |
| Healthcheck Path                   | `/api/health`               | `/healthz`                          |
| Healthcheck Timeout                | `600`                       | `120`                               |
| Replicas                           | `1`                         | `1`                                 |
| Restart policy                     | On Failure, 3 retries       | On Failure, 3 retries               |
| Serverless                         | Disabled                    | Disabled                            |

1. **open-seo**: apply the settings above, set `AUTH_MODE=local_noauth`
   and `PORT=3001`, attach a volume at `/app/.wrangler`, and leave public
   networking disabled (no public domain or TCP proxy).
2. **open-seo-gateway**: use the same repository and its settings above.
   Keep the source root at `/` and leave Railway Config File unset.
   Generate a Railway HTTPS domain only on this service, targeting port 8080.
3. Set gateway variables `PORT=8080`, `OPENSEO_UPSTREAM=open-seo.railway.internal:3001`
   (use the actual private hostname shown by Railway), `BASIC_AUTH_USER`, and
   `BASIC_AUTH_HASH`. Generate the bcrypt hash interactively with
   `docker run --rm -it caddy:2-alpine caddy hash-password`; do not commit it.
4. Set the app's `ALLOWED_HOST` to the gateway's generated hostname.
   Add provider keys to the app service, not the gateway.

Caddy requires authentication for every app route, including API and WebSocket
handshakes. Only `/healthz` is public and returns a fixed response. The gateway
fails to start if its credentials or upstream are missing. Railway provides
public TLS; do not expose this HTTP gateway directly outside Railway.
The shared login grants full admin access; it is not a multi-user permission
system. MCP clients requiring bearer authentication may not work behind this
browser-oriented Basic Auth gateway. Keep both services running (no sleeping).

## Cloudflare Access with your own domain

Deploy from the repository root with the `open-seo` settings above.
For legacy Config as Code services, `deploy/railway/railway.example.json` contains the same
Dockerfile, `/api/health`, 600-second startup timeout, and one-replica settings.
The app builds in the image build phase, before the runtime memory limit applies.
Leave Railway's build and start command overrides empty.

Before deploying:

1. Attach a Railway volume at `/app/.wrangler`. This preserves local D1, KV,
   R2, Durable Object, and workflow state across deployments. Keep one replica.
2. Set the service variables below. Railway supplies `PORT` automatically.
3. Keep Serverless/app sleeping disabled so the integrated scheduler can run.
4. Deploy, check logs and `/api/health`, then verify a project survives a restart.
   A healthy HTTP response confirms readiness; inspect the response's feature
   checks as well to confirm provider configuration.

| Variable                     | Value                                                            |
| ---------------------------- | ---------------------------------------------------------------- |
| `AUTH_MODE`                  | `cloudflare_access` for a public domain behind Cloudflare Access |
| `TEAM_DOMAIN`                | Your `https://<team>.cloudflareaccess.com` URL                   |
| `POLICY_AUD`                 | The Access application's audience tag                            |
| `ALLOWED_HOST`               | The exact public hostname, without `https://`                    |
| `DATAFORSEO_API_KEY`         | Base64 of your DataForSEO `login:password`                       |
| `OPENROUTER_API_KEY`         | Optional, for AI features                                        |
| `CONTEXT_API_KEY`            | Optional, for JavaScript-rendered site audits                    |
| `OPENSEO_TELEMETRY_DISABLED` | Optional: `1` to disable anonymous telemetry                     |

The image sets `CLOUDFLARE_INCLUDE_PROCESS_ENV=true` and
`VITE_SHOW_DEVTOOLS=false`. For Google integrations, additionally configure
`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `BETTER_AUTH_SECRET` with the
matching HTTPS callback URLs.

For a private service with no public domain or TCP proxy, `AUTH_MODE=local_noauth`
is supported. It grants every caller admin access; do not publish it without
an authenticating proxy. Configuring Cloudflare Access requires an actual Access
application and proxy/domain setup in addition to the variables above.

Changing `AUTH_MODE` requires rebuilding the image so client and server agree.
This Dockerfile deliberately supports only the two self-host modes. Do not
enable `hosted`, which requires a different build and additional hosted services.
Do not move migrations to a pre-deploy command: volumes are not mounted there.

Railway Trial has a 1 GB runtime memory limit. Moving the build into the image
avoids a known startup memory bottleneck, but does not guarantee large audits
fit within that limit. Monitor actual runtime usage. Redeployments with a volume
have downtime; configure volume backups before relying on stored data.

Local image check (Docker Engine must be running):

```sh
docker build -f deploy/railway/Dockerfile --build-arg AUTH_MODE=local_noauth -t open-seo:railway .
docker run --rm -p 127.0.0.1:3001:3001 -v open-seo-railway:/app/.wrangler -e PORT=3001 open-seo:railway
```

Provider keys belong in Railway Variables, never in Git or Docker build arguments.
