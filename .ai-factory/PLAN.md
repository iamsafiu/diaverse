# Implementation Plan: Raid Mechanics Clarity UI

Created: 2026-05-30
Mode: AIF fast plan, workspace root, no branch changes
Branch: none
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: quick targeted checks only; add/adjust frontend tests if helper math or rendered labels become non-trivial.
- Logging: standard; keep existing raid UI logs, add only discrete dev logs for info-panel tab changes if useful.
- Docs: no mandatory docs checkpoint for this fast UI iteration.
- Roadmap Linkage: none, `.ai-factory\ROADMAP.md` not found.
- Constraint: do not change raid mechanics, formulas, prices, rewards, trap rules, or DCR/game-dollar decisions.
- Constraint: keep the current composition: full-screen raid map plus persistent bottom slots sheet. Do not turn the map into a table page.

## Goal

Make raid mechanics understandable in the mobile UI without overloading the map:

```text
map = emotional location choice
bottom sheet = working area and mechanics explanation
dispatch step = exact cost/risk/reward confirmation
result modal = formulas that teach what happened
```

The player should understand:

- why this location is useful;
- why this pet is a good or bad match;
- what "bonus series" does;
- how Base / Subscription / USDT differ;
- what rewards and risks apply before sending a pet;
- why trap ransom and final rewards have those numbers.

## Current Findings

- `diaweb\frontend\modules\raids\components\RaidLocationCard.tsx` currently shows only location title and entry price on the island.
- `RaidSlotsSheet.tsx` is now the main persistent bottom sheet with `slots`, `pets`, and `dispatch` steps.
- `RaidDispatchStep.tsx` already compares modes but does not show enough reward context.
- `RaidPetCard.tsx` already has pet rarity, price, image, matching bonus label, and availability.
- `RaidResultModal.tsx` displays rewards but does not explain formulas.
- `diaverseapi\app\raids\services\state_service.py` currently sends location `effective_chance_percent` calculated for `basic_xdv`, not for every selected mode.

## UX Decisions

- Rename visible "Стрик" to "Бонус серии" in user-facing raid UI.
- Show compact map badges, not large panels, on biome islands.
- Add a location briefing inside the bottom sheet after a location is selected.
- Add a segmented subview in the sheet: `Слоты` / `Разведка` / `Награды`.
- Use formulas sparingly and only where they explain a decision:
  - `+1% за пэта сюда`
  - `60% x серия 1.35 = 81%`
  - `выкуп = 3 x цена входа`
- For switching locations, warn when the selected start will reset another active bonus series.

## Repository Matrix

| Repository | Path | Affected | Branch changes | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan only | none | Stores this fast plan |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | none | Raid mobile UI and copy |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | maybe | none | Only if frontend needs mode-specific calculated chances from API |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | none | Not affected |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | none | Not affected |

## Tasks

### Phase 1 - Display Model

- [x] Task 1: Create raid UI mechanics display helpers.
  - Files/paths:
    - new optional `diaweb\frontend\modules\raids\mechanicsDisplay.ts`
    - `diaweb\frontend\modules\raids\types.ts`
  - Deliverable:
    - Centralize formatting for bonus series, trap risk, mode duration, mode multipliers, entry price, matching rarity, and reward formulas.
    - Prefer existing backend state/catalog data. Use frontend constants only for stable display labels already fixed by the mechanics contract: XP x1/x2/x5, chest x1/x2/x4, duration labels.
    - Add helper to detect whether starting in selected location resets another active bonus series.
  - Logging:
    - No runtime logs in pure helpers.
  - Dependencies:
    - None.

### Phase 2 - Map Badges

- [x] Task 2: Add compact mechanic badges to biome islands without adding large plates.
  - Files/paths:
    - `diaweb\frontend\modules\raids\components\RaidLocationCard.tsx`
    - `diaweb\frontend\modules\raids\components\raidShell.module.css`
    - `diaweb\frontend\modules\i18n\dictionaries\ru.json`
    - `diaweb\frontend\modules\i18n\dictionaries\en.json`
    - `diaweb\frontend\modules\i18n\types.ts`
  - Deliverable:
    - Show small island badges: `+N% серия`, trap risk for current/default XDV mode, and short XDV price.
    - Keep Russian location names and current island placement.
    - Do not add full cards or opaque name plates over the island art.
  - Logging:
    - No new logs.
  - Dependencies:
    - Depends on Task 1 helpers where useful.

### Phase 3 - Bottom Sheet Briefing

- [x] Task 3: Add selected-location briefing and sheet subviews.
  - Files/paths:
    - `diaweb\frontend\modules\raids\components\RaidSlotsSheet.tsx`
    - optional new `diaweb\frontend\modules\raids\components\RaidLocationBriefing.tsx`
    - optional new `diaweb\frontend\modules\raids\components\RaidRewardPreview.tsx`
    - `diaweb\frontend\modules\raids\components\raidShell.module.css`
    - i18n files under `diaweb\frontend\modules\i18n\`
  - Deliverable:
    - In the sheet header/body, show selected location summary:
      - role/purpose of location;
      - `Бонус серии +N% / cap`;
      - progress meter;
      - "влияет: ресурсы и шкатулки; не влияет: XP, цена, ядра, токены".
    - Add subview control: `Слоты` / `Разведка` / `Награды`.
    - `Разведка` shows location traits: best pet rarity, primary resource, trap risk, crit, Oasis discount, special loot availability.
    - `Награды` shows current reward preview: resources, chest chances, special loot zero/available state.
  - Logging:
    - Optional dev-only `console.debug("[raids.ui] info tab changed", { tab })`.
    - Do not log scroll/drag events.
  - Dependencies:
    - Depends on Task 1.

### Phase 4 - Pet And Dispatch Explanation

- [x] Task 4: Make pet cards and dispatch step explain the actual decision.
  - Files/paths:
    - `diaweb\frontend\modules\raids\components\RaidPetCard.tsx`
    - `diaweb\frontend\modules\raids\components\RaidDispatchStep.tsx`
    - `diaweb\frontend\modules\raids\components\raidShell.module.css`
    - i18n files under `diaweb\frontend\modules\i18n\`
  - Deliverable:
    - Pet card shows why it fits or does not fit:
      - matching pet: `Подходит: +50% XP`, base/better price;
      - non-matching pet: `Нет XP-бонуса`, `цена x2/x3` when applicable.
    - Dispatch mode cards show:
      - price;
      - duration;
      - trap risk;
      - XP multiplier;
      - chest multiplier;
      - slot compatibility/lock reason.
    - Selected mode summary shows predicted key rewards for selected location + pet + mode.
    - If a different location currently owns the bonus series, show reset warning before sending.
  - Logging:
    - Preserve existing `dispatch mode selected`, command submitted/result/failure logs.
    - No additional noisy render logs.
  - Dependencies:
    - Depends on Tasks 1 and 3.

### Phase 5 - Traps And Results Teaching Moments

- [x] Task 5: Explain trap ransom and reward formulas where the player sees outcomes.
  - Files/paths:
    - `diaweb\frontend\modules\raids\components\RaidTrapCard.tsx`
    - `diaweb\frontend\modules\raids\components\RaidResultModal.tsx`
    - `diaweb\frontend\modules\raids\components\raidShell.module.css`
    - i18n files under `diaweb\frontend\modules\i18n\`
  - Deliverable:
    - Trap card shows `выкуп = 3 x цена входа` and rescue risk `50%, при провале спасатель застрянет`.
    - Result modal shows compact formulas for XP, resources, chests, crit, and special loot zero states.
    - Make result screen feel like a payoff, not a raw list.
  - Logging:
    - No new logs.
  - Dependencies:
    - Depends on Task 1 helpers where useful.

### Phase 6 - Optional API Support And Verification

- [x] Task 6: Add minimal backend support only if frontend cannot accurately calculate selected-mode reward preview from existing data.
  - Files/paths if needed:
    - `diaverseapi\app\raids\schemas.py`
    - `diaverseapi\app\raids\services\state_service.py`
    - `diaverseapi\app\raids\tests\test_state_service.py`
    - `diaweb\frontend\modules\raids\types.ts`
  - Deliverable:
    - Prefer no backend change.
    - If needed, expose mode-specific effective chest chances, e.g. `effective_chance_percent_by_mode`.
    - Keep response backwards-compatible.
  - Logging:
    - Backend: no extra logs for pure read-shape calculation.
  - Dependencies:
    - Depends on Task 4 discovering a real data gap.

- [x] Task 7: Run quick verification.
  - Files/paths:
    - `diaweb`
    - `diaverseapi` only if Task 6 is used
  - Deliverable:
    - Run targeted frontend checks available in the repo for raids components.
    - If backend was changed, run targeted raids state tests or compile check.
    - Do not start a local dev server unless the user explicitly asks.
    - Manually reason through mobile layout: no text overlap, no map composition drift, sheet remains usable.
  - Logging:
    - Remove or reduce any noisy logs found during verification.
  - Dependencies:
    - Depends on implementation tasks.

## Verification Plan

Default quick checks:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb
```

Use the repo's existing targeted frontend test/lint commands for raid modules if available.

If backend Task 6 is needed:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
python -m compileall app\raids
python -m pytest app\raids\tests\test_state_service.py -q
```

If `pytest` is unavailable locally, record that limitation in the final answer.

## Commit Plan

- Commit 1 after Tasks 1-3: `feat(raids): add location briefing and reward preview`
- Commit 2 after Tasks 4-7: `feat(raids): clarify dispatch rewards and trap outcomes`

## Next Step

Run `$aif-implement` to execute this fast plan.
