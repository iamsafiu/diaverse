# Club Subscription Marathon Plan

Created: 2026-05-19
Branch: `feature/club-subscription-marathon`
Base branch: `dev`

## Workspace Mode

- Mode: multi-repo full
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Task brief: `C:\Users\Indigo\Desktop\diaverse\docs\tasks\club.md`
- Shared graph: `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
- Product code repositories: `diaweb`, `diaverseapi`, `aibot`
- Top-level workspace is a coordination git repository only; product code stays in child repositories.

## Repository Matrix

| Repository | Path | Affected | Branch | Initial status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `feature/club-subscription-marathon` | clean, created from `dev` | Club domain, payments, roster, steps, bot internal API, staff API |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `feature/club-subscription-marathon` | clean, created from `dev` | Staff `/staff/club` UI and access wiring |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | yes | `feature/club-subscription-marathon` | clean, created from `dev` | Club copywriting, AI images, Telegram publish profile |

## Settings

- Testing: yes. Include backend unit/integration tests, aibot use-case/API tests, and focused frontend tests where local patterns exist.
- Logging: verbose, structured, configurable. New services/jobs must log state transitions, external calls, idempotency keys, retry decisions, and skipped actions.
- Docs: yes. Add or update runbooks after implementation.
- Roadmap Linkage: none. `.ai-factory/ROADMAP.md` is not present.

## Decisions From Discussion

- `diaverseapi` owns the `club` business domain.
- `clubbot` is a thin Telegram adapter deployed on a foreign server. For v1 source placement, implement it in the `diaverseapi` repo as a separate runtime/package with no direct DB access; it talks to `diaverseapi` through signed internal HTTP only.
- `aibot` does not own club state. It generates/publishes club content and AI leaderboard images.
- AI club content is published by `aibot` through a per-target `club` bot profile backed by environment token. The token is not stored in DB.
- `clubbot` owns Telegram updates/webhooks for the club bot. `aibot` may send outbound messages with the same bot token, but it must not consume updates.
- Club leaderboards use app DB steps from `user_activities` for active club memberships. Screenshot submissions are optional engagement/chat evidence, not the source of truth for ranking.
- AI may generate leaderboard images. The exact leaderboard JSON snapshot remains the source of truth.
- Telegram Bot API must not be treated as a source for listing all group members. We maintain our own roster from payments, manual adds, join requests, and known-user `getChatMember` checks.
- Manual member addition is required in `/staff/club` for migration, gifts, VIPs, tests, and non-Prodamus access.
- Manual migration must support bulk import for existing group members, but username-only data is never enough to silently activate a member into leaderboards.
- All club operations, including club alerts, must be managed from the `/staff/club` module. Backend may reuse the cabinet logging/notification pipeline for persistence and delivery, but the staff-facing club alert surface belongs inside `/staff/club`, not the generic `/staff/logging` module.
- Do not require users to confirm themselves through `/start` during v1 onboarding. Keep bot DM/start verification as a future enhancement only.
- Future recurring payments are not fully implemented in this slice, but the club schema and state machine must be ready for renewal failure, 3-day grace, pause, removal, and pair reformation.
- No pre-renewal push reminders. React only after actual failed renewal.
- User-facing club checkout/join pages are intentionally not added to this plan until the product path is clarified. This plan only keeps backend/payment readiness and staff/manual operations.

## Source Findings

- `diaverseapi/app/cabinet/payments/types.py` currently limits `CabinetPaymentDomainCode` to `advent | shop`.
- `diaverseapi/app/cabinet/payments/registry.py` registers `prodamus-hosted` only for `advent | shop`.
- `diaverseapi/app/cabinet/payments/finalizers.py` registers Advent and Shop finalizers only.
- `diaverseapi/app/activities/models.py` stores step rows in `user_activities`; `datetime_to_date_user(created_at, user_id)` is already used for user-local daily grouping.
- `diaverseapi/app/cabinet/rbac/staff_modules.py` and `app/cabinet/rbac/seed.py` do not include `club`.
- `diaverseapi/app/cabinet/logging/service.py` already supports deduplicated alerting through `record_alerting_event`.
- `diaverseapi/app/security/dependecies.py` has an HMAC internal bot signature pattern for auth bot calls.
- `diaweb/frontend/shared/auth/staffAccess.ts` and `diaweb/frontend/modules/staff/navigation.tsx` do not include `club`.
- `aibot/app/application/use_cases/daily_fact.py` and `aibot/app/domain/daily_fact_prompt.py` already implement a 10,000 steps daily fact rubric.
- `aibot/app/domain/publish_config.py`, `aibot/app/application/use_cases/publish_draft.py`, and `aibot/services/telegram_service.py` support Telegram publish targets, but the bot transport currently resolves one global bot token.

## Target Architecture

```text
Prodamus callback
  -> diaverseapi/app/club
     -> membership, payment contract, invite/join state, buddy groups, leaderboards, alerts

Telegram updates
  -> clubbot runtime on foreign server
     -> signed internal HTTP
        -> diaverseapi/app/club/internal_api.py

Telegram outbound commands
  -> diaverseapi ClubTelegramOutbox
     -> signed claim/ack internal API
        -> clubbot runtime executes Telegram Bot API methods

Staff panel
  -> diaweb /staff/club
     -> diaverseapi /v1/admin/club...

Copywriting and visuals
  -> diaverseapi signed service request with idempotency key
  -> aibot club-benefit rubric
  -> aibot AI leaderboard image endpoint/job
  -> aibot Telegram publish target with bot_profile=club
```

## Domain Model Sketch

`diaverseapi/app/club/models.py` should include explicit enums instead of boolean-only state:

- `ClubProgram`: slug, title, timezone, start/end, active/default flags, daily step goal, Telegram chat id, topic/thread ids, schedules, curator settings.
- `ClubMembership`: program id, user id, Telegram user id, username snapshot, source, status, joined/left/verified timestamps, access window, current payment contract.
- `ClubPaymentContract`: provider, provider subscription id, current period, next charge, last successful/failed renewal, grace window, auto-renew/cancel state.
- `ClubInvite`: membership id, token, Telegram invite link metadata, status, expiry, used timestamp.
- `ClubManualAccess`: audit-friendly fields for manual/gift/migration/test additions if not folded into membership metadata.
- `ClubMembershipEvent`: durable audit/event trail for status transitions, manual actions, payment events, Telegram verification, pair changes, and removal attempts.
- `ClubBuddyGroup`: program id, kind (`pair`, `waiting_anchor`, optional `trio`), status, active window, reason.
- `ClubBuddyMember`: group id, membership id, role (`participant`, `anchor`), joined/left timestamps.
- `ClubTelegramEvent`: idempotent record of update id/message/member event, raw payload hash, event type, processing status.
- `ClubChatActivity`: last seen/message dates per membership for silence detection.
- `ClubStepReportEvidence`: optional Telegram report evidence from the "my steps" topic, including message id, thread id, photo/file metadata, parsed text steps if any, and moderation status.
- `ClubDailyStepSnapshot`: optional materialized per-member date steps from `user_activities`.
- `ClubLeaderboardSnapshot`: date/range, kind, exact payload JSON, image generation status, image URL/path, publish message id.
- `ClubTelegramOutbox`: idempotent outbound commands for DM, group message, approve join, kick/ban/unban, retry metadata, claim lease, ack/nack status, and Telegram error payload.

Membership statuses:

```text
pending_payment
paid_pending_join
pending_verification
active
manual_active
payment_grace
expired_nonpayment
left_group
removed
```

## Telegram Membership Flow

1. User pays or staff creates manual pending membership.
2. Backend creates a unique invite or join-request link tied to membership.
3. User requests to join the supergroup through the membership invite/join flow.
4. `clubbot` receives `chat_join_request` or `chat_member` update.
5. `clubbot` sends signed event to `diaverseapi`.
6. Backend resolves membership by invite token or known Telegram identity.
7. Backend verifies known users with `getChatMember` where needed.
8. Membership becomes `active`, buddy pairing runs, welcome/group message is queued.
9. Direct messages are best-effort in v1; if Telegram does not allow DM because the user never opened the bot, the event is logged and surfaced in `/staff/club`.

## Telegram Outbox Execution Contract

- `diaverseapi` owns business state and persists desired Telegram actions in `ClubTelegramOutbox`.
- `clubbot` owns actual Telegram Bot API calls for club system actions. It claims pending outbox commands through signed internal HTTP, executes them, then acknowledges success/failure.
- Backend jobs may enqueue, retry, release stale leases, and dead-letter commands, but must not hide Telegram delivery failures from `/staff/club`.
- Every outbox command must have an idempotency key so repeated callbacks, retries, or bot restarts do not duplicate welcomes, approvals, removals, or leaderboard publications.
- `clubbot` preflight must verify bot identity, configured chat id, allowed updates, topic/thread ids, and admin permissions needed for join approval and future removal.

Manual migration flow:

1. Staff creates pending manual membership by Diaverse user and optional Telegram username/user id.
2. Backend generates a short verification code or one-time verification link for staff-assisted use.
3. For v1, staff may bind a known numeric Telegram user id or create a pending membership and verify it via join/member events.
4. Future enhancement: user opens `@ClubBot` and confirms with `/start <code>` or a code entry flow.
5. Backend binds true Telegram numeric user id, checks group membership with `getChatMember` when available, and activates.

Manual/bulk import guardrail:

- Existing group members can be imported manually or in bulk, but username-only records remain `pending_verification` until a numeric Telegram user id is verified by staff, join/member event, or explicit staff override with reason.
- Verified manual members may use `manual_active`; unverified imported members must be excluded from rankings by default.

## Step And Leaderboard Rules

- Source of truth: active club roster + `UserActivity.steps`.
- Daily date grouping: use existing `datetime_to_date_user(UserActivity.created_at, UserActivity.user_id)` behavior unless a club-wide timezone override is explicitly needed.
- Ranking population for date D:
  - `active` and `manual_active` memberships active on D;
  - `payment_grace` memberships still counted during grace;
  - `paid_pending_join`, `pending_verification`, `expired_nonpayment`, `left_group`, `removed` excluded.
- New member inclusion rule:
  - joined before configured cutoff, e.g. 12:00 club timezone, may count that day;
  - joined after cutoff starts leaderboard from next day.
- Missing steps are represented as `0` or `no_data`; the payload must distinguish these for staff analysis.
- Pair leaderboard sums active pair members for the date. If one member is missing steps, show the sum and missing marker rather than silently hiding the pair.
- `ClubLeaderboardSnapshot.payload_json` is authoritative; AI image is presentational.
- Telegram screenshots/messages are optional accountability evidence and silence-scan input. They never replace DB step aggregation for rankings in v1.

## Service Auth For Creative Assets

- `diaverseapi -> aibot` calls for club leaderboard images/publishing must use explicit service authentication, not staff BFF tokens.
- Acceptable v1 shape: HMAC-SHA256 or short-lived service JWT with issuer/audience scoped to club creative endpoints, plus `X-Request-ID`, timestamp, and idempotency key.
- `aibot` must authorize this service caller only for club asset generation/publish endpoints and must log service name, request id, snapshot id, and idempotency key without logging secrets.

## Future Recurring Payment Guardrails

Implement model readiness now; defer full recurring job/callback behavior unless exact Prodamus payloads are confirmed.

- `renewal_failed` event moves membership to `payment_grace`.
- Day 0, 1, 2 DMs are queued only after failure, never before renewal. If DM is unavailable because the user never opened the bot, the failure is logged and shown in `/staff/club`.
- During `payment_grace`, preserve current pair but do not put the member into new pairing.
- If renewal succeeds during grace, return to `active` and keep pair.
- At grace deadline, move to `expired_nonpayment`, queue final DM, queue Telegram removal, close/reform pair.
- Telegram removal must use outbox/retry, not inline payment callback logic.

## Tasks

### Phase 1 - Backend Club Foundations

- [x] Task 1 [diaverseapi]: Create `app/club` package skeleton.
  - Files: `app/club/__init__.py`, `app/club/enums.py`, `app/club/models.py`, `app/club/schemas.py`, `app/club/repositories.py`, `app/club/service.py`, `app/club/dependencies.py`, `app/club/errors.py`.
  - Deliverable: domain package with enums/statuses and empty service/repository seams matching cabinet conventions.
  - Logging: service constructors and future state transitions should use `[club]` structured log prefixes.

- [x] Task 2 [diaverseapi]: Add club schema and migration.
  - Files: `app/club/models.py`, `migrations/versions/20260519_club_domain.py`.
  - Deliverable: create club programs, memberships, payment contracts, invites, manual access, membership events/audit trail, buddy groups/members, telegram events, report evidence, chat activity, daily step snapshots, leaderboard snapshots, and telegram outbox tables.
  - Constraints: use short explicit index/constraint names under PostgreSQL 63-byte identifier limit.
  - Outbox constraints: include idempotency key, claim lease fields, ack/nack status, attempt counters, next attempt timestamp, and dead-letter metadata.
  - Logging: migration is schema-only; runtime logging starts in services.

- [x] Task 3 [diaverseapi]: Implement club membership state machine and roster service.
  - Files: `app/club/service.py`, `app/club/repositories.py`, `app/club/schemas.py`.
  - Deliverable: create/update/resolve the active club program, provide an idempotent bootstrap for the initial current program, create pending paid/manual memberships, activate, mark left, remove, enter/exit payment grace, validate transition rules, and persist a `ClubMembershipEvent` for every meaningful transition.
  - Program bootstrap: scheduled jobs and payment finalizers must resolve a configured active program and fail loudly/log clearly if no active program exists.
  - Logging: log every transition with membership id, previous status, next status, reason, actor, event id, and idempotency key.

- [x] Task 4 [diaverseapi]: Add manual member management service.
  - Files: `app/club/service.py`, `app/club/schemas.py`, `app/club/repositories.py`.
  - Deliverable: staff can create manual/gift/migration/test membership, bulk import existing members, generate verification code, verify Telegram user id, set access window, and record explicit staff override reasons.
  - Guardrail: username is a hint only. Username-only manual records stay `pending_verification` and are excluded from leaderboards unless a numeric Telegram user id is verified or a staff override with reason is recorded.
  - Logging: log manual source, staff id, target user id, bulk import id/count, Telegram id presence, verification code id without exposing secret code.

- [x] Task 5 [diaverseapi]: Implement Telegram event ingestion contract for `clubbot`.
  - Files: `app/club/internal_api.py`, `app/club/telegram_schemas.py`, `app/club/security.py`, `app/core/settings.py`, `app/routers/v1/endpoints.py`.
  - Deliverable: signed internal endpoints for join request, chat member update, message/chat activity, step report evidence, staff-assisted verification events, and outbox claim/ack/nack from `clubbot`.
  - Security: use HMAC-SHA256 or short-lived service JWT separate from existing auth bot secret; include timestamp/replay protection and request id logging.
  - Logging: log signature validation, event type, Telegram update id, dedupe result, and processing outcome.

- [x] Task 6 [diaverseapi]: Implement Telegram outbox.
  - Files: `app/club/outbox.py`, `app/club/tasks.py`, `app/core/broker_app.py`, `app/core/settings.py`.
  - Deliverable: enqueue Telegram commands for welcome, DM, approve join, group notice, leaderboard publish, and future kick/remove; expose claim/ack workflow for `clubbot`; release stale leases and retry/dead-letter failed commands.
  - Boundary: `diaverseapi` owns command state and retries. `clubbot` executes Telegram Bot API methods; backend code must not require direct Telegram bot token access for club system commands.
  - Logging: log command id, type, membership id, chat/user target, attempt count, retry/dead state, Telegram error code.

- [x] Task 7 [diaverseapi]: Implement buddy pairing.
  - Files: `app/club/pairing.py`, `app/club/service.py`, `app/club/repositories.py`.
  - Deliverable: transactional assignment with waiting single, waiting anchor for `@vlad_gradov`, replacement of anchor by next real member, pair close/reform APIs.
  - Constraints: use row locks or advisory locks around pairing decisions.
  - Logging: log selected candidate, lock path, group id, anchor replacement, and skipped cases.

- [x] Task 8 [diaverseapi]: Integrate club with cabinet payments and Prodamus initial checkout.
  - Files: `app/cabinet/payments/types.py`, `app/cabinet/payments/registry.py`, `app/cabinet/payments/finalizers.py`, `app/club/payment_finalizer.py`, `app/club/payments.py`.
  - Deliverable: add `club` domain, enable `prodamus-hosted` for `club`, create `ClubPaymentFinalizer`, and create/activate `paid_pending_join` membership on paid initial session.
  - Logging: log checkout creation, provider callback finalization, source ref parse result, membership linkage, duplicate callback reuse.

- [x] Task 9 [diaverseapi]: Add recurring-ready payment contract layer.
  - Files: `app/club/payments.py`, `app/club/service.py`, `app/club/models.py`, migration from Task 2 if not complete.
  - Deliverable: normalize payment events `initial_paid`, `renewal_paid`, `renewal_failed`, `cancelled`, `refunded`; update contract and membership state without implementing full Prodamus recurring callbacks.
  - Product rule: no pre-renewal reminders.
  - Logging: log provider event ids, event kind, current period, grace start/end, and no-op dedupe.

- [x] Task 10 [diaverseapi]: Implement DB-step aggregation for club.
  - Files: `app/club/steps.py`, `app/club/repositories.py`.
  - Deliverable: query active memberships and aggregate `UserActivity.steps` by date/range using existing user-local day expression; optionally expose Telegram report evidence next to DB steps for staff analysis without using it for ranking.
  - Logging: log program id, date/range, membership count, missing step count, query duration.

- [x] Task 11 [diaverseapi]: Implement leaderboard snapshots.
  - Files: `app/club/leaderboards.py`, `app/club/schemas.py`, `app/club/repositories.py`.
  - Deliverable: daily individual, daily pair, overall individual, overall pair snapshots with exact payload JSON and stable idempotency.
  - Logging: log snapshot key, input counts, top ids, status, reused vs created.

- [x] Task 12 [diaverseapi]: Add aibot client for creative assets.
  - Files: `app/club/aibot_client.py`, `app/club/aibot_auth.py`, `app/core/settings.py`, `app/club/leaderboards.py`.
  - Deliverable: signed service HTTP client to request leaderboard AI image generation/publish from `aibot`, passing exact snapshot payload, target profile, request id, timestamp, and idempotency key.
  - Architecture: this is an explicit `diaverseapi -> aibot` integration for club creative assets only; no DB sharing.
  - Security: do not reuse diaweb staff BFF tokens; use a service HMAC or short-lived service JWT scoped to club creative endpoints.
  - Logging: log request id, snapshot id, idempotency key, timeout/retry, aibot response status, image job id/message id.

- [x] Task 13 [diaverseapi]: Implement silence detection and alerting.
  - Files: `app/club/alerts.py`, `app/club/tasks.py`, `app/cabinet/logging/models.py`, `app/cabinet/logging/service.py` if needed.
  - Deliverable: detect members with no DB steps and no chat activity for configured threshold; create/dedupe club alerts and expose them through `/staff/club`. Reuse cabinet logging/notification internals only as backend plumbing, not as the primary staff UI.
  - Logging: log scanned active count, matched silent count, alert fingerprint, dedupe result.

- [x] Task 14 [diaverseapi]: Add scheduled club jobs.
  - Files: `app/club/tasks.py`, `app/core/broker_app.py`.
  - Deliverable: schedule daily cutoff/snapshot, 09:00 leaderboard publish request, silence scan, known-member Telegram verification scan, stale outbox lease release, and outbox retry maintenance.
  - Logging: log each tick start/end, program count, job duration, created snapshots, skipped disabled programs.

- [x] Task 15 [diaverseapi]: Add staff club API.
  - Files: `app/club/admin_api.py`, `app/club/dependencies.py`, `app/club/schemas.py`, `app/routers/v1/endpoints.py`.
  - Deliverable: endpoints for dashboard, members, manual add, bulk import, verify in Telegram, invites, pairs, leaderboards, settings, membership event history, Telegram report evidence, and all club alerts including silence, payment-grace, Telegram delivery, and onboarding failures.
  - RBAC: view endpoints require `club:view`; mutations require `club:edit` or narrower permissions such as `club.alerts:update` and `club.settings:manage`.
  - Logging: log staff id, route action, filters, mutation target, validation failures.

- [x] Task 16 [diaverseapi]: Add staff RBAC and logging module support.
  - Files: `app/cabinet/rbac/staff_modules.py`, `app/cabinet/rbac/seed.py`, `app/cabinet/logging/models.py`.
  - Deliverable: add `club` module and permissions (`club:view`, `club:edit`, `club.alerts:update`, `club.settings:manage`); include `club` in logging modules only as backend alert infrastructure, while keeping the staff-facing alert workflows inside `/staff/club`.
  - Logging: seed already logs role/permission creation; ensure club additions are idempotent.

- [x] Task 17 [diaverseapi]: Add `clubbot` runtime package.
  - Files: `app/clubbot/__init__.py`, `app/clubbot/main.py`, `app/clubbot/settings.py`, `app/clubbot/telegram_client.py`, `app/clubbot/backend_client.py`, `app/clubbot/handlers.py`.
  - Deliverable: webhook-capable Telegram bot adapter using existing `python-telegram-bot` dependency, signing calls to backend, processing join requests, member updates, staff-assisted verification events, group messages, step report evidence, and claimed outbox commands. `/start` code confirmation is deferred.
  - Constraint: no direct DB imports or DB credentials in `clubbot`.
  - Preflight: add startup/health checks for bot identity, configured chat id, allowed updates, topic/thread ids, and admin permissions for join approval and future removal.
  - Logging: log update id, handler kind, backend request id, outbox command id, Telegram method failures, redacted tokens.

- [x] Task 18 [diaverseapi]: Backend tests.
  - Files: `tests/test_club_*.py`, `tests/test_cabinet_prodamus_payments.py`, `tests/test_cabinet_payment_sessions.py`, `tests/test_alembic_graph.py`.
  - Deliverable: cover state transitions, membership events, manual add, bulk import guardrails, Prodamus club finalizer, Telegram event idempotency, outbox claim/ack/retry, service auth signing, pairing race behavior, DB-step leaderboards, Telegram report evidence, silence alerts.
  - Verification: include Alembic heads and offline SQL compile for new migration.

### Phase 2 - Staff Club Frontend

- [x] Task 19 [diaweb]: Add staff module access wiring for `club`.
  - Files: `frontend/shared/auth/staffAccess.ts`, `frontend/modules/staff/navigation.tsx`, relevant admin access labels.
  - Deliverable: `club` module key, route protection, nav item, managed permissions.
  - Logging: route guard/client logs should include module key for denied access if local pattern exists.

- [x] Task 20 [diaweb]: Add club API client and types.
  - Files: `frontend/modules/club/api.ts`, `frontend/modules/club/types.ts`, `frontend/modules/club/index.ts`.
  - Deliverable: typed client for dashboard, members, manual add, bulk import, verify, pairs, leaderboards, settings, membership events, report evidence, and club alerts.
  - Logging: client mutations log concise action context and failed responses without sensitive payloads.

- [x] Task 21 [diaweb]: Add `/staff/club` route shell.
  - Files: `frontend/app/[lang]/staff/club/page.tsx`, `frontend/modules/club/components/ClubAdminPage.tsx`.
  - Deliverable: tabbed operational admin surface, not a marketing page.
  - UI: dense staff tool layout with dashboard, members, pairs, leaderboards, settings.

- [x] Task 22 [diaweb]: Implement club dashboard.
  - Files: `frontend/modules/club/components/ClubDashboard.tsx`.
  - Deliverable: active count, pending join, pending verification, grace, missing steps, silence alerts, latest snapshots.
  - Logging: log dashboard load failures and refresh actions.

- [x] Task 23 [diaweb]: Implement member management and manual add.
  - Files: `frontend/modules/club/components/ClubMembersTable.tsx`, `ClubManualAddDialog.tsx`, `ClubBulkImportDialog.tsx`, `ClubVerificationPanel.tsx`, `ClubMembershipEventsPanel.tsx`.
  - Deliverable: search/filter, add manual member, bulk import migration/VIP/test members, send/generate verification code, verify in Telegram, create invite, remove/expire, and show membership event history.
  - Guardrails: username is shown as hint only; UI must distinguish numeric Telegram id verified vs username-only pending and show explicit override reason if staff activates without bot verification.

- [x] Task 24 [diaweb]: Implement buddy pairs management.
  - Files: `frontend/modules/club/components/ClubPairsPanel.tsx`.
  - Deliverable: show active pairs, waiting anchor, payment hold, reassign/close actions, pair health from steps.
  - Logging: log pair mutation requests and failures.

- [x] Task 25 [diaweb]: Implement leaderboards and AI image controls.
  - Files: `frontend/modules/club/components/ClubLeaderboardsPanel.tsx`.
  - Deliverable: daily/overall individual and pair snapshots, exact payload table, optional Telegram report evidence markers, generated image preview, regenerate/publish/retry buttons.
  - Product rule: exact payload table is authoritative even if image is AI-generated.

- [x] Task 26 [diaweb]: Implement club settings.
  - Files: `frontend/modules/club/components/ClubSettingsPanel.tsx`.
  - Deliverable: program schedule, timezone, join cutoff, Telegram chat/thread ids, curator/anchor user, silence threshold, aibot target/profile, club benefit prompt/profile mapping, leaderboard image settings, and bot preflight status.
  - Logging: log settings saves, validation errors, and dirty state.

- [x] Task 27 [diaweb]: Frontend tests and verification.
  - Files: existing frontend test locations if present; otherwise focused component/route smoke checks.
  - Deliverable: access guard, API client, manual add form validation, leaderboard panel state.

### Phase 3 - Aibot Club Publishing And Visuals

- [x] Task 28 [aibot]: Add per-target bot profile support.
  - Files: `core/config.py`, `app/domain/publish_config.py`, `app/api/routes/publish_targets.py`, `app/application/use_cases/publish_draft.py`, `services/telegram_service.py`, `.env.example`.
  - Deliverable: publish target config supports `bot_profile`, `message_thread_id`, `publish_transport=bot`; token resolver maps profile names to env secrets.
  - Security: never persist raw bot tokens in DB or responses.
  - Logging: log bot profile name, not token; include thread id and target id.

- [x] Task 29 [aibot]: Add club benefit rubric.
  - Files: `app/domain/club_benefit_prompt.py`, `app/application/use_cases/club_benefit.py`, `app/api/routes/club_benefits.py`, `app/worker/processors/generate_club_benefit.py`, `app/worker/main.py`, `db/models.py`, `db/repositories/*`, `migrations/20260519_0001_copywriting_club_benefits.sql`.
  - Deliverable: 1-2 daily rich walking/10k steps posts, using global style plus `club_benefit_prompt` style field; reuse/extract daily-fact patterns where practical.
  - Logging: log selected slot/date, prompt source, draft id, generation job id, publish target.

- [x] Task 30 [aibot]: Add club leaderboard image generation endpoint/job.
  - Files: `app/api/routes/club_assets.py`, `app/application/use_cases/club_leaderboard_image.py`, `app/worker/processors/generate_club_leaderboard_image.py`, `db/models.py`, `db/repositories/*`, `migrations/20260519_0002_copywriting_club_leaderboard_assets.sql`.
  - Deliverable: accept exact snapshot payload from `diaverseapi`, validate service auth, create or reuse idempotent AI image job, store prompt/model/version/path, optionally publish to Telegram target with `bot_profile=club`.
  - Guardrail: payload JSON is never altered by the image prompt; output metadata links image back to snapshot id.
  - Logging: log service caller, request id, snapshot id, idempotency key, hash of payload, image job id, model, publish event id/message id.

- [x] Task 31 [aibot]: Keep club style support backend-owned and editable from `/staff/club`.
  - Files: `app/api/routes/styles.py`, `app/domain/club_benefit_prompt.py`, `app/api/routes/club_benefits.py`; `diaweb/frontend/modules/copywriting/*` should not be changed unless a generic style API contract breaks.
  - Deliverable: `aibot` exposes/accepts `club_benefit_prompt` as a style/profile field, while the staff-facing edit surface for club-specific prompts lives in `diaweb` `/staff/club/settings`, not `/staff/copywriting`.
  - Logging: log style field reads/writes through existing copywriting API logging without leaking prompt secrets into unrelated club logs.

- [x] Task 32 [aibot]: Aibot tests and verification.
  - Files: `tests/test_publish_targets*.py`, `tests/test_publish_draft*.py`, `tests/test_club_benefit*.py`, `tests/test_club_leaderboard_image*.py`.
  - Deliverable: token resolver, sanitized config, bot profile publish, message thread publish, service auth validation, rubric generation, image endpoint idempotency.

### Phase 4 - Cross-Repo Integration

- [x] Task 33 [cross-repo]: Wire `diaverseapi` to `aibot` for club creative assets.
  - Files: `diaverseapi/app/club/aibot_client.py`, `diaverseapi/app/club/aibot_auth.py`, `aibot/app/api/routes/club_assets.py`, shared env examples.
  - Deliverable: signed service-auth request from backend snapshot to aibot image generation/publish, stable idempotency key shared across retries, response persisted on `ClubLeaderboardSnapshot`.
  - Logging: correlated request id, service caller, snapshot id, and idempotency key across both services.

- [x] Task 34 [cross-repo]: End-to-end club onboarding flow.
  - Files: `diaverseapi/app/club/*`, `diaverseapi/app/clubbot/*`, `diaweb/frontend/modules/club/*`.
  - Deliverable: staff can create program/manual member, bulk import existing members, generate invite/verification, bot verifies Telegram identity, membership activates only after verified identity or explicit override, buddy pairing occurs.
  - Logging: one traceable request/update id from Telegram event to backend membership transition.

- [x] Task 35 [cross-repo]: End-to-end leaderboard flow.
  - Files: `diaverseapi/app/club/leaderboards.py`, `aibot/app/application/use_cases/club_leaderboard_image.py`, `diaweb/frontend/modules/club/components/ClubLeaderboardsPanel.tsx`.
  - Deliverable: snapshot from DB steps, AI image job, Telegram publish via club bot profile, staff preview and retry.
  - Logging: snapshot id and publish event id visible across services.

- [x] Task 36 [cross-repo]: Documentation and deployment notes.
  - Files: `docs/club.md` or repo-local docs/runbooks as appropriate, `.env.example` files in affected repos.
  - Deliverable: describe env vars, service-auth secrets, bot deployment on foreign server, webhook setup, allowed updates, Telegram permission preflight, outbox claim/ack contract, Prodamus setup, no-list-members roster model, recurring future behavior, and `/staff/club` alert ownership.

## Verification Plan

`diaverseapi`:

```powershell
poetry run pytest tests/test_alembic_graph.py
poetry run pytest tests/test_club_*.py tests/test_cabinet_prodamus_payments.py tests/test_cabinet_payment_sessions.py
poetry run python -m alembic heads
poetry run python -m alembic upgrade <down_revision>:20260519_club_domain --sql
```

`diaweb`:

```powershell
npm run lint
npm run typecheck
npm test -- --runInBand club
```

Use actual package scripts from `diaweb/frontend/package.json` during implementation if names differ.

`aibot`:

```powershell
pytest tests/test_publish_targets*.py tests/test_publish_draft*.py tests/test_club_*.py
python -m compileall app services db core
```

Workspace:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1
```

Run Graphify refresh after code changes, not after this planning-only setup.

## Commit Plan

Suggested checkpoints:

1. `diaverseapi`: `feat(club): add membership domain and telegram roster foundation`
   - Tasks 1-7.
2. `diaverseapi`: `feat(club): integrate payments steps leaderboards and alerts`
   - Tasks 8-18.
3. `diaweb`: `feat(club): add staff club management module`
   - Tasks 19-27.
4. `aibot`: `feat(copywriting): support club bot publishing and visuals`
   - Tasks 28-32.
5. Cross-repo final: `feat(club): wire onboarding and leaderboard flows`
   - Tasks 33-36, grouped by repository commits if changes span repos.

## Open Implementation Notes

- Confirm exact Prodamus recurring callback payloads before implementing renewal failure automation.
- Confirm whether club join should use `chat_join_request` approval only or unique invite links without pre-approval. Preferred: join request approval.
- Confirm public/user-facing club purchase and post-payment join UX before adding any `diaweb` customer checkout pages.
- Confirm Telegram thread ids for welcome, reports/activity, and leaderboard publishing.
- Confirm whether members in `payment_grace` should stay in daily leaderboard during all three days. Current plan says yes.
- Confirm whether late-day join cutoff should be 12:00 club timezone. Current plan uses this as configurable default.
