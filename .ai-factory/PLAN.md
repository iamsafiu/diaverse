# Club Rating Reward Claims

**Created:** 2026-06-29
**Mode:** fast plan, no branch creation
**Branch:** none

## Settings

- **Testing:** yes
- **Logging:** standard operational logging for materialization, claim, and skipped duplicate paths
- **Docs:** plan only; update product docs only if implementation changes the public API contract
- **GBrain:** searched first; no direct rating reward pages found, so source files were verified directly

## Workspace Scope

This is a cross-repo feature plan from the workspace root.

- `diaverseapi`: backend reward materialization, claim API, fulfillment, migrations, tests
- `diaweb`: BFF routes, rating UI, rewards vault UI, claim modal, tests
- `diaverse-mobile`: out of scope for first implementation unless a separate mobile Club rating surface is added
- root `diaverse`: plan file only

## Product Decisions

- Rating rewards are **claimable entitlements**, not direct grants during leaderboard calculation.
- Daily rewards are finalized after the day closes, for the previous calendar day.
- Season rewards are finalized after the 15-day season closes, before pair rollover changes the active pair groups.
- The rating screen shows **"Итоги прошлого сезона" for 3 days** after season end.
- After those 3 days, season results disappear from the rating tab, but unclaimed rewards stay available in the rewards vault until claimed.
- Reward bundles are fixed by rank and board type. No extra random roll happens at claim time.
- Pair rewards are granted per eligible member of the winning pair.
- First implementation uses backend static reward rule config. Staff/admin reward editing is not included.

## Reward Table

### Daily Personal

- Rank 1: `100 XDV`, `Rare box x1`, `DNA capsule x100`
- Rank 2: `75 XDV`, `Unusual box x2`, `DNA capsule x75`
- Rank 3: `50 XDV`, `Unusual box x1`, `DNA capsule x50`
- Ranks 4-10: `25 XDV`, `Basic box x1`

### Daily Pair

- Rank 1: `75 XDV`, `Unusual box x2`, `Galaglue x150`
- Rank 2: `50 XDV`, `Unusual box x1`, `Galaglue x100`
- Rank 3: `35 XDV`, `Basic box x2`
- Ranks 4-5: `20 XDV`, `Basic box x1`

### Season Personal

- Rank 1: `500 XDV`, `Mythical box x2`, `Rare mutagen x5`
- Rank 2: `350 XDV`, `Epic box x2`, `Rare mutagen x3`
- Rank 3: `250 XDV`, `Rare box x3`, `Common mutagen x10`
- Ranks 4-10: `100 XDV`, `Rare box x1`

### Season Pair

- Rank 1: `350 XDV`, `Epic box x2`, `Rare mutagen x3`
- Rank 2: `250 XDV`, `Rare box x3`, `Common mutagen x10`
- Rank 3: `180 XDV`, `Rare box x2`
- Ranks 4-5: `75 XDV`, `Unusual box x2`

## Tasks

### Phase 1 - Backend Reward Entitlements

- [x] **Task 1: Add rating reward entitlement persistence**
  - Add an Alembic migration and SQLAlchemy model for `club_rating_reward_entitlements`.
  - Store: `program_id`, `period_key`, `period_start`, `period_end`, `board_kind`, `rank`, `target_kind`, `user_id`, optional `membership_id`, optional `buddy_group_id`, `status`, `available_at`, `season_result_visible_until`, `claimed_at`, `fulfillment_batch_id`, `idempotency_key`, `rewards_json`, `snapshot_json`, and metadata.
  - Add uniqueness around the idempotency key and per-user period/board entitlement to prevent duplicate grants.
  - Add indexes for listing pending rewards by user and visible season results by period.
  - Logging: migration itself does not log; model/service callers must log duplicate-skip and materialization counts.

- [x] **Task 2: Add static reward rules and materialization service**
  - Add `app/club/rating_rewards.py` with explicit reward rule constants for daily/season and personal/pair boards.
  - Convert reward rules into existing fulfillment line format (`currency`, `loot_box`, `resource`, `mutagen`).
  - Materialize daily entitlements from the closed previous-day boards.
  - Materialize season entitlements from frozen season totals, not from mutable current rating UI state.
  - For pair rewards, expand each winning pair into per-member entitlements and capture the buddy group/member snapshot.
  - Logging: log board kind, period key, generated count, skipped duplicate count, and empty-board cases.

- [x] **Task 3: Wire materialization into Club background jobs**
  - Update `app/club/tasks.py` so daily snapshots finalize previous-day rating rewards after leaderboard snapshots are written.
  - Update the pair rollover path so season rewards finalize for the just-ended 15-day period before active buddy groups are closed or replaced.
  - Keep the rollover idempotent: reruns must not duplicate reward rows or grants.
  - Logging: log season materialization start/end, period dates, and duplicate rerun skips.

### Phase 2 - Backend Claim API

- [x] **Task 4: Add reward list and claim API contracts**
  - Add schemas for reward entitlement cards, reward lines, season result visibility, claim requests, and claim responses.
  - Add authenticated Club cabinet endpoints:
    - `GET /v1/cabinet/club/rewards`
    - `POST /v1/cabinet/club/rewards/{reward_id}/claim`
  - Include pending rewards, claimed rewards needed for recent UI state, and previous-season result data while `season_result_visible_until` is in the future.
  - Logging: log claim attempts, successful claims, already-claimed responses, and authorization failures without sensitive data.

- [x] **Task 5: Connect claims to existing fulfillment and notifications**
  - Use `FulfillmentService.grant_batch` with `source_domain="club_rating_reward"`.
  - Use entitlement idempotency keys so retrying a claim cannot grant twice.
  - Mark entitlements claimed only after fulfillment succeeds.
  - Add cabinet notification formatting for rating rewards, with separate labels for daily and season rewards.
  - Logging: log fulfillment batch ids and failed claim transitions; do not log raw private profile data.

### Phase 3 - Diaweb API And UI

- [x] **Task 6: Add diaweb BFF routes and client types**
  - Add same-origin BFF routes under `frontend/app/api/cabinet/club/rewards`.
  - Extend `frontend/modules/club-onboarding/api.ts` and `types.ts` with reward entitlement and claim response types.
  - Normalize backend snake_case into existing camelCase frontend state conventions.
  - Logging: keep BFF logging aligned with existing route behavior; surface backend errors without leaking internals.

- [x] **Task 7: Show 3-day season results in the rating tab**
  - Update `ClubRatingMobile.tsx` to show `Итоги прошлого сезона` below the current rating controls while backend visibility is active.
  - Display top ranks, the current user's rank/reward status, and a clear claim CTA when a reward is pending.
  - Hide the block automatically after 3 days based on backend `visible_until`.
  - Keep the existing current daily/current season tabs intact.
  - Logging: no client logging beyond existing error handling; failed loads should be visible in UI state.

- [x] **Task 8: Add rewards vault and claim modal**
  - Extend `ClubRewardsMobile.tsx` with a `Сейф наград` section for daily and season rating rewards.
  - Show reward cards grouped by pending/claimed and daily/season.
  - Add a claim flow with loading, success, and already-claimed states.
  - Add a reward modal listing the received items with existing item title/image helpers where available.
  - Logging: no noisy client logs; claim errors should map to user-visible retry/error states.

### Phase 4 - Tests And Verification

- [x] **Task 9: Add backend tests**
  - Cover daily personal rewards, daily pair rewards, season personal rewards, season pair rewards, duplicate materialization, duplicate claim retry, and unauthorized claim attempts.
  - Cover fulfillment integration with `club_rating_reward` idempotency.
  - Cover notification formatting for rating rewards.
  - Cover Alembic graph and SQL generation for the new migration.
  - Logging: assert expected log events only where they protect idempotency or failure visibility.

- [x] **Task 10: Add diaweb tests**
  - Cover BFF reward list and claim route behavior.
  - Cover rating tab season result visibility and 3-day hide condition.
  - Cover rewards vault pending/claimed grouping.
  - Cover claim modal success and already-claimed states.
  - Logging: tests should assert user-facing error states, not console noise.

## Suggested Commit Plan

1. `feat(api): add club rating reward entitlements`
   - Tasks 1-3
2. `feat(api): add club rating reward claims`
   - Tasks 4-5 and backend coverage from Task 9
3. `feat(web): show and claim club rating rewards`
   - Tasks 6-8 and frontend coverage from Task 10

## Verification Commands

Run from `diaverseapi`:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_club_rating_rewards.py tests/test_club_cabinet_api.py tests/test_club_tasks.py tests/test_cabinet_notifications.py tests/test_alembic_graph.py
.\.venv\Scripts\python.exe -m alembic heads
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

Run from `diaweb/frontend`:

```powershell
npm run test -- __tests__/modules/club-onboarding __tests__/app/api/cabinet/club
npm run typecheck
npm run lint
```

After implementation, sync the touched sources into the local knowledge layer:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1
```

## Definition Of Done

- Daily personal and pair rewards are created once per closed day.
- Season personal and pair rewards are created once per closed 15-day season.
- Season results are visible in the rating tab for exactly 3 days after season end.
- Unclaimed rewards remain claimable from the rewards vault after the 3-day season result block disappears.
- Claims use existing fulfillment, are idempotent, and create cabinet notifications.
- Backend and diaweb tests cover materialization, claim, visibility, and duplicate paths.
