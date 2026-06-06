# Implementation Plan: Raid Vouchers for Premium Raids

Branch: none
Created: 2026-06-06
Mode: fast

## Settings

- Testing: yes
- Logging: verbose
- Docs: warn-only

## Scope

Implement location-specific raid vouchers that unlock the existing USDT raid mechanics without creating new payment orders.

In scope:

- Backend raid-owned voucher entity and grant inventory.
- One voucher consumed for one dispatched pet.
- Voucher-gated `start_raid` for `mode_key=usdt`.
- Raid state inventory counts for the selected location.
- Raid lifecycle/merge support for voucher grants as raid-owned profile children.
- Frontend display label change from `USDT` to a user-facing premium/voucher mode label.
- Frontend voucher count, insufficient-voucher state, and buy-voucher CTA copy/link target.
- Frontend handling for raid command `status=blocked` returned via HTTP 200.
- Targeted backend and frontend tests.

Out of scope:

- Shop sale items, shop category implementation, checkout, or pricing.
- Sellable shop catalog rows for raid vouchers.
- Legacy CSV compensation, backfill, or migration of old voucher balances.
- Voucher icon asset upload. Use stable icon keys/placeholders and wire uploaded icons in a later task.
- Renaming the technical backend `mode_key=usdt`; keep it for catalog/reward compatibility.
- Removing legacy paid raid finalizer behavior for already-created payment orders.

## Repo Matrix

| Repo | Role | Planned changes |
| --- | --- | --- |
| `diaverseapi` | Raid domain, persistence, API state, start command | New voucher grants, inventory state, voucher consumption on premium raids |
| `diaweb` | Raid UI, BFF/client types, i18n | Premium label, voucher counts, insufficient state, CTA |
| root `diaverse` | Coordination | This plan and daily log only |

## Research Context

Sources checked:

- Local GBrain raid docs: raid mechanics, gameplay guide, legacy compensation notes, economy audit.
- Backend source: `diaverseapi/app/raids`, raid catalog YAML, command/payment/state services, immunity implementation.
- Frontend source: `diaweb/frontend/modules/raids`, raid i18n dictionaries, shop route data.
- Desktop CSV `Vouchers and immunities` was inspected only as historical reference; compensation is not part of this plan.

Relevant current behavior:

- The existing `usdt` mode is the premium raid mechanics bucket: 24h duration, no traps, no slot limit, boosted rewards.
- Current `start_raid` for `mode.entry_currency == "usdt"` creates a `RaidPaymentOrder` and returns `payment_required`.
- Immunities already have a modern raid-owned grant/effect design that can be used as the local pattern.
- Existing legacy `RaidVoucher` / `UserRaidVoucher` model names are not suitable for this implementation.

## Design Decisions

1. Create a new raid-owned grant entity, not a generic voucher table.
   - Proposed model: `RaidVoucherGrant`.
   - Proposed table: `raid_voucher_grants`.
   - Location-specific grants: `rusty_wastelands`, `oasis`, `radioactive_cave`.

2. Keep technical mode `usdt`, change only user-facing raid mode copy.
   - Recommended Russian label: `Премиум`.
   - Recommended English label: `Premium`.
   - Keep `RaidBalance.key = "usdt"` and `usdtLabel` for the real USDT wallet/balance.
   - UI can mention that premium raids require vouchers.

3. Consumption is one grant per participant.
   - A request with 3 selected pets must lock and consume 3 available grants for that location.
   - Each consumed grant should store both `consumed_run_id` and `consumed_participant_id`.
   - Also store `consumed_user_character_id` for audit clarity.
   - This makes the per-pet mapping explicit while still allowing run-level reporting.

4. No partial consumption.
   - If fewer than N grants are available, return blocked `insufficient_raid_voucher`.
   - Do not create a run.
   - Do not consume any grants.

5. Use the existing raid idempotency and locking pattern.
   - Lock profile/idempotency first.
   - Select grants with row locks inside the same transaction.
   - Create run and participants.
   - Pair participant rows with selected grants deterministically.
   - Mark grants consumed in the same transaction.

6. Keep paid raid finalization backward-compatible.
   - New starts must not create direct USDT payment orders.
   - The old payment finalizer can keep creating runs for already-created payment orders.
   - If run creation helpers are refactored to expose participants, update the payment finalizer call site at the same time.

7. Treat command `status` as the business result on the frontend.
   - HTTP 200 with `status=blocked` is still a failed business command.
   - Premium voucher failures must remain visible and must not clear the selected pet or close the actionable flow.

## Commit Plan

- **Commit 1** (after tasks 1-3): `feat: add raid voucher grants`
- **Commit 2** (after tasks 4-8): `feat: gate premium raids with vouchers`
- **Commit 3** (after tasks 9-12): `feat: show raid vouchers in premium mode`

## Tasks

### Phase 1: Backend Voucher Foundation

- [x] Task 1: Add raid voucher domain definitions and API schemas.
  - Files: `diaverseapi/app/raids/domain/vouchers.py`, `diaverseapi/app/raids/schemas.py`.
  - Define stable item keys, location mapping, display metadata, `icon_key`, and `required_per_pet = 1`.
  - Add `RaidErrorCode.insufficient_raid_voucher`.
  - Add response schemas for voucher grants/inventory counts: `RaidVoucherGrantRead`, `RaidVoucherInventoryRead`.
  - Keep actual icon files out of scope; expose stable keys/metadata that can map to uploaded icons later.
  - Logging requirements: keep domain definitions pure; log only schema validation failures at existing API/service boundaries, DEBUG for resolved voucher definition during service calls, ERROR for impossible definition/location mismatches.

- [x] Task 2: Add `RaidVoucherGrant` model, Alembic migration, and model registration.
  - Files: `diaverseapi/app/raids/models.py`, `diaverseapi/migrations/env.py`, `diaverseapi/migrations/versions/<new>_raid_voucher_grants.py`, `diaverseapi/app/raids/tests/test_models.py`.
  - Add `RaidVoucherGrantStatus` with `available`, `consumed`, `expired`.
  - Fields: `profile_id`, `user_id`, `item_key`, `location_key`, `status`, source tuple, consumed run/participant/user-character refs, consumed timestamp, metadata, timestamps.
  - Add FKs:
    - `profile_id -> raid_profiles.uuid` with `CASCADE`.
    - `user_id -> users.uuid` with `SET NULL`.
    - `source_line_id -> cab_fulfillment_lines.uuid` with `SET NULL`.
    - `consumed_run_id -> raid_runs.uuid` with `SET NULL`.
    - `consumed_participant_id -> raid_participants.uuid` with `SET NULL`.
  - Add indexes for available grants by profile/location/status and unique idempotent source unit keys.
  - Register the new model in `migrations/env.py` so Alembic metadata includes it.
  - Update raid model contract tests for expected tables, user FKs, and profile cascade tables.
  - Do not use legacy `RaidVoucher` or `UserRaidVoucher`.
  - Logging requirements: no runtime logs in migration; verification must capture Alembic SQL output and migration errors. Application code using this model must avoid logging user ids unless already standard in raid logs.

- [x] Task 3: Add voucher repository methods and grant service.
  - Files: `diaverseapi/app/raids/infrastructure/repositories.py`, new `diaverseapi/app/raids/services/voucher_grant_service.py`.
  - Methods: create/reuse grants by source unit, count available by location, list inventory grants, lock N available grants for consumption, mark grants consumed with run/participant/user-character refs.
  - Lock selection must be deterministic: oldest available grants first by `created_at`, then `uuid`.
  - Mirror immunity grant idempotency semantics for future support/shop grants.
  - Logging requirements: DEBUG for grant lookup/reuse and available-count queries, INFO for successful grant batches and consumption batches, WARN for unsupported item/location or insufficient count, ERROR with context for DB failures. Keep source refs sanitized.

### Phase 2: Backend Raid Flow Integration

- [x] Task 4: Add voucher inventory to raid state responses.
  - Files: `diaverseapi/app/raids/services/state_service.py`, `diaverseapi/app/raids/schemas.py`, related route/state tests.
  - Return grouped inventory per location with `available_count`, `required_per_pet`, `item_key`, title/icon metadata.
  - Preserve existing immunity inventory response.
  - Optionally mirror the selected location's available voucher count into location metadata if the current frontend flow benefits from location-local lookup.
  - Logging requirements: DEBUG for computed voucher inventory counts, WARN if catalog location lacks a voucher definition, ERROR for repository failures.

- [x] Task 5: Gate `start_raid` for `mode_key=usdt` by voucher grants.
  - Files: `diaverseapi/app/raids/services/command_service.py`, `diaverseapi/app/raids/services/payment_service.py` if run helper signatures change.
  - Replace new direct-payment start behavior with voucher validation/consumption.
  - Required flow: lock profile/idempotency, validate location/mode/pets, count selected pets, lock N available grants for request location, block if insufficient, create normal run, create participants, consume one grant per participant.
  - Refactor run creation safely:
    - Either introduce `RaidRunCreationResult(run, participants)` for internal voucher flow.
    - Or add a second helper that exposes participants while keeping `_create_run` returning `RaidRun`.
    - Preserve old paid-finalizer behavior for already-created payment orders.
  - Return blocked code `insufficient_raid_voucher` with context `{location_key, required, available, required_per_pet}`.
  - Keep run `mode_key = "usdt"` so reward calculations continue to use current catalog behavior.
  - No voucher consumption may happen if run/participant creation fails.
  - Logging requirements: INFO for premium raid voucher start and consumption success, WARN for insufficient vouchers with required/available/location, DEBUG for selected grants and participant pairing counts, ERROR for transaction failures.

- [x] Task 6: Update raid lifecycle and account merge support.
  - Files: `diaverseapi/app/security/usecases.py`, `diaverseapi/app/raids/tests/test_account_lifecycle.py`, `diaverseapi/tests/test_merge_account_coverage.py`.
  - Include `raid_voucher_grants` in raid-owned child row counts.
  - Transfer `RaidVoucherGrant.user_id` when `_merge_raid_state` transfers a loser raid profile to the winner.
  - While touching the same raid child lists, verify existing `RaidImmunityEffect` and `RaidImmunityGrant` are not omitted from merge/lifecycle coverage.
  - Vouchers should not block merge preflight unless a future pending-payment/table rule explicitly requires it.
  - Logging requirements: INFO for transferred raid voucher counts during merge, WARN for merge conflicts or unexpected missing profile links, ERROR only for actual transfer failures.

- [x] Task 7: Add non-sellable fulfillment/catalog support for future grants.
  - Files: `diaverseapi/app/cabinet/fulfillment/handlers.py`, `diaverseapi/app/cabinet/fulfillment/registry.py`, `diaverseapi/app/cabinet/item_catalog/types.py`, `aliases.py`, `providers.py`, `title_resolver.py` if required.
  - Add `raid_voucher` item type and fulfillment handler that calls the voucher grant service.
  - Add virtual support/reward catalog entries only if needed for staff/support grantability.
  - Mark raid voucher catalog entries as `is_grantable=True`, `is_rewardable=True`, `is_sellable=False`.
  - Do not add shop catalog rows, prices, category visibility, offer seeds, checkout flow, or storefront sale behavior.
  - Logging requirements: DEBUG for fulfillment payload parsing, INFO for successful voucher grants, WARN for invalid quantity/location/item key, ERROR for grant service failures.

- [x] Task 8: Add and update backend tests.
  - Files:
    - New `diaverseapi/tests/test_raid_voucher_items.py` for domain/catalog/fulfillment/grant service tests.
    - `diaverseapi/app/raids/tests/test_command_start.py` for start command behavior.
    - `diaverseapi/app/raids/tests/test_raids_flow.py` for end-to-end command flow expectations.
    - `diaverseapi/app/raids/tests/test_state_service.py` for state inventory.
    - `diaverseapi/app/raids/tests/test_models.py` for SQLModel metadata/FK contracts.
    - `diaverseapi/app/raids/tests/test_account_lifecycle.py` and `diaverseapi/tests/test_merge_account_coverage.py` for transfer coverage.
  - Cover: grant idempotency, inventory counts, insufficient block, exact N vouchers for N pets, no partial consumption, consumed run/participant/user-character refs, idempotency replay without double consumption, no new payment order for voucher starts, and backward-compatible paid payment finalizer tests for existing orders.
  - Replace existing USDT start expectations that assert `payment_required` for new starts with voucher-start expectations.
  - Verification commands:
    - `cd diaverseapi; poetry run pytest tests/test_raid_voucher_items.py -q`
    - `cd diaverseapi; poetry run pytest tests/test_raid_immunity_items.py tests/test_raid_voucher_items.py -q`
    - `cd diaverseapi; poetry run pytest app/raids/tests/test_command_start.py app/raids/tests/test_raids_flow.py app/raids/tests/test_state_service.py app/raids/tests/test_models.py app/raids/tests/test_account_lifecycle.py tests/test_merge_account_coverage.py -q`
    - `cd diaverseapi; poetry run alembic upgrade <down_revision>:<new_revision> --sql`
  - Logging requirements: assert important WARN/INFO paths where existing test logging helpers support it; avoid brittle checks on DEBUG-only lines.

### Phase 3: Frontend Premium Voucher UI

- [x] Task 9: Extend frontend raid types, command parsing, and i18n strings.
  - Files: `diaweb/frontend/modules/raids/types.ts`, `diaweb/frontend/modules/raids/api.ts` if needed, `diaweb/frontend/modules/i18n/types.ts`, `diaweb/frontend/modules/i18n/dictionaries/ru.json`, `diaweb/frontend/modules/i18n/dictionaries/en.json`, raid test fixtures.
  - Add voucher inventory response types and `insufficient_raid_voucher` command error mapping.
  - Rename visible raid mode label from `USDT` to `Премиум` / `Premium`.
  - Do not rename wallet/balance `usdtLabel`.
  - Add copy for available vouchers, required vouchers, insufficient vouchers, one-voucher-per-pet wording, and buy-voucher CTA.
  - Logging requirements: no render-loop logs; DEBUG only for command response parsing or unexpected missing inventory, WARN for unknown server error codes.

- [x] Task 10: Update premium dispatch UI and premium entry behavior.
  - Files: `diaweb/frontend/modules/raids/components/RaidLocationStack.tsx`, `RaidSlotGrid.tsx`, `RaidDispatchStep.tsx`, `RaidConfirmDialog.tsx`, `RaidPetCard.tsx`, `RaidLocationBriefing.tsx`, `mechanicsDisplay.ts`, `featureFlags.ts`.
  - In premium mode, show location-specific available voucher count.
  - Required voucher count equals selected pet count; for current single-pet UI this is `1`, but keep the helper compatible with batch starts.
  - Premium mode should be selectable so users can see the voucher requirement and CTA; disable send/start when available vouchers are less than required.
  - Do not depend on XDV slot capacity to expose the premium entry. Premium/voucher mode is independent from XDV slots.
  - Replace USDT price labels in dispatch card, pet card, confirm dialog, and shared mechanics display with voucher requirement labels.
  - Show buy-voucher CTA pointing to the existing localized shop raids route, e.g. `/${lang}/shop/raids`, without implementing shop purchase behavior.
  - Enable premium mode only after backend gated behavior is wired.
  - Logging requirements: DEBUG for user action blocked by insufficient vouchers, INFO for premium start attempt, WARN for missing inventory in premium mode. Do not log selected pet names or sensitive user data.

- [x] Task 11: Handle raid command `status=blocked` as visible business feedback.
  - Files: `diaweb/frontend/modules/raids/components/RaidLocationStack.tsx`, related raid UI tests.
  - For `start_raid` responses with `status="blocked"`, keep the selected pet/sheet context intact and render a visible command notice from `result.errors`.
  - Add specific formatting for `insufficient_raid_voucher`: required, available, and buy-voucher CTA.
  - Keep success cleanup only for `status="completed"` or the relevant accepted success state.
  - Preserve existing transport-error handling via `onError`.
  - Logging requirements: INFO for blocked business result with code/status, WARN for unrecognized blocked response shape, DEBUG for notice rendering only in non-production.

- [x] Task 12: Add/update frontend tests and run type/lint checks.
  - Files: focused Vitest tests under `diaweb/frontend/__tests__/modules/raids` and existing raid app/BFF fixtures that hardcode USDT copy.
  - Cover: premium label, voucher count display, required count changes with selected pets, premium entry visible independently of XDV slot availability, disabled send on insufficient vouchers, CTA visibility, server `insufficient_raid_voucher` blocked response, selected pet not cleared after blocked response, and payment-required expectations removed from new premium start tests.
  - Verification commands:
    - `cd diaweb/frontend; npm run test -- --run __tests__/modules/raids`
    - `cd diaweb/frontend; npm run test -- --run __tests__/app/api/cabinet/raids`
    - `cd diaweb/frontend; npm run typecheck`
    - `cd diaweb/frontend; npm run lint`
  - Logging requirements: test any newly added client logging helpers at action boundaries only; avoid snapshots that depend on DEBUG text.

### Phase 4: Final Verification

- [x] Task 13: Cross-repo verification and cleanup.
  - Confirm `diaverseapi` and `diaweb` git statuses only contain planned changes.
  - Run targeted backend and frontend commands from tasks 8 and 12.
  - Manually verify the core flow: premium location with 0 vouchers blocks and keeps UI feedback visible, with N vouchers and N pets starts and consumes N grants, replay does not consume again, and old paid-order finalizer tests still pass.
  - Update docs only if the implementation changes public contracts beyond this plan.
  - Run targeted GBrain sync for changed docs/source after meaningful changes.
  - Logging requirements: review new logs for safe fields, correct levels, and no raw profile/user identifiers beyond established project conventions.

## Open Questions

- Exact voucher icon asset keys will be finalized after the three icons are uploaded.
- The buy-voucher CTA should point to the existing shop raids route for navigation, but shop content and purchase behavior remain a separate task.
- If support grants are not needed before shop implementation, Task 7 can be deferred; the core raid-gating flow does not depend on storefront sales.
