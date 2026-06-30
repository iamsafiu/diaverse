# Implementation Plan: Factory Level 4 Playable Scope

Branch: none
Created: 2026-06-30

## Settings
- Testing: yes
- Logging: standard
- Docs: yes

## Workspace Scope

This is a fast cross-repo plan from the workspace root. No branches are created.

| Repository | Path | Affected | Role |
| --- | --- | --- | --- |
| diaverse | C:\Users\Indigo\Desktop\diaverse | yes | active AIF plan and factory documentation |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes | authoritative factory rules, state, commands, catalog behavior, tests |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes | web cabinet factory UI, BFF client/types, tests |
| diaverse-mobile | C:\Users\Indigo\Desktop\diaverse\diaverse-mobile | no | mobile factory screen remains out of scope |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | no | out of scope |
| diaverse-content | C:\Users\Indigo\Desktop\diaverse\diaverse-content | no | out of scope |
| diaverse-ai-cofounder | C:\Users\Indigo\Desktop\diaverse\diaverse-ai-cofounder | no | archived/reference only |
| club10000-bot | C:\Users\Indigo\Desktop\diaverse\club10000-bot | no | out of scope |
| diaverse-auth-bot | C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot | no | out of scope |

## Roadmap Linkage

Milestone: "none"
Rationale: Fast plan requested; no `.ai-factory/ROADMAP.md` is available in the workspace context.

## Research Context

Source: `docs/tasks/fabric/factory-mechanics-final.md`, local GBrain `diaverse-docs/features/factory`, and verified source files in `diaverseapi/app/factory` and `diaweb/frontend/modules/factory`.

Note: `.ai-factory/RESEARCH.md` currently has an unrelated Telegram ops-agent active summary, so it is intentionally not carried into this factory plan.

Goal:
- Raise the supported playable factory scope from levels 1-3 to levels 1-4 in backend and diaweb.
- Allow a valid level 3 factory to upgrade to level 4 using existing level 4 catalog pricing and requirements.
- At factory level 4, expose the level 4 gameplay surface from the final mechanics document: resource parts up to level 4, pet craft workshop as normal required content, rare pet craft as normal required content, epic pet craft as early access, rare biomass as normal content, epic biomass as early access, and mutagen workshop/common mutagen as early access.

Constraints:
- Backend remains the source of truth for requirements, spendability, unlocks, inventory reservation, craft results, timers, idempotency, and payment-finalized state.
- Frontend may hide unsupported future targets but must not calculate authoritative requirements or balances.
- Keep the established convention that all factory levels use the same playable map and hotspot geometry unless a separate art decision changes it.
- Do not build native mobile factory screens or mobile-specific contracts in this scope.
- Do not enable level 5 progression yet; target level 5 must remain hidden/blocked until a separate implementation raises the max gate.
- Avoid catalog economy changes unless tests reveal a mismatch required for level 4 playability.

Decisions:
- Change both hard caps from `3` to `4`: backend `FACTORY_SUPPORTED_MAX_LEVEL` and frontend `FACTORY_SUPPORTED_MAX_LEVEL`.
- Treat the existing catalog v1 level 4 row and early-access rows as the intended economy source unless implementation tests prove otherwise.
- Keep level 4 visual keys stable and use the existing shared map fallback; add only minimal manifest/test polish if the level 4 upgrade preview is visibly broken.
- Use targeted backend and frontend tests around the old blocked level 4 paths instead of broad unrelated factory refactors.

Open questions:
- Whether level 5 requirement rows should already include mutagen workshop/common mutagen as mandatory for 5 -> 6. This is noted as future level 5 scope and should not block level 4 enablement unless current tests fail.

## Tasks

### Phase 1: Backend Gate And Level Upgrade

- [x] **Task 1: Raise the backend factory supported max level to 4**
  - Deliverable: Update backend policy gates so target level 4 is accepted and target level 5 is still rejected.
  - Expected behavior:
    - `is_factory_level_upgrade_supported(3)` returns true.
    - `is_factory_target_level_supported(4)` returns true.
    - Target level 5 remains unsupported through the same controlled command error path.
  - Files:
    - `diaverseapi/app/factory/domain/policies.py`
    - `diaverseapi/app/factory/services/command_service.py`
    - `diaverseapi/app/factory/services/state_service.py`
    - `diaverseapi/app/factory/tests/test_command_service.py`
    - `diaverseapi/app/factory/tests/test_state_service.py`
  - Logging requirements:
    - Keep existing command-service logging shape.
    - Log level-up accept/reject decisions at INFO/WARNING with user/profile id, current level, target level, and supported max level.
    - Do not log full factory state, inventory payloads, payment payloads, or raw balance snapshots.
  - Dependencies: none.

- [x] **Task 2: Cover successful 3 -> 4 upgrade requirements and failure cases**
  - Deliverable: Replace old "target level 4 is blocked" expectations with tests that prove level 3 requirements can unlock level 4, while incomplete requirements still block the upgrade.
  - Expected behavior:
    - A level 3 profile with all level 3 resource parts, life force built, epic life force level 5, and optional pet craft early access can upgrade to level 4.
    - Missing required level 3 prerequisites still returns a typed requirement failure.
    - Target level 5 returns an unsupported-target error with `supported_max_level: 4`.
  - Files:
    - `diaverseapi/app/factory/tests/test_command_service.py`
    - `diaverseapi/app/factory/tests/test_catalog.py`
    - `diaverseapi/app/factory/services/command_service.py` if tests reveal missing normalization.
  - Logging requirements:
    - INFO on successful level-up command completion with old/new level and idempotency key.
    - WARNING on unmet requirement failure with requirement code/target only, not full state.
    - DEBUG may be used in tests/helpers for setup details, controlled by normal test logging.
  - Dependencies: Task 1.

### Phase 2: Backend Level 4 Gameplay Surface

- [x] **Task 3: Verify and expose level 4 state/actions for buildings and compartments**
  - Deliverable: Add focused state/action tests for level 4 availability across resource, biomass, pet craft, and mutagen surfaces.
  - Expected behavior:
    - Resource workshop parts can upgrade/build through resource level 4.
    - `dna_capsule_workshop.rare_biomass` is normal content at level 4 and `epic_biomass` is early access.
    - `pet_craft_workshop` and `rare_pet_craft` are normal content at level 4; `epic_pet_craft` is early access.
    - `mutagen_workshop` and `common_mutagen` are visible/buildable as early access at level 4.
    - Level 5-only content remains locked or early access exactly as the catalog defines.
  - Files:
    - `diaverseapi/app/factory/services/state_service.py`
    - `diaverseapi/app/factory/services/building_service.py`
    - `diaverseapi/app/factory/services/compartment_service.py`
    - `diaverseapi/app/factory/tests/test_state_service.py`
    - `diaverseapi/app/factory/tests/test_building_service.py`
    - `diaverseapi/app/factory/tests/test_compartment_service.py`
  - Logging requirements:
    - INFO for build/package purchase state transitions with building/compartment key and early-access flag.
    - WARNING for blocked build/upgrade commands with lock reason and factory level.
    - Avoid per-card state logs during normal state rendering.
  - Dependencies: Tasks 1-2.

- [x] **Task 4: Verify level 4 crafting and inventory mappings**
  - Deliverable: Add/adjust backend crafting coverage for level 4 craftable outputs and aliases so production jobs reserve inputs and credit outputs correctly.
  - Expected behavior:
    - Rare pet craft remains concrete-shard based and still reserves the selected rare shard before producing the selected rare pet.
    - Epic pet craft is available as level 4 early access and uses the same selected-shard validation pattern for epic fragments if supported by current catalog/resource helpers.
    - Common mutagen craft produces the existing canonical mutagen resource through the `common_mutagen`/`mutagen_common` alias path.
    - Rare and epic biomass craft rows reserve the configured inputs and credit the configured biomass output keys.
  - Files:
    - `diaverseapi/app/factory/services/crafting_service.py`
    - `diaverseapi/app/factory/services/inventory_gateway.py`
    - `diaverseapi/app/factory/services/resource_assets.py`
    - `diaverseapi/app/factory/tests/test_crafting_service.py`
    - `diaverseapi/app/factory/tests/test_inventory_gateway.py`
    - `diaverseapi/app/factory/tests/test_award_resource_support.py`
  - Logging requirements:
    - INFO on craft job creation/collection with building key, compartment key, output key, and job id.
    - WARNING when selected shard/material validation fails, with the requested material id/key only.
    - ERROR on inventory reservation/credit failure using sanitized gateway context.
  - Dependencies: Task 3.

### Phase 3: Diaweb Gate And Level 4 UI

- [x] **Task 5: Raise the diaweb supported max level to 4**
  - Deliverable: Update the frontend factory cap and tests so level 4 upgrade controls render when backend state offers target level 4, while level 5 remains hidden.
  - Expected behavior:
    - `FactoryShell` no longer hides the 3 -> 4 upgrade CTA solely because of the local max constant.
    - The existing unsupported-target guard now applies to target level 5.
    - The UI still respects backend `available_actions`, lock reasons, and command errors.
  - Files:
    - `diaweb/frontend/modules/factory/constants.ts`
    - `diaweb/frontend/modules/factory/components/FactoryShell.tsx`
    - `diaweb/frontend/__tests__/modules/factory/FactoryShell.test.tsx`
  - Logging requirements:
    - Keep production client logs minimal.
    - Use existing warning/error handling for rejected commands.
    - Do not log full `FactoryStateSnapshot` or inventory excerpts.
  - Dependencies: Tasks 1-2.

- [x] **Task 6: Cover level 4 workshop and compartment rendering in diaweb**
  - Deliverable: Add frontend tests for the level 4 gameplay surface and update UI normalization only where tests reveal stale assumptions.
  - Expected behavior:
    - Pet craft workshop appears as normal content at level 4.
    - Rare pet craft appears as normal content; epic pet craft appears as early access.
    - Mutagen workshop/common mutagen and epic biomass can render as early-access cards/actions using existing labels and asset manifest keys.
    - Resource and production screens show backend-provided lock reasons instead of client-side unsupported-level text.
  - Files:
    - `diaweb/frontend/modules/factory/catalogView.ts`
    - `diaweb/frontend/modules/factory/displayLabels.ts`
    - `diaweb/frontend/modules/factory/components/FactoryResourceWorkshopScreen.tsx`
    - `diaweb/frontend/modules/factory/components/FactoryProductionWorkshopScreen.tsx`
    - `diaweb/frontend/modules/factory/components/FactoryCompartmentScreen.tsx`
    - `diaweb/frontend/__tests__/modules/factory/FactoryResourceWorkshopScreen.test.tsx`
    - `diaweb/frontend/__tests__/modules/factory/FactoryProductionWorkshopScreen.test.tsx`
    - `diaweb/frontend/__tests__/modules/factory/FactoryCompartmentScreen.test.tsx`
  - Logging requirements:
    - No new noisy render logs.
    - Keep user-visible blocked states in the UI and reserve console errors for failed mutations or malformed data.
    - Any dev-only debug logs must stay behind existing factory debug environment flags.
  - Dependencies: Task 5.

- [x] **Task 7: Polish level 4 visual keys and upgrade preview behavior**
  - Deliverable: Ensure level 4 map, hotspot geometry, and upgrade preview render nonblank with stable manifest keys and mobile-first layout.
  - Expected behavior:
    - `factory.map.level_4` resolves through the shared playable map convention.
    - If the upgrade dialog asks for a level 4 preview key, it either has a manifest entry or reliably falls back to the level 4 map without broken image UI.
    - Existing workshop hotspots remain stable across levels.
  - Files:
    - `diaweb/frontend/modules/factory/assetManifest.ts`
    - `diaweb/frontend/modules/factory/components/FactoryUpgradeDialog.tsx`
    - `diaweb/frontend/modules/factory/components/FactoryScene.tsx`
    - `diaweb/frontend/__tests__/modules/factory/FactoryScene.test.tsx`
    - `diaweb/frontend/__tests__/modules/factory/FactoryUpgradeDialog.test.tsx` if present or created.
  - Logging requirements:
    - Do not add production image-load logs.
    - Keep any asset fallback diagnostics dev-only.
    - Test visual-key selection directly instead of relying on console output.
  - Dependencies: Task 5.

### Phase 4: Documentation And Verification

- [x] **Task 8: Update factory documentation for level 4 support**
  - Deliverable: Update canonical workspace docs so they no longer say web/backend only support levels 1-3.
  - Expected behavior:
    - `docs/features/factory.md` states that levels 1-4 are playable after implementation.
    - The doc names the level 4 enabled surface and keeps level 5+ explicitly unsupported.
    - Any smoke/task note that references the old target level 4 block is adjusted or linked to the new implementation status.
  - Files:
    - `docs/features/factory.md`
    - `docs/tasks/fabric/factory-web-integration-smoke.md` if it still asserts the old gate.
  - Logging requirements:
    - Documentation changes do not add runtime logging.
    - Include a note in verification/daily work only after implementation, not as a runtime log.
  - Dependencies: Tasks 1-7.

## Verification Plan

Run from `diaverseapi`:

```powershell
.\.venv\Scripts\python.exe -m pytest app/factory/tests/test_catalog.py app/factory/tests/test_command_service.py app/factory/tests/test_state_service.py app/factory/tests/test_building_service.py app/factory/tests/test_compartment_service.py app/factory/tests/test_crafting_service.py app/factory/tests/test_inventory_gateway.py app/factory/tests/test_award_resource_support.py -q
.\.venv\Scripts\python.exe -m ruff check app/factory
```

Run from `diaweb/frontend`:

```powershell
npm run test -- __tests__/modules/factory
npm run lint -- modules/factory __tests__/modules/factory
npm run typecheck
```

Run from the workspace root after code/docs changes:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1
```

## Commit Plan

- **Commit 1** (after tasks 1-4): `feat(api): enable factory level four`
- **Commit 2** (after tasks 5-7): `feat(web): expose factory level four`
- **Commit 3** (after task 8 and verification): `docs(factory): mark level four playable`

## Definition Of Done

- Backend and diaweb both support factory target level 4 and still block/hide target level 5.
- A valid level 3 factory can upgrade to level 4 through existing command/payment/inventory paths.
- Level 4 state exposes the intended normal and early-access workshops/compartments from the final mechanics document.
- Craft/build/package flows for level 4 content have targeted backend coverage.
- Diaweb renders the level 4 upgrade and gameplay surface without broken map/preview assets or stale unsupported-level copy.
- Canonical factory docs describe the new supported scope and the remaining level 5+ boundary.
- Targeted backend and frontend checks pass.
