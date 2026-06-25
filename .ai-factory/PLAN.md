# Implementation Plan: Diaverse Content Factory Structure

Branch: none
Created: 2026-06-25

## Settings

- Testing: yes
- Logging: standard
- Docs: yes

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Branch operations: none
- Planning assumptions: fast-plan defaults were applied because the user asked for senior/lead structure planning without an interactive preference pass.

## Goal

Prepare the structural foundation for a separate Diaverse content factory based on `C:\Users\Indigo\Desktop\stateinik-engine`, while serving public content as pages on the main Diaverse domain.

The plan is limited to repository structure, ownership, runtime boundaries, routing, staff/admin access, SEO plumbing, analytics, deployment, and verification. Actual SEO content strategy, editorial directions, article production, keyword clusters, and final content taxonomy are out of scope for this phase.

Target public URL shape:

```text
diaverse.app/ru/learn/club/...  -> club content vertical
diaverse.app/ru/learn/game/...  -> game content vertical
```

Target repository/service shape:

```text
diaverse/
|-- diaweb/            # browser app, BFF, staff shell, root SEO aggregator
|-- diaverseapi/       # auth, RBAC, analytics, product/game/club truth
|-- aibot/             # draft generation and optional publish bridge
`-- diaverse-content/  # new independent content factory repo/service
```

## Research Context

Source: `.ai-factory/RESEARCH.md` (Active Summary)

The current active research summary is about factory map/layout conventions and is not a requirement source for this content-factory plan. It remains intentionally unrelated.

## Repository Matrix

| Repository | Path | Affected | Current branch/status observed | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | yes | dirty, existing unrelated docs/AIF changes | workspace map, plan, docs, scripts, GBrain sources |
| `diaverse-content` | `C:\Users\Indigo\Desktop\diaverse\diaverse-content` | yes, new | does not exist yet | standalone content factory service |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `master`, dirty unrelated changes | main-domain shell, staff content UI/BFF, root SEO aggregator |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `main`, dirty unrelated changes | RBAC permissions, staff module registry, site analytics endpoint |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | later/skeletal | `dev`, dirty unrelated `docker-compose.prod.yml` | optional draft-to-content publish bridge |
| `diaverse-mobile` | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | `main`, clean | not affected by web content factory |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | `dev`, clean | not affected |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | `dev`, clean | not affected |

Before implementation, either preserve/stash/commit unrelated dirty work in `diaweb`, `diaverseapi`, and `aibot`, or implement only the new `diaverse-content` and root documentation tasks first.

## Architecture Decisions

- Public content should live on the main domain as pages, not on a separate root domain.
- Do not mount content directly under `/ru/club`; that path remains reserved for club onboarding/cabinet behavior.
- Use `/ru/learn/club/*` and `/ru/learn/game/*` as the first stable public path contract.
- Create a new independent child repository named `diaverse-content`; do not import Stateinik into `diaweb`.
- Keep `diaverse-content` isolated with its own Next.js runtime, Prisma schema, and Postgres database.
- Keep Stateinik's Next 14 / React 18 stack initially. Do not combine it with `diaweb` Next 16 / React 19 during the foundation phase.
- Replace or hard-disable Stateinik's standalone public admin auth. Staff access must go through `diaweb` + `diaverseapi` RBAC.
- `diaweb` owns browser staff entrypoints and same-origin BFF routes.
- `diaverseapi` owns user/session/RBAC truth and existing site analytics storage.
- `diaverse-content` owns content models, drafts, revisions, slugs, public rendering, content search, and content SEO fragments.
- `aibot` may later publish approved drafts into `diaverse-content`, but it must not own public content state.
- Root SEO files on `diaverse.app` must have one owner/aggregator; content service should expose fragments, not fight `diaweb` for `/sitemap.xml`, `/robots.txt`, or `/llms.txt`.
- A path-mounted Next.js app cannot share the root `/_next/*` namespace with `diaweb`; `diaverse-content` needs an explicit `basePath` or isolated asset prefix before same-domain routing is enabled.
- Stateinik's current global slug uniqueness is not enough for two content directions. The content model needs `area` and `locale` namespaces before production content is imported.
- Content pages must use Diaverse privacy/consent semantics before sending analytics events. The new runtime must not bypass the existing `PrivacyConsentGate` behavior.
- Uploaded/generated media must be backed by persistent object storage or a reviewed persistent volume; local container-layer uploads are not acceptable for production content.
- Stateinik's newsletter, digest, bookmarks, internal analytics, H1 experiments, GSC, and IndexNow features must be explicitly enabled or disabled so they do not duplicate Diaverse product systems by accident.

## Second-Pass Refinement Notes

- The first plan covered the ownership split, but under-specified runtime details that matter most in production: path-mounted Next assets, database namespaces, media persistence, and consent parity.
- This revision keeps the same direction and adds foundation tasks that should happen before route wiring and editorial UI work.
- `aibot` publishing remains useful, but it should stay behind the structural work and use idempotent, versioned contracts once content schema is stable.
- Existing `docs-health.ps1` currently fails on an invalid-path parsing case in this workspace; that should be fixed or isolated before docs health becomes a release gate for this initiative.

## Tasks

### Phase 1: Workspace And Repository Foundation

- [x] Task 1: Register `diaverse-content` as a first-class child repository in workspace metadata.

  Files:
  - `AGENTS.md`
  - `README.md`
  - `.gitignore`
  - `.ai-factory/DESCRIPTION.md`
  - `.ai-factory/ARCHITECTURE.md`
  - `docs/README.md`
  - `scripts/aif-workspace-status.ps1`
  - `scripts/aif-workspace-branch.ps1`
  - `scripts/gbrain-sources.ps1`

  Deliverable:
  - Add `diaverse-content` to the workspace map as an independent child repository.
  - Add a GBrain source id such as `diaverse-content-code`.
  - Include `diaverse-content` in workspace status/branch helpers without changing behavior for existing repos.
  - Clarify that the root repository still tracks only docs/AIF/scripts and not child repo source.

  Logging:
  - Workspace helper scripts should log `INFO` when `diaverse-content` exists and `WARN` when it is missing.
  - Do not log local env paths beyond the safe workspace path already used by existing helpers.

  Dependencies:
  - None.

- [x] Task 2: Create the new `diaverse-content` repository from the Stateinik engine baseline.

  Files:
  - New repo root: `C:\Users\Indigo\Desktop\diaverse\diaverse-content`
  - Source baseline: `C:\Users\Indigo\Desktop\stateinik-engine`
  - New/updated files inside `diaverse-content`: `package.json`, `README.md`, `AGENTS.md`, `.env.example`, `.gitignore`, `LICENSE`, `Dockerfile`, `docker-compose.yml`

  Deliverable:
  - Copy the Stateinik baseline into `diaverse-content` without mutating the original `stateinik-engine` folder.
  - Initialize `diaverse-content` as its own git repository.
  - Rename package metadata to `diaverse-content` or `diaverse-learn`.
  - Preserve Stateinik license/attribution.
  - Mark the service as Diaverse-owned and private unless a later product decision says otherwise.
  - Add a repo-local `AGENTS.md` describing that this repo owns public content rendering and content admin APIs only.

  Logging:
  - Add setup/script logs for scaffold and seed commands using `INFO [content.setup]`.
  - Runtime logs are not required yet except existing Next/Prisma failures.

  Dependencies:
  - Should follow Task 1, but can be done in isolation if existing dirty workspace state blocks root edits.

- [x] Task 3: Stabilize the `diaverse-content` base stack and environment contract.

  Files:
  - `diaverse-content/package.json`
  - `diaverse-content/.env.example`
  - `diaverse-content/src/site.config.ts`
  - `diaverse-content/prisma/schema.prisma`
  - `diaverse-content/src/app/api/health/route.ts` or equivalent health route
  - `diaverse-content/Dockerfile`
  - `diaverse-content/docker-compose.yml`

  Deliverable:
  - Keep Next 14 / React 18 / Prisma 5 initially.
  - Set Russian defaults: `DEFAULT_LOCALE=ru`, `FTS_LANGUAGE=russian` or `simple` after verifying the Postgres dictionary in target environments.
  - Define server-only envs for database, internal JWT validation, public base URL, service name, and analytics API base.
  - Add a health endpoint that verifies app boot and optionally database connectivity.
  - Ensure migrations and seed commands are explicit and safe for a new standalone database.

  Logging:
  - Health route logs `INFO [content.health]` for failed dependency checks only, not for every successful probe.
  - Migration/seed scripts log started/completed/failed states and never log database URLs.

  Dependencies:
  - Requires Task 2.

- [x] Task 3A: Adapt the content data model for area, locale, and slug namespaces.

  Files:
  - `diaverse-content/prisma/schema.prisma`
  - `diaverse-content/prisma/migrations/*`
  - `diaverse-content/src/site.config.ts`
  - Stateinik slug history, redirects, topic, series, guide, and concept query helpers

  Deliverable:
  - Add explicit content area support, initially `club` and `game`.
  - Add explicit locale support, initially `ru`, without blocking later `en` or other locales.
  - Replace global public slug uniqueness with scoped uniqueness such as `(area, locale, slug)` for guides, concepts, topics, and series where public URLs depend on slug.
  - Scope slug history and redirects by area and locale so `/ru/learn/club/*` and `/ru/learn/game/*` cannot steal each other's redirects.
  - Backfill existing Stateinik seed/demo records into a safe default namespace, or drop demo data during repo extraction if it is not needed.
  - Update all public and admin lookup code to require area and locale instead of resolving by naked slug.

  Logging:
  - Log failed slug resolution with `area`, `locale`, normalized slug, request id, and route family.

  Dependencies:
  - Requires Task 3.

- [x] Task 3B: Normalize path-mounted Next.js runtime assets and cache headers.

  Files:
  - `diaverse-content/next.config.mjs`
  - `diaverse-content/src/site.config.ts`
  - `diaverse-content/app/*`
  - `diaverse-content/public/*`
  - edge proxy config/runbook docs under `docs/infrastructure/*`

  Deliverable:
  - Decide and implement one mounting strategy:
    - preferred: `basePath=/ru/learn` for public content runtime, with internal API/admin routes handled separately; or
    - explicit `assetPrefix`/static route isolation if `basePath` cannot cover all required routes.
  - Ensure Stateinik public routes, `_next/static`, images, OG images, search, and API endpoints do not collide with `diaweb` assets on the same domain.
  - Add cache policy notes for static assets, public content pages, preview/admin APIs, and SEO files.
  - Add local/staging verification URLs for both `club` and `game` routes.

  Logging:
  - At startup, warn if configured public URL, base path, or asset prefix is inconsistent with the route mount.

  Dependencies:
  - Requires Task 3.

- [x] Task 3C: Set up the new repository remote, CI, and release skeleton.

  Files:
  - `diaverse-content/.github/workflows/*` or chosen CI provider equivalent
  - `diaverse-content/Dockerfile`
  - `diaverse-content/package.json`
  - `diaverse-content/README.md`
  - workspace helper scripts under `scripts/*`

  Deliverable:
  - Create the `diaverse-content` git repository with a clean initial branch and remote.
  - Add CI for install, lint, typecheck, Prisma validation, tests, build, and Docker image build.
  - Add required secret/env placeholders without committing private values.
  - Register the repo in workspace status/branch helpers so future multi-repo work includes it when selected.
  - Define branch and release conventions consistent with the existing child repos.

  Logging:
  - CI should emit clear step names and fail on missing required public configuration without printing secret values.

  Dependencies:
  - Requires Task 2.

  Progress:
  - Local `diaverse-content` remote configured as `ssh://git@gitlab.diaverse.app:2222/diaverse/diaverse-content.git`.
  - CI/release skeleton prepared locally in `diaverse-content`.
  - GitLab project is reachable and `main` pushed to `origin/main` at `e706fd5`.

- [x] Task 3D: Decide media storage and prune duplicate Stateinik capabilities.

  Files:
  - `diaverse-content/src/lib/capabilities.ts`
  - `diaverse-content/src/lib/storage/*`
  - `diaverse-content/prisma/schema.prisma`
  - `diaverse-content/.env.example`
  - `diaverse-content/Dockerfile` / compose files
  - `docs/runbooks/*`

  Deliverable:
  - Choose production media storage: S3-compatible object storage is preferred; a persistent volume is acceptable only if explicitly documented for the environment.
  - Disable illustration generation, transcript import, and upload flows unless persistent storage is configured.
  - Disable or quarantine Stateinik digest/newsletter, bookmarks, internal analytics, H1 experiments, GSC sync, and IndexNow until each is mapped to a Diaverse-owned product decision.
  - Keep only the foundation capabilities required for public SEO pages and staff editorial workflows.
  - Document how media URLs are generated, cached, backed up, and restored.

  Logging:
  - Log disabled capability access attempts as warnings with capability name and actor/request id.

  Dependencies:
  - Requires Tasks 2 and 3.

### Phase 2: Public Route Model And Reader Surface

- [x] Task 4: Add a stable content route abstraction for `/ru/learn/club/*` and `/ru/learn/game/*`.

  Files:
  - `diaverse-content/src/site.config.ts`
  - `diaverse-content/src/app/(content)/**`
  - `diaverse-content/src/lib/routes.ts` or equivalent route helper
  - `diaverse-content/src/lib/content-areas/**`
  - Focused tests under `diaverse-content/src/**/__tests__` or `diaverse-content/tests`

  Deliverable:
  - Introduce a route/content-area layer for `club` and `game` without creating actual SEO article content.
  - Public reader URLs resolve under `/ru/learn/:area/:slug`.
  - Keep slugs, redirects, canonical URLs, and preview URLs generated through route helpers only.
  - Keep Stateinik concepts/glossary behavior disabled or internal unless it fits the new route contract.

  Logging:
  - Log `WARN [content.routes]` when an unknown content area is requested.
  - Do not log full MDX content or draft bodies.

  Dependencies:
  - Requires Tasks 3, 3A, and 3B.

- [x] Task 5: Define same-domain routing and local/staging access.

  Files:
  - `diaverse-content/README.md`
  - `diaverse-content/docker-compose.yml`
  - root docs under `docs/infrastructure/`
  - optional `diaweb/frontend/next.config.ts` only if local development needs a rewrite fallback

  Deliverable:
  - Production target: `diaverse.app/ru/learn/*` routes to `diaverse-content`.
  - Development target: either `dev.diaverse.app/ru/learn/*` path route or temporary `learn.dev.diaverse.app` until path routing is verified.
  - Prefer reverse-proxy path routing for production; use `diaweb` rewrites only as a local/development fallback if needed.
  - Document that `diaweb` continues to own `/ru`, `/ru/shop`, `/ru/profile`, `/ru/raids`, `/ru/club`, and `/ru/staff`.
  - Verify the selected mount preserves `diaverse-content` static assets, image optimizer, OG image routes, and API routes without using `diaweb`'s `/_next/*` namespace.

  Logging:
  - Reverse proxy access logs should preserve request path and status.
  - Do not log query strings for content pages if they can contain campaign or auth parameters.

  Dependencies:
  - Requires Task 4.

### Phase 3: Staff Access, RBAC, And Internal API

- [x] Task 6: Add content staff permissions and staff module registration.

  Files:
  - `diaverseapi/app/cabinet/rbac/staff_modules.py`
  - RBAC permission seed/config files if present in `diaverseapi`
  - Backend tests under `diaverseapi/tests/`
  - `docs/features/cabinet/rbac-guide.md` if permission docs are updated

  Deliverable:
  - Add a `content` staff module with route `/staff/content`.
  - Add permissions such as `content:read`, `content:create`, `content:edit`, `content:publish`, and `content.settings:manage`.
  - Update RBAC seed/config so permissions are reproducible in new and existing environments.
  - Ensure only staff with content permissions can access content management.
  - Do not grant content permissions broadly by default unless existing role policy requires it.

  Logging:
  - RBAC denial should use existing auth/RBAC logs.
  - Do not log session cookies, Telegram init data, or internal JWTs.

  Dependencies:
  - Can run in parallel with Tasks 3-5 after dirty `diaverseapi` state is handled.

- [x] Task 7: Create the `diaweb` staff content shell and BFF boundary.

  Files:
  - `diaweb/frontend/app/[lang]/staff/content/**`
  - `diaweb/frontend/app/api/staff/content/**`
  - `diaweb/frontend/modules/content/**`
  - `diaweb/frontend/modules/staff/**` if staff navigation requires updates
  - Frontend tests under `diaweb/frontend/__tests__/modules/content/**`

  Deliverable:
  - Add a minimal staff content workspace shell at `/ru/staff/content`.
  - Add same-origin BFF routes under `/api/staff/content/*`.
  - BFF validates cabinet session/RBAC through existing `diaverseapi` flow.
  - Reuse the existing copywriting staff BFF pattern for session validation, permission filtering, short-lived internal JWT issuance, request ids, and upstream proxy error mapping.
  - BFF sends short-lived signed internal tokens to `diaverse-content`.
  - Browser cookies never reach `diaverse-content`.
  - Initial UI can be structural: list drafts/pages, open editor route, publish status placeholders, health/readiness panel.

  Logging:
  - Use `INFO [content.bff]` for proxied request start/end and upstream status.
  - Use `WARN [content.bff]` for RBAC denial and upstream mapping errors.
  - Never log draft bodies, cookies, or full internal JWTs.

  Dependencies:
  - Requires Task 6 for permission contract.
  - Requires Task 8 for internal API contract.

- [x] Task 8: Replace or lock down Stateinik admin with a Diaverse internal API contract.

  Files:
  - `diaverse-content/src/app/api/admin/**`
  - `diaverse-content/src/app/admin/**`
  - New `diaverse-content/src/app/internal/v1/**`
  - `diaverse-content/src/lib/auth/**`
  - `diaverse-content/src/lib/capabilities.ts`
  - Tests under `diaverse-content/tests` or `src/**/__tests__`

  Deliverable:
  - Disable public `/admin` and `/api/admin` exposure, or hard-gate them behind internal auth until the `diaweb` staff shell replaces them.
  - Add internal API routes for content list/read/create/update/preview/publish/readiness.
  - Validate short-lived internal JWTs issued by `diaweb`.
  - Mirror the proven `aibot` internal JWT expectations: HS256 only, max 300 second TTL, issuer/audience validation, clock skew handling, `jti`, and request correlation.
  - Map token permissions to content capabilities.
  - Preserve revisions, slug history, preview, and publish semantics from Stateinik where safe.

  Logging:
  - Use `INFO [content.api]` for state transitions such as draft created, draft updated, preview generated, published.
  - Use `WARN [content.auth]` for invalid/missing token or insufficient permission.
  - Use `ERROR [content.api]` for persistence failures with entity ids only.
  - Do not log MDX bodies, raw JWTs, cookies, or secret headers.

  Dependencies:
  - Requires Task 3.
  - Needed before Task 7 can fully work.

### Phase 4: SEO, Analytics, And Product Integration

- [x] Task 9: Add content SEO fragment endpoints and root SEO aggregation.

  Files:
  - `diaverse-content/src/app/sitemap.ts`
  - `diaverse-content/src/app/robots.ts`
  - `diaverse-content/src/app/llms.txt/route.ts` or current Stateinik equivalent
  - New internal SEO fragment routes in `diaverse-content/src/app/internal/v1/seo/**`
  - `diaweb/frontend/app/sitemap.ts`
  - `diaweb/frontend/app/robots.ts`
  - `diaweb/frontend/app/llms.txt/route.ts` or equivalent
  - Tests in `diaverse-content` and `diaweb`

  Deliverable:
  - `diaverse-content` exposes content-only sitemap/llms fragments.
  - `diaweb` or the edge/root SEO owner emits the public `diaverse.app/sitemap.xml`, `robots.txt`, and `llms.txt`.
  - Drafts, previews, internal routes, staff routes, and admin routes are `noindex`/excluded.
  - Canonical URLs always point to `https://diaverse.app/ru/learn/...`.
  - Keep IndexNow disabled until production routing and canonical URLs are verified.

  Logging:
  - Log `WARN [content.seo]` when SEO fragment generation skips invalid published content.
  - Do not log full unpublished content.

  Dependencies:
  - Requires Tasks 4 and 5.

- [x] Task 9A: Implement privacy and consent parity for public content pages.

  Files:
  - `diaverse-content/app/*/layout.tsx`
  - `diaverse-content/src/lib/privacy/*`
  - `diaverse-content/src/lib/analytics/*`
  - `diaweb/frontend/modules/privacy/*`
  - `docs/features/site-analytics.md`
  - `docs/product/*`

  Deliverable:
  - Match Diaverse privacy behavior before analytics or personalization runs on content pages.
  - Reuse the existing consent storage semantics where browser-safe, or document a compatible cross-runtime handoff.
  - Link public content pages to the canonical privacy policy and terms pages on the main site.
  - Ensure analytics strips query strings/hashes and avoids raw visitor identifiers, consistent with `diaweb`.
  - Decide whether no-consent users get no analytics or strictly essential aggregate events only; document the decision.

  Logging:
  - Log consent-gated analytics suppression only at debug level, without user-identifying values.

  Dependencies:
  - Requires Tasks 3B and 5.

- [x] Task 10: Add site analytics tracking for content pages.

  Files:
  - `diaverse-content/src/components/**` or app layout equivalent
  - `diaverse-content/src/lib/analytics/**`
  - `diaverseapi/app/analytics/**` only if the existing visit schema needs a safe `source`/segment extension
  - `docs/features/site-analytics.md`
  - Tests in `diaverse-content` and `diaverseapi` if backend changes are needed

  Deliverable:
  - Public content pages emit visits into the existing `diaverseapi` site analytics pipeline.
  - Staff/admin/internal routes are excluded.
  - Stored paths omit query strings and hashes, matching current site analytics privacy rules.
  - If backend schema is extended, add explicit migration/test coverage and keep existing `diaweb` tracker behavior unchanged.
  - Reconcile or disable Stateinik's local guide analytics so the same page view is not double-counted through two product analytics systems.

  Logging:
  - Client must not log visitor ids, referrers, URLs with query strings, or analytics payloads.
  - Backend uses existing sanitized analytics logs only.

  Dependencies:
  - Requires Tasks 4, 5, and 9A.

- [x] Task 11: Prepare the aibot-to-content publish bridge as a disabled/skeletal adapter.

  Files:
  - `aibot/app/application/use_cases/publish_draft.py`
  - `aibot/app/api/routes/publish_targets.py`
  - `aibot/app/domain/publish_config.py`
  - `aibot/tests/**`
  - `diaverse-content/src/app/internal/v1/imports/**`

  Deliverable:
  - Add or plan a `content` / `stateinik` publish target type that can send approved markdown/MDX drafts to `diaverse-content` as drafts.
  - Keep it disabled by default until staff approval flow is tested end to end.
  - Ensure imports are idempotent by draft id/version/content hash.
  - Version the payload and document ownership of every field before wiring real production drafts.
  - Do not auto-publish imported drafts.
  - Do not mix this with Telegram publish targets.

  Logging:
  - `aibot` logs `INFO [copywriting.publish.content]` for enqueue/success and `WARN` for rejected target/config.
  - `diaverse-content` logs `INFO [content.import]` for draft import accepted/reused.
  - Never log full draft bodies, internal tokens, or provider secrets.

  Dependencies:
  - Requires Task 8 internal API.
  - Also depends on Task 3A if payloads include area, locale, slug, topic, or series references.
  - Can be deferred if current `aibot` dirty state should not be touched.

### Phase 5: Deployment, Verification, And Documentation

- [x] Task 12: Add deployment/runbook structure for `diaverse-content`.

  Files:
  - `diaverse-content/Dockerfile`
  - `diaverse-content/docker-compose.yml`
  - `diaverse-content/README.md`
  - `docs/infrastructure/deployment-matrix.md`
  - `docs/infrastructure/domains-and-ports.md`
  - `docs/infrastructure/services/reverse-proxy.md`
  - New or updated runbook under `docs/runbooks/`

  Deliverable:
  - Define production and development runtime placement.
  - Define service health checks, migration order, env names, Postgres/Redis ownership, backup expectations, and rollback path.
  - Define reverse proxy rules for `/ru/learn/*`.
  - Define smoke checks for public pages, internal health, staff BFF, sitemap/robots/llms, and analytics beacon.
  - Avoid exposing content database, admin API, or internal API publicly.

  Logging:
  - Runtime startup logs service version, environment name, enabled content areas, and DB connectivity status.
  - Do not log database URLs, JWT secrets, cookies, or full request headers.

  Dependencies:
  - Requires Tasks 3, 5, 8, and 9.

- [x] Task 13: Add regression tests and smoke scripts for the foundation.

  Files:
  - `diaverse-content/tests/**` or `src/**/__tests__`
  - `diaweb/frontend/__tests__/modules/content/**`
  - `diaverseapi/tests/**`
  - `aibot/tests/**` if Task 11 is implemented
  - Optional smoke scripts under `diaverse-content/scripts/**`

  Deliverable:
  - Test route helpers for `/ru/learn/club/*` and `/ru/learn/game/*`.
  - Test duplicate slug handling across club/game and locale namespaces.
  - Test content page JS/CSS asset loading under the selected path mount.
  - Test unknown content area handling.
  - Test internal JWT acceptance/rejection in `diaverse-content`.
  - Test `diaweb` BFF auth denial and upstream request mapping.
  - Test content RBAC module/permissions in `diaverseapi`.
  - Test sitemap/robots/llms exclusion of drafts/internal/staff routes.
  - Test consent-gated analytics behavior before and after accepted privacy consent.
  - Test analytics tracker excludes staff/admin/internal pages.
  - Test media persistence or explicit disabled upload behavior.
  - If Task 11 is implemented, test idempotent draft import from `aibot`.

  Logging:
  - Test logs must not contain real content bodies, cookies, internal JWTs, or production URLs with secrets.
  - Smoke scripts should print status codes and route names only.

  Dependencies:
  - Runs after the relevant implementation tasks.

- [x] Task 13A: Fix or isolate the current docs-health preflight failure.

  Files:
  - `scripts/docs-health.ps1`
  - `docs/documentation-system.md`
  - offending docs discovered by the script

  Deliverable:
  - Fix the invalid-path parsing case that currently causes `docs-health.ps1` to throw before it can report actionable findings, or explicitly document why this initiative should use a narrower docs validation command.
  - Ensure the script reports the offending document/link path without treating malformed markdown/link text as a filesystem path.
  - Keep docs validation usable before adding `diaverse-content` documentation to the gate.

  Logging:
  - Print concise warnings for malformed links or unresolved paths.

  Dependencies:
  - Can run any time before Task 14 verification.

- [x] Task 14: Update cross-repo documentation and sync local knowledge.

  Files:
  - `docs/architecture/content-factory.md` or equivalent new architecture doc
  - `docs/README.md`
  - `docs/features/site-analytics.md`
  - `docs/infrastructure/*`
  - `.ai-factory/ARCHITECTURE.md` if the new repo becomes part of the canonical workspace architecture
  - GBrain local state via `scripts/gbrain-sync.ps1`

  Deliverable:
  - Document ownership, route map, admin boundary, SEO ownership, analytics ownership, deployment, and rollback.
  - Include path-mounted asset strategy, slug namespace rules, media storage decision, consent behavior, and disabled/enabled Stateinik capabilities.
  - Add `diaverse-content-code` to GBrain sources and run sync after meaningful docs/code changes.
  - Keep public docs free of secrets, private runtime details, raw IPs, and provider tokens.

  Logging:
  - GBrain sync logs stay local.
  - Public daily/docs entries must not include private infra details or secrets.

  Dependencies:
  - Should be updated alongside implementation and finalized after Tasks 1-13A.

## Verification Plan

New `diaverse-content` repo:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverse-content
npm ci
npm run typecheck
npm run lint
npx prisma validate
npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script
npm run build
npm test
```

`diaweb`:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
pnpm vitest run modules/content
pnpm vitest run app/api/staff/content
pnpm lint
```

`diaverseapi`:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests -k "content or rbac or analytics" -q
```

If any Alembic migration is added for analytics/RBAC changes, run PostgreSQL DDL SQL compilation:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

`aibot` if Task 11 is implemented:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\aibot
pytest tests -k "publish and content" -q
```

Workspace docs and knowledge:

```powershell
cd C:\Users\Indigo\Desktop\diaverse
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1
```

`docs-health.ps1` now reports malformed local links as warnings, skips daily/vendor cache folders, and can be used as a release-gate preflight for this initiative. Existing H1 warnings remain non-blocking.

Manual smoke:

- `GET /ru/learn/club/...` returns public content page or controlled empty/placeholder state.
- `GET /ru/learn/game/...` returns public content page or controlled empty/placeholder state.
- Public content page JS/CSS loads from the intended `diaverse-content` asset namespace, not `diaweb`'s `/_next/*`.
- `GET /ru/club` still opens the club product/onboarding route, not content.
- `GET /ru/staff/content` requires staff auth and content permission.
- Direct public access to content admin/internal APIs returns `401`, `403`, or `404`.
- `sitemap.xml`, `robots.txt`, and `llms.txt` include public content and exclude drafts/internal/staff/admin routes.
- A public content page emits a sanitized site analytics visit only after the required consent behavior is satisfied.
- Shared slugs can exist across `club` and `game` without redirect/canonical collisions.
- Uploaded or generated media remains readable after service/container recreation when media capabilities are enabled.
- Rollback can remove `/ru/learn/*` route without affecting `diaweb`, `diaverseapi`, game, club, or auth flows.

## Commit Plan

Because the plan has more than five tasks, split implementation into independent commits by ownership boundary:

1. Root `diaverse` after Task 1 and planning docs are stable.
   - Suggested commit: `chore(workspace): register content factory repo`
2. `diaverse-content` after Tasks 2, 3, 3A, 3B, 3C, 3D, and 4 pass validation/build/typecheck.
   - Suggested commit: `feat(content): scaffold diaverse content factory`
3. `diaverse-content` plus infra docs after Tasks 5, 9, 9A, 10, and 12.
   - Suggested commit: `feat(content): add public routing seo and analytics foundation`
4. `diaverseapi` after Task 6 and any backend analytics/RBAC changes pass tests.
   - Suggested commit: `feat(rbac): add content staff permissions`
5. `diaweb` after Task 7 and SEO aggregator/BFF tests pass.
   - Suggested commit: `feat(staff): add content factory staff shell`
6. `aibot` after Task 11 if implemented.
   - Suggested commit: `feat(copywriting): add content publish target bridge`
7. Root `diaverse` after Tasks 13A and 14 docs/GBrain sync.
   - Suggested commit: `docs(content): document content factory architecture`

Do not stage unrelated dirty files from existing worktrees.

## Guardrails

- Do not generate or publish SEO articles in this phase.
- Do not launch public health/finance/investment advice content without a later editorial/SEO review.
- Do not move Diaverse product/game/club source of truth into `diaverse-content`.
- Do not let `diaverse-content` write to the Diaverse backend database.
- Do not expose Stateinik admin, Prisma Studio, content DB, internal import APIs, or admin APIs publicly.
- Do not use `/ru/club/*` for SEO articles; keep it for product club flows.
- Do not create a separate root marketing domain unless a later brand strategy explicitly asks for it.
- Do not let root `sitemap.xml`, `robots.txt`, or `llms.txt` have multiple competing owners.
- Do not route a separate Next app under `diaverse.app/ru/learn/*` until `_next`, static, image, and OG assets are isolated from `diaweb`.
- Do not publish production content until slug uniqueness is scoped by `area` and `locale`.
- Do not enable uploads or generated images without persistent storage and a restore/readability check.
- Do not enable Stateinik digest/newsletter/experiments/search-console/indexing integrations by default.
- Preserve Stateinik license attribution if its source is copied.
- Keep current unrelated dirty work in `diaweb`, `diaverseapi`, and `aibot` isolated from this implementation.
