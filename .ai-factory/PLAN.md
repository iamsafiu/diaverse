# Implementation Plan: Auth Bot Broadcasts In Copywriting

Branch: none
Created: 2026-06-02
Mode: fast workspace plan

## Settings

- Testing: yes
- Logging: verbose
- Docs: yes
- Branching: none in fast mode
- Affected repositories: `diaweb`, `aibot`, `diaverseapi`, root docs
- Not affected for source changes: `diaverse-auth-bot`, `club10000-bot`

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first through `scripts\gbrain.ps1`, then raw source verification

## Repository Matrix

| Repository | Path | Affected | Branch | Role |
| --- | --- | --- | --- | --- |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | unchanged | staff UI, copywriting tab, same-origin BFF |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | yes | unchanged | broadcast campaign API, media storage, worker sender |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | unchanged | auth-bot audience source and RBAC permission truth |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | unchanged | Telegram auth transport only; no campaign ownership |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | unchanged | unrelated |
| root docs | `C:\Users\Indigo\Desktop\diaverse\docs` | yes | unchanged | feature docs and rollout notes |

## Product Decisions

- Audience means users who have authorized or linked through the auth bot at least once, represented by durable Telegram identity in `diaverseapi`: active, non-deleted `users` with `tg_user_id IS NOT NULL`.
- Sender is the auth bot token. The auth bot process/repo stays stateless and does not own campaigns, queues, or recipient truth.
- Image is mandatory for every broadcast.
- Text is mandatory for every broadcast.
- Test send goes only to configured staff Telegram ID `8057982030`.
- MVP sending is immediate only: no schedule, no segments, no drafts after queueing.
- Mass delivery must be asynchronous through a campaign/outbox job, not a synchronous browser request.
- The UI must force a test send before enabling "send to all" in the current page session.
- Use a dedicated permission such as `copywriting.broadcast:send`; do not rely only on `copywriting:publish`.

## Architecture Sketch

```text
Staff browser
  -> diaweb /[lang]/staff/copywriting/broadcasts
  -> diaweb BFF /api/staff/copywriting/broadcasts/*
  -> aibot /internal/v1/broadcasts/*
  -> aibot copywriting_jobs kind=send_broadcast_campaign
  -> diaverseapi internal audience endpoint, paginated
  -> Telegram Bot API with auth bot token/profile
  -> broadcast recipient status rows
  -> UI polls campaign progress
```

## Research Context

Source: GBrain `architecture/copywriting-web-architecture`, `.ai-factory/DESCRIPTION.md`, `.ai-factory/ARCHITECTURE.md`, and raw source verification.

Key source facts:

- `diaweb` owns browser-facing copywriting routes and BFF proxying through `frontend/app/api/staff/copywriting/_utils.ts`.
- Copywriting tabs are configured in `diaweb/frontend/modules/copywriting/components/CopywritingTabsNav.tsx`.
- `aibot` owns internal copywriting API and worker roles; routes are mounted in `aibot/app/api/main.py`.
- `aibot` already has manual SQL migrations under `aibot/migrations/`.
- `aibot/services/telegram_service.py` already supports Bot API `send_photo`, local files, bot profiles, and aiogram.
- `diaverseapi` owns Telegram identity through `app/security/models.py` `User.tg_user_id` and `app/internal/models.py` `BotUser.platform_id`.
- The auth bot is stateless by architecture and should not gain DB/queue responsibilities.

## Out Of Scope

- Scheduled broadcasts.
- Audience segmentation.
- Text-only broadcasts.
- Editing or cancelling a campaign after it starts sending.
- Building a DB or queue into `diaverse-auth-bot`.
- Public API access to `aibot` or the audience endpoint.
- Using the Telegram userbot publish path for DM broadcasts.

## Commit Plan

- Commit 1 (`diaverseapi`): `feat: expose auth-bot broadcast audience`
- Commit 2 (`aibot`): `feat: add copywriting broadcast campaigns`
- Commit 3 (`diaweb`): `feat: add copywriting broadcast tab`
- Commit 4 (root docs, optional per repo docs): `docs: document auth bot broadcast workflow`

## Tasks

### Phase 1: Audience And Permission Contract

- [x] Task 1: Add a protected auth-bot audience endpoint in `diaverseapi`.

  Deliverable: a paginated internal endpoint that returns active recipients with Telegram IDs for broadcast materialization.

  Expected behavior:
  - Endpoint path should be internal-only, for example under the existing auth/internal surface: `GET /v1/auth/internal/auth-bot-broadcast-recipients`.
  - It returns only active, non-deleted users with `User.tg_user_id IS NOT NULL`.
  - Response includes stable `user_id`, `tg_user_id`, optional `tg_username` when available, `total_count`, and `next_cursor`.
  - It must not expose cookies, JWTs, balances, emails, or unrelated profile data.
  - Use a service-to-service signature or shared internal secret dedicated to the copywriting broadcast audience, not browser cookies.

  Files:
  - `diaverseapi/app/security/api.py` or a new small router imported by it
  - `diaverseapi/app/security/schemas.py`
  - `diaverseapi/app/security/dependecies.py` or a dedicated dependency module
  - `diaverseapi/app/core/settings.py`
  - `diaverseapi/tests/test_auth_bot_broadcast_audience.py`

  Logging requirements:
  - Log `INFO` for accepted audience page requests with `request_id`, page size, returned count, and whether a next cursor exists.
  - Log `WARN` for rejected internal signatures without logging secrets or full signatures.
  - Log `DEBUG` for query boundaries in non-production only if helpful.

- [x] Task 2: Add and propagate a dedicated broadcast permission.

  Deliverable: `copywriting.broadcast:send` is available in backend RBAC, appears in staff access claims for allowed users, and reaches `aibot` through `diaweb` internal JWTs.

  Expected behavior:
  - Superadmin receives the permission by default.
  - Ordinary copywriting staff should not automatically get mass-send rights unless the product decision is explicit.
  - `diaweb` BFF permission filtering keeps the new `copywriting.broadcast:` namespace.
  - `aibot` send/test endpoints require `copywriting.broadcast:send`; read/status endpoints may require `copywriting:read`.

  Files:
  - `diaverseapi/app/cabinet/rbac/seed.py`
  - `diaverseapi/app/cabinet/rbac/staff_modules.py`
  - `diaverseapi/tests/test_cabinet_rbac_seed.py`
  - `diaverseapi/tests/test_cabinet_staff_access_api.py`
  - `diaweb/frontend/app/api/staff/copywriting/_auth.ts`
  - `diaweb/frontend/__tests__/shared/auth-permissions.test.ts`
  - `aibot/app/api/deps/auth.py` only if helper behavior needs clearer errors

  Logging requirements:
  - Keep RBAC seed logs at existing levels for created permission and role-permission links.
  - Log `WARN` on `aibot` permission denial with `request_id`, `user_id`, and missing permission only.

### Phase 2: Broadcast Domain In Aibot

- [x] Task 3: Add broadcast campaign and recipient persistence in `aibot`.

  Deliverable: durable tables and repository methods for campaign status, media path, text length, counters, and per-recipient delivery status.

  Expected behavior:
  - Add `copywriting_broadcast_campaigns` with statuses such as `queued`, `sending`, `completed`, `failed`.
  - Add `copywriting_broadcast_recipients` with statuses such as `pending`, `sent`, `blocked`, `failed`, `retry_pending`.
  - Store `campaign_id`, `user_id`, `tg_user_id`, `telegram_message_id`, `attempt_count`, `last_error`, `sent_at`, and timestamps.
  - Add unique constraint on `(campaign_id, tg_user_id)` for idempotency.
  - Store image path in the campaign, not raw image bytes in the DB.

  Files:
  - `aibot/db/models.py`
  - `aibot/db/repositories/broadcast_repo.py`
  - `aibot/db/__init__.py`
  - `aibot/migrations/20260602_0001_copywriting_broadcasts.sql`
  - `aibot/tests/test_broadcast_repository.py`

  Logging requirements:
  - Repository logs use `copywriting.broadcast.repo.*`.
  - Log `DEBUG` for campaign creation and recipient upsert counts.
  - Log `INFO` for status transitions with campaign ID and sanitized counters.
  - Never log full message text or raw image bytes.

- [x] Task 4: Add `aibot` configuration and internal client for `diaverseapi` audience paging.

  Deliverable: `aibot` can fetch broadcast recipients from `diaverseapi` with a signed internal request and pagination.

  Expected behavior:
  - Add settings for audience base URL, internal secret, timeout, and page size.
  - Client signs requests consistently with the new `diaverseapi` dependency.
  - Client handles 401/403/5xx/timeout as explicit errors for the worker.
  - Client supports paging until `next_cursor` is empty.

  Files:
  - `aibot/core/config.py`
  - `aibot/app/infrastructure/diaverseapi_broadcast_client.py` or similar
  - `aibot/tests/test_broadcast_audience_client.py`

  Logging requirements:
  - Log `INFO` for audience sync start/done with page count and recipient count.
  - Log `WARN` for upstream non-2xx with status code and request ID.
  - Log `ERROR` for timeout/transport failure without logging secrets.

- [x] Task 5: Add `aibot` broadcast API routes and image validation.

  Deliverable: internal API endpoints for test send, campaign creation, list, and campaign detail.

  Expected behavior:
  - `POST /internal/v1/broadcasts/test` accepts multipart form with mandatory `image` and `text`, sends only to configured test TG ID `8057982030`, and returns send result.
  - `POST /internal/v1/broadcasts` accepts multipart form with mandatory `image` and `text`, stores image, creates campaign, enqueues `send_broadcast_campaign`, and returns campaign summary.
  - `GET /internal/v1/broadcasts` returns recent campaigns and counters.
  - `GET /internal/v1/broadcasts/{campaign_id}` returns status and recipient counters.
  - Allowed image extensions: `.jpg`, `.jpeg`, `.png`, `.webp`; max size should match the existing reference image policy unless Telegram constraints require stricter limits.
  - Store images under a dedicated directory such as `COPYWRITING_BROADCAST_MEDIA_DIR`, not the reference image settings directory.

  Files:
  - `aibot/app/api/routes/broadcasts.py`
  - `aibot/app/api/schemas/broadcasts.py`
  - `aibot/app/api/main.py`
  - `aibot/app/application/use_cases/broadcasts.py`
  - `aibot/tests/test_broadcast_routes.py`

  Logging requirements:
  - Log `INFO` for test send request, campaign creation, and job enqueue with `request_id`, `user_id`, `campaign_id`, image size, and text length.
  - Log `WARN` for invalid image/text with validation reason.
  - Do not log message body, auth token, or full local filesystem paths in production logs.

- [x] Task 6: Add a worker processor that sends broadcast campaigns through the auth bot profile.

  Deliverable: `send_broadcast_campaign` processor sends the required image and text to all materialized recipients, updates counters, and survives retries.

  Expected behavior:
  - Register processor in `aibot/app/worker/processors/__init__.py`.
  - Use `TelegramService` with an auth-bot profile, for example `COPYWRITING_BROADCAST_BOT_PROFILE=auth` backed by an env token such as `TELEGRAM_AUTH_BOT_TOKEN`.
  - Fetch recipients from `diaverseapi`, materialize them idempotently, then send per recipient.
  - Use `send_photo` with caption when text fits Telegram caption constraints; if too long, send photo and text as a planned two-message sequence.
  - Handle Telegram blocked/forbidden errors as non-retryable recipient failures.
  - Handle rate limits and retry-after as retryable, with campaign/job requeue where appropriate.
  - Maintain campaign counters for pending, sent, blocked, failed, and retrying.
  - Mark campaign `completed` when all recipients are terminal; mark `failed` only for unrecoverable campaign-level problems.

  Files:
  - `aibot/app/worker/processors/send_broadcast_campaign.py`
  - `aibot/app/worker/processors/__init__.py`
  - `aibot/app/application/use_cases/broadcast_delivery.py`
  - `aibot/services/telegram_service.py` only if a small global broadcast throttle/helper is needed
  - `aibot/tests/test_broadcast_worker.py`
  - `aibot/tests/test_telegram_service.py`

  Logging requirements:
  - Log `INFO` for campaign start, page materialization summary, batch progress, and completion.
  - Log `DEBUG` for per-batch retry decisions and rate limit sleeps.
  - Log `WARN` for individual blocked users and retryable delivery failures.
  - Log `ERROR` for campaign-level unrecoverable errors.
  - Logs must use `copywriting.broadcast.worker.*` and include `campaign_id`, `job_id`, `request_id` where available, and aggregate counts.

### Phase 3: Diaweb BFF And Staff UI

- [x] Task 7: Add `diaweb` BFF routes for broadcast API calls.

  Deliverable: same-origin routes proxy multipart and JSON requests to `aibot` without exposing browser cookies to `aibot`.

  Expected behavior:
  - `POST /api/staff/copywriting/broadcasts/test` proxies multipart form to `/internal/v1/broadcasts/test`.
  - `POST /api/staff/copywriting/broadcasts` proxies multipart form to `/internal/v1/broadcasts`.
  - `GET /api/staff/copywriting/broadcasts` proxies list requests.
  - `GET /api/staff/copywriting/broadcasts/[id]` proxies campaign detail.
  - Multipart route should follow the existing upload-reference proxy pattern and use the existing internal JWT proxy helper.
  - Mass campaign creation should return quickly after enqueue; it must not wait for all Telegram sends.

  Files:
  - `diaweb/frontend/app/api/staff/copywriting/broadcasts/route.ts`
  - `diaweb/frontend/app/api/staff/copywriting/broadcasts/test/route.ts`
  - `diaweb/frontend/app/api/staff/copywriting/broadcasts/[id]/route.ts`
  - `diaweb/frontend/app/api/staff/copywriting/_utils.ts` if multipart helper extraction is needed
  - `diaweb/frontend/__tests__/app/api/staff/copywriting/broadcasts.test.ts`

  Logging requirements:
  - Log `WARN` for invalid multipart requests and upstream failures.
  - Log `DEBUG` in non-production for proxy start/done with route, method, request ID, and response status.
  - Never log uploaded file bytes or message text.

- [x] Task 8: Add frontend types, API helpers, and polling hooks.

  Deliverable: typed client helpers for test send, campaign creation, campaign list, and campaign status polling.

  Expected behavior:
  - API helpers use `FormData` for image/text submission.
  - Poll campaign detail while status is `queued` or `sending`.
  - Surface validation and upstream failures as visible UI errors.
  - Keep errors actionable without exposing internal service details.

  Files:
  - `diaweb/frontend/modules/copywriting/types.ts`
  - `diaweb/frontend/modules/copywriting/api.ts`
  - `diaweb/frontend/modules/copywriting/hooks.ts`
  - `diaweb/frontend/__tests__/modules/copywriting/broadcast-api.test.ts`

  Logging requirements:
  - Use existing `logCopywritingEvent` for client-side broadcast actions.
  - Log `DEBUG` for request start/done and polling state in development.
  - Log `WARN` for validation or failed API responses.

- [x] Task 9: Add the Copywriting "Broadcasts" tab and page.

  Deliverable: staff can open a dedicated tab, upload an image, enter text, send a test to `8057982030`, then confirm immediate send to all auth-bot users.

  Expected behavior:
  - Add route `/[lang]/staff/copywriting/broadcasts`.
  - Add a nav tab label with dictionary support and fallback label.
  - UI has mandatory image input with preview, mandatory text area, test-send button, and send-all confirmation.
  - Send-all button is disabled until the current image/text has passed a test send in the current page session.
  - After send-all, UI shows campaign status and counters: total, pending, sent, blocked, failed.
  - UI must stay usable on mobile and desktop; text must not overflow buttons or panels.
  - Do not add marketing copy or explanatory feature cards; this is a staff tool.

  Files:
  - `diaweb/frontend/app/[lang]/staff/copywriting/broadcasts/page.tsx`
  - `diaweb/frontend/modules/copywriting/components/CopywritingBroadcastsView.tsx`
  - `diaweb/frontend/modules/copywriting/components/CopywritingTabsNav.tsx`
  - `diaweb/frontend/modules/copywriting/index.ts`
  - i18n dictionary files used by `Dictionary["copywriting"]`
  - `diaweb/frontend/__tests__/modules/copywriting/CopywritingBroadcastsView.test.tsx`

  Logging requirements:
  - Log `INFO` for successful test send and campaign creation.
  - Log `WARN` for blocked send-all attempts, invalid image/text, and API failures.
  - Use sanitized metadata only: file size/type, text length, campaign ID, status.

### Phase 4: Tests, Docs, And Rollout

- [x] Task 10: Run targeted automated verification for all affected repos.

  Deliverable: tests cover audience selection, permission gating, API validation, worker delivery statuses, BFF proxy behavior, and UI guardrails.

  Expected behavior:
  - No live Telegram sends in tests; mock aiogram/Bot API calls.
  - Test blocked-user and retry-after behavior.
  - Test that mass send cannot run without image, text, permission, or current-session test send.
  - Test that non-staff and copywriting users without `copywriting.broadcast:send` cannot send.

  Commands:
  - `cd C:\Users\Indigo\Desktop\diaverse\diaverseapi; pytest tests/test_auth_bot_broadcast_audience.py tests/test_cabinet_rbac_seed.py tests/test_cabinet_staff_access_api.py`
  - `cd C:\Users\Indigo\Desktop\diaverse\aibot; pytest tests/test_broadcast_repository.py tests/test_broadcast_audience_client.py tests/test_broadcast_routes.py tests/test_broadcast_worker.py tests/test_telegram_service.py`
  - `cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend; npm run test:copywriting`
  - `cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend; npm run typecheck`

  Logging requirements:
  - Test assertions should verify meaningful log branches where practical: auth denial, validation failure, enqueue, campaign completion, blocked recipient.
  - Keep test output free of tokens, raw env values, and SSH details.

- [x] Task 11: Add documentation and deployment smoke checklist.

  Deliverable: docs explain the broadcast workflow, ownership boundaries, required env configuration, and safe rollout order.

  Expected behavior:
  - Document that the auth bot sends the Telegram messages from the user's perspective, but `aibot` owns campaign execution.
  - Document required env names without writing secret values.
  - Document that the first production action is test send to `8057982030`, then a carefully confirmed mass campaign.
  - Document rollback by repo: `diaweb` for UI/BFF, `aibot` for campaign/worker, `diaverseapi` for audience/RBAC.
  - After docs/code changes, run targeted GBrain sync.

  Files:
  - `docs/features/copywriting/auth-bot-broadcasts.md`
  - `docs/features/cabinet/auth-bot.md`
  - `docs/README.md` if navigation needs a new link
  - deployment notes in the relevant repo docs if existing runtime docs require it

  Commands:
  - `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\docs-health.ps1`
  - `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`

  Logging requirements:
  - Documentation must not contain raw SSH commands, IP addresses, bot tokens, internal secrets, or raw env values.
  - Smoke logs should record only sanitized campaign ID, test recipient ID, status, and aggregate delivery counters.

## Verification Plan

- `diaverseapi`: audience endpoint tests, RBAC seed tests, staff access tests.
- `aibot`: repository tests, route tests, audience client tests, worker tests, Telegram service tests with mocks.
- `diaweb`: copywriting BFF tests, UI tests, `npm run test:copywriting`, `npm run typecheck`.
- Docs: `scripts/docs-health.ps1`.
- Knowledge: targeted or full `scripts/gbrain-sync.ps1` after meaningful code/docs changes.

## Deployment And Smoke Notes

- Configure `diaverseapi` audience internal secret and route access before deploying `aibot`.
- Configure `aibot` with the auth bot token/profile and broadcast media directory.
- Deploy order: `diaverseapi` -> `aibot` -> `diaweb`.
- Smoke sequence:
  1. Confirm non-staff cannot access broadcast BFF routes.
  2. Confirm a sender without `copywriting.broadcast:send` cannot test or mass-send.
  3. Send a test broadcast to `8057982030`.
  4. Confirm the Telegram message arrives from the auth bot.
  5. Create a mass campaign only after test send succeeds.
  6. Watch campaign counters until all recipients are terminal.

## Risks And Guards

- Telegram can only DM users who started the auth bot and have not blocked it; blocked users must be recorded as terminal recipient failures.
- A mass DM can hit Telegram rate limits; worker must respect retry-after and avoid sending in the browser request path.
- `users.tg_user_id IS NOT NULL` is the durable proxy for "authorized through auth bot"; if historical precision needs more than that, a new consent/contact table is a later feature.
- The existing `publish` flow is draft/channel oriented and must not be overloaded for user DM broadcasts.
- The auth bot repo should remain stateless; adding campaigns there would violate the workspace architecture.
