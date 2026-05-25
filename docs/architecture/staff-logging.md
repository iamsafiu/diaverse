# Staff Logging

Status: active for Phase 1
Last updated: 2026-04-27

## Purpose

`/[lang]/staff/logging` is the staff-facing observability module for cabinet incidents and operator investigation.

V1 is Advent-first: the UI already supports module tabs, but only `Advent` is active. The browser surface lives in `diaweb`, while structured event and alert storage lives in the sibling `diaverseapi` repository.

## Repository Responsibilities

### `diaweb`

- renders the logging dashboard, module tabs, filters, detail panel, and bell UI
- shows unread counters in the staff sidebar and mobile menu
- gates page and alert actions with `logging:*` permissions
- reads backend data directly from `/v1/cabinet/logging/*`

### `diaverseapi`

- owns structured logging models, service, API, scheduler tasks, and retention jobs in `app/cabinet/logging`
- instruments Advent, guest transfer, pay1time, and Zion hosted payment flows
- remains the source of truth for events, alerts, unread state, and cleanup policy
- does not use legacy `app/observability/*` or `user_request_logs` as the staff UI data source

### `aibot`

- owns Telegram delivery for staff log alerts through a signed internal ops endpoint
- sends all staff log notifications to one configured Telegram group with a dedicated ops bot token
- stores idempotency state so backend retries do not create duplicate Telegram messages
- does not fetch alert details back from `diaverseapi`; it sends the sanitized payload snapshot it receives

## UI Scope

- top module tabs with `Advent` active and future tabs marked `Soon`
- search by `user_id`, `tg_id`, `public_reference`, `payment_session_uuid`, and `line_code`
- date filters for `7`, `30`, and `60` days
- severity filter for all events vs errors only
- grey normal rows and red error rows
- bell panel with module-scoped alerts
- unread badges for the `Logging` nav item and the `Advent` module tab
- summary cards plus full event and alert detail panel

## Searchable Identifiers

- `user_id`
- `tg_id` via backend join from `actor_user_id` to cabinet user records
- `public_reference`
- `payment_session_uuid`
- `line_code`

Provider invoice/payment identifiers remain available inside alert/event metadata for operator drill-down even though they are not primary free-text search keys in V1.

## Alert-Worthy Advent Events

The following event codes should open or update alerts instead of staying only in the event stream:

- `advent.reward_grant_failed`
- `advent.payment.finalization_failed`
- `advent.payment.review_required`
- `advent.payment.processing_stuck`
- `advent.guest_transfer.failed`
- `pay1time.callback_processing_error`
- `pay1time.callback_target_not_found`
- `advent.payment.stuck_finalization`

Expected business rejections such as `DATE_LOCKED`, `PREVIOUS_DAY_REQUIRED`, and `PAYMENT_REQUIRED` stay visible as events but do not create alerts.

## Alert Workflow Semantics

- `read` is per-staff-user and explicitly clears the unread state for that alert
- `ack` records operator ownership but does not replace `read`
- `resolve` closes the alert but does not erase alert history
- if a new matching failure occurs, fingerprint-based aggregation updates the same alert and makes it unread again for staff users

## API Contract

List responses stay lightweight for tables and badges:

- `GET /v1/cabinet/logging/events` returns event summary rows plus pagination
- `GET /v1/cabinet/logging/alerts` returns alert summary rows plus pagination
- `GET /v1/cabinet/logging/counters` returns total and per-module unread/open counts

Detail responses are used for drill-down:

- `GET /v1/cabinet/logging/events/{event_id}`
- `GET /v1/cabinet/logging/alerts/{alert_id}`

Alert workflow mutations:

- `POST /v1/cabinet/logging/alerts/{alert_id}/read`
- `POST /v1/cabinet/logging/alerts/{alert_id}/ack`
- `POST /v1/cabinet/logging/alerts/{alert_id}/resolve`

Ops notification inspection:

- `GET /v1/cabinet/logging/notifications/backlog` returns pending, failed, dead, and oldest pending notification counters

## Telegram Ops Notifications

Alert-worthy staff incidents are delivered to Telegram through an outbox:

1. `diaverseapi` records `cab_log_events` and opens or updates `cab_log_alerts`.
2. `diaverseapi` writes a sanitized row to `cab_log_notification_deliveries`.
3. The FastStream `worker` process claims due rows and sends a short signed HTTP request to `aibot`.
4. `aibot` validates HMAC headers, checks idempotency, formats an HTML-safe message, and sends it to one Telegram group.

The API request path never waits for Telegram or `aibot`. If `aibot` or Telegram is down, the outbox backlog grows and retries later.

Production uses one dedicated ops bot token and one Telegram group chat ID. Modules such as `advent`, `shop`, `support`, and `admin` are shown in message text only; there is no per-topic or per-chat routing in V1.

Telegram messages must not contain raw `metadata_json`, full provider payloads, bot tokens, HMAC signatures, or customer/payment secrets.

## Permissions

- `logging:read` for the page and event list
- `logging.alerts:read` for bell and alert detail access
- `logging.alerts:update` for `read`, `ack`, and `resolve`

## Retention

- `cab_log_events` are cleaned in batches after 60 days
- resolved alerts may be pruned after 180 days
- open alerts and unread alert state must not be deleted prematurely
- the schema is partition-ready, but V1 uses batched scheduled cleanup instead of monthly table partitioning

## Backend Touchpoints

Primary backend ownership lives in:

- `diaverseapi/app/cabinet/logging`
- `diaverseapi/app/cabinet/offers/advent`
- `diaverseapi/app/cabinet/guest`
- `diaverseapi/app/cabinet/payments/pay1time`
- `diaverseapi/app/cabinet/payments/zion`
