# Content Factory Foreign Server Runbook

[Back to Runbooks](../README.md)

## Scope

`diaverse-content` runs as a separate service on an overseas content server, while public URLs stay on the main Diaverse domain:

```text
https://diaverse.app/ru/learn/*
https://diaverse.app/_diaverse-content/_next/*
```

The main Diaverse edge proxy forwards only those content paths to the content upstream over HTTPS. `diaweb` continues to own `/ru`, `/ru/club`, `/ru/staff`, product flows, and the root SEO aggregator.

## Runtime Placement

| Surface | Owner | Placement |
| --- | --- | --- |
| Public content pages | `diaverse-content` | overseas content server |
| Content assets | `diaverse-content` | S3-compatible object storage/CDN |
| Main public domain | edge proxy | `diaverse-prod` / `diaverse-dev` |
| Staff browser shell | `diaweb` | existing Diaverse web runtime |
| Staff identity/RBAC | `diaverseapi` | existing Diaverse API runtime |

The content upstream should expose only the application HTTPS listener to the edge proxy. Do not expose the content database, Prisma Studio, admin APIs, or internal import APIs publicly.

`diaverse-content/compose.production.yml` starts the app container only and binds it to a local interface by default:

```text
CONTENT_HTTP_BIND=127.0.0.1
CONTENT_HTTP_PORT=3000
```

Run a reviewed TLS proxy on the content server in front of that local port. The Diaverse edge proxy should call the content server over HTTPS, not the raw Next.js container port.

The container command is `node scripts/start-production.mjs`. Startup order:

1. Log safe runtime context with `INFO [content.startup] boot`.
2. Run `node scripts/migrate-deploy.mjs`.
3. Log database connectivity as `INFO [content.startup] database_ready`.
4. Start the standalone Next server.

Startup logs may include service name, version, environment label, content areas, locale, storage driver, and feature flags. They must not include database URLs, JWT secrets, cookies, S3 credentials, raw headers, or private proxy config.

## Required Environment Contract

Production media storage is S3-compatible object storage. Local container filesystem media is allowed only for local development.

Required production media env values:

```text
STORAGE_DRIVER=s3
S3_BUCKET=<set on server>
S3_PUBLIC_BASE_URL=<set on server>
S3_ENDPOINT=<set when provider requires it>
S3_REGION=<set when provider requires it>
```

Required service/runtime env values:

```text
CONTENT_ENVIRONMENT=production
NEXT_PUBLIC_APP_URL=https://diaverse.app
CONTENT_PUBLIC_BASE_URL=https://diaverse.app
CONTENT_CANONICAL_BASE_URL=https://diaverse.app
CONTENT_MOUNT_PATH=/ru/learn
CONTENT_STATIC_ROUTE_PREFIX=/_diaverse-content
CONTENT_ASSET_PREFIX=/_diaverse-content
INTERNAL_JWT_TRUSTED_ISSUERS=diaweb
CONTENT_IMPORTS_ENABLED=false
DIAVERSE_API_URL=<private or protected Diaverse API upstream>
DIAVERSE_ANALYTICS_API_BASE=<private or protected Diaverse API upstream>
```

If the disabled `aibot` import bridge is enabled later, add `aibot` to `INTERNAL_JWT_TRUSTED_ISSUERS`, set the matching shared secret out of band, and keep `CONTENT_IMPORTS_ENABLED=false` until the staff approval flow, idempotent import reuse, and draft-only behavior are smoke-tested.

Write-capable media flows additionally require credentials or an instance-profile equivalent and an explicit feature flag:

```text
UPLOADS_ENABLED=true
S3_ACCESS_KEY_ID=<set on server>
S3_SECRET_ACCESS_KEY=<set on server>
```

Keep these disabled until product approval and restore checks are complete:

```text
IMAGE_GENERATION_ENABLED=false
TRANSCRIPT_IMPORT_ENABLED=false
BOOKMARKS_ENABLED=false
LOCAL_ANALYTICS_ENABLED=false
H1_TESTING_ENABLED=false
DIGEST_ENABLED=false
INDEXNOW_ENABLED=false
GSC_SYNC_ENABLED=false
```

## Media URL And Cache Policy

Media URLs should be generated from `S3_PUBLIC_BASE_URL` plus object keys owned by `diaverse-content`. Public media objects may be cached as immutable assets:

```text
Cache-Control: public, max-age=31536000, immutable
```

Do not generate public media URLs from private S3 endpoints, temporary signed URLs, or the content app container hostname. If a CDN is added, point `S3_PUBLIC_BASE_URL` at the CDN origin and keep object keys stable.

## Backup And Restore

Back up these independently:

| Data | Backup expectation |
| --- | --- |
| Content Postgres database | scheduled logical dump plus provider snapshot if available |
| S3 media bucket | provider lifecycle/versioning or scheduled object copy |
| Runtime env file/secrets | server-side secret store or encrypted ops backup |
| Docker image/tag | GitLab registry or retained release artifact |

Restore check before enabling uploads/generated media:

1. Restore the database into a staging content runtime.
2. Restore or attach the media bucket snapshot/copy.
3. Open a published guide with a hero image through the edge path.
4. Confirm the image still loads from `S3_PUBLIC_BASE_URL`.
5. Recreate the app container and repeat the image smoke check.

## Edge Proxy Requirements

Forward these paths from the Diaverse edge to the overseas content upstream:

```text
/ru/learn/*
/_diaverse-content/_next/static/*
/_diaverse-content/_next/image
```

Do not forward browser cookies to the content upstream. Future staff/internal calls should use short-lived signed internal JWTs from `diaweb` BFF routes, not user browser cookies.

Recommended request behavior:

| Header / behavior | Requirement |
| --- | --- |
| `Host` | preserve `diaverse.app` when the upstream needs canonical host context, or set an explicitly reviewed content upstream host |
| `X-Forwarded-Proto` | set to `https` |
| `X-Forwarded-Host` | set to the public host |
| `X-Request-Id` | preserve or generate for correlation |
| `Cookie` | strip browser cookies |
| query strings | preserve for normal public navigation, but do not log raw query strings |

Expected cache behavior:

| Path | Cache |
| --- | --- |
| `/ru/learn/*` | `s-maxage=3600`, `stale-while-revalidate=86400` |
| `/_diaverse-content/_next/static/*` | immutable |
| `/_diaverse-content/_next/image` | image optimizer cache |
| admin/internal/API paths | blocked publicly or `no-store` |

## Smoke Checks

After deploy and proxy wiring:

```bash
CONTENT_SMOKE_BASE_URL=https://<content-upstream-health-host> npm run smoke:foundation
```

Manual equivalents:

```text
GET https://diaverse.app/ru/learn/club/<slug>
GET https://diaverse.app/ru/learn/game/<slug>
GET https://diaverse.app/_diaverse-content/_next/static/<asset>
GET https://<content-upstream-health-host>/api/health
GET https://diaverse.app/sitemap.xml
GET https://diaverse.app/robots.txt
GET https://diaverse.app/llms.txt
```

Expected:

- content paths are served by `diaverse-content`
- `/_diaverse-content/_next/*` assets load without using `diaweb` root `/_next/*`
- `/ru/club` still resolves to the Diaverse club product route
- public access to content admin/internal APIs returns `401`, `403`, or `404`
- `diaweb` staff BFF can call `/internal/v1/readiness` with a short-lived internal JWT
- `diaweb` root SEO files include public content fragments and exclude drafts/internal/staff/admin routes
- disabled capabilities emit `WARN [content.capability] disabled_access` without secrets

## Rollback

Rollback should be reversible at the edge:

1. Disable `/ru/learn/*` and `/_diaverse-content/_next/*` proxy routes.
2. Keep `diaweb`, `diaverseapi`, club, game, auth, and payment routes untouched.
3. Keep the content database and media bucket intact for investigation.
4. Re-enable the previous content image tag only after database migration compatibility is confirmed.
