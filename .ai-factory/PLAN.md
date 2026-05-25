# Implementation Plan: Copywriting Chat Situation Reports Via Ops Bot

Created: 2026-05-25
Mode: AIF fast plan, workspace root, no branch changes
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: yes
- Logging: verbose
- Docs: no - `WARN [docs]` only unless implementation changes operator-facing setup enough to require a short docs update
- Roadmap Linkage: none, no `.ai-factory\ROADMAP.md` found
- Graphify: refresh after code or docs changes with `scripts\graphify-update.ps1`

## Goal

Add a daily internal "обстановка в чате" report for the copywriting morning workflow.

The report must summarize what is happening in the source community chats: overall mood, concrete recurring problems, what people are confused about, what support/content should answer today, and which product issues should be escalated. It should be sent to the working Telegram group through the existing ops/alert bot account, but it must not use the incident alert endpoint, alert payload, or alert message format.

The intended behavior is:

- Generate an internal team report from persisted `copywriting_source_messages`, not from the legacy `COMMUNITY_CHAT_ID` scheduler path.
- Keep this separate from public post generation: the current "Рекомендации" may inspire the report style, but this artifact is for the working group.
- Use the same physical Telegram bot token/chat configuration as the ops bot when report-specific settings are not provided.
- Do not call `/internal/v1/ops/telegram-alerts`, do not create `ops_alert_deliveries`, and do not route through `send_ops_alert`.
- Store report state, delivery state, and retry/idempotency data in `aibot`.
- Optionally surface the report and manual send/retry controls in the existing `diaweb` staff copywriting morning page.

## Workspace Mode

- Mode: fast, multi-repo workspace plan
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Shared graph: `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
- Branch operations: none

## Repository Matrix

| Repository / Area | Path | Affected | Current branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | yes | `dev` | clean | source chat data, report generation, worker scheduling, Telegram Bot API delivery, internal API, backend tests |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `dev` | clean | staff copywriting UI, BFF routes, client hooks/types, frontend tests |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | no | `dev` | clean | existing ops alert producer; leave unchanged |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | `dev` | clean | unrelated standalone Club10000 bot |

## Research Context

### AIF Active Summary

The workspace root coordinates four separate repositories and is now a lightweight git repository for documentation, AI context, shared scripts, and workspace config only. Source truth stays in child repos. Cross-repo plans live under top-level `.ai-factory`; product-code branch/status/commit operations happen only inside child repositories.

### Feature Recon

- `aibot` already owns copywriting source ingest, daily run generation, worker jobs, and Telegram delivery helpers.
- `aibot\db\repositories\source_repo.py` can load recent persisted messages and readiness stats from `copywriting_source_messages`.
- `aibot\app\application\use_cases\daily_run.py` already computes source readiness and uses source chat messages for the morning copywriting flow.
- `aibot\agents\analyzer.py` extracts topics, pain points, content ideas, and summaries, but the current planner output is optimized for public post generation. The new report needs its own structured prompt/use case.
- `aibot\app\api\routes\ops_alerts.py` and `aibot\app\application\use_cases\send_ops_alert.py` are incident-alert specific. Reusing that route would mix daily editorial telemetry with production alerts, so this plan avoids it.
- `aibot\services\telegram_service.py` is the right low-level sender because it accepts an explicit bot token and already handles Bot API message sends.
- `aibot\app\worker\main.py` already schedules daily copywriting/fact/club jobs around the Moscow morning schedule.
- `diaweb\frontend\modules\copywriting\components\CopywritingDailyView.tsx` already has the morning "Рекомендации" tab and copywriting logging utilities, so it is the natural staff surface for status/manual send.
- Runtime exploration showed that the deployed `aibot` API/worker has ops bot settings configured and the source chat DB has recent persisted messages, so the feature can be built without adding a new bot.

## Key Decisions

- Reuse the ops bot account, not the ops alert pipeline.
- Add report-specific feature flags and optional chat/thread overrides:
  - `CHAT_SITUATION_REPORTS_ENABLED`
  - `CHAT_SITUATION_REPORTS_TELEGRAM_BOT_TOKEN`
  - `CHAT_SITUATION_REPORTS_TELEGRAM_CHAT_ID`
  - `CHAT_SITUATION_REPORTS_MESSAGE_THREAD_ID`
  - fallback to `OPS_ALERTS_TELEGRAM_BOT_TOKEN` and `OPS_ALERTS_TELEGRAM_CHAT_ID` when report-specific token/chat are empty
- Keep `CHAT_SITUATION_REPORTS_ENABLED=false` by default; production enables it explicitly.
- Store a daily report row so generation and Telegram delivery are auditable and retryable.
- Sanitize the report: paraphrase examples, do not include usernames, Telegram IDs, tokens, raw env values, or long raw chat excerpts.
- If source data is unavailable, create a `source_not_ready` report and send one short non-alert status note per day so the team knows the report did not silently fail.

## Tasks

### Phase 1 - Domain Model And Data Access

- [x] `[aibot]` Add the chat situation report persistence model.
  - Files:
    - `aibot\db\models.py`
    - `aibot\db\__init__.py`
    - `aibot\migrations\20260525_0001_copywriting_chat_situation_reports.sql`
  - Deliverable:
    - New `CopywritingChatSituationReport` table/model with fields for `report_date`, `timezone`, `status`, `status_reason`, source window timestamps, source chat/message counts, structured `report_json`, formatted `report_text`, Telegram delivery fields, `job_id`, `pending_job_ids`, `idempotency_key`, `metadata_json`, `created_by_user_id`, timestamps, and a unique idempotency constraint.
    - Status values should cover `scheduled`, `generating`, `ready`, `sending`, `sent`, `source_not_ready`, and `failed`.
  - Logging:
    - Repository/model usage must log status transitions at `info`, missing/duplicate/reused rows at `warning` or `info`, and never log report text or raw messages.
  - Dependencies:
    - Must be completed before worker/API tasks can persist report state.

- [x] `[aibot]` Add a repository for report lifecycle operations.
  - Files:
    - `aibot\db\repositories\chat_situation_report_repo.py`
    - `aibot\db\__init__.py`
  - Deliverable:
    - Methods for `create_or_get_active_by_date`, `get_by_id`, `get_latest`, `update_fields`, `mark_generating`, `mark_ready`, `mark_source_not_ready`, `mark_sending`, `mark_sent`, and `mark_failed`.
    - Idempotent lookup by date/timezone/window and support for row locking where send/generate races are possible.
  - Logging:
    - `debug` for lookup results and query parameters, `info` for create/update/status transitions, `warning` for conflicts or missing rows.
  - Dependencies:
    - Depends on the model/migration task.

### Phase 2 - Report Generation

- [x] `[aibot]` Implement the report generation use case from persisted source chat messages.
  - Files:
    - `aibot\app\application\use_cases\chat_situation_report.py`
    - `aibot\db\repositories\source_repo.py`
    - optionally `aibot\app\domain\chat_situation_prompt.py` or `aibot\core\prompts.py`
  - Deliverable:
    - `ensure_chat_situation_report_record(...)`
    - `enqueue_chat_situation_report_generation_job(...)`
    - `execute_chat_situation_report_generation(...)`
    - A structured report schema with at least:
      - `overall_mood`
      - `dominant_topics`
      - `concrete_problems`
      - `support_response_suggestions`
      - `product_escalations`
      - `public_content_guidance`
      - `dont_post_about`
      - `confidence`
      - source counts/window metadata
    - Input data should come from enabled active source chats and recent `copywriting_source_messages`.
    - The prompt must ask for concrete problem clusters and practical team actions, not public Telegram post ideas.
  - Logging:
    - `info` for generation start/done with report id, date, source chat count, message count, and status.
    - `debug` for prompt/template source, selected window, and character counts only.
    - `warning` for no enabled sources, no recent messages, malformed LLM output, or low confidence.
    - `error` for provider failures, without raw message text.
  - Dependencies:
    - Depends on the repository task.

- [x] `[aibot]` Add safe formatting for the working Telegram group message.
  - Files:
    - `aibot\app\application\use_cases\chat_situation_report.py`
    - optionally `aibot\app\domain\chat_situation_formatting.py`
  - Deliverable:
    - Deterministic formatter that converts `report_json` into concise Russian Telegram text.
    - Format should be clearly a team report, not an alert: title/date, mood, top problems, suggested responses, product escalations, and content guidance.
    - Enforce max length with deterministic truncation and preserve the highest-priority sections.
    - Escape HTML if using HTML parse mode.
  - Logging:
    - `debug` for section counts and final message length.
    - `warning` when truncation occurs.
  - Dependencies:
    - Depends on structured generation output.

### Phase 3 - Telegram Delivery Via Existing Bot Account

- [x] `[aibot]` Add report-specific config and delivery use case using `TelegramService`.
  - Files:
    - `aibot\core\config.py`
    - `aibot\app\application\use_cases\send_chat_situation_report.py`
    - optionally `aibot\tests\test_config.py`
  - Deliverable:
    - New settings listed in `Key Decisions`.
    - Token/chat resolution that prefers report-specific settings and falls back to `OPS_ALERTS_TELEGRAM_BOT_TOKEN` / `OPS_ALERTS_TELEGRAM_CHAT_ID`.
    - Sender uses `TelegramService(bot_token=resolved_token)` directly.
    - Sender does not import or call `send_ops_alert`, does not use `OpsAlertRepository`, and does not write `ops_alert_deliveries`.
    - Optional `message_thread_id` support if the working group uses Telegram topics; if `TelegramService.send_message` does not support it yet, extend it narrowly.
  - Logging:
    - `info` for send start/done with report id, date, status, message length, and Telegram message id.
    - `debug` for configuration resolution flags like `has_report_token`, `uses_ops_fallback`, `has_thread_id`; do not log token or raw chat id.
    - `warning` for disabled/missing config and duplicate/in-flight sends.
    - `error` for Telegram API failure with exception class only.
  - Dependencies:
    - Depends on report formatter and repository.

- [x] `[aibot]` Wire a worker processor and daily schedule.
  - Files:
    - `aibot\app\worker\main.py`
    - `aibot\app\worker\processors\generate_chat_situation_report.py`
    - `aibot\app\worker\processors\__init__.py`
    - `aibot\tests\test_worker_loop.py`
  - Deliverable:
    - New job kind `generate_chat_situation_report`.
    - Scheduler creates/reuses one report job per Moscow date after the existing daily copywriting schedule, for example at `03:10 Europe/Moscow`.
    - Processor generates the report and sends it when `CHAT_SITUATION_REPORTS_ENABLED=true`.
    - Processor returns payload with report id, status, source counts, and Telegram message id when sent.
    - Existing daily run/fact/club schedules remain unchanged.
  - Logging:
    - `info` for scheduled/reused/claimed/completed jobs.
    - `debug` for related entity id and available_at calculation.
    - `warning` for source not ready or disabled sending.
    - `error` for generation/send failures with report id and job id only.
  - Dependencies:
    - Depends on generation and delivery use cases.

### Phase 4 - Internal API For Staff Visibility And Manual Retry

- [x] `[aibot]` Add internal API schemas and routes for chat situation reports.
  - Files:
    - `aibot\app\api\schemas\chat_situation_reports.py`
    - `aibot\app\api\routes\chat_situation_reports.py`
    - `aibot\app\api\routes\__init__.py`
    - `aibot\app\api\main.py`
  - Deliverable:
    - `GET /internal/v1/chat-situation-reports/today`
    - `POST /internal/v1/chat-situation-reports/today`
    - `POST /internal/v1/chat-situation-reports/{report_id}/send`
    - `POST /internal/v1/chat-situation-reports/{report_id}/regenerate` if manual regeneration is needed in the same release.
    - Require `copywriting:read` for read, `copywriting:create` for ensure/regenerate, and `copywriting:publish` or equivalent elevated permission for send.
    - Response must expose sanitized report sections, source counts, status, pending job ids, and delivery state.
  - Logging:
    - `info` for API get/ensure/send/regenerate calls with request id, user id, report id, status, and job id.
    - `warning` for not found, invalid state, disabled sending, or permission-safe validation failures.
    - `debug` for response shape and pending job ids.
  - Dependencies:
    - Depends on worker and delivery use cases.

- [x] `[diaweb]` Add BFF proxy routes and copywriting client contracts.
  - Files:
    - `diaweb\frontend\app\api\staff\copywriting\chat-situation-reports\today\route.ts`
    - `diaweb\frontend\app\api\staff\copywriting\chat-situation-reports\[reportId]\send\route.ts`
    - optionally `diaweb\frontend\app\api\staff\copywriting\chat-situation-reports\[reportId]\regenerate\route.ts`
    - `diaweb\frontend\modules\copywriting\api.ts`
    - `diaweb\frontend\modules\copywriting\hooks.ts`
    - `diaweb\frontend\modules\copywriting\types.ts`
    - `diaweb\frontend\modules\copywriting\index.ts`
  - Deliverable:
    - Same-origin BFF routes that proxy to the new `aibot` internal endpoints using the existing copywriting proxy helper.
    - Types for report status, source counts, sections, delivery state, and actions.
    - Hooks for `useTodayChatSituationReport`, `useEnsureTodayChatSituationReport`, `useSendChatSituationReport`, and optional regeneration.
    - Polling while status is `scheduled`, `generating`, `sending`, or pending jobs exist.
  - Logging:
    - Use `logCopywritingEvent` at `info` for successful ensure/send actions, `warn`/`error` for failures, and `debug` for polling decisions in development.
    - Do not log report text or raw report sections in browser logs.
  - Dependencies:
    - Depends on API route contracts.

- [x] `[diaweb]` Surface the report in the morning copywriting UI.
  - Files:
    - `diaweb\frontend\modules\copywriting\components\CopywritingDailyView.tsx`
    - optionally `diaweb\frontend\modules\copywriting\components\ChatSituationReportPanel.tsx`
  - Deliverable:
    - Add an "Обстановка в чате" section inside the existing "Рекомендации" tab or a nearby compact panel in the daily view.
    - Show status, source window/counts, overall mood, top concrete problems, suggested response actions, product escalations, content guidance, and delivery state.
    - Provide buttons for create/refresh and send/retry when the user has permissions exposed by the API.
    - Keep the existing recommendation display intact.
    - Empty/source-not-ready state should explain that source chat data is missing/stale without exposing infrastructure details.
  - Logging:
    - `info` for user-triggered create/send/regenerate actions.
    - `warn` for blocked actions and failed mutations.
    - `debug` for panel render state in development only.
  - Dependencies:
    - Depends on BFF/hooks/types.

### Phase 5 - Tests And Verification Coverage

- [x] `[aibot]` Add backend unit tests for generation, formatting, settings fallback, and sanitization.
  - Files:
    - `aibot\tests\test_chat_situation_report.py`
    - optionally `aibot\tests\test_config.py`
  - Deliverable:
    - Tests for source-not-ready behavior.
    - Tests for structured LLM output normalization and malformed output fallback.
    - Tests that formatter paraphrases/escapes and enforces max length.
    - Tests that report settings can fall back to ops bot token/chat without enabling the ops alert route.
    - Tests that raw usernames/Telegram ids are not emitted in formatted report examples.
  - Logging:
    - Tests should assert important log events with `caplog` where practical, especially disabled config, source-not-ready, and Telegram failures.
  - Dependencies:
    - Depends on generation and sender use cases.

- [x] `[aibot]` Add worker/API integration tests.
  - Files:
    - `aibot\tests\test_worker_loop.py`
    - `aibot\tests\test_service_entrypoints.py`
    - optionally `aibot\tests\test_api_auth.py`
  - Deliverable:
    - Processor registry contains `generate_chat_situation_report`.
    - Scheduler reuses an existing daily job instead of duplicating it.
    - API routes are registered and enforce read/create/send permissions.
    - Manual send moves report to `sent` on success and to retryable failure state on Telegram failure.
  - Logging:
    - Tests should verify scheduling/send log events do not contain token/chat id or raw report text.
  - Dependencies:
    - Depends on worker and API tasks.

- [x] `[diaweb]` Add frontend tests for BFF and UI behavior.
  - Files:
    - `diaweb\frontend\__tests__\app\api\staff\copywriting\chat-situation-reports-route.test.ts`
    - optionally `diaweb\frontend\__tests__\modules\copywriting\ChatSituationReportPanel.test.tsx`
  - Deliverable:
    - BFF routes proxy correct internal paths/methods.
    - Hooks invalidate/poll query state correctly.
    - UI renders loading, source-not-ready, ready, sending, sent, and failed states.
    - Send/retry buttons respect disabled states.
  - Logging:
    - Tests should avoid snapshotting raw report text where not needed and ensure mutation failures call existing logging path safely.
  - Dependencies:
    - Depends on frontend implementation tasks.

## Verification Plan

- `aibot`: run targeted tests:
  - `pytest tests/test_chat_situation_report.py tests/test_worker_loop.py tests/test_service_entrypoints.py tests/test_api_auth.py`
- `aibot`: run lint/type checks used by the repo, at minimum:
  - `ruff check app agents db services tests`
  - If the repo uses mypy/pyright in CI, run that configured command too.
- `aibot`: apply SQL migration in a local/staging database and verify the new table/indexes.
- `diaweb`: run targeted frontend tests:
  - `npm run test -- chat-situation-reports`
  - `npm run test -- CopywritingDailyView`
- `diaweb`: run:
  - `npm run typecheck`
  - `npm run lint`
- End-to-end smoke:
  - With `CHAT_SITUATION_REPORTS_ENABLED=false`, ensure report generation stores `ready` but does not send.
  - With sending enabled and a test chat/thread, ensure one daily message is sent and a retry does not duplicate after `sent`.
  - Confirm existing `/internal/v1/ops/telegram-alerts` still behaves only as the alert gateway.
- Workspace:
  - After source changes, run `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`.

## Rollout Notes

- Production should enable the feature with a non-secret toggle first: `CHAT_SITUATION_REPORTS_ENABLED=true`.
- If the working report should go to the same group as ops alerts, no new bot token is needed; the sender can fall back to the existing ops bot token/chat configuration.
- If the working group uses a Telegram topic, set only the report-specific `CHAT_SITUATION_REPORTS_MESSAGE_THREAD_ID`.
- Keep alert pipeline metrics separate from report delivery metrics; report failures should log as copywriting report failures, not incident alert failures.
- Rollback is config-first: set `CHAT_SITUATION_REPORTS_ENABLED=false`; generated report rows can remain for audit/UI visibility.

## Commit Plan

- `aibot` commit 1 after Phase 1 and Phase 2:
  - `feat(copywriting): model chat situation reports`
- `aibot` commit 2 after Phase 3 and Phase 4 API:
  - `feat(copywriting): send chat situation reports via ops bot`
- `diaweb` commit 3 after Phase 4 frontend:
  - `feat(copywriting): show chat situation reports in staff daily view`
- `aibot`/`diaweb` commit 4 after Phase 5:
  - `test(copywriting): cover chat situation report flow`

Fast mode stops here. To start implementation, run `$aif-implement` from `C:\Users\Indigo\Desktop\diaverse`.
