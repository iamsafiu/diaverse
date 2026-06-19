# Implementation Plan: Club Pair Missions And Pair Feed

Branch: none (fast mode; use current child-repo branches before implementation)
Created: 2026-06-19

## Settings

- Testing: yes. Cover backend mission eligibility/claim idempotency, feed event deduplication, hub payload normalization, BFF proxying, and Buddy screen rendering.
- Logging: standard. Use INFO for successful claims/actions/feed event creation, DEBUG for computed mission/feed state and blocked reasons, WARN for expected unavailable states, ERROR only for unexpected persistence/reward failures.
- Docs: no. Treat documentation as warn-only unless implementation changes public club API contracts or operations runbooks.
- Roadmap Linkage: none. `.ai-factory/ROADMAP.md` has no applicable active milestone for this club feature.

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain was attempted first; `diaverseapi-code` search timed out and `diaweb-code` returned no results, so exact planning is based on raw source verification.
- Primary affected repositories: `diaverseapi`, `diaweb`
- Explicitly out of scope: mobile app, aibot, club10000-bot, Telegram bot changes, realtime push, pair mini-chat, referral mechanics, and redesigning the supplied Buddy layout.

## Repository Matrix

| Repository | Path | Affected | Current branch | Current status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `dev` | clean at planning | club source of truth, missions, feed, rewards |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `dev` | dirty with existing Buddy frontend work | BFF routes, hub types, Buddy UI wiring |
| `diaverse` root | `C:\Users\Indigo\Desktop\diaverse` | yes | current | plan file only | coordination |
| `diaverse-mobile` | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | unchanged | not checked | out of scope |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | unchanged | not checked | out of scope |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | unchanged | not checked | out of scope |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | unchanged | not checked | out of scope |

## Research Context

Source: current exploration and raw source verification.

Goal:
- Make the Club Buddy screen show real pair missions and pair feed from backend state.
- Keep personal daily missions separate from pair missions.
- Keep `diaverseapi` as the source of truth for rewards, claims, event identity, and feed history.

Current implementation facts:
- `diaverseapi/app/club/schemas.py` already exposes `ClubHubRead`, `ClubHubMissionRead`, `ClubBuddyActionResponse`, and daily mission claim responses.
- `diaverseapi/app/club/models.py` already has `ClubBuddyInteraction` for boost/motivation and `ClubDailyMissionClaim` for personal daily mission rewards.
- `diaverseapi/app/club/service.py` already computes hub state, today steps, buddy sync percent, streak, pair rank, daily missions, and buddy action availability.
- Boost/motivation are already limited by 10,000 sender steps and one use per pair/day.
- Motivation already creates cabinet notifications.
- `diaweb/frontend/modules/club-onboarding/components/ClubBuddyMobile.tsx` already has visual blocks for joint missions and pair feed, but these are currently static/local calculations.

Decisions:
- Add explicit `pair_missions` and `pair_feed` fields to `ClubHubRead`; do not overload existing personal `missions`.
- Add backend pair mission claim persistence scoped by `group_id`, `membership_id`, `local_date`, and `mission_key`.
- Add a small pair feed event ledger with idempotency keys instead of generating frontend-only fake feed items.
- Rewards for pair missions are claimed per member. A pair can complete a mission together, but each user receives their own XDV claim once.
- MVP feed should not log every step update. It should record only meaningful milestones and interactions.

Open questions:
- Whether pair mission rewards should always be per-user or sometimes shared/team-only. MVP uses per-user rewards because the current fulfillment system grants to a user.
- Whether step milestone feed events should be materialized during hub reads or by a later scheduled/background reconciliation. MVP can use an idempotent hub materializer if no existing worker is available.

## Commit Plan

- **Commit 1** (`diaverseapi`, after tasks 1-3): `feat: add club pair mission persistence`
- **Commit 2** (`diaverseapi`, after tasks 4-5): `feat: expose club pair missions and feed`
- **Commit 3** (`diaweb`, after tasks 6-7): `feat: wire club buddy pair feed`

## Tasks

### Phase 1: Backend Persistence And Contracts

- [x] Task 1: `diaverseapi` - add pair mission and pair feed schema/model contracts.

  Deliverable:
  - Add backend read schemas in `diaverseapi/app/club/schemas.py`:
    - `ClubPairMissionRead`
    - `ClubPairFeedItemRead`
    - `ClubPairMissionClaimRequest`
    - `ClubPairMissionClaimResponse`
  - Extend `ClubHubRead` with `pair_missions: list[ClubPairMissionRead]` and `pair_feed: list[ClubPairFeedItemRead]`.
  - Add SQLModel tables in `diaverseapi/app/club/models.py`:
    - `ClubPairMissionClaim`
    - `ClubPairFeedEvent`
  - Add enum values/classes in `diaverseapi/app/club/enums.py` if needed for mission claim status and feed event type.
  - Keep payload names snake_case in backend and plan camelCase normalization in `diaweb`.

  LOGGING REQUIREMENTS:
  - DEBUG when serializing pair mission/feed payload sizes in hub service.
  - WARN if a feed event payload is malformed or references a missing pair member.
  - ERROR only for unexpected DB model/persistence failures.

  Dependencies: none.

- [x] Task 2: `diaverseapi` - create Alembic migration for pair mission claims and feed events.

  Deliverable:
  - Add a new revision under `diaverseapi/migrations/versions/`.
  - Create `club_pair_mission_claims` with short explicit constraint/index names:
    - unique idempotency key
    - unique `(group_id, membership_id, local_date, mission_key)`
    - indexes by `membership_id/local_date`, `group_id/local_date`, and fulfillment batch
  - Create `club_pair_feed_events` with short explicit constraint/index names:
    - unique idempotency key
    - indexes by `group_id/occurred_at`, `target_membership_id/occurred_at`, `local_date`
  - Update `diaverseapi/tests/test_alembic_graph.py` for the new revision and identifier guard expectations.

  LOGGING REQUIREMENTS:
  - No runtime logging in migration.
  - Add migration comments/docstrings explaining table ownership and idempotency keys.

  Dependencies: task 1.

- [x] Task 3: `diaverseapi` - add repository helpers for pair claims, feed events, and pair-day facts.

  Deliverable:
  - Extend `diaverseapi/app/club/repositories.py` with helpers to:
    - add/get pair mission claim by idempotency key
    - get pair mission claim by unique day key
    - list current user's pair mission claims for a day
    - add/list pair feed events by group and by current membership visibility
    - list buddy interactions for the current group/day, including both directions
  - Reuse existing `ClubBuddyInteraction` data for boost/motivation mission eligibility instead of duplicating interaction state.
  - Keep repository methods small and composable for service-level orchestration.

  LOGGING REQUIREMENTS:
  - DEBUG for query result counts and date/group scopes.
  - WARN when expected pair context is absent for a repository-driven operation.
  - Do not log user secrets, raw notification details, or full JSON payloads.

  Dependencies: tasks 1-2.

### Phase 2: Backend Mission Engine And Feed

- [x] Task 4: `diaverseapi` - implement pair mission definitions, eligibility, progress, and claim endpoint.

  Deliverable:
  - Add pair mission definitions in `diaverseapi/app/club/service.py` using the existing daily mission style.
  - MVP mission set:
    - `both_10k`: both pair members reached 10,000 steps today, reward 150 XDV per claimant.
    - `pair_20000`: pair combined steps reached 20,000 today, reward 120 XDV per claimant.
    - `motivation_after_goal`: claimant sent motivation after 10,000 steps, reward 75 XDV.
    - `boost_after_goal`: claimant sent boost after 10,000 steps, reward 100 XDV.
    - `pair_3_day_streak`: both members reached 10,000 steps for 3 consecutive days, reward 250 XDV per claimant.
  - Always include `both_10k`; rotate or include 2-3 additional pair missions based on `program.code + local_date`.
  - Add service method `claim_pair_mission_for_user` with idempotent fulfillment through the existing fulfillment service.
  - Add API route in `diaverseapi/app/club/cabinet_api.py`: `POST /v1/cabinet/club/pair-missions/{mission_key}/claim`.

  LOGGING REQUIREMENTS:
  - INFO on successful pair mission claim with membership id, group id, mission key, reward, and fulfillment batch id.
  - DEBUG for computed eligibility, progress current/goal, selected rotating missions, and idempotency replay.
  - WARN for blocked claims with reason codes such as `no_active_buddy`, `mission_incomplete`, `already_claimed`, `sender_below_goal`, `target_not_linked`.
  - ERROR for unexpected fulfillment or persistence failures with non-secret context.

  Dependencies: tasks 1-3.

- [x] Task 5: `diaverseapi` - implement pair feed materialization and hub integration.

  Deliverable:
  - Add a feed writer/materializer in `diaverseapi/app/club/service.py` or a focused helper module under `diaverseapi/app/club/`.
  - Persist idempotent feed events for:
    - `buddy_assigned`
    - `member_goal_completed`
    - `pair_goal_completed`
    - `boost_sent`
    - `boost_received`
    - `motivation_sent`
    - `motivation_received`
    - `pair_mission_completed`
    - `pair_mission_claimed`
    - `pair_streak_extended`
    - `pair_rank_top_entry` only for top-10/top-3 changes if rank data is reliable enough
  - Integrate feed event creation into explicit write flows first: boost, motivation, pair mission claim.
  - For step/pair milestones, either:
    - materialize idempotently during hub build with deterministic keys, or
    - derive read-only feed items from current state if side effects during GET are rejected during implementation.
  - Extend `get_hub_for_user` to return `pair_missions` and latest `pair_feed` items.

  LOGGING REQUIREMENTS:
  - INFO when new feed events are inserted, grouped by event type and idempotency key.
  - DEBUG when feed events are skipped because they already exist.
  - WARN when a feed event cannot be created due to missing group/member/user linkage.
  - ERROR for unexpected feed persistence failures.

  Dependencies: task 4.

### Phase 3: Diaweb BFF And UI Wiring

- [x] Task 6: `diaweb` - add frontend API types, normalizers, and BFF route for pair mission claims.

  Deliverable:
  - Extend `diaweb/frontend/modules/club-onboarding/types.ts` with:
    - `ClubPairMission`
    - `ClubPairFeedItem`
    - `ClubPairMissionClaimResponse`
    - `pairMissions` and `pairFeed` on `ClubHubState`
  - Extend `diaweb/frontend/modules/club-onboarding/api.ts` with payload normalizers for `pair_missions` and `pair_feed`.
  - Add `claimClubPairMission`.
  - Add BFF route `diaweb/frontend/app/api/cabinet/club/pair-missions/[missionKey]/claim/route.ts` that proxies to the new backend endpoint using existing club BFF patterns.
  - Keep backwards-compatible fallbacks when backend fields are absent.

  LOGGING REQUIREMENTS:
  - DEBUG behind existing club debug controls for normalized pair mission/feed counts.
  - WARN only for failed BFF claim responses or malformed payloads.
  - Do not log raw auth/session headers.

  Dependencies: task 5.

- [x] Task 7: `diaweb` - wire real pair missions and pair feed into the Buddy mobile screen without redesigning layout.

  Deliverable:
  - Update `diaweb/frontend/modules/club-onboarding/components/ClubBuddyMobile.tsx`.
  - Replace hardcoded joint mission rows with `hubState.pairMissions`.
  - Replace hardcoded feed rows with `hubState.pairFeed`.
  - Preserve the supplied visual layout and existing assets/classes.
  - Add click handling for claimable pair missions with the same smooth claimed/check animation pattern as daily missions.
  - Keep sensible fallback rows only for local dev/no-backend states.

  LOGGING REQUIREMENTS:
  - DEBUG for user interactions: pair mission click, blocked claim, successful claim, feed item click if interactive.
  - WARN for failed claim requests with reason code and mission key.
  - No noisy render logs in production unless existing debug flag is enabled.

  Dependencies: task 6.

### Phase 4: Verification

- [x] Task 8: verify backend, frontend, migration safety, and regression coverage.

  Deliverable:
  - Add/extend backend tests in `diaverseapi/tests/` for:
    - pair mission eligibility and rotation
    - pair claim idempotency
    - reward fulfillment idempotency
    - feed event deduplication
    - hub payload includes pair missions/feed for active completed onboarding
    - no access/onboarding required/no buddy blocked states
  - Add/extend frontend tests in `diaweb/frontend/__tests__/modules/club-onboarding/` for:
    - hub normalization with pair fields
    - Buddy screen renders backend pair missions/feed
    - pair mission claim calls the BFF and updates UI state
  - Run targeted verification commands listed below.

  LOGGING REQUIREMENTS:
  - Tests should assert important reason codes where practical.
  - Do not snapshot volatile timestamps without normalization.

  Dependencies: tasks 1-7.

## Verification Plan

- `diaverseapi`: run targeted pytest for club service/API coverage and alembic graph tests.
- `diaverseapi`: run Alembic SQL DDL compilation for the new revision, shaped like `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`, to catch PostgreSQL identifier length issues.
- `diaverseapi`: run any existing formatting/lint/type commands used by the repo if available and reasonably scoped.
- `diaweb/frontend`: run targeted Vitest files for `ClubBuddyMobile`, `ClubHubMobile`, `ClubOnboardingClient`, and API normalizers if covered.
- `diaweb/frontend`: run `npm run typecheck`.
- `diaweb/frontend`: run targeted eslint for changed club onboarding files if the repo supports it.
- Knowledge: after implementation is complete and code/docs materially change, run targeted GBrain sync if the local GBrain lock/search issue is resolved.
