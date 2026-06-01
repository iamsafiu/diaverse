# Implementation Plan: Club Pairing Rollover Images And 14-Day Cadence

Created: 2026-06-01
Mode: fast
Branch: none

## Settings

- Testing: yes
- Logging: verbose
- Docs: yes

## Workspace Mode

- Mode: fast multi-repo workspace plan
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain via `scripts\gbrain.ps1`; source code remains final authority

## Repository Matrix

| Repository | Path | Affected | Role |
| --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | Club pairing cadence, rollover state, settings API, signed aibot requests, scheduler |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | yes | AI image generation and Telegram publication for pairing rollover posts |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `/staff/club/settings` prompt field and labels |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | Standalone payment bridge; not part of pairing/image behavior |
| `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan/docs/daily only | Coordination plan, docs update, daily/GBrain follow-up |

## Goal

Пересборка пар в клубе должна происходить каждые 14 дней, начиная от последней успешной месячной пересборки. После успешной пересборки нужно публиковать в Telegram-группу пост с текстом и AI-картинкой. Картинка использует те же reference images, что и картинки рейтингов, но имеет отдельный prompt в настройках клуба. Публикация должна идти в общий чат/general: не передавать `message_thread_id`, если отдельный топик не задан.

## Product Decisions

- The first 14-day cycle starts from the latest successful monthly rollover state:
  - prefer `program.metadata_json.last_monthly_pairing_at` when present;
  - otherwise derive the anchor date from `last_monthly_pairing_month` as the first day of that month in the program timezone.
- Do not implement `*/14` day-of-month cron. Run a daily scheduler tick and let the backend service decide whether `last_successful_rollover_date + 14 days <= today`.
- New default cadence is 14 calendar days.
- Keep the existing pair text template concept, but update labels/semantics from "monthly" to "pairing rollover" where user-facing.
- Add a separate image prompt setting for pairing rollover images.
- Reuse `leaderboard_image_reference_paths` for pairing rollover image references.
- Telegram publication should include both text and image in the group/general destination.
- Avoid automatic duplicate posts: if the initial aibot request is accepted, let the async aibot publish job own the image+caption publication; enqueue plain-text fallback only if the initial signed aibot request cannot be accepted.

## Source Context

- `diaverseapi/app/core/broker_app.py`: schedules `club_monthly_pairing_rollover` with cron `10 0 1 * *`.
- `diaverseapi/app/club/tasks.py`: task handler calls `ClubPairingService.run_monthly_rollover()`.
- `diaverseapi/app/club/pairing.py`: current rollover is idempotent by `last_monthly_pairing_month`, closes active pairs, shuffles active regular members, creates new pairs, and queues a text notice.
- `diaverseapi/app/club/admin_api.py` and `diaverseapi/app/club/schemas.py`: settings metadata currently exposes leaderboard image prompt/reference fields and monthly pair text.
- `diaverseapi/app/club/aibot_client.py`: signed HMAC client already prepares leaderboard image/publish payloads with prompt template and reference paths.
- `aibot/app/api/routes/club_assets.py`: signed internal endpoint creates/reuses image assets and jobs.
- `aibot/app/application/use_cases/club_leaderboard_image.py`: image generation, prompt rendering, reference image validation, and Telegram publish plan already exist for club leaderboard assets.
- `diaweb/frontend/modules/club/components/ClubSettingsPanel.tsx`: staff settings UI currently has "Текст ежемесячной пересборки" and "Картинка рейтинга".
- `docs/club.md`: runbook currently documents "Monthly marathon reset" and must be updated.

## Tasks

### Phase 1: Backend Cadence And Settings Contract

- [ ] Task 1: Add 14-day rollover settings and due-date calculation in `diaverseapi`.

  Deliverable:
  - Update `diaverseapi/app/club/schemas.py` and `diaverseapi/app/club/admin_api.py` to expose and normalize:
    - `pairing_rollover_interval_days` with default `14`;
    - `pairing_rollover_image_prompt_template`;
    - optional future-compatible `telegram_pairing_rollover_message_template`, while falling back to existing `telegram_monthly_pairs_message_template`.
  - Keep old `telegram_monthly_pairs_message_template`, `last_monthly_pairing_month`, and `last_monthly_pairing_at` readable for backward compatibility.
  - Add a helper in `diaverseapi/app/club/pairing.py` that resolves the rollover anchor from the last successful monthly rollover and computes whether the next 14-day rollover is due in the program timezone.
  - Update `diaverseapi/app/core/broker_app.py` so the scheduler ticks daily instead of monthly. Keep the Redis channel name if changing it would add unnecessary deployment risk, but make logs and code comments clear that the task is now period-based.
  - No Alembic migration is expected if all new settings live in `ClubProgram.metadata_json`; verify before implementation.

  Logging requirements:
  - DEBUG log anchor source, anchor date, interval days, computed next due date, current local date, and due/not-due result.
  - INFO log skipped daily ticks that are not due with compact date metadata.
  - WARNING log invalid interval values, invalid timezone fallback, and missing legacy anchor when the service cannot safely determine the first due date.

  Dependencies:
  - None.

### Phase 2: Periodic Pair Rollover State And Notice Payload

- [ ] Task 2: Generalize `run_monthly_rollover()` into a 14-day periodic rollover while preserving idempotency.

  Deliverable:
  - In `diaverseapi/app/club/pairing.py`, add or refactor to a method such as `run_periodic_rollover(program_id=...)`.
  - Preserve the existing pair formation rules:
    - close all active buddy groups;
    - shuffle active regular members;
    - exclude fallback-only admin from regular shuffle;
    - use fallback admin only for an odd regular member;
    - create a real `solo_buffer` if fallback cannot be used.
  - Replace month-only idempotency with a period key such as the due date (`YYYY-MM-DD`) and store:
    - `last_pairing_rollover_period_key`;
    - `last_pairing_rollover_at`;
    - `last_pairing_rollover_anchor_date`;
    - `last_pairing_rollover_payload` containing pair lines and counts for retryable image publication.
  - Continue writing legacy `last_monthly_pairing_month` / `last_monthly_pairing_at` only if needed for compatibility, but do not use them as the new primary idempotency key after migration.
  - Return a result object that includes period key, pair lines, created groups, closed groups, fallback id, odd waiting id, and whether the run was skipped as not due or already processed.
  - Update the task log text in `diaverseapi/app/club/tasks.py` from monthly-only wording to periodic/14-day wording.

  Logging requirements:
  - INFO log due rollover start and completion with program id, period key, interval days, closed count, created count, fallback id, and odd waiting id.
  - INFO log idempotent skips separately from not-due skips.
  - DEBUG log candidate membership ids before shuffle and generated pair lines count.
  - WARNING log empty candidates, invalid state transitions, fallback busy/missing for odd members, and cases where a previous active group cannot be closed.

  Dependencies:
  - Depends on Task 1.

### Phase 3: Backend Aibot Request For Pairing Rollover Image+Text

- [ ] Task 3: Add a signed `diaverseapi -> aibot` request path for pairing rollover image publication.

  Deliverable:
  - Extend `diaverseapi/app/club/aibot_client.py` with a pairing rollover creative config that:
    - reads `pairing_rollover_image_prompt_template`;
    - reuses `leaderboard_image_reference_paths`;
    - uses the rendered pairing rollover text as publish text/caption;
    - computes an image config hash from the prompt + references.
  - Build a deterministic payload/idempotency key from program id, period key, pair list payload hash, and image config hash.
  - Publish to general by default: do not pass `message_thread_id` unless a future explicit pairing rollover thread setting exists.
  - In `diaverseapi/app/club/tasks.py` or a small service helper, request aibot publication only after the rollover transaction has committed or after saved rollover payload state is durable.
  - If the initial aibot HTTP request fails synchronously, enqueue the existing plain text group notice as a fallback so the club still receives the pair list.
  - Do not enqueue the old plain text notice when the aibot request is accepted, to avoid duplicate text posts.

  Logging requirements:
  - DEBUG log payload hash, prompt length, reference count, target profile, and whether a thread id was intentionally omitted.
  - INFO log accepted image publication request with program id, period key, idempotency key, image config hash, asset/job ids when returned, and fallback-notice status.
  - WARNING log missing aibot config, rejected aibot response, and fallback notice enqueue.
  - Never log raw reference file contents, HMAC signatures, or full prompt text; log lengths and hashes only.

  Dependencies:
  - Depends on Tasks 1 and 2.

### Phase 4: Aibot Pairing Rollover Image Generation And Publish

- [ ] Task 4: Teach `aibot` to generate and publish pairing rollover images using the existing club asset pipeline.

  Deliverable:
  - Add a signed internal route in `aibot/app/api/routes/club_assets.py`, for example `/internal/club/pairing-rollovers/image`, or extend the current route with an explicit `asset_kind="pairing_rollover"` without changing the leaderboard behavior.
  - Reuse the existing image asset/job infrastructure where practical to avoid a database migration; only add a migration if source verification shows the current asset model cannot safely distinguish asset kinds.
  - Add prompt rendering in `aibot/app/application/use_cases/club_leaderboard_image.py` or a sibling use case for pairing rollover images.
  - Support template fields:
    - `{club_title}`;
    - `{period_key}`;
    - `{period_start}`;
    - `{period_end}`;
    - `{pairs_list}`;
    - `{pairs_count}`;
    - `{generated_at}`.
  - Use the same safe reference image validation and `OPENAI_IMAGE_MODEL` behavior as leaderboard images.
  - Publish the generated image with the provided text/caption through the existing publish target/userbot flow, with no topic override by default.
  - Preserve idempotency: a repeated request for the same period/payload/config should reuse the existing asset/job or completed image.

  Logging requirements:
  - INFO log asset ensure, job enqueue, generation start/done, and publish request/done with asset id, period key, payload hash, image config hash, reference count, target profile, and publish transport.
  - DEBUG log template source (`custom` vs `default`) and sanitized prompt hash.
  - WARNING log unknown template fields, missing reference images, publish target problems, and idempotency conflicts.
  - Do not log full prompt text, signatures, tokens, raw Telegram destination secrets, or image bytes.

  Dependencies:
  - Depends on Task 3 payload contract.

### Phase 5: Staff Settings UI

- [ ] Task 5: Add the pairing rollover image prompt to `/staff/club/settings`.

  Deliverable:
  - Update `diaweb/frontend/modules/club/types.ts` with the new settings fields.
  - Update `diaweb/frontend/modules/club/components/ClubSettingsPanel.tsx`:
    - add a textarea for `pairing_rollover_image_prompt_template`;
    - relabel "Текст ежемесячной пересборки" to "Текст пересборки пар";
    - explain through compact helper text that references are shared with leaderboard images;
    - keep the existing reference uploader as the single source for both rating and pairing rollover images.
  - Update API payload mapping in `ClubSettingsPanel.tsx` so the new prompt is loaded and saved.
  - Keep the UI general-topic behavior implicit: do not add a new topic field unless backend adds an explicit pairing rollover topic setting later.

  Logging requirements:
  - Runtime logging is not required for pure UI field mapping.
  - Keep existing development console diagnostics, if any, to lengths/counts only. Do not log full prompt text.

  Dependencies:
  - Depends on Task 1 response contract.

### Phase 6: Tests, Docs, And Knowledge Sync

- [ ] Task 6: Add targeted tests and update operational documentation.

  Deliverable:
  - `diaverseapi` tests:
    - 14-day due calculation from `last_monthly_pairing_at`;
    - legacy fallback from `last_monthly_pairing_month`;
    - not-due daily tick skips without closing pairs;
    - due rollover closes/recreates pairs and stores new period metadata;
    - repeated same-period run is idempotent;
    - aibot request omits `message_thread_id` for general publication;
    - synchronous aibot request failure queues plain text fallback.
  - `aibot` tests:
    - pairing rollover prompt template renders allowed fields;
    - unknown template fields fall back safely;
    - reference paths are reused and validated;
    - idempotent pairing rollover asset/job reuse;
    - publish plan uses general destination when no thread override is provided.
  - `diaweb` tests:
    - settings form loads/saves the new prompt field;
    - labels no longer say "monthly" for the pair rollover text.
  - Update `docs/club.md`:
    - replace "Monthly marathon reset" with 14-day periodic rollover behavior;
    - document daily scheduler tick + backend due-date check;
    - document image+text publication and shared references.
  - Run targeted GBrain sync for changed sources after implementation.
  - Append daily work entry after implementation.

  Logging requirements:
  - Tests should assert key branch behavior where practical, but avoid brittle exact log phrasing.
  - Documentation should mention which logs operators should inspect for due-date skips, rollover completion, aibot request acceptance, and publish failures.

  Dependencies:
  - Depends on Tasks 1-5.

## Verification Plan

- `diaverseapi`:
  - `.venv\Scripts\python.exe -m pytest tests/test_club_service.py -q -k "rollover or pairing or aibot"`
  - `.venv\Scripts\python.exe -m pytest tests -q -k "club and (rollover or pairing or settings)"`
  - `.venv\Scripts\python.exe -m ruff check app/club app/core/broker_app.py tests`
  - If an Alembic migration becomes necessary, run SQL DDL compilation: `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
- `aibot`:
  - `.venv\Scripts\python.exe -m pytest tests -q -k "club_leaderboard or club_assets or pairing_rollover"`
  - `.venv\Scripts\python.exe -m ruff check app/api/routes/club_assets.py app/application/use_cases app/worker/processors tests`
- `diaweb`:
  - `npm test -- --run frontend/__tests__/modules/club/ClubSettingsPanel.test.tsx`
  - `npm run typecheck`
- Docs/knowledge:
  - Update `docs/club.md`.
  - Run targeted GBrain sync for `diaverseapi-code`, `aibot-code`, `diaweb-code`, and `diaverse-docs`.

## Commit Plan

- Commit 1 (`diaverseapi`): `feat(club): run pairing rollover every fourteen days`
  - Tasks 1-3 backend behavior and backend tests.
- Commit 2 (`aibot`): `feat(club): generate pairing rollover images`
  - Task 4 and aibot tests.
- Commit 3 (`diaweb`): `feat(club): configure pairing rollover image prompt`
  - Task 5 and frontend tests.
- Commit 4 (`diaverse` root): `docs(club): document pairing rollover image flow`
  - Task 6 docs/daily/GBrain follow-up if root files changed.

## Risks And Edge Cases

- If no legacy monthly anchor exists, the first 14-day due date cannot be derived safely. Prefer a warning and no destructive rollover until staff sets/creates an anchor.
- A daily scheduler tick can run more often than the rollover. Idempotency must protect pair state and Telegram posts.
- Aibot image generation is asynchronous. The backend should not block the pair state transaction on image completion.
- Initial aibot request failure and async image-generation failure are different states. Only the initial synchronous failure should trigger automatic plain-text fallback to avoid duplicate posts.
- Long pair lists may exceed Telegram caption limits. Use the existing aibot publish planner or split behavior instead of hand-building one oversized caption.
- Existing metadata names contain "monthly". User-facing labels and new primary metadata should use "pairing rollover", while old fields remain readable for compatibility.
