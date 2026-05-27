# Implementation Plan: Factory Real Inventory Integration

Created: 2026-05-27
Mode: AIF fast plan, workspace root, no branch changes
Branch: none
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: yes - include targeted backend and frontend tests for changed factory inventory, crafting, slot-token, warehouse, and UI selector behavior.
- Logging: standard - keep existing factory INFO command-boundary logs; add DEBUG logs only for entity resolution, inventory debit/credit/grant decisions, and unexpected recipe/entity mismatches.
- Docs: no - warn-only docs checkpoint; implementation may update feature docs only if the final contract changes materially.
- Roadmap Linkage: none, no non-empty `.ai-factory\ROADMAP.md` found.
- Knowledge: use local GBrain first for source navigation, then verify exact behavior in source files. Run targeted GBrain sync after meaningful code changes.

## Goal

Finish the factory integration with the existing Diaverse inventory domain instead of using temporary factory-only duplicates. Factory recipes must consume and produce real entities: existing resources, concrete pet shards, user pets, EvoGen vouchers, mutagens, token details, synthesis cores, slot tokens, XDV, and game dollars.

## Current Findings

- EvoGens already exist as `evogen_rare`, `evogen_epic`, `evogen_legendary` custom rewards mapped to `VoucherType.rare_pet_4_evolution`, `VoucherType.epic_pet_4_evolution`, and `VoucherType.legendary_pet_4_evolution`.
- Pet fragments already exist as concrete `CharacterShard` records tied to a specific `Character`, with rarity, kind/title, icon, and `UserCharacterShard` balances.
- Existing systems already grant specific shards and random shards by rarity through `random_shard` metadata.
- The temporary `ResourceType.rare_pet_fragment`, `ResourceType.epic_pet_fragment`, `ResourceType.legendary_pet_fragment`, and `ResourceType.rare_evogen` duplicate existing domains and must stop being the authoritative factory model.
- The factory catalog still contains recipe keys such as `rare_pet_fragment`, `epic_pet_fragment`, `legendary_pet_fragment`, `rare_evogen`, `evogen_rare`, `character_rare`, and mutagen/nullifier outputs that need a typed resolver instead of direct `ResourceType` lookup.

## Non-Goals

- Do not create a second shard, pet, EvoGen, or mutagen inventory system.
- Do not convert concrete shard ownership into generic rarity-only balances.
- Do not silently delete any user balances if temporary factory resources already exist in an environment.
- Do not redesign unrelated cabinet, shop, exchange, club, or copywriting flows.
- Do not create branches in fast mode.
- Do not run browser/manual verification unless the user explicitly asks later.

## Repository Matrix

| Repository | Path | Affected | Branch changes | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan only | none | Stores this fast plan and daily entry |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | none in fast mode | Factory entity resolver, inventory adapters, crafting, warehouse, slot token assembly |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | none in fast mode | Factory UI types, selectors, inventory/warehouse display, recipe screens |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | none | Not affected |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | none | Not affected |

## Implementation Decisions

- Treat recipe keys like `shard_rare`, `rare_pet_fragment`, `evogen_rare`, `character_rare`, and `rare_mutagen` as typed factory entity aliases, not as automatic `ResourceType` names.
- Keep generic fragment labels only as UI/recipe wording. Runtime debits and credits must reference concrete `CharacterShard` rows.
- For shard inputs, require selected concrete `shard_id` or a selected shard balance matching the recipe rarity.
- For pet inputs, require selected `user_character_id` matching the recipe rarity and current ownership rules.
- For pet outputs, grant a real `UserCharacter`; where the recipe says "selected type" or "depending on loaded fragment", derive the character from the selected shard's `CharacterShard.character_id`.
- For random shard outputs, grant existing concrete random shards by rarity through the current shard grant semantics.
- For EvoGen outputs and slot-token inputs, use existing `UserVoucher`/`Voucher` records, not `ResourceType.rare_evogen`.
- For mutagen outputs, use `UserMutagen` with `MutationRarity`.
- Resource workshop production stays warehouse-backed. Production workshop outputs go to real inventory on collect, matching the mechanics doc.
- If temporary factory resource balances exist, implementation must preserve them as legacy/hidden until a deliberate migration decision is made; do not invent a lossy conversion from generic fragments to concrete shard species.

## Tasks

### Phase 1 - Inventory Taxonomy Cleanup

- [x] Task 1: Define the factory entity resolver contract.
  - Files/paths:
    - `docs\tasks\fabric\factory-mechanics-final.md`
    - `diaverseapi\app\factory\catalog\data\factory_catalog.v1.yaml`
    - `diaverseapi\app\factory\catalog\schema.py`
    - `diaverseapi\app\factory\infrastructure\inventory_gateway.py`
    - new `diaverseapi\app\factory\domain\entities.py` if a separate resolver module is cleaner
  - Deliverable:
    - Add/define a typed mapping for factory recipe aliases: normal resources, currencies, concrete shard aliases by rarity, random shard outputs, character outputs, EvoGen vouchers, mutagens, token details, synthesis cores, and slot tokens.
    - Document which keys remain legacy aliases and which keys are true persisted inventory keys.
    - Keep direct `ResourceType` resolution only for real resource types.
  - Logging:
    - Add DEBUG logs when a recipe key resolves to a non-resource entity type or fails validation.
    - Do not log full user inventory payloads or raw payment data.
  - Dependencies:
    - None.

- [x] Task 2: Remove temporary factory-only duplicates from the authoritative model.
  - Files/paths:
    - `diaverseapi\app\shards_and_resources\models.py`
    - `diaverseapi\migrations\versions\factory_web_state_20260525.py`
    - new corrective Alembic migration only if required by applied data/schema state
    - `diaverseapi\app\factory\tests\test_inventory_gateway.py`
    - `diaverseapi\app\factory\tests\test_award_resource_support.py`
  - Deliverable:
    - Stop treating `rare_pet_fragment`, `epic_pet_fragment`, `legendary_pet_fragment`, and `rare_evogen` as normal `ResourceType` inventory resources.
    - Replace tests that asserted those fake resources with tests for typed entity aliases.
    - Preserve existing data safely: if fake resource rows/balances may exist, leave a non-spendable legacy handling path or add a corrective data migration that does not lose user value.
  - Logging:
    - Add migration/service INFO logs only for legacy data handling counts if a corrective migration/service path is introduced.
    - Add DEBUG logs in the resolver when a legacy key is encountered.
  - Dependencies:
    - Depends on Task 1.

- [x] Task 3: Normalize factory catalog recipe keys to existing domain names.
  - Files/paths:
    - `diaverseapi\app\factory\catalog\data\factory_catalog.v1.yaml`
    - `diaverseapi\app\factory\catalog\validator.py`
    - `diaverseapi\app\factory\tests\test_catalog.py`
    - `diaverseapi\migrations\versions\factory_v2_data.py` as historical reference only
  - Deliverable:
    - Prefer canonical aliases such as `shard_rare`, `shard_epic`, `shard_legendary`, `character_rare`, `character_epic`, `evogen_rare`, `evogen_epic`, `evogen_legendary`, and mutagen rarity keys.
    - Keep designer/mechanics labels in metadata where the UI needs "редкий фрагмент", "эпический фрагмент", or "Эвоген".
    - Ensure catalog validation rejects unknown entity aliases early with clear errors.
  - Logging:
    - Keep catalog loader warnings for invalid aliases.
    - Add no per-row runtime logs.
  - Dependencies:
    - Depends on Task 1.

### Phase 2 - Backend Mixed Inventory Integration

- [x] Task 4: Extend factory inventory gateway for mixed entity balances.
  - Files/paths:
    - `diaverseapi\app\factory\infrastructure\inventory_gateway.py`
    - `diaverseapi\app\factory\schemas.py`
    - `diaverseapi\app\shards_and_resources\models.py`
    - `diaverseapi\app\characters\models.py`
    - `diaverseapi\app\vouchers\models.py`
    - `diaverseapi\app\factory\tests\test_inventory_gateway.py`
  - Deliverable:
    - Support balance snapshots for resources/currencies, shards grouped by rarity and exposed as selectable concrete shard balances, EvoGen vouchers by rarity, mutagens by rarity, and token ingredients.
    - Support safe debit/credit/grant operations for each entity type needed by factory recipes.
    - Keep resource balance behavior backwards-compatible for warehouse/resource workshops.
  - Logging:
    - DEBUG: entity kind, alias, rarity, selected id presence, amount, reason, and idempotency context.
    - ERROR/WARN: invalid selected entity, insufficient balance, or entity type mismatch.
    - Never log full pet/shard/voucher records or private user profile payloads.
  - Dependencies:
    - Depends on Tasks 1-3.

- [x] Task 5: Wire crafting start/collect/cancel to real inputs and outputs.
  - Files/paths:
    - `diaverseapi\app\factory\services\crafting_service.py`
    - `diaverseapi\app\factory\services\command_service.py`
    - `diaverseapi\app\factory\models.py`
    - `diaverseapi\app\factory\schemas.py`
    - `diaverseapi\app\factory\tests\test_crafting_service.py`
    - `diaverseapi\app\factory\tests\test_command_service.py`
  - Deliverable:
    - Extend craft start requests to carry selected concrete inputs: `shard_id`, `user_character_id`, `user_voucher_id` or equivalent typed selections.
    - Validate selected inputs match recipe rarity, ownership, quantity, and current availability before debiting anything.
    - On collect, grant real outputs: warehouse resources only where intended, concrete random shards, real pets, EvoGen vouchers, mutagens, nullifiers/other existing entities if present.
    - Preserve idempotency and refund/cancel behavior for reserved ingredients.
  - Logging:
    - INFO: craft start/collect/cancel command boundaries already present.
    - DEBUG: resolved recipe entities, selected inputs, debit reservation, output grant, refund path, and unsupported alias details.
    - ERROR: partial grant/debit failure with job id and entity alias, without dumping full inventory records.
  - Dependencies:
    - Depends on Task 4.

- [x] Task 6: Adapt life-force, pet craft, incubator, EvoGen, mutagen, brick, and biomass behavior to mechanics.
  - Files/paths:
    - `diaverseapi\app\factory\services\crafting_service.py`
    - `diaverseapi\app\factory\domain\policies.py`
    - `diaverseapi\app\characters\grants.py`
    - `diaverseapi\app\vouchers\grants.py`
    - `diaverseapi\app\characters\usecases\mutagen_usecases.py`
    - `diaverseapi\app\factory\tests\test_crafting_service.py`
  - Deliverable:
    - Life-force consumes selected real pet and outputs random concrete shards/resources by rarity.
    - Pet craft/incubator consume selected concrete shards and output the corresponding real pet type.
    - Brick/biomass/EvoGen recipes consume concrete shards by required rarity.
    - EvoGen workshop outputs existing EvoGen vouchers.
    - Mutagen workshop outputs existing user mutagens.
  - Logging:
    - DEBUG: rarity matching, selected source entity, output entity type, and count.
    - WARN: recipe requires a domain entity that has no existing grant/debit handler yet.
  - Dependencies:
    - Depends on Task 5.

- [x] Task 7: Fix slot-token assembly to consume real EvoGen vouchers.
  - Files/paths:
    - `diaverseapi\app\factory\services\slot_token_service.py`
    - `diaverseapi\app\factory\catalog\data\factory_catalog.v1.yaml`
    - `diaverseapi\app\factory\tests\test_slot_token_service.py`
    - `diaweb\frontend\modules\factory\components\SlotTokenDialog.tsx`
  - Deliverable:
    - Replace `rare_evogen` resource assumptions with existing `evogen_rare` voucher consumption.
    - Keep token details, synthesis core, and slot token as their correct existing inventory types.
    - Make the dialog display the user's real available EvoGen count and disable assembly when vouchers are missing.
  - Logging:
    - DEBUG: token assembly input resolution and voucher debit decision.
    - ERROR: idempotency replay mismatch or partial assembly failure.
  - Dependencies:
    - Depends on Tasks 4-5.

- [x] Task 8: Keep warehouse semantics limited to resource workshop output.
  - Files/paths:
    - `diaverseapi\app\factory\services\warehouse_service.py`
    - `diaverseapi\app\factory\services\state_service.py`
    - `diaverseapi\app\factory\services\crafting_service.py`
    - `diaverseapi\app\factory\tests\test_warehouse_service.py`
    - `diaverseapi\app\factory\tests\test_state_service.py`
  - Deliverable:
    - Resource workshops continue accruing to factory warehouse/storage and transfer to inventory.
    - Production craft outputs go directly to existing inventory on collect, as the mechanics doc says.
    - State balances clearly distinguish `factory_warehouse`, `user_inventory`, and selectable domain balances.
  - Logging:
    - DEBUG: warehouse settlement and inventory transfer source/destination.
    - WARN: attempt to place non-resource production output into warehouse.
  - Dependencies:
    - Depends on Tasks 4-6.

### Phase 3 - Frontend Contract And UI

- [x] Task 9: Update frontend factory types, API helpers, and catalog view model for typed entities.
  - Files/paths:
    - `diaweb\frontend\modules\factory\types.ts`
    - `diaweb\frontend\modules\factory\api.ts`
    - `diaweb\frontend\modules\factory\catalogView.ts`
    - `diaweb\frontend\modules\factory\iconResolver.ts`
    - `diaweb\frontend\modules\factory\assetManifest.ts`
    - `diaweb\frontend\__tests__\modules\factory\factory-api.test.ts`
  - Deliverable:
    - Remove frontend assumptions that `rare_pet_fragment` and `rare_evogen` are resource keys.
    - Represent ingredients/outputs with entity kind, rarity, selected id requirements, label, icon, and available quantity.
    - Resolve shard icons from concrete shard data when available; use generic rarity icon only as fallback.
  - Logging:
    - Keep existing `[factory]` DEBUG API logs.
    - Add WARN only for unknown entity kind or missing icon metadata.
  - Dependencies:
    - Depends on backend schema from Tasks 4-5.

- [x] Task 10: Add concrete input selectors to production workshop and compartment screens.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\ProductionWorkshopScreen.tsx`
    - `diaweb\frontend\modules\factory\components\CompartmentScreen.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryInventoryDrawer.tsx`
    - `diaweb\frontend\modules\i18n\dictionaries\ru.json`
    - `diaweb\frontend\modules\i18n\dictionaries\en.json`
    - `diaweb\frontend\__tests__\modules\factory\FactoryProductionWorkshopScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryCompartmentScreen.test.tsx`
  - Deliverable:
    - For recipes requiring fragments, show selectable concrete shard cards grouped by rarity/species.
    - For life-force, show selectable owned pets of required rarity.
    - For EvoGen/token recipes, show real EvoGen voucher availability.
    - Start craft only when required selections are complete and backend quote says balances are sufficient.
  - Logging:
    - No render-loop logs.
    - WARN through existing UI logging only when backend returns an entity-selection validation error that the UI cannot map.
  - Dependencies:
    - Depends on Task 9.

- [x] Task 11: Align inventory, warehouse, and dialogs with real entity balances.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryInventoryDrawer.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryWarehouseScreen.tsx`
    - `diaweb\frontend\modules\factory\components\SlotTokenDialog.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryUpgradeDialog.tsx`
    - `diaweb\frontend\modules\i18n\dictionaries\ru.json`
    - `diaweb\frontend\modules\i18n\dictionaries\en.json`
    - `diaweb\frontend\__tests__\modules\factory\FactoryInventoryDrawer.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryWarehouseScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryDialogs.test.tsx`
  - Deliverable:
    - Inventory section shows real resources, concrete shards, EvoGens, mutagens, and token ingredients without duplicate fake fragment/EvoGen rows.
    - Warehouse screen only shows warehouse-backed resources and transfers only valid resource quantities.
    - Slot-token dialog shows "Редкий ЭвоГен" from vouchers, not a resource icon/balance.
  - Logging:
    - Add no new presentational logs.
    - Keep existing mutation logs for transfer and assembly actions.
  - Dependencies:
    - Depends on Tasks 7-10.

### Phase 4 - Tests, Migration Safety, And Sync

- [x] Task 12: Add backend coverage for the mixed inventory contract.
  - Files/paths:
    - `diaverseapi\app\factory\tests\test_inventory_gateway.py`
    - `diaverseapi\app\factory\tests\test_crafting_service.py`
    - `diaverseapi\app\factory\tests\test_slot_token_service.py`
    - `diaverseapi\app\factory\tests\test_warehouse_service.py`
    - `diaverseapi\app\factory\tests\test_catalog.py`
  - Deliverable:
    - Cover fake resource rejection/deprecation, concrete shard debit, random shard grant, pet grant, EvoGen voucher grant/debit, mutagen grant, warehouse-only resource transfer, and idempotent replay.
    - If a corrective migration is introduced, verify PostgreSQL DDL compilation with `alembic upgrade <down_revision>:<new_revision> --sql`.
  - Logging:
    - Tests should assert behavior, not logging internals, except where a warning/error path is part of the contract.
  - Dependencies:
    - Depends on Tasks 1-8.

- [x] Task 13: Add frontend coverage for typed entity UI flows.
  - Files/paths:
    - `diaweb\frontend\__tests__\modules\factory\FactoryProductionWorkshopScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryCompartmentScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryInventoryDrawer.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryWarehouseScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryDialogs.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\factory-api.test.ts`
  - Deliverable:
    - Cover shard selector rendering, missing-selection disabled state, selected shard payload, EvoGen voucher display, absence of duplicate fake resources, and warehouse resource-only display.
    - Keep snapshot/assertions focused on behavior and visible Russian UI labels.
  - Logging:
    - No new logs required in tests.
  - Dependencies:
    - Depends on Tasks 9-11.

- [x] Task 14: Run targeted verification and sync changed knowledge sources.
  - Files/paths:
    - `diaverseapi`
    - `diaweb`
    - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
  - Deliverable:
    - Run targeted backend tests for factory catalog, inventory gateway, crafting, slot token, warehouse, state, and command service.
    - Run targeted frontend tests for factory API, production screens, compartment screens, inventory drawer, warehouse, and dialogs.
    - Run repo lint/type checks if package scripts are available and implementation changes touch typed contracts.
    - Sync `diaverseapi-code` and `diaweb-code` GBrain sources after implementation.
  - Logging:
    - Verification should not add runtime logs.
    - Summarize failures by command and first failing assertion during implementation.
  - Dependencies:
    - Depends on Tasks 12-13.

## Verification Plan

Run from `C:\Users\Indigo\Desktop\diaverse\diaverseapi` after backend changes:

```powershell
.\.venv\Scripts\python.exe -m pytest app\factory\tests\test_catalog.py app\factory\tests\test_inventory_gateway.py app\factory\tests\test_crafting_service.py app\factory\tests\test_slot_token_service.py app\factory\tests\test_warehouse_service.py app\factory\tests\test_state_service.py app\factory\tests\test_command_service.py
```

If a migration is added, also run:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

Run from `C:\Users\Indigo\Desktop\diaverse\diaweb` after frontend changes, using the repo's actual scripts:

```powershell
npm test -- factory-api FactoryProductionWorkshopScreen FactoryCompartmentScreen FactoryInventoryDrawer FactoryWarehouseScreen FactoryDialogs
npm run lint
```

Run from `C:\Users\Indigo\Desktop\diaverse` after implementation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverseapi-code
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaweb-code
```

## Commit Plan

- **Commit 1** (after Tasks 1-3, `diaverseapi`): `fix(factory): resolve recipes through existing inventory entities`
- **Commit 2** (after Tasks 4-8, `diaverseapi`): `fix(factory): wire crafting to real shards and evogens`
- **Commit 3** (after Tasks 9-11, `diaweb`): `fix(factory): show real inventory entities in factory`
- **Commit 4** (after Tasks 12-14, affected repos): `test(factory): cover mixed inventory integration`

## Rollback Plan

- Revert `diaverseapi` commits that introduce typed entity resolver, mixed inventory gateway changes, or craft/slot-token behavior.
- Revert `diaweb` commits that depend on the new typed entity schema.
- If a corrective migration is applied, rollback with a deliberate migration path; do not manually edit production balances.
- Keep temporary legacy handling available until real environments are confirmed to have no fake factory fragment/EvoGen balances.

## Next Step

Run `$aif-implement` from `C:\Users\Indigo\Desktop\diaverse` when ready to execute this fast plan.
