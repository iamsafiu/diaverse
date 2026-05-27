# Implementation Plan: Factory Level 1 Spec Alignment

Created: 2026-05-27
Mode: AIF fast plan, workspace root, no branch changes
Branch: none
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: yes - include targeted unit/component tests for changed factory logic, but do not run browser/manual verification unless the user explicitly asks.
- Logging: standard - preserve existing `[factory]`, `[factory/bff]`, and backend factory logs; add DEBUG only around state/status resolution and entitlement/construction decisions that are hard to diagnose.
- Docs: no - warn-only docs checkpoint; this is an implementation plan, not a documentation task.
- Roadmap Linkage: none, no non-empty `.ai-factory\ROADMAP.md` found.
- Knowledge: use local GBrain first for source navigation, then verify exact behavior in source files. Run targeted GBrain sync after meaningful code changes.

## Goal

Bring the factory level 1 web experience into alignment with `factory-mechanics-final.md` and `factory-designer-brief-levels-1-2-8.md`, with priority on the main factory map A1, building info bubbles A2, and the level-1 gameplay loop. The result must feel like a mobile game screen: the factory map is the primary full-screen surface, buildings sit on the real image platforms, bottom nav remains, and locked/buildable/active states match the spec.

## Non-Goals

- Do not redesign unrelated cabinet, shop, club, or copywriting flows.
- Do not turn the workspace root into a product repository.
- Do not replace the existing factory catalog/state architecture.
- Do not fake frontend-only business rules when backend can provide the authoritative state.
- Do not run browser verification in implementation unless the user separately permits it.
- Do not push automatically from this fast plan; pushing belongs to the implementation/commit step.

## Research Context

Source: `.ai-factory\RESEARCH.md` active summary is workspace-level, not factory-specific. Relevant constraints carried forward:

- Keep child repositories separate; product changes belong to `diaweb` and `diaverseapi`.
- Use the top-level AIF plan as the progress source of truth.
- Source code and canonical docs override stale GBrain output.
- Keep GBrain local CLI-first and sync changed sources after implementation.

## Repository Matrix

| Repository | Path | Affected | Branch changes | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan only | none | Stores this fast plan |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | none in fast mode | Factory map, screens, i18n, BFF-facing UI tests |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | none in fast mode | Factory authoritative state, construction timers, subscription recognition if needed |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | none | Not affected |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | none | Not affected |

## Implementation Decisions

- Treat A1/A2 level 1 as the first acceptance gate. Other screens must not be polished in isolation while the main map still misrepresents state.
- Use uploaded map/building assets through `diaweb/public/factory/**` and `assetManifest.ts`; do not keep Russian asset filenames in code-facing paths.
- Calibrate hotspot/building coordinates against the actual map image, not the current placeholder grid.
- Preserve bottom navigation and hide only the cabinet topbar on factory routes.
- Keep desktop factory routes in mobile-width game shell, matching the user's requirement that desktop also shows the mobile view.
- Prefer backend-derived `available_actions`, lock reasons, timers, and statuses. Frontend status helpers may only translate/render state, not invent mechanics.
- Backend construction timers are a real spec dependency. If they are too large for this pass, implement a clearly scoped minimal backend contract for resource build/upgrade timers instead of pretending instant builds satisfy B2/A2/A5.

## Tasks

### Phase 1 - Contract And Level 1 State Audit

- [x] Task 1: Lock down the level-1 state contract between the spec, backend, and frontend.
  - Files/paths:
    - `docs\tasks\fabric\factory-mechanics-final.md`
    - `docs\tasks\fabric\factory-designer-brief-levels-1-2-8.md`
    - `diaverseapi\app\factory\services\state_service.py`
    - `diaverseapi\app\factory\catalog\data\factory_catalog.v1.yaml`
    - `diaweb\frontend\modules\factory\types.ts`
    - `diaweb\frontend\modules\factory\components\FactoryHotspotLayer.tsx`
  - Deliverable:
    - Define the exact level-1 render matrix: warehouse built, 6 resource workshops buildable ruins, life force early access, other production workshops locked with required factory level.
    - Confirm which fields already exist in backend state for `resource_part`, `production_part`, `available_actions`, `lock_reasons`, and timers.
    - Identify the minimum backend additions needed for construction/build timers, if current state cannot represent them.
  - Logging:
    - No new runtime logs required in this audit task.
    - If temporary diagnostics are added during implementation, remove them before commit unless they become useful DEBUG logs.
  - Dependencies:
    - None.

- [x] Task 2: Fix backend state/action semantics that block correct A1/A2 rendering.
  - Files/paths:
    - `diaverseapi\app\factory\services\state_service.py`
    - `diaverseapi\app\factory\services\building_service.py`
    - `diaverseapi\app\factory\models.py`
    - `diaverseapi\app\factory\schemas.py`
    - `diaverseapi\app\factory\tests\test_state_service.py`
    - `diaverseapi\app\factory\tests\test_building_service.py`
  - Deliverable:
    - Ensure resource workshop buildability is independent from production-part availability.
    - Return clear lock reasons such as `available_from_factory_level` for locked production workshops.
    - Represent resource build/upgrade construction timers if current instant activation prevents B2/A2/A5 compliance.
    - Preserve idempotency, authoritative server time, and catalog-driven rules.
  - Logging:
    - Add DEBUG logs for build/upgrade state transitions: profile id, building key, part, previous status, next status, target time. Do not log payment/provider payloads.
    - Keep INFO logs only for command boundaries already present in `api.py`.
  - Dependencies:
    - Depends on Task 1.

- [x] Task 3: Verify factory subscription recognition needed by A12-A14 and level-1 modifiers.
  - Files/paths:
    - `diaverseapi\app\factory\infrastructure\subscription_resolver.py`
    - `diaverseapi\app\factory\domain\modifiers.py`
    - `diaverseapi\app\factory\tests\test_subscriptions.py`
    - related cabinet pass entitlement files only if factory cannot see web-purchased Trademaster.
  - Deliverable:
    - Confirm Pro and Trademaster modifiers reach factory state for the actual subscription/pass models used by web purchases.
    - If Trademaster is stored as a personal pass rather than `UserSubscription`, add the resolver path needed by factory.
    - Keep A12/A13/A14 frontend display purely state-driven.
  - Logging:
    - Add DEBUG logs for entitlement source selection: user subscription, personal pass, or none.
    - Do not log raw payment identifiers, tokens, or full subscription objects.
  - Dependencies:
    - Depends on Task 1.

### Phase 2 - Asset And Map Scene Foundation

- [x] Task 4: Normalize factory map/building assets and manifest references.
  - Files/paths:
    - `diaweb\public\factory\maps\**`
    - `diaweb\public\factory\buildings\**`
    - `diaweb\frontend\modules\factory\assetManifest.ts`
    - `diaweb\frontend\modules\factory\iconResolver.ts`
  - Deliverable:
    - Move newly uploaded map/preview/building images into stable folders with English slug filenames.
    - Convert remaining source images to `.webp` where they are raster gameplay assets.
    - Keep SVG only for UI icons/effects where SVG is already appropriate.
    - Update manifest visual keys so code never depends on Russian filenames.
  - Logging:
    - No runtime logs needed for static asset moves.
    - Keep existing manifest validation warning logs for missing/bad assets.
  - Dependencies:
    - Depends on Task 1 for required visual keys.

- [x] Task 5: Rebuild A1 map layout as a true mobile game scene.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryScene.tsx`
    - `diaweb\frontend\modules\factory\components\factoryScene.module.css`
    - `diaweb\frontend\modules\factory\components\FactoryShell.tsx`
    - `diaweb\frontend\modules\cabinet\components\CabinetLayout.tsx`
    - `diaweb\frontend\__tests__\modules\cabinet\CabinetLayout.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryScene.test.tsx`
  - Deliverable:
    - Make factory routes full-height within the mobile shell, with no extra borders/padding around the map.
    - Keep bottom nav visible and remove cabinet topbar only on factory routes.
    - On desktop, keep the same mobile-width game viewport instead of stretching the factory scene.
    - Use stable dimensions/aspect constraints so the map does not scroll, collapse, or distort.
  - Logging:
    - Keep page/render logs at existing DEBUG level only.
    - Do not add noisy render-loop logs.
  - Dependencies:
    - Depends on Task 4.

- [x] Task 6: Calibrate real platform coordinates for buildings and bubbles.
  - Files/paths:
    - `diaweb\frontend\modules\factory\assetManifest.ts`
    - `diaweb\frontend\modules\factory\components\FactoryHotspotLayer.tsx`
    - `diaweb\frontend\modules\factory\components\BuildingInfoBubble.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryHotspotLayer.test.tsx`
  - Deliverable:
    - Replace placeholder `hotspotLayout` grid with coordinates matching the actual level-1 map platforms.
    - Position building images and A2 bubbles with anchors that stay inside the viewport.
    - Use different visual scale/anchors for warehouse, resource workshops, production workshops, and locked ruins.
    - Preserve tap targets without adding visible layout boxes/borders.
  - Logging:
    - No runtime logs for normal coordinate rendering.
    - Keep manifest validation warnings for missing coordinates or missing visual keys.
  - Dependencies:
    - Depends on Tasks 4-5.

### Phase 3 - A1/A2 Gameplay State Rendering

- [x] Task 7: Rewrite map status resolution to match A1/A2.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryHotspotLayer.tsx`
    - `diaweb\frontend\modules\factory\components\BuildingInfoBubble.tsx`
    - `diaweb\frontend\modules\factory\catalogView.ts`
    - `diaweb\frontend\modules\i18n\dictionaries\ru.json`
    - `diaweb\frontend\modules\i18n\dictionaries\en.json`
    - `diaweb\frontend\modules\i18n\types.ts`
    - `diaweb\frontend\__tests__\modules\factory\FactoryHotspotLayer.test.tsx`
  - Deliverable:
    - Resource ruins show `Руины. Тап чтобы построить` when build action is available.
    - Locked production ruins show `Доступно с уровня N фабрики`.
    - Resource active state shows resource part level and production rate text.
    - Building/upgrade states show timer/progress when backend provides construction timing.
    - Ready production state shows collect action, routed to warehouse for now as previously requested.
    - Remove any misleading `Недоступно` wording when a more specific lock reason exists.
  - Logging:
    - Add DEBUG only for unexpected state combinations, e.g. no action and no lock reason for a visible ruin.
    - Avoid logging every rendered building on every render.
  - Dependencies:
    - Depends on Tasks 1-2 and 6.

- [x] Task 8: Align A1 header and map actions with the designer brief.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryScene.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryInventoryDrawer.tsx`
    - `diaweb\frontend\modules\factory\components\FactorySubscriptionIndicator.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryUpgradeDialog.tsx`
    - `diaweb\frontend\modules\i18n\dictionaries\ru.json`
    - `diaweb\frontend\modules\i18n\dictionaries\en.json`
  - Deliverable:
    - Header text is two lines: `Фабрика` and `Уровень N`, no extra badge/pill.
    - Keep inventory and subscription entry points as compact icon actions.
    - Keep buy-next-level action visible only when applicable and absent at level 8.
    - Ensure modal z-index consistently sits above the map and A2 bubbles.
  - Logging:
    - No new logs for static header rendering.
    - Keep existing mutation logs for upgrade/inventory actions.
  - Dependencies:
    - Depends on Tasks 5 and 7.

- [x] Task 9: Re-check A5/A6/A7 screen templates against the corrected state model.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\ResourceWorkshopScreen.tsx`
    - `diaweb\frontend\modules\factory\components\ProductionWorkshopScreen.tsx`
    - `diaweb\frontend\modules\factory\components\CompartmentScreen.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryBackArrow.tsx`
    - `diaweb\frontend\__tests__\modules\factory\ResourceWorkshopScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\ProductionWorkshopScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\CompartmentScreen.test.tsx`
  - Deliverable:
    - Keep simplified headers: title only, no workshop type badge, no subscription pill, no decorative ruins icon.
    - Resource card secondary line shows resource-part level, not duplicate build status.
    - Output text uses compact format like `0,3204 ДНК-капсулы/сутки`.
    - Back control remains icon-only arrow.
    - Help question icons always open modal dialogs, not inline text panels.
  - Logging:
    - Preserve command/mutation logs through hooks.
    - Add no logs for presentational text changes.
  - Dependencies:
    - Depends on Tasks 2 and 7.

### Phase 4 - Level Upgrade, Warehouse, And Onboarding Pass

- [x] Task 10: Align A3/A4 warehouse and level-upgrade surfaces after map changes.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryWarehouseScreen.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryUpgradeDialog.tsx`
    - `diaweb\frontend\modules\factory\assetManifest.ts`
    - `diaweb\frontend\__tests__\modules\factory\FactoryWarehouseScreen.test.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryUpgradeDialog.test.tsx`
  - Deliverable:
    - Warehouse screen has no subscription pill in the header.
    - Level-upgrade dialog uses uploaded level 2/3 preview images as large decorative previews, not as actual maps.
    - Copy says `Переход на уровень N`.
    - Requirements/costs remain backend-driven.
  - Logging:
    - Preserve existing upgrade mutation logs.
    - Add no logs for preview rendering.
  - Dependencies:
    - Depends on Tasks 4 and 8.

- [x] Task 11: Re-anchor A18 onboarding to the corrected map.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryOnboardingOverlay.tsx`
    - `diaweb\frontend\modules\factory\components\FactoryOnboardingOverlay.module.css`
    - `diaweb\frontend\modules\factory\components\FactoryHotspotLayer.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryOnboardingOverlay.test.tsx`
  - Deliverable:
    - Onboarding targets align with warehouse, first buildable resource workshop, and level-upgrade action after coordinate recalibration.
    - Overlay does not block bottom nav unless the current step requires it.
    - Text remains concise and does not duplicate visible UI labels.
  - Logging:
    - Keep existing onboarding completion mutation logs.
    - Add DEBUG only if target lookup fails and fallback placement is used.
  - Dependencies:
    - Depends on Tasks 6-8.

### Phase 5 - Verification, Sync, And Commit Prep

- [x] Task 12: Run targeted backend tests for factory state, build, subscriptions, and warehouse/craft regressions.
  - Files/paths:
    - `diaverseapi`
  - Deliverable:
    - Run targeted pytest for:
      - `app\factory\tests\test_state_service.py`
      - `app\factory\tests\test_building_service.py`
      - `app\factory\tests\test_subscriptions.py`
      - `app\factory\tests\test_warehouse_service.py`
      - `app\factory\tests\test_crafting_service.py`
    - Run migration checks only if Task 2 introduces schema/data migrations.
  - Logging:
    - Verification should not add runtime logs.
    - Capture concise pass/fail notes in implementation summary.
  - Dependencies:
    - Depends on Tasks 2-3.

- [x] Task 13: Run targeted frontend tests for factory map and screens.
  - Files/paths:
    - `diaweb`
  - Deliverable:
    - Run targeted tests for changed factory components and cabinet layout.
    - Run type/lint checks using the repo's existing package manager scripts.
    - Do not run browser/manual verification unless the user explicitly permits it.
  - Logging:
    - Verification should not add runtime logs.
    - Test output should be summarized briefly during implementation.
  - Dependencies:
    - Depends on Tasks 5-11.

- [x] Task 14: Sync local knowledge and prepare per-repo commit notes.
  - Files/paths:
    - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
    - changed `diaweb` and `diaverseapi` files
  - Deliverable:
    - Run targeted GBrain sync for changed sources after implementation:
      - `diaverseapi-code` if backend changed.
      - `diaweb-code` if frontend changed.
    - Prepare conventional commit messages grouped by repository.
    - Leave root repo changes limited to this plan and any daily-work entry required by workspace rules.
  - Logging:
    - Use existing script logging only.
    - Do not commit generated runtime state unless it is intentionally tracked.
  - Dependencies:
    - Depends on Tasks 12-13.

## Verification Plan

Run from `C:\Users\Indigo\Desktop\diaverse\diaverseapi` when backend files change:

```powershell
.\.venv\Scripts\python.exe -m pytest app\factory\tests\test_state_service.py app\factory\tests\test_building_service.py app\factory\tests\test_subscriptions.py app\factory\tests\test_warehouse_service.py app\factory\tests\test_crafting_service.py
```

Run from `C:\Users\Indigo\Desktop\diaverse\diaweb` when frontend files change, using the repo's actual package manager/script names:

```powershell
npm test -- FactoryScene FactoryHotspotLayer ResourceWorkshopScreen ProductionWorkshopScreen CompartmentScreen FactoryWarehouseScreen FactoryUpgradeDialog FactoryOnboardingOverlay CabinetLayout
npm run lint
```

Run from `C:\Users\Indigo\Desktop\diaverse` after implementation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaweb-code
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverseapi-code
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-health.ps1
```

Browser/manual verification is intentionally excluded from this fast plan because the user previously asked not to verify. Add it only if explicitly requested later.

## Commit Plan

- **Commit 1** (after Tasks 1-3, `diaverseapi` if changed): `fix(factory): align level one state contract`
- **Commit 2** (after Tasks 4-8, `diaweb`): `fix(factory): rebuild level one map scene`
- **Commit 3** (after Tasks 9-11, `diaweb`): `fix(factory): align workshop and upgrade screens`
- **Commit 4** (after Tasks 12-14, per affected repo): `test(factory): cover level one factory flow`

## Rollback Plan

- Revert `diaweb` commits that change factory assets, map coordinates, scene layout, or screen templates.
- Revert `diaverseapi` commits that change factory state/build/subscription semantics.
- If a backend migration is introduced and reaches an environment, use a deliberate corrective migration instead of manual production mutation.
- Restore the previous `assetManifest.ts` entries only as a temporary rollback; do not keep placeholder coordinates as the final state.

## Next Step

Run `/aif-implement` from `C:\Users\Indigo\Desktop\diaverse` when ready to execute this fast plan.
