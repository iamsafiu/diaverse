# Club10000 Broadcasts In Copywriting

[Back to Docs](../../README.md)

## Назначение

Club10000 broadcast - staff-инструмент внутри вкладки copywriting Club для мгновенной рассылки Telegram-сообщения пользователям `@club10000_bot`. Кампания создается и доставляется через `aibot`, браузер работает только через same-origin BFF в `diaweb`, а аудитория берется из durable state `club10000-bot`.

## Ownership

| Область | Владелец |
| --- | --- |
| Staff UI and same-origin BFF | `diaweb` |
| Campaign API, image storage, worker delivery, recipient counters | `aibot` |
| Club10000 audience truth, funnel state, payment attempts, subscriptions | `club10000-bot` |
| Staff RBAC permission truth | `diaverseapi` |
| Telegram sender identity | `@club10000_bot` through `bot_profile=club10000` |

## Product Contract

- Sender is `@club10000_bot`.
- Image is mandatory.
- Text is mandatory.
- Test send is mandatory before mass send in the current browser session.
- Test send recipient is configured by `COPYWRITING_CLUB_BROADCAST_TEST_TG_USER_ID`.
- Mass send is immediate only in the MVP: no scheduling, no drafts, no editing after queueing.
- Required permission for send/test is `copywriting.club.broadcast:send`.
- Ordinary copywriting staff do not receive `copywriting.club.broadcast:send` automatically.
- Campaign creation returns after enqueue; browser requests must never wait for all Telegram sends.

## Segments

| Segment | UI label | Definition |
| --- | --- | --- |
| `all` | Все | `club10000-bot.users` where `is_bot=false` and `is_blocked=false`. |
| `started_payment_not_paid` | Начали оплату, но не завершили | Users with at least one `pay1time_payment_attempts` row, no successful attempt, no completed payment, and not blocked. |
| `paid` | Оплатили | Users who have ever paid successfully, based on `pay1time_payment_attempts.status='SUCCESS'` or `payments.status='COMPLETED'`, and not blocked. |

`started_payment_not_paid` means the bot generated a payment attempt or payment link. It does not prove the user clicked through or opened the external checkout form.

`paid` means ever successfully paid for MVP. If product needs only current active members later, add a separate `active_subscription` segment instead of changing this definition silently.

## Runtime Flow

```text
Staff browser
  -> diaweb /[lang]/staff/copywriting/club
  -> diaweb BFF /api/staff/copywriting/club-broadcasts/*
  -> aibot /internal/v1/club-broadcasts/*
  -> aibot job send_broadcast_campaign
  -> signed club10000-bot audience page requests with segment
  -> Telegram Bot API through club10000 bot profile
  -> campaign and recipient counters
  -> diaweb polls campaign status
```

## Required Configuration

Do not store raw values in docs, git, daily public digest, scripts, or screenshots.

### `club10000-bot`

- `BROADCAST_AUDIENCE_SECRET`
- `BROADCAST_AUDIENCE_KEY_ID`
- `BROADCAST_AUDIENCE_SIGNATURE_TOLERANCE_SECONDS`
- `BROADCAST_AUDIENCE_PAGE_SIZE`
- `BROADCAST_AUDIENCE_MAX_LIMIT`

The audience endpoint is signed internal API. The production compose file must not publish direct host ports for the bot runtime; public/webhook access should stay behind the reviewed reverse proxy.

### `aibot`

- `COPYWRITING_CLUB_BROADCAST_AUDIENCE_BASE_URL`
- `COPYWRITING_CLUB_BROADCAST_AUDIENCE_SECRET`
- `COPYWRITING_CLUB_BROADCAST_AUDIENCE_KEY_ID`
- `COPYWRITING_CLUB_BROADCAST_AUDIENCE_TIMEOUT_SECONDS`
- `COPYWRITING_CLUB_BROADCAST_AUDIENCE_PAGE_SIZE`
- `COPYWRITING_CLUB_BROADCAST_TEST_TG_USER_ID`
- `COPYWRITING_CLUB_BROADCAST_BOT_PROFILE`
- `TELEGRAM_BOT_TOKEN_CLUB10000` when `COPYWRITING_CLUB_BROADCAST_BOT_PROFILE=club10000`
- `COPYWRITING_BROADCAST_MEDIA_DIR`
- `COPYWRITING_BROADCAST_MAX_IMAGE_SIZE_BYTES`

The path configured by `COPYWRITING_BROADCAST_MEDIA_DIR` must be shared between `copywriting-api` and `copywriting-worker`, because the API stores the uploaded image and the worker reads it during Telegram delivery.

### `diaweb`

Existing staff copywriting BFF configuration remains required:

- copywriting service URL
- internal JWT signing secret
- copywriting request timeout

### `diaverseapi`

RBAC seed must include `copywriting.club.broadcast:send`; superadmin receives it through the full permission set.

## API Surfaces

| Repo | Endpoint | Purpose |
| --- | --- | --- |
| `club10000-bot` | `GET /internal/v1/broadcast-recipients` | Signed internal Club10000 audience page with `segment`, `limit`, and `cursor`. |
| `aibot` | `GET /internal/v1/club-broadcasts/audience-preview` | Live count for selected segment. |
| `aibot` | `POST /internal/v1/club-broadcasts/test` | Test send to configured staff Telegram ID. |
| `aibot` | `POST /internal/v1/club-broadcasts` | Store image, create source-scoped campaign, enqueue worker job. |
| `aibot` | `GET /internal/v1/club-broadcasts` | Recent Club10000 campaign list. |
| `aibot` | `GET /internal/v1/club-broadcasts/{campaign_id}` | Campaign status and counters. |
| `diaweb` | `/api/staff/copywriting/club-broadcasts/*` | Same-origin BFF proxy for staff browser. |

## Delivery Semantics

- `aibot` materializes recipients idempotently per campaign.
- Club recipients store `external_user_id` from `club10000-bot`, not a fake backend UUID.
- `aibot` sends a photo with caption when the text fits Telegram caption limits.
- If the text is too long for a caption, `aibot` sends the photo first and the text as a second message.
- Broadcast text is normalized to safe Telegram HTML before test send, campaign storage, and worker delivery.
- Safe links can be entered as `<a href="https://example.com">visible text</a>`.
- Markdown-style links such as `[visible text](https://example.com)` are converted to Telegram HTML.
- Telegram-copied hidden links that paste as `visible text (https://example.com)` on a single line are converted back into a hidden link for that line.
- Blocked, forbidden, or chat-not-found recipients become terminal `blocked`.
- Retry-after and rate-limit style errors move recipients to `retry_pending` and requeue the worker job.
- Campaign status becomes `completed` only when all recipients are terminal.
- Campaign-level unrecoverable errors such as missing media, invalid audience auth, unknown source, or missing bot token can mark the campaign `failed`.

## Safe Rollout

Deploy order:

1. `club10000-bot`: signed audience endpoint and env configuration.
2. `diaverseapi`: RBAC permission.
3. `aibot`: migration, source-aware campaign API, audience client, worker delivery, bot profile token.
4. `diaweb`: BFF routes and Club tab UI.
5. Root docs: workflow and rollback references.

Smoke sequence:

1. Confirm a staff user without `copywriting.club.broadcast:send` cannot test-send or create a Club10000 campaign.
2. Confirm a sender with `copywriting.club.broadcast:send` can open the Club tab and switch to Broadcasts.
3. Select each segment and verify the preview count returns without exposing payment, phone, email, or subscription data.
4. Upload a small approved image and enter short text.
5. Send the test broadcast to the configured test Telegram ID.
6. Confirm the Telegram message arrives from `@club10000_bot`.
7. Create the mass campaign only after the test succeeds and the UI confirmation is accepted.
8. Watch campaign counters until all recipients are terminal.

Do not use a production smoke to mass-send unless the operator explicitly confirms the selected content and segment.

## Rollback

| Repo | Rollback action |
| --- | --- |
| `diaweb` | Hide the Club Broadcasts local tab or remove the BFF routes. Existing campaigns in `aibot` are unaffected. |
| `aibot` | Stop the worker or disable the broadcast processor to halt delivery; keep DB rows for audit. |
| `club10000-bot` | Disable audience secret/config access only after `aibot` delivery is stopped. |
| `diaverseapi` | Remove or revoke `copywriting.club.broadcast:send` assignment for staff users. |

## Verification

Expected targeted checks:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\club10000-bot
.venv\Scripts\python.exe -m pytest tests\test_club_broadcast_audience.py tests\test_prodamus_callback.py tests\test_start_handler.py -q
.venv\Scripts\python.exe -m ruff check app tests

cd C:\Users\Indigo\Desktop\diaverse\aibot
.venv\Scripts\python.exe -m pytest tests\test_broadcast_repository.py tests\test_broadcast_audience_client.py tests\test_club10000_broadcast_audience_client.py tests\test_broadcast_routes.py tests\test_broadcast_worker.py tests\test_worker_loop.py tests\test_telegram_service.py -q

cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm run test -- __tests__/app/api/staff/copywriting/club-broadcasts-route.test.ts __tests__/modules/copywriting/CopywritingClubBroadcastsView.test.tsx __tests__/modules/copywriting/broadcast-api.test.ts __tests__/shared/auth-permissions.test.ts
npm run typecheck

cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.venv\Scripts\python.exe -m pytest tests\test_cabinet_rbac_seed.py tests\test_cabinet_staff_access_api.py -q
.venv\Scripts\python.exe -m ruff check app\cabinet\rbac tests\test_cabinet_rbac_seed.py tests\test_cabinet_staff_access_api.py
```

## Security Notes

- Audience page requests are HMAC-signed with a dedicated secret.
- The browser never calls `aibot` or `club10000-bot` directly.
- BFF routes pass multipart bytes but must not log image bytes or message text.
- Runtime logs must not contain message text, image bytes, raw secrets, signatures, phone, email, payment URLs, invoice IDs, subscription identifiers, or raw upstream payloads.
- Public docs and daily public digest must not include bot tokens, raw secrets, server addresses, SSH commands, or raw environment values.

## See Also

- [Auth Bot Broadcasts In Copywriting](auth-bot-broadcasts.md)
