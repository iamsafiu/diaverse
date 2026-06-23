# Implementation Plan: Raid Pet Reward Abilities

Branch: none (fast mode; use current child-repo branches before implementation)
Created: 2026-06-23

## Settings

- Testing: yes. Raid rewards, entry prices, trap immunity, and catalog economy are gameplay-critical and must be locked by tests.
- Logging: verbose. Use DEBUG for sanitized decision snapshots, INFO for successful user-facing state changes, WARN for blocked actions, and ERROR only for unexpected failures.
- Docs: yes. Update raid product docs after implementation because the supported pet bonus model and location reward tables change.

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain was used first during raid exploration; exact planning is based on raw source verification.
- Primary affected repositories: `diaverseapi`, `diaweb`
- Verification-only repository: `diaverse-mobile`
- Root workspace affected: this plan, raid docs under `docs/`, daily log after implementation, and targeted GBrain sync after changes.
- Explicitly out of scope: new raid locations, new pet kinds, DB migrations unless implementation proves a resource type is missing, unrelated repos, and changing non-XDV payment semantics without product approval.

## Repository Matrix

| Repository | Path | Affected | Current branch | Current status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `main` | clean at planning | backend raid catalog, reward rolls, pricing, trap immunity, tests |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `master` | clean at planning | raid UI types, previews, pet bonus display |
| `diaverse-mobile` | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | verify only | `main` | clean at planning | confirm shared backend raid contracts are not broken |
| `diaverse` root | `C:\Users\Indigo\Desktop\diaverse` | yes | `dev` | dirty before planning | coordination plan/docs only; preserve unrelated existing changes |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | not checked in this fast plan | not checked | out of scope |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | not checked in this fast plan | not checked | out of scope |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | not checked in this fast plan | not checked | out of scope |

## Research Context

Current implementation facts:
- Raid backend source of truth is `diaverseapi/app/raids/catalog/data/raids_catalog.v1.yaml`.
- Existing catalog has three pet abilities only: `jetboa`/Jerboa for `rusty_wastelands`, `capybara` for `oasis`, and `badger` for `radioactive_cave`.
- Existing pet abilities combine `trap_immunity` with fixed `chest_chance_multiplier` values; those fixed chest multipliers must be replaced with the new level-scaled bonus.
- Reward rolls are implemented in `diaverseapi/app/raids/domain/rewards.py`; XDV/USDT entry prices are in `diaverseapi/app/raids/domain/pricing.py`; trap immunity is in `diaverseapi/app/raids/domain/traps.py`.
- State assembly exposes pet prices and `metadata.trap_immunity_locations` from `diaverseapi/app/raids/services/state_service.py`.
- Web raid UI consumes these contracts through `diaweb/frontend/modules/raids/types.ts`, `mechanicsDisplay.ts`, and raid components.
- Current location base resources already include `bullet`, `galaglue`, and `nuclear_acorn`; they do not include `gear`, `xp_capsule`, `brick`, or `dna_capsule`.
- Current pet-kind spellings to preserve in this scope: `jetboa` for Тушканчик and `bobr` for Бобер.
- The current `.ai-factory/RESEARCH.md` Active Summary is unrelated factory map research and is not carried into this raid plan.

Product decisions captured from the request:
- Every mapped raid pet gets a bonus in its own location.
- The bonus affects only the entity assigned to that pet: a specific resource, chest chance, trap immunity, or XDV entry cost.
- Max level 70 bonus is `x2` for reward entities; combat free-entry pets reach 100% XDV entry discount at level 70.
- Growth must happen every pet level, not only every 10 levels.
- Missing assigned resources must be added to base location rewards so the pet bonus has a base quantity to multiply.

## Pet Ability Map

| Location | Pet kind | Pet | Assigned entity | Effect |
| --- | --- | --- | --- | --- |
| `rusty_wastelands` | `meerkat` | Сурикат | `bullet` | multiply bullet quantity by level bonus |
| `rusty_wastelands` | `jetboa` | Тушканчик | chests + traps | multiply chest chances by level bonus; keep binary trap immunity in wastelands |
| `rusty_wastelands` | `rhinoceros` | Носорог | XDV entry price | apply progressive XDV discount; level 70 is free |
| `oasis` | `octopus` | Осьминог | `gear` | multiply gear quantity by level bonus |
| `oasis` | `hyena` | Гиена | `galaglue` | multiply galaglue quantity by level bonus |
| `oasis` | `capybara` | Капибара | chests + traps | multiply chest chances by level bonus; keep binary trap immunity in oasis |
| `oasis` | `hippo` | Бегемот | XDV entry price | apply progressive XDV discount; level 70 is free |
| `radioactive_cave` | `pig` | Свинка | `xp_capsule` | multiply XP capsule quantity by level bonus |
| `radioactive_cave` | `bobr` | Бобер | `brick` | multiply brick quantity by level bonus |
| `radioactive_cave` | `rat` | Крыса | `dna_capsule` | multiply DNA capsule quantity by level bonus |
| `radioactive_cave` | `warthog` | Бородавочник | `nuclear_acorn` | multiply nuclear acorn quantity by level bonus |
| `radioactive_cave` | `badger` | Барсук | chests + traps | multiply chest chances by level bonus; keep binary trap immunity in caves |
| `radioactive_cave` | `elephant` | Слон | XDV entry price | apply progressive XDV discount; level 70 is free |

Base reward additions:
- `oasis`: add `gear`.
- `radioactive_cave`: add `xp_capsule`, `brick`, and `dna_capsule`.
- `bullet`, `galaglue`, and `nuclear_acorn` are already present and should not be duplicated.
- Exact min/max quantities for new base resources are a balance decision. If product does not provide final numbers before implementation, use explicit conservative secondary-resource values in the catalog and mark them in docs for later economy tuning.

## Bonus Formula

Use one shared helper for all level-scaled effects:
- Clamp pet level to `1..70`; missing/invalid level behaves as level 1.
- Anchor multipliers: level 1 `1.00`, 10 `1.01`, 20 `1.04`, 30 `1.10`, 40 `1.21`, 50 `1.38`, 60 `1.62`, 70 `2.00`.
- Between anchors, compute every integer level through monotonic log-space interpolation with easing:
  `multiplier = exp(lerp(log(anchor_a), log(anchor_b), smoothstep(t)))`, where `t = (level - level_a) / (level_b - level_a)` and `smoothstep(t) = t * t * (3 - 2 * t)`.
- This keeps the user-provided anchor values exact while still giving progressive per-level growth between them.
- For resource and chest effects, use `multiplier` directly.
- For combat free-entry pets, use `discount_percent = (multiplier - 1) * 100`, capped to `0..100`; level 70 becomes 100% XDV discount.

## Commit Plan

- **Commit 1** (`diaverseapi`): `feat(raids): add level-scaled pet ability catalog`
- **Commit 2** (`diaverseapi`): `feat(raids): apply pet bonuses to rewards and pricing`
- **Commit 3** (`diaweb`): `feat(raids): show raid pet bonuses`
- **Commit 4** (`diaverseapi`, `diaweb`, root docs if changed): `test(raids): cover raid pet bonus model`
- **Commit 5** (root docs): `docs(raids): document raid pet rewards`

## Tasks

### Phase 1: Backend Catalog And Formula

- [x] Task 1: Extend the raid pet ability catalog model.
  - Files: `diaverseapi/app/raids/catalog/schema.py`, `diaverseapi/app/raids/catalog/data/raids_catalog.v1.yaml`, `diaverseapi/app/raids/tests/test_catalog.py`.
  - Deliverable: replace the narrow `chest_chance_multiplier`-only model with an ability contract that can express `resource_type`, `chest_bonus`, `trap_immunity`, and `entry_discount` effects by `pet_kind` and `location_key`.
  - Expected behavior: all 13 mapped pets exist exactly once for their location; ability location rarity still matches the location's `matching_pet_rarity`; current `jetboa` and `bobr` spellings are preserved.
  - Logging requirements: no runtime logs for static schema changes; catalog validation errors must include ability key, pet kind, location, and failing field through existing loader/validation exception paths.
  - Dependencies: none.

- [x] Task 2: Add missing assigned resources to base location rewards.
  - Files: `diaverseapi/app/raids/catalog/data/raids_catalog.v1.yaml`, `diaverseapi/app/raids/tests/test_catalog.py`.
  - Deliverable: add `gear` to `oasis.resources`, and `xp_capsule`, `brick`, `dna_capsule` to `radioactive_cave.resources`; keep existing `bullet`, `galaglue`, and `nuclear_acorn` resources intact.
  - Expected behavior: every resource-target pet has a base resource row in its location; catalog tests assert no duplicate resource rows per location and assert explicit min/max quantities.
  - Logging requirements: no runtime logs; catalog validation/test failures must identify the missing or duplicated resource type and location.
  - Dependencies: task 1 for any catalog validation helper changes.

- [x] Task 3: Implement the shared pet-level bonus helper.
  - Files: `diaverseapi/app/raids/domain/pet_abilities.py` or `diaverseapi/app/raids/domain/rewards.py`, `diaverseapi/app/raids/tests/test_domain_rules.py`.
  - Deliverable: add a pure helper that clamps levels, returns exact anchor multipliers, interpolates each level between anchors, and returns the derived entry discount percent for combat pets.
  - Expected behavior: level 1 is `1.00`, level 70 is `2.00`, requested anchor levels match exactly, intermediate levels are monotonic and non-flat at full precision.
  - Logging requirements: helper remains side-effect free and does not log; callers log selected effect, level, multiplier, and discount at DEBUG.
  - Dependencies: task 1.

### Phase 2: Backend Runtime Behavior

- [x] Task 4: Apply resource and chest bonuses during reward settlement.
  - Files: `diaverseapi/app/raids/domain/rewards.py`, `diaverseapi/app/raids/services/settlement_service.py`, `diaverseapi/app/raids/tests/test_domain_rules.py`, `diaverseapi/app/raids/tests/test_settlement_service.py`.
  - Deliverable: resource-target pets multiply only their assigned resource quantity; chest-target pets multiply all chest chances in their location using the level helper; old fixed `x2/x2.5/x3` chest multipliers are removed.
  - Expected behavior: bonuses stack with existing streak/mode mechanics in a documented order; Pig affects `xp_capsule` resource rewards only and does not change raid XP; unmapped pets and wrong-location pets get no ability bonus.
  - Logging requirements: DEBUG settlement snapshot with sanitized user/profile id, raid id, location, pet kind, pet level, effect type, base quantity/chance, multiplier, and final quantity/chance; do not log random seeds or sensitive payment data.
  - Dependencies: tasks 1-3.

- [x] Task 5: Apply combat-pet free-entry discount to XDV raid pricing.
  - Files: `diaverseapi/app/raids/domain/pricing.py`, `diaverseapi/app/raids/services/command_service.py`, `diaverseapi/app/raids/services/payment_service.py`, `diaverseapi/app/raids/services/trap_service.py`, `diaverseapi/app/raids/services/state_service.py`, `diaverseapi/app/raids/tests/test_command_start.py`, `diaverseapi/app/raids/tests/test_domain_rules.py`, `diaverseapi/app/raids/tests/test_state_service.py`.
  - Deliverable: `rhinoceros`, `hippo`, and `elephant` receive progressive XDV entry discounts in their assigned locations; level 70 produces zero XDV price; USDT mode remains unchanged unless product explicitly changes it later.
  - Expected behavior: server-side dispatch and rescue/ransom price calculations never trust frontend prices; `RaidPetRead.xdv_prices_by_location` reflects the pet-specific discounted XDV price for UI previews.
  - Logging requirements: DEBUG pricing snapshot with location, mode, pet kind, pet level, base price, discount percent, and final amount; INFO when a raid is started with a zero XDV entry price; WARN when funds are insufficient after discount.
  - Dependencies: tasks 1 and 3.

- [x] Task 6: Preserve and retest trap immunity semantics.
  - Files: `diaverseapi/app/raids/domain/traps.py`, `diaverseapi/app/raids/services/command_service.py`, `diaverseapi/app/raids/services/trap_check_service.py`, `diaverseapi/app/raids/services/trap_service.py`, `diaverseapi/app/raids/tests/test_command_start.py`, `diaverseapi/app/raids/tests/test_domain_rules.py`.
  - Deliverable: `jetboa`, `capybara`, and `badger` remain binary immune in their assigned locations; their chest bonus becomes level-scaled; other pets do not gain immunity.
  - Expected behavior: immunity applies by `pet_kind` even when a user pet has a custom display name, and only in the matching location.
  - Logging requirements: DEBUG trap-check snapshot when a trap roll is skipped due to pet immunity, including raid id, location, pet kind, and immunity source; no sensitive user data.
  - Dependencies: tasks 1 and 3.

- [x] Task 7: Expose ability metadata through raid state/API schemas.
  - Files: `diaverseapi/app/raids/schemas.py`, `diaverseapi/app/raids/services/state_service.py`, `diaverseapi/app/raids/tests/test_state_service.py`.
  - Deliverable: include pet ability metadata needed by clients: assigned location, effect type, resource type if relevant, current multiplier, free-entry discount percent, and trap immunity locations.
  - Expected behavior: clients can render the active bonus without duplicating backend business rules; location resource previews include newly added base resource rows.
  - Logging requirements: keep per-request logs minimal; DEBUG only for unexpected missing ability/resource metadata during state assembly, with sanitized identifiers.
  - Dependencies: tasks 1-6.

### Phase 3: Web UI Integration

- [x] Task 8: Update raid frontend types and reward preview helpers.
  - Files: `diaweb/frontend/modules/raids/types.ts`, `diaweb/frontend/modules/raids/mechanicsDisplay.ts`, related raid test files under `diaweb/frontend/__tests__/modules/raids/` if present.
  - Deliverable: type the new backend metadata and update selected-pet previews so resource, chest, and XDV price displays reflect the chosen pet's current level bonus.
  - Expected behavior: frontend consumes backend-provided multiplier/discount where available; any fallback formula must use the same anchor table and be tested to avoid drift.
  - Logging requirements: no production `console` logging; if local debug output is needed, guard it behind an existing development/debug flag.
  - Dependencies: task 7.

- [x] Task 9: Display pet bonuses and resource labels in raid UI.
  - Files: `diaweb/frontend/modules/raids/components/RaidPetCard.tsx`, `diaweb/frontend/modules/raids/components/RaidDispatchStep.tsx`, `diaweb/frontend/modules/raids/components/RaidRewardPreview.tsx`, `diaweb/frontend/modules/raids/components/RaidConfirmDialog.tsx`, raid resource label/i18n helpers.
  - Deliverable: show a concise bonus line for resource, chest+immunity, and free-entry pets; add labels/assets for `xp_capsule`, `brick`, `dna_capsule`, and `gear` if the raid UI does not already have them.
  - Expected behavior: users can see why a pet is useful before dispatch; level 70 combat pets clearly show zero XDV cost in their matching location; UI text remains compact on mobile-sized web viewports.
  - Logging requirements: no production logs; ensure tests fail on missing labels rather than relying on runtime console warnings.
  - Dependencies: task 8.

### Phase 4: Verification And Documentation

- [x] Task 10: Add backend coverage for the full pet ability matrix.
  - Files: `diaverseapi/app/raids/tests/test_catalog.py`, `diaverseapi/app/raids/tests/test_domain_rules.py`, `diaverseapi/app/raids/tests/test_command_start.py`, `diaverseapi/app/raids/tests/test_settlement_service.py`, `diaverseapi/app/raids/tests/test_state_service.py`, `diaverseapi/app/raids/tests/test_raids_flow.py` if the flow test needs contract updates.
  - Deliverable: tests cover catalog completeness, formula anchors/interpolation, resource quantity bonus, chest chance bonus, trap immunity, XDV price discount, level 70 free entry, wrong-location no-op behavior, and state metadata.
  - Expected behavior: tests lock the new bonus model and prevent reintroducing fixed chest multipliers for immune pets.
  - Logging requirements: tests should assert meaningful error messages for catalog validation failures; do not add logs that leak raw payment or user secrets.
  - Dependencies: tasks 1-7.

- [x] Task 11: Add frontend and mobile contract verification.
  - Files: `diaweb/frontend/modules/raids/**`, `diaweb/frontend/__tests__/modules/raids/**`, relevant mobile API types/hooks only if verification finds a breaking contract.
  - Deliverable: web tests cover bonus labels/previews and discounted prices; mobile typecheck or targeted contract check confirms the new raid state payload does not break mobile consumers.
  - Expected behavior: existing raid screens still render with and without selected pet metadata; unknown/new metadata is tolerated by older clients where possible.
  - Logging requirements: no production client logs; fail tests on missing required metadata or labels.
  - Dependencies: tasks 7-9.

- [x] Task 12: Update raid docs and sync local knowledge.
  - Files: `docs/tasks/raids/raids-mechanics.md`, `docs/tasks/raids/raids-gameplay-guide.md`, `docs/features/raids-user-guide.md`, current `docs/daily/YYYY-MM-DD-safiu.md` after implementation.
  - Deliverable: document the new pet ability matrix, the level bonus formula, base resource reward additions, and the XDV-only interpretation for combat free-entry pets; append the required Russian daily work entry after implementation.
  - Expected behavior: docs no longer describe old fixed Jerboa/Capybara/Badger chest multipliers; GBrain is synced for changed docs/code sources after implementation.
  - Logging requirements: docs must not include secrets, raw infra details, raw user ids, private DB values, or sensitive stack traces.
  - Dependencies: tasks 1-11.

## Verification Plan

- `diaverseapi`: `.\.venv\Scripts\python.exe -m pytest app\raids\tests\test_catalog.py app\raids\tests\test_domain_rules.py app\raids\tests\test_command_start.py app\raids\tests\test_settlement_service.py app\raids\tests\test_state_service.py app\raids\tests\test_raids_flow.py -q`
- `diaverseapi`: `.\.venv\Scripts\python.exe -m ruff check app\raids`
- `diaweb/frontend`: run the repo's existing raid/module test command for `frontend/modules/raids` and `frontend/__tests__/modules/raids`; then run the existing typecheck/lint commands.
- `diaverse-mobile`: run the existing typecheck or targeted API contract check if raid state types are consumed there.
- Root docs: run `powershell -ExecutionPolicy Bypass -File scripts\docs-health.ps1` if raid docs change.
- Knowledge: run targeted GBrain sync for changed sources after implementation, at minimum `diaverseapi-code`, `diaweb-code`, and `diaverse-docs`.

## Risks And Open Decisions

- New base resource quantities for `gear`, `xp_capsule`, `brick`, and `dna_capsule` need explicit balance values in the raid catalog. The implementation should not leave them implicit or undocumented.
- Combat pet "free raid" is interpreted as XDV entry price discount only. USDT raid mode remains paid because the current raid pricing model separates XDV and USDT modes.
- `rat` is present as a pet kind in code context but may not be publicly seeded in the shop; the ability should still work for owned rats and should not require shop changes in this scope.
- `jetboa` and `bobr` are existing catalog spellings; renaming them would be a separate data migration/normalization task.
