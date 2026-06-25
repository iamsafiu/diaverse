# Implementation Plan: Diaverse AI Cofounder Server Runtime

Created: 2026-06-25
Mode: fast plan, no branch creation

## Settings

- Testing: yes
- Logging: standard
- Docs: yes
- Roadmap: none found in `.ai-factory/ROADMAP.md`
- GBrain/daily: do not update by explicit user instruction

## Goal

Deploy a Diaverse-specific AI Cofounder on a foreign server as a safe operational layer that can:

- understand the Diaverse product, repositories, architecture, content factory, and approved business context
- read selected product, analytics, finance, and content-performance data through safe interfaces
- generate SEO/content strategy and article drafts for club/game directions
- send Telegram reports and approval requests
- import content only as drafts, never auto-publish

Non-goals:

- do not make AI Cofounder the source of truth for product code or business data
- do not give it broad production DB credentials
- do not expose the 3D bridge publicly
- do not run unrestricted `claude -p` / shell automation against production directories
- do not publish articles or change production code without human approval and GitLab review

## Workspace Mode

This is a cross-repo Diaverse plan from the root workspace:

- root `diaverse` owns coordination docs, context, and deployment runbooks
- new child repo `diaverse-ai-cofounder` should own the Diaverse AI Cofounder runtime
- implementation code stays inside affected child repositories
- root repo must not track child repo source files

## Research Context

- Read-only GBrain search for existing AI Cofounder/content-factory context returned no matching canonical page.
- Source inspection found `C:\Users\Indigo\Desktop\ai-cofaunder` is an unpacked AI-Cofounder v1.1.0 starter, not a git repo.
- The starter is macOS-first: Keychain via `keytar`, launchd scheduling, local Claude Code setup, Telegram, SQLite/Prisma, Hono, Electron/React/three bridge.
- Server deployment requires a Linux adapter layer for secrets, scheduling, and runtime safety.
- Diaverse already has the safer content-write path: `aibot` -> `diaverse-content` internal draft import, with no auto-publish.

## Affected Repositories

- `diaverse`: docs, workspace registration, deployment runbooks
- `diaverse-ai-cofounder`: new private child repo created from the `ai-cofaunder` baseline
- `diaverseapi`: safe read-only analytics/finance/product context endpoints or views
- `diaverse-content`: content draft import/read integration hardening if needed
- `aibot`: draft generation/publish bridge integration if needed
- `diaweb`: staff review/SEO readiness integration and production promotion gates if needed
- `diaverse-mobile`: not affected
- `club10000-bot`: not affected
- `diaverse-auth-bot`: not affected

## Architecture Decisions

1. Create a separate private repo named `diaverse-ai-cofounder`.
   - Do not work directly in `C:\Users\Indigo\Desktop\ai-cofaunder`.
   - Preserve upstream license and keep the original starter as a reference copy.

2. Treat AI Cofounder as an ops/content orchestrator, not as a privileged backend.
   - It reads curated context and safe metrics.
   - It writes content drafts through existing APIs.
   - It reports decisions to Telegram and staff UI.

3. Add Linux support instead of relying on macOS-only runtime pieces.
   - Secrets: env/file/Docker secrets provider for Linux, Keychain provider for macOS.
   - Scheduling: systemd timers or container cron on Linux, launchd only on macOS.
   - Bridge: bind to localhost/private network only.

4. Use least privilege for all data access.
   - Prefer backend/service APIs or read-only database roles/views.
   - No broad production DSNs.
   - No write access to product databases.
   - No raw secrets in prompts, logs, docs, Telegram, or generated articles.

5. Disable dangerous unattended target execution on server by default.
   - Server runtime must not run arbitrary `targetCwd` jobs with `bypassPermissions`.
   - Code-writing agents belong in local/MR workflows, not in production cron.

6. Keep human approval mandatory.
   - Articles enter draft status only.
   - Publishing, code changes, payment/finance actions, and production deployment remain human-approved.

## Phase 1 - Repository And Safety Baseline

- [x] Task 1: Create `diaverse-ai-cofounder` repo from the starter baseline
  - Files/repos:
    - new `diaverse-ai-cofounder/`
    - root `AGENTS.md`
    - root `README.md` or docs navigation if needed
  - Deliverable:
    - private GitLab project connected to local child repo
    - baseline committed without secrets or generated local state
    - original `C:\Users\Indigo\Desktop\ai-cofaunder` left untouched
  - Logging:
    - installation/setup logs may mention file names and versions only
    - never log license token, API keys, Telegram tokens, DB DSNs, or SSH material
  - Dependencies:
    - GitLab project exists

- [x] Task 2: Add Diaverse repo-local operating rules
  - Files/repos:
    - `diaverse-ai-cofounder/AGENTS.md`
    - `diaverse-ai-cofounder/README.md`
    - `diaverse-ai-cofounder/SECURITY.md`
    - `diaverse-ai-cofounder/.env.example`
  - Deliverable:
    - clear boundaries for data access, content draft flow, Telegram approval, server deployment, and forbidden operations
    - explicit distinction between upstream engine layer and Diaverse user layer
  - Logging:
    - document redaction rules and safe run-log format
  - Dependencies:
    - Task 1

- [x] Task 3: Add Linux-compatible secret providers
  - Files/repos:
    - `diaverse-ai-cofounder/src/secrets/*`
    - `diaverse-ai-cofounder/src/telegram/secrets.ts`
    - `diaverse-ai-cofounder/src/tools/project-db/index.ts`
    - `diaverse-ai-cofounder/tests/*`
  - Deliverable:
    - provider interface: `keychain`, `env`, `file`, and optional Docker secrets
    - macOS keeps existing Keychain behavior
    - Linux can run from environment or mounted secret files
    - secret lookup errors reference logical secret names only
  - Logging:
    - log provider type and missing key names only
    - never log resolved secret values
  - Dependencies:
    - Task 1

- [x] Task 4: Add Linux scheduling support
  - Files/repos:
    - `diaverse-ai-cofounder/infrastructure/systemd/*`
    - `diaverse-ai-cofounder/scripts/install-routines-systemd.ts` or shell-free npm script equivalent
    - `diaverse-ai-cofounder/docs/server-scheduling.md`
  - Deliverable:
    - systemd service/timer templates that call existing routine runner
    - launchd remains available only for macOS
    - bridge schedule apply is disabled or clearly unsupported on Linux until a safe systemd adapter exists
  - Logging:
    - routine start/end logs include routine id, duration, status, and trace id
  - Dependencies:
    - Task 3

- [x] Task 5: Guard unsafe unattended execution
  - Files/repos:
    - `diaverse-ai-cofounder/src/routines/runtime.ts`
    - `diaverse-ai-cofounder/bridge/server.ts`
    - `diaverse-ai-cofounder/config/*`
    - `diaverse-ai-cofounder/tests/*`
  - Deliverable:
    - default `AI_COFUNDER_ALLOW_UNATTENDED_TARGETS=false`
    - server runtime denies `targetProject`/`targetCwd` execution unless explicitly enabled in a non-production profile
    - no `bypassPermissions` execution path for production routines
    - bridge binds to `127.0.0.1` by default and has an explicit exposure warning
  - Logging:
    - denied execution logs include routine id and reason, not prompt content with sensitive data
  - Dependencies:
    - Task 3

## Phase 2 - Diaverse Knowledge And Data Layer

- [x] Task 6: Create Diaverse user layer
  - Files/repos:
    - `diaverse-ai-cofounder/org/*`
    - `diaverse-ai-cofounder/ai-clone/*`
    - `diaverse-ai-cofounder/projects/diaverse/*`
    - `diaverse-ai-cofounder/agents/*`
  - Deliverable:
    - company profile, product map, audience assumptions, repository map, content taxonomy, and decision rules
    - agents separated by responsibility: content strategist, article drafter, metrics analyst, finance analyst, product researcher
    - context excludes secrets, raw credentials, private tokens, and unapproved personal data
  - Logging:
    - agent runs log source document ids and generated artifact ids
  - Dependencies:
    - Task 2

- [x] Task 7: Add safe analytics and finance read interfaces
  - Files/repos:
    - `diaverseapi/app/analytics/*`
    - `diaverseapi/app/cabinet/finance/*`
    - `diaverseapi/app/core/*` or internal auth module if needed
    - `diaverse-ai-cofounder/src/tools/diaverse-api/*`
  - Deliverable:
    - service-authenticated read endpoints or read-only views for approved metrics
    - endpoints return aggregated/sanitized data, not broad table dumps
    - finance data is minimized to operational summaries needed for reports
  - Logging:
    - backend audit logs include service principal, endpoint, status, and row/aggregate count
    - no raw payment payloads or PII in AI logs
  - Dependencies:
    - Task 6
  - Migration guard:
    - if DB schema changes are required, inspect existing Alembic history first and add reversible migrations only after model/schema alignment is confirmed

- [x] Task 8: Add content factory read integration
  - Files/repos:
    - `diaverse-content/src/app/internal/*`
    - `diaverse-ai-cofounder/src/tools/content-factory/*`
  - Deliverable:
    - AI Cofounder can read content catalog, draft status, SEO metadata, and performance-ready identifiers through internal APIs
    - no direct content DB write path
    - service token scopes distinguish `content:read` and `content:create`
  - Logging:
    - content API logs route, scope, status, and content id only
  - Dependencies:
    - Task 7 can run in parallel if API scopes are already defined

- [x] Task 9: Add draft-only content production path
  - Files/repos:
    - `diaverse-ai-cofounder/agents/content-*`
    - `diaverse-ai-cofounder/skills/*` if local skills are added
    - `aibot/app/application/use_cases/*`
    - `aibot/app/infrastructure/*`
    - `diaverse-content/src/app/internal/v1/imports/drafts/route.ts`
  - Deliverable:
    - content agents produce structured article briefs and drafts for `club` and `game`
    - draft import uses existing no-auto-publish path
    - generated drafts carry source links, target area, guide type, difficulty, and review notes
  - Logging:
    - log draft id, topic, target area, and import status
    - do not log full article text if it may contain private context
  - Dependencies:
    - Tasks 6 and 8

- [x] Task 10: Wire Telegram human gate and staff review loop
  - Files/repos:
    - `diaverse-ai-cofounder/src/pipelines/human-gate.ts`
    - `diaverse-ai-cofounder/agents/*`
    - `diaweb/frontend/app/staff/content/*` if production review gaps remain
    - `diaweb/frontend/app/api/staff/content/*`
  - Deliverable:
    - Telegram approval messages for strategy summaries and draft batches
    - staff review remains the actual publishing surface
    - approval/rejection/edit decisions are persisted in the AI Cofounder run journal
  - Logging:
    - Telegram message ids and decision ids only
    - no token, chat secret, or private payload values
  - Dependencies:
    - Task 9

## Phase 3 - Production Deployment And Operations

- [x] Task 11: Containerize and deploy to the foreign server
  - Files/repos:
    - `diaverse-ai-cofounder/Dockerfile`
    - `diaverse-ai-cofounder/compose.yml`
    - `diaverse-ai-cofounder/infrastructure/foreign-server/*`
    - root `docs/runbooks/ai-cofounder-foreign-server.md`
  - Deliverable:
    - service runs as an unprivileged user
    - persistent volume for SQLite/journal state
    - secrets mounted through environment or secret files
    - bridge/API is localhost-only or VPN-only
    - no Docker socket mount
    - no production SSH key material inside the container
  - Logging:
    - stdout structured logs suitable for Docker/systemd journal
    - healthcheck logs only service status and dependency readiness
  - Dependencies:
    - Tasks 3, 4, 5

- [x] Task 12: Add observability, budgets, and failure controls
  - Files/repos:
    - `diaverse-ai-cofounder/src/observability/*`
    - `diaverse-ai-cofounder/src/routines/*`
    - `diaverse-ai-cofounder/config/budgets.yml`
    - `diaverse-ai-cofounder/docs/operations.md`
  - Deliverable:
    - per-agent run journal with status, duration, model spend estimate, artifact links, and approval state
    - daily/weekly budget caps for LLM calls
    - retry/backoff and circuit-breaker behavior for external APIs
    - alert to Telegram when a routine fails repeatedly or hits spend limits
  - Logging:
    - structured fields: run_id, agent_id, routine_id, status, duration_ms, spend_estimate, error_code
    - redact prompts/responses by default unless explicitly safe
  - Dependencies:
    - Task 11 can start before this, but production schedule should wait for this task

- [x] Task 13: Promote content SEO readiness on the main domain
  - Files/repos:
    - `diaweb/frontend/app/robots.ts`
    - `diaweb/frontend/app/sitemap.ts`
    - `diaweb/frontend/app/llms.txt/route.ts`
    - `diaweb/frontend/shared/content/*`
    - deployment docs
  - Deliverable:
    - production `diaverse.app` exposes content-aware `robots.txt`, `sitemap.xml`, and `llms.txt`
    - content pages under `/ru/learn/*` remain on the main domain
    - existing API/web routes are not shadowed by content edge routing
  - Logging:
    - web server logs should distinguish proxied content routes from native diaweb routes
  - Dependencies:
    - current content factory deployment stays healthy

- [x] Task 14: Write runbooks and rollback steps
  - Files/repos:
    - root `docs/architecture/ai-cofounder.md`
    - root `docs/runbooks/ai-cofounder-foreign-server.md`
    - `diaverse-ai-cofounder/docs/*`
  - Deliverable:
    - setup, deploy, rotate secrets, disable schedules, restore journal DB, rollback image, and emergency stop procedures
    - clear list of required environment variables without values
    - current server topology documented without public digest leakage
  - Logging:
    - runbook examples must use placeholders, never real secrets
  - Dependencies:
    - Tasks 11 and 12

## Verification Plan

Run targeted checks before any production schedule is enabled:

- `diaverse-ai-cofounder`
  - `pnpm install --frozen-lockfile`
  - `pnpm typecheck`
  - `pnpm test`
  - `pnpm build`
  - secret provider tests: macOS keychain mocked, Linux env/file provider real temp files
  - unsafe target execution test: production profile denies `targetCwd`/`bypassPermissions`
  - routine dry run: metrics summary to local artifact, no Telegram send

- `diaverseapi`
  - targeted pytest for new internal analytics/finance endpoints
  - auth tests for service token scopes
  - migration check if any schema changes are introduced

- `diaverse-content`
  - draft import tests remain draft-only
  - internal scope tests for `content:read` and `content:create`
  - smoke: create draft from AI Cofounder payload and verify it is not published

- `aibot`
  - publish adapter tests for draft-only content import
  - schema validation tests for club/game article metadata

- `diaweb`
  - content staff route tests if touched
  - SEO route smoke for `robots.txt`, `sitemap.xml`, `llms.txt`
  - production deploy smoke confirms `/api/health` still belongs to diaweb and `/ru/learn/*` belongs to content edge

- Server smoke
  - container starts with no secret values in logs
  - healthcheck passes
  - one manual routine can read safe metrics and write a run journal entry
  - one content draft can be generated and imported as draft
  - Telegram dry-run or approved test chat receives a redacted report
  - disabling the systemd timer stops scheduled work

## Commit And Push Plan

Use small commits grouped by repository:

- `diaverse-ai-cofounder`
  - `chore(cofounder): import baseline and add diaverse rules`
  - `feat(cofounder): add linux secrets and scheduling adapters`
  - `fix(cofounder): disable unsafe unattended targets by default`
  - `feat(cofounder): add diaverse agents and content draft workflow`
  - `chore(cofounder): add deployment and operations docs`

- `diaverseapi`
  - `feat(api): expose safe ai cofounder metrics summaries`

- `diaverse-content`
  - `feat(content): expose scoped content read integration`
  - or no commit if existing internal APIs are enough

- `aibot`
  - `feat(aibot): support ai cofounder draft handoff`
  - or no commit if existing publish adapter is enough

- `diaweb`
  - `feat(web): promote content seo aggregation to production`
  - only if production branch still lacks the dev content SEO routes

- root `diaverse`
  - `docs: plan ai cofounder server integration`
  - `docs: add ai cofounder deployment runbook`

## Open Risks

- The upstream AI-Cofounder starter is designed for macOS. Linux production support is real implementation work, not just configuration.
- The current `executeUnattendedRoutine` path can bypass permissions when pointed at external project directories. This must be guarded before server schedules are enabled.
- Finance and analytics data needs careful minimization. Start with aggregate reports, not table-level database access.
- AI content quality depends on a later SEO/content strategy pass. This plan builds the structure and safety rails first.
- `diaverse.app` production SEO aggregation is not fully live until the `diaweb` production branch receives the content SEO route changes already proven on dev.

## Definition Of Done

- `diaverse-ai-cofounder` exists as a private GitLab-backed child repo.
- It runs on the foreign server with Linux secrets and scheduling.
- It has Diaverse-specific product context and safe agents.
- It can read approved aggregate data only.
- It can create content drafts through the approved draft-only path.
- It reports to Telegram with human approval gates.
- It cannot publish content, mutate production DBs, or run unrestricted code/shell on production by default.
- Targeted tests and server smoke checks pass.
- Deployment and rollback runbooks exist.
- GBrain and daily logs remain untouched unless the user later allows updates.
