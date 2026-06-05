# Auth Bot Broadcasts In Copywriting

[Back to Docs](../../README.md)

## Назначение

Auth-bot broadcast - staff-инструмент в разделе copywriting для мгновенной рассылки Telegram-сообщения пользователям, которые хотя бы раз стартовали auth bot и прошли его approve-flow. С точки зрения пользователя сообщение приходит от Telegram auth bot. Исполнение кампании, очередь, получатели, статусы и ретраи принадлежат не auth bot repo, а связке `diaweb` + `aibot` + `diaverseapi`.

## Ownership

| Область | Владелец |
| --- | --- |
| Staff page and same-origin BFF | `diaweb` |
| Campaign API, image storage, worker delivery, recipient counters | `aibot` |
| Durable audience truth and RBAC permission | `diaverseapi` |
| Telegram transport identity from user perspective | auth bot runtime profile |
| Standalone auth bot source repo | stateless login/link transport only |

## Product Contract

- Audience: active, non-deleted `diaverseapi` users present in `auth_bot_broadcast_contacts`; this table is populated only by auth-bot internal approve flows, not by generic `users.tg_user_id`.
- Image is mandatory.
- Text is mandatory.
- Test send is mandatory before mass send in the current browser session.
- Test send recipient is configured by `COPYWRITING_BROADCAST_TEST_TG_USER_ID`.
- Mass send is immediate only in the MVP: no scheduling, no segments, no drafts after queueing.
- Required permission for send/test is `copywriting.broadcast:send`.
- Ordinary copywriting staff do not receive `copywriting.broadcast:send` automatically.
- Campaign creation returns after enqueue; browser requests must never wait for all Telegram sends.

## Runtime Flow

```text
Staff browser
  -> diaweb /[lang]/staff/copywriting/broadcasts
  -> diaweb BFF /api/staff/copywriting/broadcasts/*
  -> aibot /internal/v1/broadcasts/*
  -> aibot job send_broadcast_campaign
  -> signed diaverseapi audience page requests
  -> Telegram Bot API through auth bot profile
  -> campaign and recipient counters
  -> diaweb polls campaign status
```

## Required Configuration

Do not store raw values in docs, git, daily public digest, or scripts.

### `diaverseapi`

- `COPYWRITING_BROADCAST_AUDIENCE_SECRET`
- `COPYWRITING_BROADCAST_SIGNATURE_TOLERANCE_SECONDS`

### `aibot`

- `COPYWRITING_BROADCAST_AUDIENCE_BASE_URL`
- `COPYWRITING_BROADCAST_AUDIENCE_SECRET`
- `COPYWRITING_BROADCAST_AUDIENCE_KEY_ID`
- `COPYWRITING_BROADCAST_AUDIENCE_TIMEOUT_SECONDS`
- `COPYWRITING_BROADCAST_AUDIENCE_PAGE_SIZE`
- `COPYWRITING_BROADCAST_MEDIA_DIR`
- `COPYWRITING_BROADCAST_MAX_IMAGE_SIZE_BYTES`
- `COPYWRITING_BROADCAST_TEST_TG_USER_ID`
- `COPYWRITING_BROADCAST_BOT_PROFILE`
- `TELEGRAM_BOT_TOKEN_AUTH` when `COPYWRITING_BROADCAST_BOT_PROFILE=auth` (`TELEGRAM_AUTH_BOT_TOKEN` is also supported by the resolver).

The path configured by `COPYWRITING_BROADCAST_MEDIA_DIR` must be shared between `copywriting-api` and `copywriting-worker`, because the API stores the uploaded image and the worker reads it during Telegram delivery.
In Docker Compose production runtime, `copywriting-volume-init` must complete before `copywriting-api` and `copywriting-worker` so the shared broadcast image volume is writable by the non-root `copywriting` user.

### `diaweb`

Existing copywriting BFF configuration remains required:

- copywriting service URL
- internal JWT signing secret
- copywriting request timeout

## API Surfaces

| Repo | Endpoint | Purpose |
| --- | --- | --- |
| `diaverseapi` | `GET /v1/auth/internal/auth-bot-broadcast-recipients` | Signed internal audience page |
| `aibot` | `POST /internal/v1/broadcasts/test` | Test send to configured staff Telegram ID |
| `aibot` | `POST /internal/v1/broadcasts` | Store image, create campaign, enqueue worker job |
| `aibot` | `GET /internal/v1/broadcasts` | Recent campaign list |
| `aibot` | `GET /internal/v1/broadcasts/{campaign_id}` | Campaign status and counters |
| `diaweb` | `/api/staff/copywriting/broadcasts/*` | Same-origin BFF proxy for staff browser |

## Delivery Semantics

- `aibot` materializes recipients idempotently per campaign.
- `aibot` sends a photo with caption when the text fits Telegram caption limits.
- If the text is too long for a caption, `aibot` sends the photo first and the text as a second message.
- Broadcast text is normalized to safe Telegram HTML before test send, campaign storage, and worker delivery.
- Safe links can be entered as `<a href="https://example.com">visible text</a>`.
- Markdown-style links such as `[visible text](https://example.com)` are converted to Telegram HTML.
- Telegram-copied hidden links that paste as `visible text (https://example.com)` on a single line are converted back into a hidden link for that line.
- Blocked, forbidden, or chat-not-found recipients become terminal `blocked`.
- Retry-after and rate-limit style errors move recipients to `retry_pending` and requeue the worker job.
- Campaign status becomes `completed` only when all recipients are terminal.
- Campaign-level unrecoverable errors such as missing media or invalid audience auth can mark the campaign `failed`.

## Safe Rollout

Deploy order:

1. `diaverseapi`: audience endpoint and RBAC permission.
2. `aibot`: campaign tables, API routes, worker processor, env configuration.
3. `diaweb`: BFF routes and Broadcasts tab.

Smoke sequence:

1. Confirm a staff user without `copywriting.broadcast:send` cannot test-send or mass-send.
2. Confirm a sender with `copywriting.broadcast:send` can open the Broadcasts tab.
3. Upload a small approved image and enter a short text.
4. Send the test broadcast to the configured test Telegram ID.
5. Confirm the Telegram message arrives from the auth bot profile.
6. Create the mass campaign only after the test succeeds.
7. Watch campaign counters until all recipients are terminal.

## Rollback

| Repo | Rollback action |
| --- | --- |
| `diaweb` | Remove or hide the Broadcasts tab and BFF routes. Existing campaigns in `aibot` are unaffected. |
| `aibot` | Stop the worker or disable the broadcast processor to halt delivery; keep DB rows for audit. |
| `diaverseapi` | Disable audience secret/config access only after `aibot` delivery is stopped. |

## Verification

Expected targeted checks:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.venv\Scripts\python.exe -m pytest tests\test_auth_bot_broadcast_audience.py tests\test_cabinet_rbac_seed.py tests\test_cabinet_staff_access_api.py -q

cd C:\Users\Indigo\Desktop\diaverse\aibot
.venv\Scripts\python.exe -m pytest tests\test_broadcast_repository.py tests\test_broadcast_audience_client.py tests\test_broadcast_routes.py tests\test_broadcast_worker.py tests\test_worker_loop.py tests\test_telegram_service.py -q

cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm run test -- __tests__/app/api/staff/copywriting/broadcasts-route.test.ts __tests__/modules/copywriting/broadcast-api.test.ts __tests__/modules/copywriting/CopywritingBroadcastsView.test.tsx __tests__/modules/copywriting/CopywritingTabsNav.test.tsx __tests__/shared/auth-permissions.test.ts
npm run typecheck
```

## Security Notes

- The audience endpoint is internal-only and signed with a dedicated secret.
- The browser never calls `aibot` directly.
- BFF routes pass multipart bytes but must not log image bytes or message text.
- Docs and daily public digest must not include bot tokens, raw secrets, server addresses, SSH commands, or raw environment values.

## See Also

- [Club10000 Broadcasts In Copywriting](club10000-broadcasts.md)
