# Implementation Plan: Club10000 Bot Broadcasts In Copywriting

Branch: none
Created: 2026-06-02
Mode: fast workspace plan

## Settings

- Testing: yes
- Logging: verbose
- Docs: yes
- Branching: none in fast mode
- Affected repositories: `diaweb`, `aibot`, `club10000-bot`, `diaverseapi`, root docs
- Not affected for source changes: `diaverse-auth-bot`

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first through `scripts\gbrain.ps1`, then raw source verification
- Previous fast plan backup: `.ai-factory/plans/2026-06-02-auth-bot-broadcasts-fast.md`

## Repository Matrix

| Repository | Path | Affected | Branch | Role |
| --- | --- | --- | --- | --- |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | unchanged | staff copywriting UI, club tab, same-origin BFF |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | yes | unchanged | broadcast campaign API, media storage, worker delivery, Telegram Bot API profile |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | yes | unchanged | Club10000 local audience truth: users, payment attempts, subscriptions |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | unchanged | staff RBAC permission truth only |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | unchanged | unrelated auth transport |
| root docs | `C:\Users\Indigo\Desktop\diaverse\docs` | yes | unchanged | feature docs and rollout notes |

## Product Decisions

- Sender is `@club10000_bot`, not auth bot and not Telegram userbot.
- Browser entrypoint stays in staff copywriting; add a club broadcast surface inside the existing copywriting Club tab.
- Image is mandatory for every club broadcast.
- Text is mandatory for every club broadcast.
- Test send is required before mass send in the current page session.
- Test send goes to configured staff Telegram ID, defaulting to `8057982030`.
- MVP sending is immediate only: no scheduling, no drafts, no campaign editing after queueing.
- Segment dropdown values:
  - `all`: all Club10000 bot users where `is_bot=false` and `is_blocked=false`.
  - `started_payment_not_paid`: users with at least one `pay1time_payment_attempts` row, no successful payment, and not blocked.
  - `paid`: users who have ever paid successfully, based on `pay1time_payment_attempts.status='SUCCESS'` or `payments.status='COMPLETED'`, and not blocked.
- "Started payment" means "entered payment flow / generated payment attempt", because the current bot creates attempts when payment links are generated.
- "Paid" means "ever successfully paid" for MVP. A separate `active_subscription` segment can be added later if the product needs current active-only membership.
- Add a live audience preview count for the selected segment before test/send.
- Use a dedicated permission: `copywriting.club.broadcast:send`; superadmin receives it by default, ordinary employees do not.

## Architecture Sketch

```text
Staff browser
  -> diaweb /[lang]/staff/copywriting/club
  -> diaweb BFF /api/staff/copywriting/club-broadcasts/*
  -> aibot /internal/v1/club-broadcasts/*
  -> aibot job send_broadcast_campaign
  -> signed club10000-bot audience page requests with segment
  -> Telegram Bot API with bot_profile=club10000
  -> campaign and recipient counters
  -> diaweb polls campaign status
```

## Research Context

- Existing auth-bot broadcast docs define the working pattern: `diaweb` BFF/UI, `aibot` campaign API and worker, signed audience paging, Telegram Bot API delivery, and campaign counters.
- `club10000-bot` owns durable Club10000 funnel state in `users`, `pay1time_payment_attempts`, `payments`, and `club_subscriptions`.
- `pay1time_payment_attempts` stores both Pay1Time and Prodamus attempts; successful Prodamus callbacks set `status='SUCCESS'`.
- Current `aibot.copywriting_broadcast_recipients.user_id` is a UUID for auth-bot users, so club recipients need a safe cross-source identifier change, not a fake UUID.
- Production sampling during exploration showed the segment sizes are small enough for the same async materialization/delivery model, but counts should be computed live.

## Out Of Scope

- Scheduled club broadcasts.
- Text-only broadcasts.
- Active-subscription-only segment unless explicitly added later.
- Editing/cancelling campaigns after they start.
- Rebuilding Club10000 funnel or payment callback logic.
- Browser calls directly to `club10000-bot`.
- Sending through the Premium Telegram userbot.

## Tasks

### Phase 1: Audience And Permission Contract

- [x] Task 1: Add a signed Club10000 broadcast audience endpoint in `club10000-bot`.

  Deliverable: paginated internal endpoint returning sendable Club10000 recipients for `all`, `started_payment_not_paid`, and `paid`.

  Expected behavior:
  - Add internal route under `club10000-bot/app/bot.py`, for example `GET /internal/v1/broadcast-recipients`.
  - Require HMAC-style service authentication with env settings in `club10000-bot/app/config.py`.
  - Accept `segment`, `limit`, and `cursor`.
  - Return `recipients`, `total_count`, and `next_cursor`.
  - Recipient shape should include `external_user_id` as Club10000 `users.id`, `tg_user_id`, and optional `tg_username`.
  - Exclude `is_bot=true` and `is_blocked=true` for every segment.
  - Never expose phone, email, payment URLs, invoice IDs, or subscription identifiers.

  Files:
  - `club10000-bot/app/bot.py`
  - `club10000-bot/app/config.py`
  - `club10000-bot/app/models/user.py`
  - `club10000-bot/app/models/pay1time_attempt.py`
  - `club10000-bot/app/models/payment.py`
  - `club10000-bot/tests/test_club_broadcast_audience.py`

  Logging requirements:
  - Log `INFO` for accepted audience page requests with request id, segment, limit, returned count, total count, and whether next cursor exists.
  - Log `WARN` for rejected signatures without logging secrets or raw signatures.
  - Log `DEBUG` for segment query boundaries in local/dev only if useful.

- [x] Task 2: Add dedicated RBAC permission for Club10000 broadcasts.

  Deliverable: `copywriting.club.broadcast:send` exists in backend RBAC, reaches diaweb staff access claims, and is accepted by `aibot`.

  Expected behavior:
  - Superadmin receives the permission by default.
  - Ordinary employee/copywriting staff do not receive it automatically.
  - `diaweb` copywriting BFF preserves the `copywriting.club.broadcast:` namespace when minting internal JWTs.
  - `aibot` club broadcast send/test endpoints require `copywriting.club.broadcast:send`.

  Files:
  - `diaverseapi/app/cabinet/rbac/seed.py`
  - `diaverseapi/tests/test_cabinet_rbac_seed.py`
  - `diaverseapi/tests/test_cabinet_staff_access_api.py`
  - `diaweb/frontend/app/api/staff/copywriting/_auth.ts`
  - `diaweb/frontend/__tests__/shared/auth-permissions.test.ts`
  - `aibot/app/api/deps/auth.py` only if clearer permission errors are needed

  Logging requirements:
  - Keep backend RBAC seed logging at existing levels.
  - Log `WARN` in `aibot` on permission denial with request id, user id, and missing permission only.

### Phase 2: Aibot Broadcast Generalization

- [x] Task 3: Extend `aibot` broadcast persistence for multiple audience sources.

  Deliverable: existing auth-bot broadcast tables can safely store both auth recipients and Club10000 recipients.

  Expected behavior:
  - Add campaign fields such as `audience_source`, `audience_segment`, and `bot_profile`.
  - Add recipient field such as `external_user_id` and make auth-specific `user_id` nullable or otherwise avoid fake UUIDs.
  - Preserve existing auth-bot campaign behavior and existing rows.
  - Keep uniqueness on `(campaign_id, tg_user_id)`.
  - Add migration with short explicit PostgreSQL-safe index/constraint names.

  Files:
  - `aibot/db/models.py`
  - `aibot/db/repositories/broadcast_repo.py`
  - `aibot/migrations/<next>_copywriting_broadcast_sources.sql`
  - `aibot/tests/test_broadcast_repository.py`

  Logging requirements:
  - Log `INFO` for campaign creation with audience source, segment, bot profile, and request id.
  - Log `DEBUG` for recipient upsert counts by campaign and audience source.
  - Never log message text, local media path, payment data, or raw Telegram IDs beyond existing sanitized recipient ids.

- [x] Task 4: Add `aibot` Club10000 audience client and preview count.

  Deliverable: `aibot` can fetch and count Club10000 broadcast recipients with signed pagination.

  Expected behavior:
  - Add settings for Club10000 audience base URL, secret, key id, timeout, and page size.
  - Add a client similar to `DiaverseapiBroadcastAudienceClient`, but targeting `club10000-bot` and accepting segment.
  - Add `GET /internal/v1/club-broadcasts/audience-preview?segment=...` to return live `total_count`.
  - Treat config/auth errors as non-retryable and transport/upstream as retryable where appropriate.

  Files:
  - `aibot/core/config.py`
  - `aibot/app/infrastructure/club10000_broadcast_audience_client.py`
  - `aibot/app/api/routes/club_broadcasts.py`
  - `aibot/app/api/schemas/broadcasts.py`
  - `aibot/tests/test_club10000_broadcast_audience_client.py`
  - `aibot/tests/test_broadcast_routes.py`

  Logging requirements:
  - Log `INFO` for preview requests with segment and total count.
  - Log `WARN` for unavailable upstream with error type and retryability.
  - Do not log secrets, signatures, phone/email/payment data, or full upstream payloads.

- [x] Task 5: Add Club10000 test-send and campaign-create API in `aibot`.

  Deliverable: internal endpoints mirror auth-bot broadcasts but require segment and use Club10000 bot profile.

  Expected behavior:
  - Add endpoints such as:
    - `POST /internal/v1/club-broadcasts/test`
    - `POST /internal/v1/club-broadcasts`
    - `GET /internal/v1/club-broadcasts`
    - `GET /internal/v1/club-broadcasts/{campaign_id}`
  - Multipart form requires `image`, `text`, and `segment`.
  - Reuse existing image storage and safe Telegram HTML normalization.
  - Test send uses `bot_profile=club10000` and the configured test recipient.
  - Campaign creation stores audience source/segment/profile and enqueues the existing worker kind with source metadata.
  - Listing should scope to Club10000 campaigns so auth-bot campaigns do not clutter the club view.

  Files:
  - `aibot/app/api/routes/club_broadcasts.py`
  - `aibot/app/application/use_cases/broadcasts.py`
  - `aibot/app/api/main.py`
  - `aibot/tests/test_broadcast_routes.py`
  - `aibot/tests/test_broadcast_formatting.py`

  Logging requirements:
  - Log `INFO` for test send and campaign enqueue with source, segment, image size, text length, and job id.
  - Log `WARN` for invalid segment or missing multipart fields.
  - Never log message text or image bytes.

- [x] Task 6: Update broadcast worker delivery for source-specific audience and bot profile.

  Deliverable: the worker materializes Club10000 recipients and sends through the Club10000 bot token while keeping auth-bot delivery intact.

  Expected behavior:
  - Route materialization by campaign `audience_source`.
  - For auth campaigns, keep the existing diaverseapi audience client.
  - For Club10000 campaigns, call the new Club10000 audience client with stored segment.
  - Send through campaign `bot_profile`, expected `club10000`.
  - Preserve blocked/retry/failed handling and campaign counters.
  - Optionally mark users blocked in `club10000-bot` only through a deliberate follow-up endpoint; do not write remote state from worker in MVP.

  Files:
  - `aibot/app/application/use_cases/broadcast_delivery.py`
  - `aibot/app/worker/processors/send_broadcast_campaign.py`
  - `aibot/services/telegram_service.py` only if profile resolution needs a test seam
  - `aibot/tests/test_broadcast_worker.py`
  - `aibot/tests/test_worker_loop.py`

  Logging requirements:
  - Log `INFO` at campaign start/done with source, segment, profile, and sanitized counters.
  - Log `WARN` for recipient delivery failures with recipient row id, status, retryability, and error type.
  - Do not log full Telegram error strings if they may contain user-specific text beyond the safe truncated existing behavior.

### Phase 3: Diaweb UI And BFF

- [x] Task 7: Add club broadcast BFF routes in `diaweb`.

  Deliverable: browser calls same-origin diaweb routes, never direct `aibot` or `club10000-bot`.

  Expected behavior:
  - Add routes under `frontend/app/api/staff/copywriting/club-broadcasts/*`.
  - Proxy preview, test, create, list, and detail endpoints to `aibot`.
  - Multipart proxy preserves `image`, `text`, and `segment`.
  - Requests require staff copywriting auth and pass the new permission namespace in the internal JWT.

  Files:
  - `diaweb/frontend/app/api/staff/copywriting/club-broadcasts/route.ts`
  - `diaweb/frontend/app/api/staff/copywriting/club-broadcasts/test/route.ts`
  - `diaweb/frontend/app/api/staff/copywriting/club-broadcasts/audience-preview/route.ts`
  - `diaweb/frontend/app/api/staff/copywriting/club-broadcasts/[id]/route.ts`
  - `diaweb/frontend/__tests__/app/api/staff/copywriting/club-broadcasts-route.test.ts`

  Logging requirements:
  - Log `WARN` for invalid multipart/content-type and invalid segment.
  - Log `ERROR` for transport failures with route and sanitized error message.
  - Do not log image bytes or message text.

- [x] Task 8: Add Club10000 broadcast UI inside `CopywritingClubView`.

  Deliverable: copywriting Club tab has a local segmented control with current useful-content panel and a new broadcasts panel.

  Expected behavior:
  - Add a local tab/segmented control: useful content and Club10000 broadcasts.
  - Broadcast panel includes image upload, text area, segment dropdown, live audience count, test send, send button, confirmation, and recent campaigns.
  - Test-send fingerprint includes selected segment so changing segment requires a fresh test.
  - Send button stays disabled until image, text, segment, audience preview, and fresh test are present.
  - Campaign counters/status polling works like auth-bot broadcasts.
  - Text link behavior matches auth-bot broadcasts; users can paste hidden links as HTML, Markdown links, or Telegram-copied `text (https://...)`.

  Files:
  - `diaweb/frontend/modules/copywriting/components/CopywritingClubView.tsx`
  - `diaweb/frontend/modules/copywriting/components/CopywritingClubBroadcastsView.tsx`
  - `diaweb/frontend/modules/copywriting/api.ts`
  - `diaweb/frontend/modules/copywriting/hooks.ts`
  - `diaweb/frontend/modules/copywriting/types.ts`
  - `diaweb/frontend/modules/i18n/dictionaries/ru.ts`
  - `diaweb/frontend/modules/i18n/dictionaries/en.ts`
  - `diaweb/frontend/modules/i18n/types.ts`
  - `diaweb/frontend/__tests__/modules/copywriting/CopywritingClubBroadcastsView.test.tsx`
  - `diaweb/frontend/__tests__/modules/copywriting/broadcast-api.test.ts`

  Logging requirements:
  - Use existing `logCopywritingEvent` for preview/test/create failures and successful campaign enqueue.
  - Log selected segment and campaign/job ids, not message text or image data.

### Phase 4: Docs, Configuration, And Rollout

- [x] Task 9: Update runtime configuration and deployment templates.

  Deliverable: both services have explicit env examples and compose/runtime notes for Club10000 broadcasts.

  Expected behavior:
  - `club10000-bot` exposes only the signed internal audience endpoint and keeps browser traffic out.
  - `aibot` has `TELEGRAM_BOT_TOKEN_CLUB10000` or a clearly named profile token for `bot_profile=club10000`.
  - Preserve existing `TELEGRAM_BOT_TOKEN_CLUB` behavior for Diaverse club operations if it is distinct.
  - Do not print or commit raw tokens/secrets.

  Files:
  - `club10000-bot/.env.example`
  - `club10000-bot/docker-compose.production.yml`
  - `aibot/.env.example`
  - `aibot/core/config.py`
  - `aibot/docker-compose.prod.yml`
  - root docs under `docs/features/copywriting/`

  Logging requirements:
  - Startup logs may say whether Club10000 broadcast audience config is present, but must not print secret values.
  - API logs should identify missing config by setting name only.

- [x] Task 10: Document Club10000 broadcast workflow.

  Deliverable: long-lived docs cover ownership, segment definitions, rollout, smoke, and rollback.

  Expected behavior:
  - Add `docs/features/copywriting/club10000-broadcasts.md`.
  - Link it from `docs/README.md` and optionally from existing auth-bot broadcast docs.
  - Include segment definitions and note that `started_payment_not_paid` means payment-flow attempt, not guaranteed external checkout click.
  - Include safe smoke sequence: preview count, test-send to staff, then mass send only after confirmation.
  - Do not include server IPs, SSH commands, token values, raw env values, or private operational traces.

  Files:
  - `docs/features/copywriting/club10000-broadcasts.md`
  - `docs/features/copywriting/auth-bot-broadcasts.md`
  - `docs/README.md`

  Logging requirements:
  - Not applicable for docs, but docs must restate that runtime logs cannot contain message text, image bytes, secrets, phone/email, or payment identifiers.

- [x] Task 11: Verify end-to-end behavior locally and with safe production probes.

  Status 2026-06-02: local automated verification completed across `club10000-bot`, `aibot`, `diaweb`, `diaverseapi`, docs health, and GBrain sync. Post-deploy configuration and safe smoke are complete: `aibot` can reach `club10000-bot` over the internal signed audience endpoint, all three segment previews return counts, `diaweb` BFF routes are deployed and protected, and the new `diaverseapi` RBAC permission exists in runtime. No mass send was performed.

  Deliverable: targeted automated tests pass and smoke probes confirm no mass send happens without explicit button flow.

  Expected behavior:
  - Run backend/unit tests for each affected repo.
  - Run typecheck for `diaweb`.
  - Run a signed audience preview probe only; do not mass-send in smoke.
  - Test-send only to the configured staff Telegram ID.
  - Confirm auth-bot broadcast still works after generalized persistence/worker changes.

  Verification commands:
  ```powershell
  cd C:\Users\Indigo\Desktop\diaverse\club10000-bot
  python -m pytest tests\test_club_broadcast_audience.py tests\test_prodamus_callback.py tests\test_start_handler.py -q
  python -m ruff check app tests

  cd C:\Users\Indigo\Desktop\diaverse\aibot
  .venv\Scripts\python.exe -m pytest tests\test_broadcast_repository.py tests\test_broadcast_audience_client.py tests\test_club10000_broadcast_audience_client.py tests\test_broadcast_routes.py tests\test_broadcast_worker.py tests\test_worker_loop.py tests\test_telegram_service.py -q

  cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
  npm run test -- __tests__/app/api/staff/copywriting/club-broadcasts-route.test.ts __tests__/modules/copywriting/CopywritingClubBroadcastsView.test.tsx __tests__/modules/copywriting/broadcast-api.test.ts __tests__/shared/auth-permissions.test.ts
  npm run typecheck

  cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
  .venv\Scripts\python.exe -m pytest tests\test_cabinet_rbac_seed.py tests\test_cabinet_staff_access_api.py -q
  .venv\Scripts\python.exe -m ruff check app\cabinet\rbac tests\test_cabinet_rbac_seed.py tests\test_cabinet_staff_access_api.py
  ```

  Logging requirements:
  - Capture only sanitized verification outcomes.
  - Do not store Telegram message text, image bytes, raw secrets, private server addresses, or SSH commands in public docs/daily.

## Risks And Considerations

- `aibot` currently stores recipient `user_id` as UUID; this must be generalized carefully so existing auth-bot campaigns and tests continue to pass.
- `club10000-bot` `pay1time_payment_attempts` represents generated payment attempts; the product text should avoid implying a confirmed external checkout start.
- `is_blocked` counts can change as users interact with the bot; audience is live and should be materialized at campaign send time.
- If `TELEGRAM_BOT_TOKEN_CLUB` and Club10000 bot token are different, use a new profile name such as `club10000` to avoid accidentally sending from the Diaverse club system bot.
- A failed old campaign should be shown as failed/dead-letter rather than visually staying queued; this is a nice-to-have UI polish if encountered again.

## Commit Plan

- `diaverseapi`: `feat: add club broadcast permission`
- `club10000-bot`: `feat: expose club broadcast audience`
- `aibot`: `feat: add club10000 broadcast campaigns`
- `diaweb`: `feat: add club broadcast UI`
- root docs: `docs: document club10000 broadcast workflow`
