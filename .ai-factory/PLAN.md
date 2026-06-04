# Implementation Plan: Crypton Request Telegram Topic Alerts

Branch: none
Created: 2026-06-04
Mode: fast workspace plan

## Settings

- Testing: yes
- Logging: standard
- Docs: yes - update ops-alert gateway documentation because the Telegram routing contract changes
- Branching: no branch creation in fast mode
- Roadmap Linkage: none - `.ai-factory/ROADMAP.md` is not present

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first through `scripts\gbrain.ps1`, then raw source verification
- Goal: new Crypton offer requests must be delivered to the staff Telegram group in a dedicated Crypton topic, with a direct link to the Crypton admin request.

## Repository Matrix

| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `dev` | clean | Crypton request event, cabinet log payload, dispatcher outbox |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | yes | `dev` | clean | ops-alert Telegram gateway and topic routing |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `dev` | clean | staff shop Crypton deep-link handling |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | `dev` | dirty: `.tmp/` untracked | unrelated standalone bot |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | `feature/auth-tgbot` | clean | unrelated auth transport |
| root AIF | `C:\Users\Indigo\Desktop\diaverse\.ai-factory` | yes | unchanged | plan artifact only | coordination |

## Research Context

- `diaverseapi` already records `crypton.request.submitted` through `CabinetLoggingService.record_alerting_event` in `diaverseapi/app/cabinet/offers/crypton/service.py`.
- `cab_log_notification_deliveries.payload_json` is JSONB, so the backend can add payload fields without a database migration.
- `aibot` is the existing non-RF Telegram gateway for `diaverseapi` staff log alerts through `/internal/v1/ops/telegram-alerts`.
- `aibot/services/telegram_service.py` already supports `message_thread_id`; `aibot/app/application/use_cases/send_ops_alert.py` does not pass it yet.
- Daily chat situation reports already use a configured thread id, so the deployment has an established topic-id pattern.
- `diaweb` staff Crypton admin lives at `/ru/staff/shop`, but the `Crypton` tab and selected request are currently local component state.

## Product Decisions

- Reuse the existing cabinet log notification outbox and `aibot` ops-alert gateway; do not call Telegram directly from `diaverseapi`.
- Add one dedicated `aibot` env setting for Crypton topic routing, e.g. `OPS_ALERTS_CRYPTON_MESSAGE_THREAD_ID=123`.
- Route Crypton topic messages in `aibot` by `event_code == "crypton.request.submitted"` or `context.alert_reason == "crypton_request_submitted"`.
- Add a staff action link to the alert payload and render it as the primary Telegram link; keep `staff_logging_url` as the generic logging fallback.
- Use admin deep links shaped as `/ru/staff/shop?tab=crypton&requestId=<request_uuid>`.
- Keep notification creation non-fatal: failures should be logged and must not block request submission.
- Do not include tokens, checkout URLs, raw provider payloads, or secrets in payloads, logs, docs, or Telegram messages.

## Commit Plan

- **Commit 1** (tasks 1-2): `feat(crypton): enrich submitted request ops alerts`
- **Commit 2** (tasks 3-4): `feat(ops): route crypton alerts to telegram topic`
- **Commit 3** (tasks 5-7): `feat(staff): deep link crypton admin requests`

## Tasks

### Phase 1: Backend Alert Payload

- [x] Task 1: Enrich the Crypton submitted-request cab-log event in `diaverseapi`.
  - Deliverable: `crypton.request.submitted` includes safe context fields needed by staff: request id/source ref, item title when available, offer units quantity, proposed price, market price, recommended price, and a clear alert reason.
  - Files: `diaverseapi/app/cabinet/offers/crypton/service.py`, `diaverseapi/app/cabinet/logging/notification_policy.py`, `diaverseapi/app/cabinet/logging/service.py`.
  - Expected behavior: submitting a Crypton request still creates the request even if logging fails; the queued `cab_log_notification_deliveries.payload_json.context` contains only whitelisted, non-secret fields.
  - Logging requirements: keep the existing WARN for skipped ops alert creation; add DEBUG/INFO only around payload construction or skipped optional fields, with request ids and event codes only.

- [x] Task 2: Add a direct staff action URL for Crypton alerts in `diaverseapi`.
  - Deliverable: notification payloads can carry `staff_action_url` for request-specific staff actions while preserving `staff_logging_url` for generic log navigation.
  - Files: `diaverseapi/app/cabinet/logging/service.py`, `diaverseapi/app/cabinet/logging/schemas.py` if payload schema helpers exist, `diaverseapi/tests/test_cabinet_logging_notifications.py`, `diaverseapi/tests/test_cabinet_crypton.py`.
  - Expected behavior: for `crypton.request.submitted`, payload contains an absolute URL based on `CABINET_PUBLIC_BASE_URL` and path `/ru/staff/shop?tab=crypton&requestId=<uuid>`; when base URL is missing, the field is omitted and the delivery still works.
  - Logging requirements: log whether an action URL was built as a boolean, not the raw full URL; WARN only for malformed base URL if validation is needed.
  - Depends on: Task 1.

### Phase 2: Aibot Topic Routing

- [x] Task 3: Extend the `aibot` ops-alert payload contract and message formatter.
  - Deliverable: `/internal/v1/ops/telegram-alerts` accepts optional `staff_action_url`, renders it as the primary "open in staff panel" link, and keeps `staff_logging_url` as fallback.
  - Files: `aibot/app/api/routes/ops_alerts.py`, `aibot/app/application/use_cases/send_ops_alert.py`, `aibot/tests/test_ops_alerts_sender.py`.
  - Expected behavior: Crypton alert messages display Russian title/summary/context labels and include one actionable admin link; existing Pay1Time/Advent alerts remain unchanged.
  - Logging requirements: include `event_code`, `module`, `severity`, and booleans for `has_staff_action_url`/`has_staff_logging_url`; do not log raw URLs or Telegram tokens.
  - Depends on: Task 2.

- [x] Task 4: Route Crypton ops alerts to a dedicated Telegram topic in `aibot`.
  - Deliverable: add `OPS_ALERTS_CRYPTON_MESSAGE_THREAD_ID` setting with validation, resolve the thread id for Crypton request-submitted alerts, and pass it to `TelegramService.send_message`.
  - Files: `aibot/core/config.py`, `aibot/app/application/use_cases/send_ops_alert.py`, `aibot/tests/test_ops_alerts_sender.py`, `aibot/docs/ops-alerts.md`.
  - Expected behavior: when the env var is positive and the payload is a Crypton submitted-request alert, Telegram send uses `message_thread_id`; when missing or zero, alerts fall back to the main ops chat without failing.
  - Logging requirements: log `has_thread_id` and `routing_reason` at INFO/DEBUG; never log the topic id if we decide it is sensitive, or log only a boolean in production paths.
  - Depends on: Task 3.

### Phase 3: Staff Admin Deep Link

- [x] Task 5: Add query-param deep-link support to the staff shop page in `diaweb`.
  - Deliverable: `/ru/staff/shop?tab=crypton&requestId=<uuid>` opens the Crypton workspace tab and asks the Crypton panel to load the given request.
  - Files: `diaweb/frontend/app/[lang]/staff/shop/page.tsx`, `diaweb/frontend/modules/staff-shop/components/ShopAdminPage.tsx`, `diaweb/frontend/__tests__/modules/staff-shop/ShopAdminPage.test.tsx`.
  - Expected behavior: invalid or absent `tab` keeps the current default "general" tab; `tab=crypton` opens Crypton without breaking existing admin shop behavior.
  - Logging requirements: keep client logs development-only; add DEBUG for accepted deep-link params and WARN for malformed params only in non-production.

- [x] Task 6: Make `CryptonRequestsPanel` load an explicit request id even when it is not on the current list page.
  - Deliverable: an initial request id from the page query drives the detail query directly; list selection still works normally after staff clicks another row.
  - Files: `diaweb/frontend/modules/staff-shop/components/CryptonRequestsPanel.tsx`, `diaweb/frontend/__tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx`.
  - Expected behavior: a Telegram link to a paid/history/non-first-page request still opens the detail aside; if the request does not exist or staff lacks access, the existing error state is shown without crashing.
  - Logging requirements: add development-only DEBUG for explicit request id activation and WARN for detail load failure, without logging user PII beyond request id.
  - Depends on: Task 5.

### Phase 4: Verification and Ops Readiness

- [x] Task 7: Verify the end-to-end flow and document the runtime configuration.
  - Deliverable: targeted automated tests pass, ops docs list the new env var, and the deployment checklist explains how to configure the Crypton Telegram topic id on the logs-bot server.
  - Files: `aibot/docs/ops-alerts.md`, plus any deployment docs/env examples already used for `OPS_ALERTS_*` if present.
  - Expected behavior: after deployment and env configuration, submitting a Crypton request creates a delivery, `aibot` sends it into the Crypton topic, and the Telegram link opens the exact admin request.
  - Logging requirements: verify logs show delivery enqueue, gateway accepted/sent, and topic routing booleans; no secrets, raw chat ids, tokens, or full internal URLs should appear in public docs or final summaries.
  - Depends on: Tasks 1-6.

## Verification Plan

- `diaverseapi`: run `pytest tests/test_cabinet_crypton.py tests/test_cabinet_logging_notifications.py` and targeted Ruff for changed backend files.
- `aibot`: run `pytest tests/test_ops_alerts_sender.py tests/test_chat_situation_report.py` and targeted Ruff for changed ops-alert/config files.
- `diaweb`: run targeted Vitest for `ShopAdminPage` and `CryptonRequestsPanel`; run lint/type checks if touched types require it.
- Runtime smoke after deploy: create or identify the Crypton Telegram topic, set `OPS_ALERTS_CRYPTON_MESSAGE_THREAD_ID`, restart the relevant `aibot` service, submit a dev Crypton request, confirm the message appears in the topic and the admin link opens the request.
- Knowledge: after meaningful code/docs changes, run targeted GBrain sync for `diaverseapi-code`, `aibot-code`, and `diaweb-code`.
