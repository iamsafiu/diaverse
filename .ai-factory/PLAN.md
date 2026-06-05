# Raid Location Immunity Items

Created: 2026-06-05
Mode: fast
Scope: `diaverseapi`, `diaweb`

## Goal

Reintroduce old raid immunity mechanics as first-class consumable items:

- 3 raid locations: `rusty_wastelands`, `oasis`, `radioactive_cave` (displayed to users as Wastelands/Oasis/Cave)
- 3 durations per location: 1, 7, 30 days
- Activation happens from raid mode selection without a checkbox
- Activation extends an active timer instead of replacing it
- Active immunity protects both at raid start and during failed rescue trapping
- Active immunity is visible in mode selection and the raid main HUD
- HUD shows a location-specific icon/animation, and click opens a modal with location and `valid until`

## Current Understanding

- Old bot dump on Desktop (`raids-tg-bot*`) likely contains historical item/effect semantics, but current implementation should be based on the new Diaverse raid domain and only use old data to validate behavior.
- Current backend raid domain is in `diaverseapi/app/raids`.
- Current frontend raid UI is in `diaweb/frontend/modules/raids`.
- Current cabinet item catalog / Advent rewards can already represent catalog items, but old Advent `boost/custom` rewards are mostly log-only and need a real raid-immunity fulfillment path.
- Existing pet immunity only protects rescue trapping (`pet_has_trap_immunity`) and does not cover raid-start trap checks. New item immunity must cover both surfaces.

## Repo Matrix

| Repo | Role | Status |
| --- | --- | --- |
| `diaverseapi` | backend domain, DB, API, fulfillment | clean at planning time |
| `diaweb` | BFF, raid UI, i18n | clean at implementation start; re-check before edits because another agent is active |
| root `diaverse` | coordination plan only | plan/daily files only |

## Senior Design Decisions

1. Use explicit raid-immunity domain tables, not generic vouchers.
   - One grant/charge table for available consumable items.
   - One effect table for the active per-profile/per-location timer.
   - Activation consumes exactly one grant and extends the effect timer from `max(now, active_until) + duration`.

2. Add a first-class cabinet item type for raid immunity.
   - Avoid hiding the behavior behind generic `custom` or old `boost` values.
   - Keep old 30-day Advent item ids/aliases compatible so existing catalog references can resolve.

3. Use the existing raid command/idempotency pattern.
   - Activation is a raid command, not an ad-hoc POST side effect.
   - Replay by `idempotency_key` must return the same `RaidCommandResponse`.

4. Snapshot immunity effects when they affect gameplay.
   - Raid start should record that a participant was protected by item immunity.
   - Rescue protection should record whether protection came from pet or raid item.
   - Trap-check jobs must honor stored snapshots instead of recalculating a different trap chance later.

5. UI is informational and action-based.
   - No checkbox.
   - Mode selection shows available immunity items and active `valid until`.
   - The user explicitly clicks a duration item (`1/7/30 days`) to extend immunity before starting/rescuing.

## Tasks

## Task Checklist

- [x] Task 1: Backend domain, persistence, and migration
- [x] Task 2: Cabinet item catalog and fulfillment
- [x] Task 3: Backfill previously claimed log-only rewards
- [x] Task 4: Raid state and activation command
- [x] Task 5: Protect raid start
- [x] Task 6: Protect failed rescue and trap checks
- [x] Task 7: Frontend BFF, API client, and mutations
- [x] Task 8: Frontend mode-selection and HUD UI
- [x] Task 9: Backend tests
- [x] Task 10: Frontend tests and verification

### 1. Backend domain, persistence, and migration

- Add raid immunity definitions under `diaverseapi/app/raids/domain/`.
  - `RaidImmunityLocation`: `rusty_wastelands`, `oasis`, `radioactive_cave`.
  - Duration presets: 1, 7, 30 days.
  - Stable item keys, for example `raid_immunity_rusty_wastelands_1d`.
- Add SQLAlchemy models in `diaverseapi/app/raids/models.py`.
  - `RaidImmunityGrant`: available/consumed item charges with `profile_id`, `user_id`, `item_key`, `location_key`, `duration_days`, `status`, `source_domain`, `source_ref`, `source_line_id`, `activated_effect_id`, `activated_at`, `metadata_json` mapped to DB column `"metadata"`.
  - `RaidImmunityEffect`: one active timer per `profile_id + location_key` with `active_until`, `last_activated_at`, `metadata_json` mapped to DB column `"metadata"`.
- Add repository methods in `diaverseapi/app/raids/infrastructure/repositories.py`.
  - list available grants by profile/location
  - get active effects by profile
  - consume grant with row-level locking
  - extend or create active effect atomically
- Add Alembic migration.
  - Use current head `exchange_instance_id_20260604` as `down_revision`.
  - Use short explicit constraint/index names to avoid PostgreSQL 63-byte truncation.
  - Include SQL compilation / migration graph checks.

### 2. Cabinet item catalog and fulfillment

- Add first-class `raid_immunity` item support in cabinet catalog:
  - `diaverseapi/app/cabinet/item_catalog/types.py`
  - `diaverseapi/app/cabinet/item_catalog/aliases.py`
  - `diaverseapi/app/cabinet/item_catalog/providers.py`
  - `diaverseapi/app/cabinet/fulfillment/registry.py`
  - `diaverseapi/app/cabinet/fulfillment/handlers.py`
  - `diaverseapi/app/cabinet/admin/service.py`
- Register 9 virtual catalog items for all location/duration combinations.
- Keep compatibility aliases for the existing Lost Calendar / Advent 30-day immunity ids.
- Update Advent reward granting in `diaverseapi/app/cabinet/offers/advent/reward_grants.py` so immunity rewards create real raid immunity grants instead of only appending `UsersRewardsInfo`.
- Make source ids deterministic so repeated fulfillment cannot duplicate grants.

### 3. Backfill previously claimed log-only rewards

- Add an explicit, idempotent backfill path for old claimed immunity rewards that were previously logged but not granted.
- Source from existing reward logs such as `UsersRewardsInfo`, not from assumptions.
- Use `source_domain/source_ref/source_line_id` uniqueness to prevent duplicate grants.
- Keep this as a migration-safe service/script path, not a one-off manual SQL snippet.

### 4. Raid state and activation command

- Extend raid schemas in `diaverseapi/app/raids/schemas.py`.
  - Add active immunity effects per location.
  - Add available immunity grants grouped by location/duration.
  - Add `activate_immunity` to `RaidActionCode`.
  - Add specific immunity error codes.
- Add `RaidImmunityService.activate_immunity`.
  - Uses existing `RaidIdempotencyRecord` flow.
  - Validates profile, grant ownership, location match, and grant availability.
  - Consumes one grant and extends `active_until`.
  - Returns full updated raid state.
- Wire a backend route for activation beside existing raid command routes.
- Update `RaidStateService.build_state`.
  - Include immunity inventory/effects.
  - Add active immunity expiry timestamps into `_next_refresh_at` so HUD/mode UI refreshes when a timer expires.

### 5. Protect raid start

- Update raid creation flow in `diaverseapi/app/raids/services/command_service.py`.
- When a selected location has active item immunity:
  - effective trap chance for new participants is `0`
  - scheduled `trap_check_at` is skipped
  - metadata records `immunity_source = raid_item`, location, and `active_until`
- Preserve existing pet logic and price/snapshot behavior.
- Ensure trap chance shown to the frontend matches the effective gameplay result.

### 6. Protect failed rescue and trap checks

- Update `diaverseapi/app/raids/services/trap_service.py`.
  - Failed rescue trapping checks both pet immunity and active raid item immunity.
  - Rescue metadata records whether protection came from pet or item.
  - Existing `rescuer_protected_by_immunity` remains useful but should not lose source detail.
- Update `diaverseapi/app/raids/services/trap_check_service.py`.
  - Honor participant snapshots/metadata instead of recalculating a fresh trap chance.
  - Keep scheduled checks from trapping users who were protected at start.

### 7. Frontend BFF, API client, and mutations

- Add route handler under `diaweb/frontend/app/api/cabinet/raids/...` for activation.
  - Mirror existing start/rescue command proxy behavior.
  - Forward idempotency key and backend errors.
- Extend frontend raid types in `diaweb/frontend/modules/raids/types.ts`.
  - `RaidActionCode.activate_immunity`
  - immunity inventory/effect DTOs
  - matching error codes
- Extend `diaweb/frontend/modules/raids/api.ts`.
  - `RaidActivateImmunityInput`
  - `activateRaidImmunity`
- Extend `diaweb/frontend/modules/raids/useRaidMutations.ts`.
  - Reuse generic command mutation behavior so returned state replaces the current raid state.
  - Track pending activation per item/location.

### 8. Frontend mode-selection and HUD UI

- Thread immunity state/actions through:
  - `RaidShell`
  - `RaidHud`
  - `RaidLocationStack`
  - `RaidSlotsSheet`
  - `RaidDispatchStep`
- Mode selection:
  - show active immunity as `Действует до: ...`
  - show available 1/7/30-day items for the selected location
  - use action buttons/cards, no checkbox
  - after activation, display the extended timer
  - show effective trap chance as `0%` while immunity is active
- Raid HUD:
  - show one icon per active location immunity
  - reserve placeholders for user-provided icons/animations
  - click opens modal with `Иммунитет в ...` and `Действует до: ...`
- Add i18n keys in:
  - `diaweb/frontend/modules/i18n/types.ts`
  - `diaweb/frontend/modules/i18n/dictionaries/ru.json`
  - `diaweb/frontend/modules/i18n/dictionaries/en.json`

### 9. Backend tests

- Add/extend tests for:
  - catalog item resolution for all 9 immunity items
  - fulfillment handler creates real grants
  - Advent reward grants no longer remain log-only
  - backfill is idempotent
  - activation consumes one grant and extends timer from `max(now, active_until)`
  - activation idempotency replay
  - start raid immunity sets effective trap chance to zero
  - failed rescue immunity protects rescuer
  - trap-check worker honors snapshots
  - state includes inventory/effects and `next_refresh_at`
- Likely test files:
  - `diaverseapi/tests/test_cabinet_item_catalog.py`
  - `diaverseapi/tests/test_cabinet_fulfillment_service.py`
  - `diaverseapi/tests/test_cabinet_advent_reward_grants.py`
  - `diaverseapi/app/raids/tests/test_command_start.py`
  - `diaverseapi/app/raids/tests/test_trap_service.py`
  - `diaverseapi/app/raids/tests/test_trap_check_service.py`
  - `diaverseapi/app/raids/tests/test_state_service.py`
  - `diaverseapi/app/raids/tests/test_repositories.py`
  - `diaverseapi/tests/test_alembic_graph.py`

### 10. Frontend tests and verification

- Add/extend tests for:
  - BFF activation route forwards payload/errors
  - API client activation method
  - mutation updates raid state
  - mode selection displays active/available immunity without a checkbox
  - HUD displays active immunity icon and modal
  - i18n type coverage
- Likely test files:
  - `diaweb/frontend/__tests__/app/api/cabinet/raids/route.test.ts`
  - `diaweb/frontend/__tests__/modules/raids/raids-api.test.ts`
  - `diaweb/frontend/__tests__/modules/raids/RaidShell.test.tsx`
  - `diaweb/frontend/__tests__/modules/raids/RaidLocationStack.test.tsx`
  - `diaweb/frontend/__tests__/modules/raids/RaidFlows.test.tsx`
  - `diaweb/frontend/__tests__/app/cabinet-raids-page.test.tsx`
- Run targeted checks:
  - backend: focused pytest for cabinet + raids + Alembic graph
  - frontend: focused Jest/Vitest tests for raids and BFF route
  - frontend: lint/typecheck for touched modules

## Open Questions

1. Exact public item ids/names for the 9 immunity items can be decided during implementation; stable internal keys should be ASCII and location-specific.
2. User-provided icons/animations are not ready yet. Implementation should expose stable asset slots/classes and work with placeholders.
3. Backfill policy needs product confirmation if historical logs contain ambiguous old immunity rewards. The safe default is idempotent backfill only for unambiguous known ids.

## Risks

- If old Advent rewards were already claimed before real fulfillment existed, users may expect already-earned immunity items. Backfill is required to avoid silent loss.
- Race conditions are possible if activation and raid start happen concurrently. Activation and effect reads must be transactionally consistent.
- Existing scheduled trap checks may still use recalculated chance. Snapshot enforcement is mandatory for correctness.
- UI state can become stale after immunity expiry unless `next_refresh_at` includes effect expiration.
- Compatibility with old `boost/custom` catalog entries must be preserved while adding first-class `raid_immunity`.

## Suggested Implementation Order

1. Backend domain + migration.
2. Catalog/fulfillment + backfill.
3. Activation command + state contract.
4. Gameplay enforcement.
5. Frontend BFF/types/mutations.
6. Frontend UI.
7. Targeted tests and verification.

## Suggested Commit Split

1. `feat(api): add raid immunity persistence and fulfillment`
2. `feat(api): apply raid immunity in commands and traps`
3. `feat(web): add raid immunity activation contract`
4. `feat(web): show raid immunity controls and hud`
