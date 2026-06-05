# Implementation Plan: Crypton Status Telegram Notifications

Branch: none
Created: 2026-06-05
Mode: archived fast plan
Scope: `diaverseapi`, `diaverse-auth-bot`

## Settings

- Testing: yes
- Logging: verbose
- Docs: no

## Goal

Send Crypton decision status changes to the concrete user in Telegram from `diaverse-auth-bot`.

Messages must cover:

- approved: Crypton approved the request
- countered: Crypton approved the request but proposed another price
- rejected: Crypton rejected the request

Each Telegram message must include an image and a user-facing link to the offers page, not a staff/admin link. The primary link should be built from `CABINET_PUBLIC_BASE_URL` and point to the user offers surface, for example `https://diaverse.app/ru/offers`.

## Current Understanding

- `diaverse-auth-bot` is currently a stateless aiogram polling runtime for `/start login_<token>` and mobile `auth_`/`authdev_` links.
- `diaverse-auth-bot` already signs calls to `diaverseapi` with `AUTH_BOT_INTERNAL_SECRET`.
- `diaverseapi` already records auth-bot reachable users in `auth_bot_broadcast_contacts` through login/mobile approve flows.
- `diaverseapi` currently creates web notifications in `CabCryptonService._create_decision_notification`.
- `diaverseapi/app/club` already has a durable Telegram outbox pattern with claim/ack/nack and retries; the Crypton/auth-bot integration should follow that shape instead of adding inbound public HTTP to the bot host.
- Current Crypton web assets are `.avif`; Telegram photo delivery uses a dedicated Crypton image URL. Product/item images must not be sent in user status notifications.

## Repository Matrix

| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `dev` | clean | backend state, outbox, Crypton decision hook |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | yes | `feature/auth-tgbot` | clean | Telegram delivery worker |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | no | `dev` | clean | no frontend change expected |
| root `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan only | current | plan update only | coordination |

## Decisions

1. Use a `diaverseapi`-owned outbox for Telegram delivery.
   - Auth bot remains stateless and polls signed internal endpoints.
   - Delivery gets idempotency, retry, ack/nack, and failure visibility.

2. Use `auth_bot_broadcast_contacts` as the primary "can message this user from auth bot" audience.
   - If a contact row is missing, fall back to `users.tg_user_id` only when that is safe and the user has started the bot.
   - If no Telegram target exists, skip Telegram delivery and keep the web notification.

3. Telegram delivery is non-fatal for Crypton decisions.
   - Admin approve/reject must not fail because Telegram is unavailable.
   - Failures stay in the outbox for retry/dead-letter handling.

4. The user link must be user-facing.
   - Use `CABINET_PUBLIC_BASE_URL`.
   - Link to `/{lang}/offers`, defaulting to `/ru/offers` when user language is unknown.
   - Do not send staff/admin/shop links to the user.

5. Image delivery should use the Crypton brand/status image.
   - Use `CRYPTON_TELEGRAM_IMAGE_URL` as the primary image.
   - Do not use selected offer or product item images.
   - Fall back to `CRYPTON_TELEGRAM_FALLBACK_IMAGE_URL` only when the primary image URL is empty.
   - If photo delivery fails because the image is invalid, send the same caption as text and nack/record the image problem according to the final retry policy.

## Tasks

### Phase 1: Backend outbox persistence and contract

- [x] Task 1: Add auth-bot Telegram outbox persistence in `diaverseapi`.
  - Files: `diaverseapi/app/security/models.py`, new Alembic migration under `diaverseapi/alembic/versions/`, likely `diaverseapi/app/security/schemas.py`.
  - Deliverable: table for pending/sent/failed/dead-letter commands with `user_id`, `tg_user_id`, `command_type`, `idempotency_key`, `payload_json`, lease fields, attempt counters, `telegram_message_id`, and error fields.
  - Logging: INFO on enqueue/reuse, DEBUG for lease state changes, WARN for invalid command state, ERROR only for unrecoverable persistence failures.

- [x] Task 2: Add signed internal claim/ack/nack endpoints for auth bot in `diaverseapi`.
  - Files: `diaverseapi/app/security/api.py`, `diaverseapi/app/security/dependecies.py`, `diaverseapi/app/security/schemas.py`, possible new `diaverseapi/app/security/auth_bot_outbox.py`.
  - Deliverable: `POST /v1/auth/internal/auth-bot-outbox/claim`, `POST /v1/auth/internal/auth-bot-outbox/{command_id}/ack`, and `POST /v1/auth/internal/auth-bot-outbox/{command_id}/nack`.
  - Logging: DEBUG for signature/claim request metadata, INFO for claimed/acked/nacked command counts, WARN for worker mismatch or stale lease, ERROR for invalid internal state.
  - Depends on: Task 1.

### Phase 2: Crypton enqueue logic

- [x] Task 3: Enqueue Telegram decision messages from Crypton decisions.
  - Files: `diaverseapi/app/cabinet/offers/crypton/service.py`, possible helper in `diaverseapi/app/cabinet/offers/crypton/telegram_notifications.py`.
  - Deliverable: after `_create_decision_notification`, enqueue one auth-bot outbox command per `(request_id, status)` for `approved`, `countered`, and `rejected`; use existing web notification idempotency key shape as the source of truth.
  - Logging: DEBUG with request/status/user lookup path, INFO when command is enqueued or reused, WARN when no Telegram recipient/image/link can be resolved, no raw secrets or tokens.
  - Depends on: Task 1.

- [x] Task 4: Build Telegram payload and user-facing link.
  - Files: `diaverseapi/app/cabinet/offers/crypton/service.py`, `diaverseapi/app/core/settings.py`.
  - Deliverable: payload includes status, item title, quantity, requested price, market price, Crypton decision price, discount text, optional reason, image URL, and `offers_url`.
  - Link requirement: `offers_url` must resolve to the user page, for example `https://diaverse.app/ru/offers`; never `staff/shop`.
  - Image requirement: use the configured Crypton image, not the selected item image; `CRYPTON_TELEGRAM_FALLBACK_IMAGE_URL` is only a compatibility fallback.
  - Logging: DEBUG for normalized payload fields excluding sensitive values, WARN for missing `CABINET_PUBLIC_BASE_URL` or unsupported image fallback, INFO for final payload readiness.
  - Depends on: Task 3.

### Phase 3: Auth bot delivery worker

- [x] Task 5: Add auth bot backend outbox client.
  - Files: `diaverse-auth-bot/app/clients/backend.py`, `diaverse-auth-bot/app/schemas/backend.py`, `diaverse-auth-bot/app/config.py`, `.env.example`.
  - Deliverable: signed methods to claim, ack, and nack auth-bot outbox commands using existing `AUTH_BOT_INTERNAL_SECRET`.
  - New env names: `AUTH_BOT_OUTBOX_WORKER_ID`, `AUTH_BOT_OUTBOX_POLL_SECONDS`, `AUTH_BOT_OUTBOX_BATCH_SIZE`, `AUTH_BOT_OUTBOX_LEASE_SECONDS`.
  - Logging: DEBUG for request paths and batch metadata, INFO for successful claim/ack/nack, WARN for upstream non-2xx, ERROR for transport failures.
  - Depends on: Task 2.

- [x] Task 6: Add Telegram command executor in `diaverse-auth-bot`.
  - Files: new `diaverse-auth-bot/app/services/outbox_delivery.py`, `diaverse-auth-bot/app/bot.py` or `app/main.py`.
  - Deliverable: execute `send_photo` with caption for Crypton status messages; fall back to `send_message` if image is absent or invalid according to the chosen policy; preserve Telegram message id in ack payload.
  - Message content: Russian copy for approved/countered/rejected, includes the user-facing offers link.
  - Logging: INFO for delivery start/success, WARN for Telegram retryable errors and blocked users, ERROR for unexpected executor failures; never log bot token.
  - Depends on: Task 5.

- [x] Task 7: Run auth bot outbox polling loop alongside existing Telegram polling.
  - Files: `diaverse-auth-bot/app/main.py`, possibly `diaverse-auth-bot/app/bot.py`.
  - Deliverable: background loop claims commands every configured interval, executes them, and ack/nack responses; shutdown cleanly closes bot/backend sessions.
  - Logging: INFO on loop start/stop and processed count, DEBUG on idle ticks, WARN on retry loop failures, ERROR on repeated unexpected failures.
  - Depends on: Task 6.

### Phase 4: Tests and verification

- [x] Task 8: Add backend tests for outbox and Crypton enqueue.
  - Files: `diaverseapi/tests/test_auth_bot_outbox.py`, `diaverseapi/tests/test_cabinet_crypton.py`, `diaverseapi/tests/test_auth_bot_broadcast_audience.py` if needed.
  - Deliverable: test idempotent enqueue, recipient lookup from `auth_bot_broadcast_contacts`, fallback/skip behavior, claim/ack/nack transitions, worker mismatch, approved/countered/rejected payload text, and user-facing `/ru/offers` link.
  - Logging: tests should assert important warning/error paths through behavior or captured logs where useful.
  - Depends on: Tasks 1-4.

- [x] Task 9: Add auth bot tests for polling client and Telegram executor.
  - Files: `diaverse-auth-bot/tests/test_backend_client.py`, new `diaverse-auth-bot/tests/test_outbox_delivery.py`, possible `tests/test_main.py`.
  - Deliverable: test signed claim/ack/nack requests, `send_photo` payload, text fallback, blocked/retryable error handling, ack/nack payloads, and worker loop single-tick behavior.
  - Logging: tests should cover delivery failure classification without exposing tokens.
  - Depends on: Tasks 5-7.

- [x] Task 10: Run targeted verification and migration checks.
  - Files: no product files unless failures require fixes.
  - Backend commands:
    - `cd diaverseapi`
    - `.venv\Scripts\python.exe -m pytest tests/test_cabinet_crypton.py tests/test_auth_bot_broadcast_audience.py tests/test_auth_bot_outbox.py -q`
    - `.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
  - Auth bot commands:
    - `cd diaverse-auth-bot`
    - `python -m pytest -q`
  - Logging: record verification failures with command, repo, and failing test names; do not log env values.
  - Depends on: Tasks 8-9.

## Commit Plan

- **Commit 1** after tasks 1-4 in `diaverseapi`: `feat(api): enqueue crypton auth bot notifications`
- **Commit 2** after tasks 5-7 in `diaverse-auth-bot`: `feat(auth-bot): deliver crypton status notifications`
- **Commit 3** after tasks 8-10 split per repo as needed:
  - `test(api): cover crypton auth bot outbox`
  - `test(auth-bot): cover crypton outbox delivery`

## Deployment Notes

- Deploy `diaverseapi` first so outbox endpoints and table exist.
- Run the Alembic migration on the production API database.
- Deploy `diaverse-auth-bot` after the API endpoints are live.
- Add auth bot outbox env values on the foreign bot host.
- Add `CRYPTON_TELEGRAM_FALLBACK_IMAGE_URL` and confirm `CABINET_PUBLIC_BASE_URL=https://diaverse.app` on prod API.
- Smoke test with one Crypton decision for a known user who has started auth bot.

## Risks

- Telegram bots can only message users who have started the bot and have not blocked it.
- If the image URL is AVIF or inaccessible to Telegram, photo send can fail; fallback behavior must prevent lost status messages.
- Admin decision must remain non-fatal even if Telegram delivery is down.
- Outbox migration needs short explicit index/constraint names to avoid PostgreSQL identifier truncation.
