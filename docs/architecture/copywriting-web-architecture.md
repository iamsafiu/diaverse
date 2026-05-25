# Copywriting Web Architecture

Status: active for Phase 1
Last updated: 2026-04-07

## Purpose

This document defines the Phase 0 architecture contract for the Diaverse copywriting domain across:

- `diaweb` as the only browser-facing entrypoint
- `aibot` as the internal copywriting service codebase under migration
- `diaverseapi` as the source of auth and RBAC truth

It exists to remove architecture drift before implementation starts.

## Repository Responsibilities

### `diaweb`

- renders the staff UI at `/[lang]/staff/copywriting`
- exposes same-origin BFF routes under `/api/staff/copywriting/*`
- validates cabinet session and RBAC using the existing `diaverseapi` flow
- signs short-lived internal tokens for the copywriting service
- never performs heavy AI generation work inside browser requests

### `aibot`

- becomes the internal copywriting domain service
- owns copywriting data, jobs, drafts, idea inbox, publish targets, and ingest checkpoints
- runs separate runtime roles for API, worker, and Telegram userbot
- remains private to the shared VPS or internal network

### `diaverseapi`

- remains the source of truth for users, sessions, roles, and permissions
- does not absorb copywriting runtime, AI orchestration, or Telegram ingest workload
- exposes only the minimal RBAC surface needed for `diaweb` to gate access

## Reconciliation: Current `aibot` Drift Inventory

| Area | Current docs claim | Current repo reality | Locked migration decision |
| --- | --- | --- | --- |
| Runtime shape | Telegram-first editorial bot with bot, userbot, worker, beat, and full automation | `main.py` is still bot-first; runtime is tightly coupled to Telegram flows | Keep repo, but pivot to service-first runtime with separate API, worker, and userbot entrypoints |
| Provider contract | `AGENTS.md` says OpenAI-centric stack | Current code actively uses `GroqService`; `OpenAIService` exists but is not the runtime contract | Normalize providers later behind one abstraction; do not let provider choice leak into domain APIs |
| Queue model | Old docs mention Celery/Beat | Current repo tree does not expose a stable service queue contract | V1 uses a Postgres-backed job queue; background work must leave the HTTP path |
| Browser integration | No browser-facing staff workflow exists | Current system is Telegram-first | Browser access must go through `diaweb` BFF only |
| Auth boundary | Legacy docs are bot/admin oriented | No internal service token contract exists yet | `diaweb` issues short-lived signed internal JWTs; browser cookies never reach `copywriting-api` |
| Source ingest | Userbot is treated as part of the bot workflow | Userbot concerns are mixed with planning/writing flows | Keep userbot as a dedicated runtime role with DB-backed source configuration |
| Data governance | Older docs do not define retention and source approval clearly | Raw chat collection is possible, but policy is not locked | Approved sources only, raw-message TTL 30 days, derived entities retained |
| Logging language | Existing logs are helpful but not standardized across future runtimes | No shared correlation contract across BFF, API, worker, and userbot | Standardize on shared correlation IDs and runtime log categories now |

## Locked Migration Stance

- Preserve the existing `aibot` repository.
- Preserve reusable domain logic from `agents/`, `services/`, and `db/` where it remains valuable.
- Treat the current Telegram bot UX as legacy-facing during migration.
- Move toward one internal copywriting service codebase with multiple runtime roles, not a network of per-agent microservices.
- Keep browser traffic same-origin to `diaweb`.
- Keep `copywriting-api` internal-only.
- Keep `diaverseapi` isolated from AI-heavy execution.

## Legacy-Only During Migration

The following remain legacy-only until explicitly reworked behind the new service contract:

- Telegram bot command handlers in `aibot/bot/`
- bot-driven inline review loops as the primary human approval surface
- direct orchestration from `aibot/main.py`
- provider assumptions embedded directly in planner/writer runtime flows
- any env-only source/publish wiring without DB-backed configuration

These areas may continue to exist temporarily, but they are not the target architecture for the web rollout.

## Target Runtime Roles

The copywriting domain is one internal service with multiple runtime roles:

- `copywriting-api`
- `copywriting-worker`
- `copywriting-userbot`
- `copywriting-postgres`

`diaweb` and `copywriting` may share one VPS in V1, but only `diaweb` is internet-facing.

## Topology

```text
Staff browser
  -> diaweb UI
  -> diaweb BFF /api/staff/copywriting/*
  -> copywriting-api (internal only)
  -> copywriting-postgres
  -> copywriting-worker
  -> copywriting-userbot

Separate VPS:
diaverseapi
  -> auth
  -> RBAC
  -> existing cabinet backend
```

## Trust Boundary

### Browser to `diaweb`

- Browser sends cabinet cookies only to `diaweb`.
- `diaweb` validates session using the existing cabinet auth flow.
- `diaweb` checks role and permission before proxying any copywriting request.

### `diaweb` to `copywriting-api`

- `diaweb` sends a short-lived signed internal JWT.
- `copywriting-api` trusts only this internal token.
- `copywriting-api` must reject browser cookies and direct public requests.

### Required internal token claims

```json
{
  "sub": "diaweb-internal",
  "user_id": "3f49f847-99d0-4d15-8a3f-0e2d5f4ec1b6",
  "roles": ["employee"],
  "permissions": [
    "copywriting:read",
    "copywriting:create",
    "copywriting:review",
    "copywriting:publish",
    "copywriting.sources:manage"
  ],
  "request_id": "req_01HRZ8Q7W32T7P1G0T4S6PV1Q9",
  "iat": 1775472000,
  "exp": 1775472060,
  "jti": "jwt_01HRZ8Q7Y1VQ6XEM6N0DJVX8A2",
  "iss": "diaweb",
  "aud": "copywriting-api"
}
```

### Example staff brief request

```json
{
  "title": "April retention push",
  "goal": "Turn support pain points into a short Telegram post series",
  "source_ids": [
    "src_chat_01HRZ8TZ8QH8H06A6M8MN3C2KW"
  ],
  "notes": "Keep tone practical and not overly salesy",
  "language": "ru"
}
```

### Example async job response

```json
{
  "job_id": "job_01HRZ94Q1BBVJQ4M0SYQSE6BWK",
  "status": "queued",
  "type": "generate_plan",
  "brief_id": "brief_01HRZ94NTHYVTPPQ5F2WKCER8F"
}
```

## Locked Web UX For Phase 1

The primary staff surface is now a single workspace at `/[lang]/staff/copywriting`.

The web flow is intentionally linear:

1. staff edits one global style prompt
2. staff clicks "Generate plans"
3. `diaweb` creates a brief from enabled source chats
4. `copywriting-worker` builds the plan from recent ingested `copywriting_source_messages` that were collected earlier by `copywriting-userbot`
5. staff expands the brief, picks a plan item, and generates a draft inline
6. the draft opens in the same page for edit, review, approval, and publish actions

### Locked UX decisions

- Global style is one active style profile, not a per-draft selector.
- The style prompt is edited in the dashboard and applied by the backend automatically during plan and draft generation.
- The primary dashboard no longer depends on a manual brief form.
- "Generate plans" never performs a live Telegram read inside the browser request path; it always works from already ingested source messages.
- Source settings and the dashboard must reflect backend-computed readiness states for each chat: `ready`, `pending`, `stale`, or `disabled`.
- `/[lang]/staff/copywriting/new` and `/[lang]/staff/copywriting/styles` are removed as standalone routes.
- `/[lang]/staff/copywriting/drafts`, `/[lang]/staff/copywriting/ideas`, and `/[lang]/staff/copywriting/settings` remain secondary or legacy surfaces during migration.

### Dashboard composition

The browser workspace is composed from these frontend pieces:

- `GlobalStyleEditor`
- `GeneratePlansButton`
- `BriefPlansCard` list inside `CopywritingDashboard`
- `InlineDraftPanel`

The dashboard is responsible only for orchestration and visibility. Prompt assembly, source analysis, planning, and writing remain in `aibot`.

### Source readiness contract

`GET /api/staff/copywriting/sources?type=chats` must surface backend readiness fields for each configured chat:

- `last_checkpoint_at`
- `latest_message_at`
- `message_count_recent`
- `total_message_count`
- `sync_status`
- `readiness_reason`

The browser must trust this API contract and must not infer planning readiness from `is_enabled` alone.

Current user-facing semantics are:

- `disabled`
  - the chat is turned off and excluded from planning
- `pending`
  - the chat is enabled, but there are no persisted source messages yet
- `stale`
  - the chat has historical messages, but nothing inside the active planning lookback window
- `ready`
  - the chat is enabled and has recent ingested messages that can be used for `generate_plan`

## Allowed Request Surfaces

### Same-origin browser surface

Only these `diaweb` BFF paths are allowed for browser access:

- `POST /api/staff/copywriting/briefs`
- `GET /api/staff/copywriting/briefs`
- `GET /api/staff/copywriting/plans`
- `POST /api/staff/copywriting/plans`
- `GET /api/staff/copywriting/drafts`
- `POST /api/staff/copywriting/drafts`
- `GET /api/staff/copywriting/drafts/:id`
- `PATCH /api/staff/copywriting/drafts/:id`
- `GET /api/staff/copywriting/jobs/:id`
- `GET /api/staff/copywriting/styles`
- `POST /api/staff/copywriting/styles`
- `GET /api/staff/copywriting/styles/active`
- `GET /api/staff/copywriting/styles/:id`
- `PUT /api/staff/copywriting/styles/:id`
- `POST /api/staff/copywriting/styles/:id?action=activate`
- `GET /api/staff/copywriting/ideas`
- `GET /api/staff/copywriting/sources`
- `POST /api/staff/copywriting/sources`
- `GET /api/staff/copywriting/publish-targets`
- `POST /api/staff/copywriting/publish-targets`
- `POST /api/staff/copywriting/publish`

### Internal service surface

The internal API may be mounted under `/internal/v1/*` and must not be published directly on the public internet.

## Data Governance

### Approved source policy

- Only DB-backed, explicitly approved source chats may be ingested.
- Only approved source accounts may read those chats.
- Private DMs, ad-hoc chats, and unapproved groups are out of scope unless added through the configuration flow.

### Retention

- Raw source messages: retain for 30 days, then delete automatically.
- Derived entities such as pain signals, ideas, briefs, plans, drafts, revisions, and publish events remain until a later policy changes them.

### Logging restrictions

- Never log full internal JWTs.
- Never log browser cookies.
- Never log raw Telegram message bodies in normal production logs.
- Debug-only raw content inspection, if ever enabled, must be explicit, local, and short-lived.
- Log entity IDs, counts, status transitions, latency, and sanitized provider metadata instead.

### Publish semantics

- V1 must support export-ready output as a staff-visible terminal action.
- Telegram publishing is optional in V1 and must stay behind an adapter boundary.
- Publish targets must be DB-backed configuration entities, not env-only destinations.

## Correlation Fields

Every BFF, API, worker, userbot, and publish log should use the same correlation vocabulary:

- `request_id`
- `user_id`
- `job_id`
- `draft_id`
- `plan_id`
- `source_batch_id`

## Log Categories

Use these category families so logs stay searchable across runtimes:

- `copywriting.bff.*`
- `copywriting.api.*`
- `copywriting.worker.*`
- `copywriting.userbot.*`
- `copywriting.publish.*`
- `copywriting.auth.*`

### Expected level defaults

- `DEBUG`: payload shape summaries, queue polling, selected provider, retry decisions
- `INFO`: request start/end, job enqueue, job completion, source sync start/end, publish result
- `WARN`: auth denial, malformed upstream response, invalid state transition, duplicate ingest batch, fallback path
- `ERROR`: failed dependency initialization, unrecoverable job failure, repeated retry exhaustion, publish failure

## Environment Contract

### `diaweb` server-only env

| Name | Purpose |
| --- | --- |
| `COPYWRITING_API_URL` | Internal base URL used by the BFF to reach `copywriting-api` |
| `COPYWRITING_INTERNAL_JWT_SECRET` | Shared secret for internal service JWT signing |
| `COPYWRITING_INTERNAL_JWT_ISSUER` | Internal JWT issuer, default `diaweb` |
| `COPYWRITING_INTERNAL_JWT_AUDIENCE` | Internal JWT audience, default `copywriting-api` |
| `COPYWRITING_INTERNAL_JWT_TTL_SECONDS` | Short token TTL for proxied requests |
| `COPYWRITING_REQUEST_TIMEOUT_MS` | Upstream timeout budget for BFF requests |

### `copywriting` service env

| Name | Purpose |
| --- | --- |
| `COPYWRITING_RUNTIME_ROLE` | Runtime mode: `legacy-bot`, `copywriting-api`, `copywriting-worker`, `copywriting-userbot` |
| `COPYWRITING_API_HOST` | Bind host for internal API |
| `COPYWRITING_API_PORT` | Bind port for internal API |
| `COPYWRITING_DATABASE_URL` | Copywriting Postgres connection string |
| `COPYWRITING_INTERNAL_JWT_SECRET` | Shared secret used to validate `diaweb` tokens |
| `COPYWRITING_INTERNAL_JWT_ISSUER` | Expected issuer from `diaweb` |
| `COPYWRITING_INTERNAL_JWT_AUDIENCE` | Expected audience for `copywriting-api` |
| `COPYWRITING_SOURCE_RETENTION_DAYS` | TTL window for raw source messages |
| `COPYWRITING_DEFAULT_EXPORT_FORMAT` | Default export format for staff output |
| `COPYWRITING_PROVIDER` | Default LLM provider until provider abstraction is normalized |

## Deferred Scope

The following are explicitly deferred after MVP unless a later task re-opens them:

- direct browser access to `copywriting-api`
- Redis/Celery as the default job substrate
- WebSocket or SSE job updates
- image generation revival
- advanced ingest orchestration and sharding
- moving runtime load into `diaverseapi`

## Regression Coverage

The MVP regression baseline is intentionally split across the browser-facing repo and the internal service repo:

- `diaweb` Vitest:
  - BFF proxy regressions for auth denial, upstream transport failure, timeout mapping, and request forwarding
  - UI regressions for the one-page flow: active style editing, plan generation, inline draft opening, draft review/save behavior, and publish/export actions
- `aibot` pytest:
  - end-to-end happy path for `brief -> plan -> draft -> review -> approve -> export`
  - route-level auth and permission failures
  - worker retry and dead-letter behavior
  - ingest checkpoint resume and ingest failure bubbling
  - publish idempotency and adapter failure handling

Suggested regression commands:

```bash
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm run test:copywriting
```

```bash
cd C:\Users\Indigo\Desktop\diaverse\aibot
pytest tests/test_copywriting_e2e_flow.py tests/test_api_auth.py tests/test_source_ingest_flow.py tests/test_publish_flow.py tests/test_worker_loop.py
```

## Logging And Noise Control

The module is designed to emit useful development logs without changing code between environments:

- `diaweb` BFF keeps verbose `console.debug` request/proxy traces only when `NODE_ENV != production`
- `copywriting` runtimes use structured `structlog` events and reduce verbosity through `LOG_LEVEL`
- request correlation is preserved through `X-Request-ID` from nginx -> `diaweb` -> `copywriting-api`

Use the shared fields below in dashboards, log search, and incident notes:

- `request_id`
- `user_id`
- `job_id`
- `draft_id`
- `plan_id`
- `source_batch_id`

## Production Diagnostics

### Stuck worker

Detect:

- `python scripts/runtime_probe.py heartbeat --file /tmp/copywriting-worker-heartbeat.json --max-age 90`
- `python scripts/runtime_probe.py queue --database-url "$COPYWRITING_DATABASE_URL" --queue default --max-lag-seconds 300`

What it means:

- stale worker heartbeat with growing available queue usually means the worker loop stopped or cannot claim/process jobs
- non-zero `staleProcessingJobs` means claimed jobs stopped heartbeating and need operator attention

Immediate response:

1. inspect `copywriting-worker` logs for the failing `job_id`
2. restart only `copywriting-worker` if API and DB remain healthy
3. if queue degradation persists, inspect the oldest queued jobs before retrying rollout

### Stale userbot ingest

Detect:

- `python scripts/runtime_probe.py heartbeat --file /tmp/copywriting-userbot-heartbeat.json --max-age 180`
- `python scripts/runtime_probe.py source-sync --database-url "$COPYWRITING_DATABASE_URL" --max-age-seconds 600 --recent-window-hours 168`

What it means:

- a stale heartbeat means the userbot loop is no longer running
- a stale source-sync probe with enabled chats means approved sources are not being ingested, so source-backed plan generation will also block or fail with readiness reasons

Immediate response:

1. inspect `copywriting-userbot` logs for flood-wait, auth/session, or checkpoint errors
2. verify the persisted Pyrogram session volume is still mounted
3. restart only `copywriting-userbot` if the rest of the stack is healthy

### Source-backed planning triage

When staff reports that "Generate plans" is blocked or a brief job ends in `dead_letter`, inspect runtimes in this order:

1. `copywriting-api`
2. `copywriting-worker`
3. `copywriting-userbot`

Operational rule of thumb:

- missing `sync_status`, `readiness_reason`, or `last_error` points to `copywriting-api`
- queued, retried, or dead-lettered `generate_plan` jobs point to `copywriting-worker`
- no fresh source data or stale checkpoints point to `copywriting-userbot`

### Runaway queue growth

Detect:

- `python scripts/runtime_probe.py queue --database-url "$COPYWRITING_DATABASE_URL" --queue default --max-lag-seconds 300`
- rising `availableJobs` and `oldestAvailableAgeSeconds` after deploy or provider incidents

What it means:

- workers are slower than incoming demand, or a whole job family is failing and being retried repeatedly

Immediate response:

1. identify the dominant failing `kind` and correlated `last_error` in `copywriting_jobs`
2. reduce intake by pausing risky flows if needed
3. restart or roll back the worker/runtime only after the root cause is understood

## Rollout

1. deploy `aibot` first so `copywriting-api` is already healthy when `diaweb` starts proxying
2. deploy `diaweb`
3. run the smoke checks from `copywriting-production-runtime.md`
4. confirm `401` on unauthenticated BFF access, then confirm authenticated staff traffic through the UI
5. confirm worker heartbeat freshness, queue lag, and source-sync freshness after the first live requests

## Rollback

Use the smallest rollback radius that restores stability:

- BFF/UI-only regression: roll back `diaweb`
- queue, publish, or ingest regression: roll back `aibot`
- cross-cutting proxy failure: restore the last known good nginx + `diaweb` pair first, then inspect internal API reachability

After rollback:

1. rerun health, heartbeat, queue, and source-sync probes
2. confirm no runaway `retry_pending` or `dead_letter` spike remains
3. document the failing `request_id`, `job_id`, or `draft_id` before the next rollout attempt
