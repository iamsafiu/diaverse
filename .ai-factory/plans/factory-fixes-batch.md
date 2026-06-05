# Implementation Plan: Factory Fixes Batch

Created: 2026-06-02
Mode: archived fast plan
Branch: none
Original source: `.ai-factory/PLAN.md` before the active fast plan was replaced by the auth-bot broadcast plan.
Restored: 2026-06-02

## Progress Checklist

- [x] Task 1: Backend fractional transfer semantics
- [x] Task 2: Frontend warehouse fractional display
- [x] Task 3: Reset production compartments on demolition
- [x] Task 4: Verify slot-token charge for level 5 -> 6
- [x] Task 5: Make pet dismantle failures visible in the frontend
- [x] Task 6: Backend coverage for rare-pet dismantle
- [x] Task 7: Immediate upgrade success feedback
- [x] Task 8: Move main-building upgrade into warehouse UI
- [x] Task 9: Apply game/DCR price multiplier
- [x] Task 10: Rename payment labels and render icon+amount requirements
- [x] Task 11: Targeted automated verification
- [x] Task 12: Knowledge refresh after implementation

## Settings

- Planning scope: archived fast workspace plan, no branch creation.
- Affected repositories: `diaverseapi`, `diaweb`.
- Out of scope: `aibot`, `club10000-bot`, `diaverse-auth-bot`.
- Testing: required, because the changes affect economy, warehouse balances, craft commands, and upgrade UX.
- Logging: add focused factory-domain logs for state-changing backend fixes and visible client-side diagnostics for blocked UI actions; avoid noisy accrual/render logs.
- Documentation: no product docs required unless implementation changes public factory rules beyond the items below.
- Dev server: optional smoke verification on the user-provided development server only if local verification cannot cover behavior; do not persist raw SSH commands, IPs, or secret paths in docs or logs.

## Workspace Mode

- Mode: multi-repo fast archive
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first, raw source verification second

## Repository Matrix

| Repository | Path | Affected | Role |
| --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | backend factory economy, warehouse, building, compartment, catalog behavior |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | factory UI, feedback states, price labels, upgrade placement |
| root docs | `C:\Users\Indigo\Desktop\diaverse\docs` | daily/knowledge only | daily capture and optional GBrain sync |

## Context

The workspace is not a monorepo. Product changes must be made in child repositories only. Source lookup used GBrain first and then raw source verification.

Relevant source facts:

- Warehouse balances are already decimal in the backend (`pending_quantity`, `stored_quantity`), but frontend warehouse rendering had whole-only behavior.
- `dna_capsule` level 1 can produce less than one whole item during the 10-hour warehouse cap, so whole-only UI made it look impossible to collect.
- `transfer_to_storage` originally moved the full decimal pending amount and cleared pending to zero, losing the intended fractional carry-over behavior.
- Production building demolition reset the building but could leave existing production compartments with old levels.
- Backend upgrade commands return updated factory state, but several upgrade dialogs/screens can fail to visibly acknowledge success until the user reopens the UI.
- Game-dollar prices are currently equal to real-money prices in catalog/dynamic compartment pricing; the new rule is game/DCR price = real payment price * 25.
- Russian payment labels should use `Оплата` and `Игровые`, not the longer old labels.
- Pet dismantle has backend selection plumbing, but the UI could silently block or fail without a visible error, confirmation, or timer state.
- Slot-token charging for production compartment level 5 -> 6 was reported suspicious; source suggests the intended rule exists, so regression coverage is needed first.

## Product Rules To Implement

- Warehouse pending and stored quantities must display with hundredths where fractional production exists.
- Sending production to storage must move only the whole part and leave tenths/hundredths pending until they accumulate into a whole unit.
- If pending is fractional and below one whole unit, the user must still be able to press collect/send so the 10-hour stopped state can resume without losing the fractional amount.
- Inventory transfer from storage should follow the same whole-part rule for factory-produced resources unless an existing currency-specific contract explicitly requires fractional currency transfer.
- Upgrade success must be visible immediately without reloading or closing/reopening the application.
- Main building upgrade must be available inside the warehouse/main-building interface, not as an external main-screen control.
- Payment requirements must render as icon + amount chips/rows, not text labels that break layout.
- Game/DCR prices must be derived from real-money prices with a `* 25` multiplier.
- Pet dismantle failures and blocked material-selection states must be visible to the user.

## Verification So Far

- `diaverseapi`: `.venv\Scripts\python.exe -m pytest app\factory\tests\test_warehouse_service.py -q` -> 7 passed.
- `diaweb`: `npm run test -- __tests__/modules/factory/FactoryWarehouseLive.test.ts __tests__/modules/factory/FactoryWarehouseScreen.test.tsx` -> 2 files / 6 tests passed.
- `diaverseapi`: `.venv\Scripts\python.exe -m pytest app\factory\tests\test_building_service.py -q` -> 9 passed.
- `diaverseapi`: `.venv\Scripts\python.exe -m pytest app\factory\tests\test_compartment_service.py -q` -> 8 passed.
- `diaweb`: `npm run test -- __tests__/modules/factory/FactoryCompartmentScreen.test.tsx __tests__/modules/factory/FactoryInventoryDrawer.test.tsx` -> 2 files / 15 tests passed.
- `diaverseapi`: `.venv\Scripts\python.exe -m pytest app\factory\tests\test_crafting_service.py -q` -> 19 passed.
- `diaweb`: `npm run test -- __tests__/modules/factory/FactoryShell.test.tsx __tests__/modules/factory/FactoryWarehouseScreen.test.tsx __tests__/modules/factory/FactoryDialogs.test.tsx __tests__/modules/factory/FactoryProductionWorkshopScreen.test.tsx __tests__/modules/factory/FactoryCompartmentScreen.test.tsx` -> 5 files / 42 tests passed.
- `diaverseapi`: `.venv\Scripts\python.exe -m pytest app\factory\tests\test_catalog.py app\factory\tests\test_command_service.py app\factory\tests\test_compartment_service.py -q` -> 26 passed.
- `diaweb`: `npm run test -- __tests__/modules/factory/FactoryDialogs.test.tsx` -> 1 file / 12 tests passed.
- `diaverseapi`: `.venv\Scripts\python.exe -m pytest app\factory\tests -q` -> 126 passed.
- `diaverseapi`: `.venv\Scripts\python.exe -m ruff check app\factory` -> passed.
- `diaweb`: `npm run test -- __tests__/modules/factory` -> 12 files / 84 tests passed.
- `diaweb`: `npm run typecheck` -> failed in unrelated concurrent copywriting broadcast files (`CopywritingBroadcastsView.tsx` expects `dictionary.broadcasts`); factory type errors were fixed before this remaining failure.
- `diaverse`: `powershell -ExecutionPolicy Bypass -File scripts\gbrain-sync.ps1` -> completed.

## Tasks

### Phase 1: Warehouse Decimal Mechanics

- [x] Task 1: Backend fractional transfer semantics

  Deliverable: `transfer_to_storage` moves only `floor(pending_quantity)` to `stored_quantity`, keeps the fractional remainder in `pending_quantity`, and resumes accrual even when the moved whole amount is zero.

  Expected behavior:
  - Level 1 DNA with `0 < pending < 1` can be collected/sent without disappearing.
  - A pending balance of `3.42` moves `3` to storage and leaves `0.42` pending.
  - A pending balance of `0.42` moves `0`, leaves `0.42`, clears the stopped cap state, and updates accrual timing.
  - Ledger/event metadata should distinguish moved whole amount and retained fractional amount.

  Files:
  - `diaverseapi/app/factory/services/warehouse_service.py`
  - `diaverseapi/app/factory/tests/test_warehouse_service.py`
  - `diaverseapi/app/factory/domain/money.py` if shared decimal helpers need tightening

  Logging:
  - Add one structured backend log around explicit transfer attempts with `profile_id`, `resource_key`, `pending_before`, `moved_amount`, `retained_fraction`, and whether the cap was resumed.

- [x] Task 2: Frontend warehouse fractional display

  Deliverable: warehouse pending/stored values render fractional amounts with stable formatting and do not hide balances below one whole unit.

  Expected behavior:
  - Pending/stored balances like `0.13` are visible.
  - Collect/send affordances remain available for positive fractional pending balances.
  - Whole values remain readable without noisy decimals when no fractional component exists.

  Files:
  - `diaweb/frontend/modules/factory/warehouseLive.ts`
  - `diaweb/frontend/modules/factory/components/FactoryWarehouseScreen.tsx`
  - `diaweb/frontend/__tests__/modules/factory/FactoryWarehouseLive.test.ts`
  - `diaweb/frontend/__tests__/modules/factory/FactoryWarehouseScreen.test.tsx`

  Logging:
  - Use existing client diagnostics only for blocked or failed transfer actions; do not log every render tick.

### Phase 2: Building And Compartment State

- [x] Task 3: Reset production compartments on demolition

  Deliverable: demolition of the production part resets related `FactoryCompartment` rows so a rebuilt workshop cannot inherit the old production compartment level/state.

  Expected behavior:
  - Demolishing production for a workshop clears production lines, timers, early access, and compartment state.
  - Rebuilding starts from level 0/new state.
  - Resource-part demolition remains scoped to resource behavior.

  Files:
  - `diaverseapi/app/factory/services/building_service.py`
  - `diaverseapi/app/factory/tests/test_building_service.py`

  Logging:
  - Log production demolition with `profile_id`, `building_key`, `part`, and number of reset compartments.

- [x] Task 4: Verify slot-token charge for level 5 -> 6

  Deliverable: regression coverage confirms slot-token spending for compartment upgrades that cross the slot-token threshold.

  Expected behavior:
  - `brick_production` level 5 -> 6 spends the expected slot token.
  - Comparable rare-pet production levels also spend correctly.
  - If tests reveal a miss, fix the backend charge path before marking complete.

  Files:
  - `diaverseapi/app/factory/tests/test_compartment_service.py`
  - `diaverseapi/app/factory/services/compartment_service.py` only if the regression reproduces

  Logging:
  - No new logs required if only tests are added.

### Phase 3: Pet Dismantle UX And Backend Coverage

- [x] Task 5: Make pet dismantle failures visible in the frontend

  Deliverable: pet dismantle/craft UI surfaces visible notices/errors for blocked starts and rejected material selection.

  Expected behavior:
  - Selecting an invalid concrete material shows a clear user-visible error.
  - A blocked start craft action produces a visible notice instead of failing silently.
  - Existing valid material-selection and craft flows still work.

  Files:
  - `diaweb/frontend/modules/factory/components/CompartmentScreen.tsx`
  - `diaweb/frontend/modules/factory/components/FactoryInventoryDrawer.tsx`
  - `diaweb/frontend/__tests__/modules/factory/FactoryCompartmentScreen.test.tsx`
  - `diaweb/frontend/__tests__/modules/factory/FactoryInventoryDrawer.test.tsx`

  Logging:
  - Log client-side blocked action metadata at `WARN` through existing factory logging utilities if available; include action and reason, not full item payload dumps.

- [x] Task 6: Backend coverage for rare-pet dismantle

  Deliverable: backend tests prove rare-pet dismantle/craft inputs are validated, consumed, and rejected correctly.

  Expected behavior:
  - Valid rare-pet dismantle material can be selected and consumed.
  - Invalid material type or wrong rarity is rejected with stable error response.
  - Duplicate/idempotent command behavior is covered if the API supports idempotency keys.
  - Inventory state remains consistent after rejected commands.

  Files:
  - `diaverseapi/app/factory/tests/test_crafting_service.py`
  - `diaverseapi/app/factory/tests/test_compartment_service.py`
  - `diaverseapi/app/factory/tests/test_api.py` if API-level coverage is needed
  - `diaverseapi/app/factory/services/crafting_service.py` only if tests expose a craft flow bug
  - `diaverseapi/app/factory/infrastructure/inventory_gateway.py` only if entity selection or rollback behavior needs tightening

  Logging:
  - Add or verify backend `WARN` logs for rejected dismantle/craft material with `profile_id`, `compartment_key`, `reason`, and sanitized item identifiers.

### Phase 4: Upgrade UX And Price Semantics

- [x] Task 7: Immediate upgrade success feedback

  Deliverable: building/compartment upgrade success is visible immediately in the active UI without forcing reload or close/reopen.

  Expected behavior:
  - Successful upgrade updates the current dialog/screen state.
  - The UI displays a short success state or refreshed level/requirements immediately.
  - Failed upgrade actions still show actionable error text.
  - Mutation cache/state invalidation does not cause duplicate command submissions.

  Files:
  - `diaweb/frontend/modules/factory/hooks/useFactoryMutations.ts`
  - `diaweb/frontend/modules/factory/components/CompartmentScreen.tsx`
  - `diaweb/frontend/modules/factory/components/FactoryShell.tsx`
  - `diaweb/frontend/modules/factory/components/FactoryWarehouseScreen.tsx` if warehouse-hosted upgrade state is shared
  - affected factory UI tests under `diaweb/frontend/__tests__/modules/factory/`

  Logging:
  - Log `INFO` for successful upgrade mutation completion with action type and target key.
  - Log `WARN` for rejected upgrade attempts with sanitized reason.

- [x] Task 8: Move main-building upgrade into warehouse UI

  Deliverable: main-building upgrade is accessible inside the warehouse/main-building interface, not as an external main-screen-only control.

  Expected behavior:
  - Warehouse/main-building view shows current main level, requirements, price options, and upgrade action.
  - Existing upgrade API contract is reused; no duplicate backend command path is introduced.
  - Main map still reflects upgraded level after mutation.
  - Mobile layout remains dense and does not overflow.

  Files:
  - `diaweb/frontend/modules/factory/components/FactoryWarehouseScreen.tsx`
  - `diaweb/frontend/modules/factory/components/FactoryShell.tsx`
  - `diaweb/frontend/modules/factory/types.ts` if view props need expansion
  - factory dictionary files for labels
  - affected factory UI tests under `diaweb/frontend/__tests__/modules/factory/`

  Logging:
  - Log `INFO` for successful main-building upgrade from warehouse context.
  - Log `WARN` for blocked upgrade from missing requirements or unavailable payment method.

- [x] Task 9: Apply game/DCR price multiplier

  Deliverable: game-dollar/DCR price options are derived as `real_money_price * 25` wherever factory catalog/dynamic pricing currently mirrors real-money amounts.

  Expected behavior:
  - Main building level options use the multiplier for game/DCR payment options.
  - Dynamic compartment/employee pricing follows the same approved rule where applicable.
  - Real-money and resource-only prices remain unchanged.
  - Tests cover representative low and high price tiers.

  Files:
  - `diaverseapi/app/factory/catalog/data/factory_catalog.v1.yaml`
  - `diaverseapi/app/factory/catalog/schema.py` if derived validation is needed
  - `diaverseapi/app/factory/services/catalog_service.py` or pricing service files if dynamic prices are computed
  - `diaverseapi/app/factory/tests/test_catalog.py` or existing factory catalog/pricing tests

  Logging:
  - Prefer tests and deterministic catalog validation over runtime logs.
  - If dynamic price derivation is implemented, log only `DEBUG` for derived kind and multiplier in non-production.

- [x] Task 10: Rename payment labels and render icon+amount requirements

  Deliverable: payment and requirement displays use compact icon+amount rows/chips and updated Russian labels.

  Expected behavior:
  - `Реальная оплата` becomes `Оплата`.
  - `Игровые доллары` becomes `Игровые`.
  - Requirement rows show icon + amount, not long text that breaks layout.
  - Labels fit on mobile and desktop.

  Files:
  - `diaweb/frontend/modules/factory/components/*` files that render factory payment requirements
  - factory dictionary files
  - `diaweb/frontend/modules/factory/iconResolver.ts` if requirement icons need mapping
  - affected factory UI tests under `diaweb/frontend/__tests__/modules/factory/`

  Logging:
  - No runtime logs required for pure rendering changes.

### Phase 5: Final Verification And Knowledge Refresh

- [x] Task 11: Targeted automated verification

  Deliverable: all touched backend/frontend factory tests pass, with no known regressions hidden behind unrelated failures.

  Commands:
  - `cd C:\Users\Indigo\Desktop\diaverse\diaverseapi; .venv\Scripts\python.exe -m pytest app\factory\tests -q`
  - `cd C:\Users\Indigo\Desktop\diaverse\diaverseapi; .venv\Scripts\python.exe -m ruff check app\factory`
  - `cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend; npm run test -- __tests__/modules/factory`
  - `cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend; npm run typecheck`

  Logging:
  - Record only sanitized verification results in daily/internal notes.

- [x] Task 12: Knowledge refresh after implementation

  Deliverable: workspace knowledge and daily notes reflect completed factory changes.

  Expected behavior:
  - Append daily entries for completed implementation chunks.
  - Run targeted GBrain sync after meaningful code/docs changes.
  - Do not publish internal-only details, server addresses, SSH commands, raw env values, or secrets.

  Files/commands:
  - `docs/daily/2026-06-02-safiu.md`
  - `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`

  Logging:
  - Knowledge refresh logs can mention source IDs and success/failure, not private infrastructure details.

## Commit Plan

- `diaverseapi`: `fix(factory): preserve fractional warehouse production`
- `diaweb`: `fix(factory): show fractional warehouse balances`
- `diaverseapi`: `fix(factory): reset production compartments on demolition`
- `diaweb`: `fix(factory): surface pet dismantle failures`
- `diaverseapi`: `test(factory): cover rare pet dismantle and slot token charges`
- `diaweb`/`diaverseapi`: `fix(factory): align upgrade UX and game price labels`
- `diaverse`: commit only if archived plan, daily, or docs updates need to be saved in the workspace repo

## Continuation Notes

- Current active fast plan is `.ai-factory/PLAN.md` for auth-bot broadcasts.
- Continue factory work from this archived plan explicitly, or copy this file back to `.ai-factory/PLAN.md` before running `$aif-implement` for the factory batch.
- Do not overwrite the active broadcast plan unless the user asks to switch active work back to factory fixes.
- Implementation was paused during Task 6 after a partial test-only patch in `diaverseapi/app/factory/tests/test_crafting_service.py`; finish or reconcile that file first before continuing later phases.
