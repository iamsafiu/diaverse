# Implementation Plan: Factory Map Inventory And Resource UI Cleanup

Created: 2026-05-28
Mode: AIF fast plan, workspace root, no branch changes
Branch: none
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: yes - include targeted frontend tests for factory inventory browse/selection split, map resource strip, minimal bubbles, and border progress. Include a small backend/unit assertion if the game-dollar asset metadata changes.
- Logging: standard - do not add render-loop logs; keep existing factory client warnings for unexpected icons/unknown states and backend logs unchanged unless an existing warning path needs a clearer message.
- Docs: no - warn-only docs checkpoint; no feature docs update unless the contract changes beyond UI/resource asset presentation.
- Roadmap Linkage: none, no non-empty `.ai-factory\ROADMAP.md` found.
- Knowledge: local GBrain searched first and returned no hits for the factory UI/resource queries; exact behavior was verified from raw docs/source. Run targeted GBrain sync for `diaweb-code` and `diaverseapi-code` after implementation.

## Research Context

Source: `.ai-factory\RESEARCH.md` Active Summary

- Goal: Use the workspace root as the shared AIF control plane over `diaweb`, `diaverseapi`, `aibot`, and `club10000-bot`.
- Constraints: child repositories remain separate; product code changes belong inside child repositories; source code is the final authority.
- Decision: keep one top-level plan for workspace-run work and sync local GBrain sources after meaningful code changes.

## Goal

Clean up the factory inventory and map UI while preserving the mixed-entity recipe selection flow:

- Hide pet fragments and pets from normal factory inventory browsing.
- Keep concrete fragments and pets available in material selection mode for recipes that require selected `shard_id` or `user_character_id`.
- Under `Фабрика / Уровень 1` on the map, show a compact resource row with only icon + amount for `xdv`, `game_dollar`, `brick`, `impulse`, and `slot_token`.
- Fix the game-dollar icon so it uses the `game_balance_usd`/`dollar.webp` visual, not the XDV icon.
- Minimalize map bubbles by removing verbose texts like `Уровень 1. Добывает ...` and `Руины. Тап чтобы построить`.
- Replace inner progress bars on map bubbles with a visible clockwise border progress indicator for construction, upgrades, and running production.

## Current Findings

- Mechanics doc confirms resource workshops accrue to warehouse continuously, can be collected any time, and stop after 10 hours if not collected: `docs\tasks\fabric\factory-mechanics-final.md`.
- Backend already accrues warehouse balances lazily by elapsed time, caps at `cap_hours = 10`, marks stopped, and resets `last_accrual_at` after transfer-to-storage.
- `FactoryInventoryDrawer` currently browses all non-warehouse user inventory balances, so concrete `shard:*` and `user_character:*` rows appear in browse mode.
- `FactoryInventoryDrawer` also powers material selection; hiding fragments/pets globally would break recipe selection, so filtering must be mode-aware.
- `assetManifest.ts` currently maps `factory.icon.game_dollar` to `/factory/resources/xdv.svg`.
- Backend Advent reward metadata maps `game_balance_usd` to `dollar.webp`; factory resource assets currently expose `game_dollar` only with `visual_key="factory.icon.game_dollar"`.
- Map bubble text is built in `FactoryHotspotLayer.tsx`; active bubbles include `Уровень N. Добывает ...`, and ruins bubbles include `Руины. Тап чтобы построить`.
- `BuildingInfoBubble` renders progress as an inner horizontal fill; `factoryScene.module.css` already has a spinner for upgrade but not a percentage border.

## Non-Goals

- Do not change factory crafting semantics or backend inventory debit/credit logic.
- Do not remove fragments or pets from recipe material pickers.
- Do not change the 10-hour warehouse cap unless source verification later shows a backend defect.
- Do not redesign full workshop/detail screens beyond the map bubble progress presentation required here.
- Do not create branches in fast mode.

## Repository Matrix

| Repository | Path | Affected | Branch changes | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan only | none | Stores this fast plan and daily entry |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | none | Factory inventory drawer, map header resource strip, icon resolver/manifest, bubble UI/tests |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes, small | none | Factory game-dollar asset metadata if needed |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | none | Not affected |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | none | Not affected |

## Tasks

### Phase 1 - Inventory Browse/Selection Split

- [x] Task 1: Make factory inventory browse mode hide fragments and pets while keeping material selection intact.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryInventoryDrawer.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryInventoryDrawer.test.tsx`
  - Deliverable:
    - In `mode="browse"`, hide concrete `shard:*`, aggregate shard rows, and `user_character:*` pet rows from visible inventory categories.
    - In `mode="select"`, keep existing compatible concrete balances visible and selectable for recipe requirements.
    - Preserve slot tokens, token details, resources, EvoGens, mutagens, synthesis cores, nullifiers, biomass, and other production products in browse mode.
    - Add tests proving browse mode excludes fragments/pets but selection mode still shows and selects concrete material balances.
  - Logging:
    - Add no new render logs.
    - Keep the existing `logFactoryClientWarning` paths for incompatible/insufficient/concrete-selection failures.
    - If a hidden browse item is also unexpectedly selectable in browse mode, do not log per render; cover that with tests.
  - Dependencies:
    - None.

### Phase 2 - Map Header Resource Strip And Icons

- [x] Task 2: Add compact factory resource balances under the map title/level.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryShell.tsx`
    - `diaweb\frontend\modules\factory\iconResolver.ts`
    - `diaweb\frontend\__tests__\modules\factory\FactoryShell.test.tsx`
  - Deliverable:
    - Under `Фабрика` and `Уровень N`, render a single compact row of icon + formatted amount for `xdv`, `game_dollar`, `brick`, `impulse`, and `slot_token`.
    - Use `state.balances` as the source and render zero only if the current state explicitly has zero; otherwise use the existing empty value behavior if a balance is missing.
    - Keep the row unframed: no cards, no pлашки, no labels unless required for accessible `aria-label`.
    - Ensure text/numbers do not overlap on mobile widths.
  - Logging:
    - Add no new presentational logs.
    - Use an existing client warning only if an expected balance kind cannot resolve an icon in development/test paths.
  - Dependencies:
    - Depends on Task 1 only if shared balance helpers are extracted; otherwise independent.

- [x] Task 3: Fix XDV/game-dollar icon resolution.
  - Files/paths:
    - `diaverseapi\app\factory\services\resource_assets.py`
    - `diaweb\frontend\modules\factory\assetManifest.ts`
    - `diaweb\frontend\modules\factory\iconResolver.ts`
    - `diaweb\frontend\__tests__\modules\factory\factory-api.test.ts`
    - `diaweb\frontend\__tests__\modules\factory\FactoryShell.test.tsx`
  - Deliverable:
    - Make `game_dollar` resolve to the same visual entity as `game_balance_usd`, using backend static `dollar.webp` where possible.
    - Keep XDV on its own XDV icon.
    - Avoid using `/factory/resources/xdv.svg` as the fallback for `factory.icon.game_dollar`.
    - Add test coverage for distinct `xdv` and `game_dollar` icon sources.
  - Logging:
    - Backend: no new INFO logs; if asset metadata is missing, rely on existing factory state warnings rather than per-request logs.
    - Frontend: add no runtime logs unless icon resolution falls through to an unknown visual key in development.
  - Dependencies:
    - Independent, but should land before Task 2 verification.

### Phase 3 - Minimal Map Bubbles And Border Progress

- [x] Task 4: Minimalize factory map bubble copy.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\FactoryHotspotLayer.tsx`
    - `diaweb\frontend\__tests__\modules\factory\FactoryScene.test.tsx`
    - `diaweb\frontend\modules\i18n\dictionaries\ru.json`
    - `diaweb\frontend\modules\i18n\dictionaries\en.json`
  - Deliverable:
    - Active resource/workshop bubbles should not show `Уровень N. Добывает ...` or equivalent verbose production copy.
    - Ruins/locked bubbles should not show `Руины. Тап чтобы построить` / `Ruins. Tap to build`.
    - Keep the title and a short state only: active/ready/building/upgrade/repair/cooldown/locked/ruins.
    - Keep accessibility labels meaningful even when visible copy is minimal.
  - Logging:
    - Add no new logs.
    - Preserve existing development warnings for missing scene mappings or unknown visual keys.
  - Dependencies:
    - None.

- [x] Task 5: Replace map bubble inner progress bar with visible clockwise border progress.
  - Files/paths:
    - `diaweb\frontend\modules\factory\components\BuildingInfoBubble.tsx`
    - `diaweb\frontend\modules\factory\components\factoryScene.module.css`
    - `diaweb\frontend\__tests__\modules\factory\FactoryScene.test.tsx`
  - Deliverable:
    - For construction, upgrade, and running production, render progress around the bubble border using `progressPercent`.
    - The border progress must be visibly thick enough on mobile and desktop and move clockwise from the top.
    - Remove or hide the inner horizontal progress track on map bubbles.
    - Continue to show timer/status text; progress remains `aria-hidden` visually while the bubble keeps an accessible status label.
    - Respect reduced motion where existing animation patterns do.
  - Logging:
    - Add no logs; this is pure presentation.
    - Use tests/class assertions for progress style state rather than runtime diagnostics.
  - Dependencies:
    - Depends on Task 4 for final bubble copy shape.

### Phase 4 - Verification And Knowledge Sync

- [x] Task 6: Run targeted verification and sync changed knowledge sources.
  - Files/paths:
    - `diaweb`
    - `diaverseapi`
    - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
  - Deliverable:
    - Run targeted frontend tests for factory shell, scene, inventory drawer, and API/icon behavior.
    - Run targeted backend tests only if `resource_assets.py` or related backend schemas are changed.
    - Run `npm run lint` in `diaweb` if available and the UI changes touch TypeScript/React/CSS.
    - Run targeted GBrain sync for `diaweb-code` and `diaverseapi-code` after implementation.
  - Logging:
    - Verification should not add runtime logs.
    - Summarize failures by command and first failing assertion during implementation.
  - Dependencies:
    - Depends on Tasks 1-5.

## Verification Plan

Run from `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend` after frontend changes, using the repo's actual scripts:

```powershell
npm test -- FactoryInventoryDrawer FactoryShell FactoryScene factory-api
npm run lint
```

If backend factory resource asset metadata changes, run from `C:\Users\Indigo\Desktop\diaverse\diaverseapi`:

```powershell
.\.venv\Scripts\python.exe -m pytest app\factory\tests\test_state_service.py app\factory\tests\test_inventory_gateway.py
```

Run from `C:\Users\Indigo\Desktop\diaverse` after implementation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaweb-code
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverseapi-code
```

## Commit Plan

- **Commit 1** (after Tasks 1-3, `diaweb` + small `diaverseapi` if needed): `fix(factory): clean inventory resources and currency icons`
- **Commit 2** (after Tasks 4-6, `diaweb`): `fix(factory): simplify map bubbles and progress`

## Rollback Plan

- Revert `diaweb` changes to `FactoryInventoryDrawer`, `FactoryShell`, `FactoryHotspotLayer`, `BuildingInfoBubble`, and related CSS/tests.
- Revert the `diaverseapi` resource asset metadata change if `game_dollar` backend icon metadata causes unexpected static asset behavior.
- No data migration or inventory repair should be required because this plan changes presentation and asset metadata only.

## Next Step

Run `$aif-implement` from `C:\Users\Indigo\Desktop\diaverse` when ready to execute this fast plan.
