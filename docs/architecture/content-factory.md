# Diaverse Content Factory Architecture

## Scope

`diaverse-content` is a standalone content factory for public learn pages on the main Diaverse domain:

```text
https://diaverse.app/ru/learn/club/*
https://diaverse.app/ru/learn/game/*
```

The repo owns content state only: drafts, revisions, slugs, slug history, content search, public rendering, SEO fragments, and draft imports. It does not own game, club, payment, user, cabinet, or product truth.

## Ownership

| Surface | Owner | Rule |
| --- | --- | --- |
| Public learn pages | `diaverse-content` | Render `/ru/learn/:area/*` only |
| Main public domain | edge proxy + `diaweb` | Keep `diaverse.app` as the canonical domain |
| Staff browser shell | `diaweb` | `/ru/staff/content` and `/api/staff/content/*` |
| Staff identity/RBAC | `diaverseapi` | Content permissions come from backend staff access |
| Site analytics storage | `diaverseapi` | Content pages post sanitized visits through the content runtime proxy |
| Copywriting drafts | `aibot` | Optional draft import source, disabled by default |
| Codex content operator | local Codex session + `diaverse-content` | Manual metrics analysis and draft-only import flow |
| Content database/media | `diaverse-content` | Separate Postgres and S3-compatible media storage |

## Route Map

| Route | Public? | Owner | Notes |
| --- | --- | --- | --- |
| `/ru/learn/club/*` | yes | `diaverse-content` | Club SEO/learn content, not `/ru/club` product flow |
| `/ru/learn/game/*` | yes | `diaverse-content` | Game SEO/learn content |
| `/_diaverse-content/_next/*` | yes | `diaverse-content` | Isolated Next assets and image optimizer |
| `/ru/staff/content/*` | staff only | `diaweb` | Browser UI and permission-aware workspace |
| `/api/staff/content/*` | same-origin staff only | `diaweb` | BFF, never forwards browser cookies to content runtime |
| `/internal/v1/*` | internal only | `diaverse-content` | Requires short-lived internal JWT |
| `/admin`, `/api/admin`, `/login`, `/api/auth` | no | `diaverse-content` | Inherited Stateinik surfaces disabled unless explicit local migration flag is set |
| `/sitemap.xml`, `/robots.txt`, `/llms.txt` | yes | `diaweb` root owner | Aggregates content fragments from `diaverse-content` |

## Staff And Internal API Boundary

Staff users never call `diaverse-content` directly from the browser. The flow is:

```text
staff browser -> diaweb /api/staff/content/*
diaweb        -> diaverseapi /v1/staff/access/me
diaweb        -> short-lived HS256 internal JWT
diaweb        -> diaverse-content /internal/v1/*
```

Internal JWT policy:

- HS256 only.
- Maximum TTL is 300 seconds.
- `jti`, `iat`, `exp`, `sub`, issuer, and audience are required.
- Permissions are explicit, for example `content:read`, `content:create`, `content:edit`, `content:publish`, and `content.settings:manage`.
- Cookies, raw JWTs, and draft bodies must not be logged.

## SEO Ownership

`diaverse-content` exposes content-only internal SEO fragments:

```text
GET /internal/v1/seo/sitemap
GET /internal/v1/seo/llms
```

`diaweb` remains the root SEO owner for:

```text
/sitemap.xml
/robots.txt
/llms.txt
```

Drafts, previews, staff pages, admin routes, internal routes, and import APIs are excluded from public SEO outputs. Canonical content URLs use `https://diaverse.app/ru/learn/...`.

## Privacy And Analytics

Content pages use the same consent storage semantics as `diaweb`:

```text
diaweb:privacy-consent:v1 = accepted | rejected
```

No optional analytics or personalization runs until consent is accepted. Content visit tracking strips query strings and hashes from paths/referrers, excludes staff/admin/API/internal routes, and forwards visits to the existing `diaverseapi` site analytics pipeline through:

```text
diaverse-content browser -> /api/analytics/site-visit
diaverse-content server  -> diaverseapi /v1/analytics/site/visit
```

The content runtime does not forward browser cookies to `diaverseapi` for analytics.

## Codex Operator Flow

Content generation is manual and operator-driven. The server does not need a
server-side LLM API key for this flow:

```text
owner connects to content server
        |
        v
local Codex session reads metrics + content operator rules
        |
        v
Codex proposes topics, rewrites, and draft payloads
        |
        v
diaverse-content validates and imports draft-only guides
        |
        v
human reviews and publishes through admin
```

This replaces the earlier active AI Cofounder runtime for content operations.
AI Cofounder may remain in Git history as a strategy/prompt archive, but it
should not be required for article analysis, draft generation, import, review,
or publication.

## Draft Import Bridge

`aibot` can define a `content` or `stateinik` publish target, and local Codex
operator runs can send validated draft payloads. Imports are disabled by default
unless the content runtime explicitly enables them:

```text
COPYWRITING_CONTENT_PUBLISH_ENABLED=false
CONTENT_IMPORTS_ENABLED=false
```

When enabled later, imports remain draft-only and idempotent by:

```text
source_service + source_draft_id + source_draft_version + source_content_hash
```

The v1 payload ownership is:

- `aibot`: source draft id/version/hash, title, markdown body, and safe source metadata.
- local Codex operator: source draft id/version/hash, title, markdown body, topic ids, CTA metadata, and safe source metadata.
- publish target config: area, locale, author id, guide type, and difficulty.
- `diaverse-content`: guide id, slug conflict handling, draft lifecycle, revisions, and publish decisions.

Imports must never auto-publish.

## Deployment

Production runtime placement is an overseas content server behind the Diaverse edge proxy:

```text
diaverse-prod edge -> HTTPS content upstream -> local TLS proxy -> diaverse-content app container
```

The app container binds to localhost by default and starts with:

```text
node scripts/start-production.mjs
```

Startup order:

1. Log safe runtime context with `INFO [content.startup] boot`.
2. Run Prisma migrations.
3. Log database connectivity as `database_ready`.
4. Start the standalone Next server.

Production media storage must be S3-compatible object storage. Local container filesystem media is development-only.

## Rollback

Rollback should be possible at the edge without touching core Diaverse flows:

1. Remove or disable `/ru/learn/*` and `/_diaverse-content/_next/*` proxy routes.
2. Leave `diaweb`, `diaverseapi`, auth, game, club, payments, and mobile routes untouched.
3. Keep the content database and media bucket intact for investigation.
4. Re-enable an older content image only after Prisma migration compatibility is confirmed.

## Verification

Use these checks before treating a deploy as ready:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverse-content
npm test
npm run typecheck
npm run lint
npx prisma validate
npm run build
```

For a deployed upstream:

```bash
CONTENT_SMOKE_BASE_URL=https://<content-upstream-host> npm run smoke:foundation
```
