# Implementation Plan: Factory Web Engine

Branch: feature/factory-web-engine
Created: 2026-05-25

## Settings
- Testing: yes
- Logging: verbose
- Docs: yes
- Branch base: `dev`
- Scope: web-only factory in `diaweb` backed by authoritative `diaverseapi`
- Asset strategy: option A, layered scene renderer with temporary placeholder assets first

## Workspace Mode
- Mode: multi-repo full
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first, then raw docs/source verification
- Plan owner: root `.ai-factory/plans/feature-factory-web-engine.md`
- Product code owners: `diaverseapi` and `diaweb`

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `feature/factory-web-engine` | clean at branch creation | Web UI, BFF, scene renderer, temporary assets |
| diaverseapi | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `feature/factory-web-engine` | clean at branch creation | Factory domain, API, DB, economy, timers, payments |
| aibot | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | `dev` | clean at planning | Not involved |
| club10000-bot | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | `dev` | clean at planning | Not involved |

## Source Documents
- `docs/tasks/fabric/README.md`
- `docs/tasks/fabric/research1.md`
- `docs/tasks/fabric/factory-mechanics-final.md`
- `docs/tasks/fabric/factory-designer-brief-levels-1-2-8.md`

## Research Context
Source: current exploration plus `docs/tasks/fabric/research1.md`.

Goal:
- Build the new Diaverse factory as a website-only feature in `diaweb`, backed by a new authoritative `diaverseapi/app/factory` bounded context.
- Do not restore or reuse the deleted legacy factory implementation.

Constraints:
- `diaweb` is the only browser-facing entrypoint.
- `diaverseapi` owns auth, RBAC, cabinet APIs, game economy, logs, payments, subscriptions, and user deletion/merge behavior.
- Mobile/native app will not implement factory UI or local factory state; later it only needs step/impulse support and possibly a deep link.
- Frontend must use layered assets: map background + building layers + effect overlays + hotspots.
- Backend must not know concrete asset paths; it returns stable `visual_key` and state.

Decisions:
- Public backend API prefix: `/v1/cabinet/factory`.
- Same-origin BFF prefix in `diaweb`: `/api/cabinet/factory`.
- New backend module path: `diaverseapi/app/factory`.
- Public website route: `/[lang]/factory`, private/auth-only inside the cabinet surface.
- Rollout must be feature-flagged on both backend router/commands and frontend navigation/page entry.
- Mutating command idempotency transport defaults to `idempotency_key` in JSON body unless Task 2 explicitly records a different contract.
- Game dollars are an existing Diaverse currency, not a new factory-only currency. Factory must use the existing gaming balance source of truth (`BotUser.dao_balans`, exposed as `UserRead.gaming_balance`) through a dedicated `GameDollarBalanceAdapter`.
- Server time and backend state are authoritative for every timer, cooldown, queue, subscription check, resource debit, refund, and collect action.
- Catalog-driven mechanics: buildings, levels, compartments, recipes, prices, unlock rules, early access, visual keys, and "in development" flags live in versioned catalog data, not scattered use-case constants.
- Resource generation uses lazy settlement, not one background job per player/timer.
- Existing `UserResource` remains the external user inventory balance, but factory needs its own ledger/reservation audit.
- Placeholder assets are acceptable for the first UI implementation, but the component architecture must be ready for final art drop-in.

Resolved Task 1 decisions:
- `$` in factory level and production-compartment price tables is a USD-denominated catalog amount, but not one storage type. The catalog must model explicit payment options: `real_money` via checkout, existing `game_dollar` via `BotUser.dao_balans` / `UserRead.gaming_balance`, and `brick` via the documented `1 USD = 1000 bricks` conversion when the action allows brick payment. UI must not infer the balance source from the `$` symbol.
- Employee/booster prices shown as `$` are existing `game_dollar` prices only, because the mechanics and designer brief explicitly say employees are hired for game dollars.
- Resource-part construction and upgrades use the explicit resource costs from the catalog: `impulse` + existing XDV for construction, XDV-only for resource upgrades, plus other resource requirements where the mechanics table says so. These actions do not use `real_money` unless a catalog entry explicitly defines that payment option.
- XDV uses the existing XDV source of truth: `BotUser.token_xdv` + `BotUser.token_xdv_fractional`, currently wrapped by `BotUserXDVBalanceAdapter` in `diaverseapi/app/cabinet/shop/money.py`. Factory should reuse or extract that adapter; it must not create a new XDV resource row, wallet, or currency.
- Existing game dollars use `BotUser.dao_balans`, exposed as `UserRead.gaming_balance`. Factory should add a dedicated `GameDollarBalanceAdapter` with get/credit/debit operations and Decimal normalization, but no new `factory_game_dollar` wallet or `ResourceType`.
- Advent/custom `game_balance_usd` alignment is outside the factory MVP. Factory will not depend on Advent custom grants; if product wants those rewards to affect the same balance before launch, add a separate cabinet rewards task to credit `BotUser.dao_balans`.
- Real-money factory purchases use a generic authenticated cabinet payment domain `factory`, not shop-backed pseudo-items. Add `factory` to `CabinetPaymentDomainCode`, provider `domain_codes`, finalizer registry, and `factory_payment_orders`. No guest factory payments.
- Subscription expiry is a server settlement event, not a user cancel action. On every state/command entry after expiry, queued/not-started jobs are refunded, subscription-only extra-line usage is reset, autostart/autocollect stop, and any running job that was started with subscription-only line/queue/autostart or subscription modifier snapshot is system-cancelled with reserved resources returned. Running jobs that never depended on subscription features may continue. The public cancel endpoint remains queued/not-started only.
- Produced entity mapping uses existing domains first: `impulse`, `brick`, `token_details`, `slot_token`, bullets, galaglue, nuclear acorns, gears, DNA capsules, XP capsules, synthesis cores, biomass, and nullifiers are `Resource` / `UserResource`; pet fragments are `CharacterShard` / `UserCharacterShard`; pets are `Character` / `UserCharacter`; EvoGens are `Voucher` / `UserVoucher` with existing EvoGen voucher types; mutagens are `UserMutagen`; "life force" is a workshop/product concept and must not become a balance unless the catalog defines a spendable resource key later.
- Daily impulse claim ownership is split: mobile/native remains the source of real steps, while `diaverseapi` owns conversion, daily cap, idempotency, and crediting. Add a factory-facing `POST /v1/cabinet/factory/impulses/claim`; it consumes existing synced step data when available and creates `factory_impulse_claims` only if the current activity flow cannot enforce `1 step = 1 impulse` and the 30,000 daily cap safely.
- Rollout flags: backend `FACTORY_WEB_ENABLED` / `settings.factory_web_enabled`; frontend `NEXT_PUBLIC_FACTORY_WEB_ENABLED` for nav/page gating. Backend remains authoritative. Disabled direct links return/render a controlled unavailable state; unauthenticated users are redirected to login before any factory state is created.

Resolved Task 2A rollout/navigation/cache policy:
- Backend feature flag source is `FACTORY_WEB_ENABLED`, exposed as `settings.factory_web_enabled`. Default is disabled unless the environment explicitly enables it; tests may override through settings fixtures. The router can be registered while disabled, but every state, catalog, and command endpoint must pass a rollout dependency before creating or mutating profile state.
- Disabled backend access returns HTTP `503 Service Unavailable` with `FactoryUnavailableResponse`, `error_code = "factory_disabled"`, `feature = "factory"`, `server_time`, and `Cache-Control: no-store`. Rollout-disabled requests must log one INFO event per request with route, user id when authenticated, and request id if available.
- Auth is checked before factory state creation. `/[lang]/factory` and nested frontend routes are auth-only through `diaweb/frontend/proxy.ts`; unauthenticated direct links redirect to login. There is no guest fallback, guest profile, guest checkout, or guest impulse claim path.
- Frontend flag source is `NEXT_PUBLIC_FACTORY_WEB_ENABLED`. When disabled, cabinet navigation hides the factory entry and direct deep links render `FactoryUnavailableState` without issuing factory BFF state/command calls. The backend flag remains authoritative if frontend and backend flags drift.
- Factory state, catalog, and command routes are private. `diaweb/frontend/next.config.ts` must include `/factory` in private cache header suffixes before UI exposure; same-origin BFF handlers must use `cache: "no-store"` and private/no-store response headers for every factory response.
- Cabinet navigation must be explicit: add a `factory` top/bottom navigation item, icon kind/assets or placeholder icon, dictionary labels, and route-transition/ranking support if the cabinet shell depends on ranked tabs. Navigation tests must cover enabled/disabled flag behavior.
- Rollout-disabled direct links are a controlled product state, not a 404. Frontend copy can be simple, but the route must preserve the cabinet layout and avoid exposing partial factory state.

## Spec Alignment Requirements

These requirements are explicit guardrails from `factory-mechanics-final.md`, `factory-designer-brief-levels-1-2-8.md`, and `research1.md`. They must be treated as acceptance criteria, not optional polish.

Backend/domain invariants:
- Factory is authenticated-only unless Task 1 explicitly changes this with a documented product decision. Do not create guest factory profiles, guest factory payments, or guest factory inventory state in the initial implementation.
- Backend factory access must be rollout-gated. Disabled state must return a stable error/response shape that diaweb can render without discovering half-registered routes.
- Real-money factory checkout must either register a real `factory` cabinet payment domain across type aliases, provider capabilities, and finalizer registry, or intentionally reuse the existing shop-backed checkout path. Do not invent a fake domain code that is not accepted by the cabinet payment service.
- Game-dollar prices and generation must use the existing gaming balance (`BotUser.dao_balans` / `UserRead.gaming_balance`). Do not create a new spendable `factory_game_dollar` currency, `ResourceType`, or parallel wallet. Factory may track uncollected warehouse accrual as pending factory state, but collected/spendable dollars must credit/debit the existing gaming balance.
- XDV debit must use the current XDV balance/debit adapter or an explicitly introduced equivalent. Do not model XDV as a normal `UserResource` row unless the existing economy already does so. `UserResource` should cover actual resource rows such as `impulse`, `token_details`, `slot_token`, bullets, galaglue, acorns, gears, bricks, DNA, and similar resources.
- Factory slot-token detail drops must not pollute the existing `event_token` economy. Use a separate `FactorySlotTokenDropService` or a safely parameterized shared drop service with tests proving event-token behavior is unchanged.
- Full backend catalog must represent mechanics for factory levels 1-8, including all workshop tables, recipes, prices, durations, resource rates, unlock rules, early-access rules, package prices, level 6/7 token requirements, and "in development" flags. UI scope can prioritize playable levels 1-2 plus the level 8 map, but backend catalog data must not be only placeholder mechanics for levels 3-7.
- Production slot-token requirements apply to production parts/compartments, not resource-part upgrades. Slot-token drop economy must be modeled from chest/loot sources with base probability/math plus subscription multipliers: no subscription x1, Step Pass Pro x5, Trademaster x10.
- Daily impulse collection must be modeled explicitly: 1 impulse per real step, daily cap 30,000, deterministic day boundary, replay-safe collection, and a clear owner for step/award integration.
- Active/running craft cannot be cancelled from UI or backend API. The cancel endpoint, if kept, is queued/not-started only and must reject running, ready, collected, cooldown, or repair states with a stable error code.
- Cooldown starts when the crafted product is collected, not when the craft timer finishes. Autostart queues wait for cooldown and then resume automatically when subscription rules allow it.
- Subscription expiry must settle deterministically on every state/command entry: queued/not-started items return reserved materials, extra-line usage is disabled/reset, autocollect/autostart features stop, and active craft behavior must follow the explicit Task 1 decision.
- Building level 6/7 lines can be built without an active subscription, but line usage, per-line queue, and autocollect require the relevant active subscription.
- Early access doubles input/time/cost penalties as specified and normalizes automatically when the factory reaches the regular unlock level; the UI badge disappears and state no longer uses early-access penalties.
- Level progression tests must include concrete level 1 -> 2 and level 2 -> 3 requirement checklists from the designer brief, not only generic rule tests.

Frontend/design invariants:
- `/[lang]/factory` must be private/auth-only in `diaweb/frontend/proxy.ts`, covered by proxy tests, and included in private cache header rules in `next.config.ts` before UI is exposed.
- Factory navigation must be wired intentionally into cabinet top/bottom navigation, icon assets, route ranking/transitions if applicable, dictionaries, and existing nav tests. Do not rely on a hidden route only.
- If rollout is disabled, the frontend must hide or disable navigation and render a controlled unavailable state for direct deep links.
- Option A layered scene is mandatory: map background plus independent building layers, effect overlays, and manifest-driven hotspots. The map must support mobile swipe/pan with bounded movement and responsive hotspot scaling.
- Temporary assets are allowed, but the manifest must be replaceable by final art with stable `visual_key` names and density-aware exports (`1x`, `2x`, `3x` or equivalent responsive WebP/PNG policy).
- The art handoff must account for Figma pages/groups `A`, `B`, `V`, `G`, `D`, reusable components, map assets for levels 1/2/8, building states, resource icons, production icons, subscription badges, UI icons, and static animation frames.
- Level 8 first implementation is a final map state only: no requirement to build all level 8 interior workshop screens unless later scope expands.
- A18 onboarding is required: first factory entry tips, skip/complete state, and no repeated forced tutorial after completion.
- A13 queue UI must expose occupied queued-slot action menu with remove/refund only before start.
- A16 toast stack must collapse/group when more than 3 notifications are visible.
- A12 subscription UI must show no-sub, Step Pass Pro, and Trademaster states plus paths to subscription shop/manage flow according to the existing diaweb navigation pattern.

## Architecture Target

```text
diaweb route /[lang]/factory
  -> modules/factory React Query hooks and scene renderer
  -> app/api/cabinet/factory/* BFF routes
  -> diaverseapi /v1/cabinet/factory/*
  -> FactoryCommandService
     -> CatalogLoader + Domain Policies
     -> FactoryRepository with row locks
     -> InventoryGateway / GameDollarBalanceAdapter / PaymentGateway / SubscriptionResolver / FeatureFlagResolver
     -> factory_* tables + UserResource + BotUser.dao_balans + subscriptions + cabinet payments
```

## Backend Target Structure

```text
diaverseapi/app/factory/
  __init__.py
  api.py
  dependencies.py
  schemas.py
  models.py
  catalog/
    __init__.py
    schema.py
    loader.py
    validator.py
    data/factory_catalog.v1.yaml
  domain/
    __init__.py
    constants.py
    errors.py
    money.py
    policies.py
    pricing.py
    requirements.py
    modifiers.py
    timers.py
    view_model.py
  services/
    __init__.py
    state_service.py
    command_service.py
    building_service.py
    warehouse_service.py
    crafting_service.py
    impulse_service.py
    slot_token_service.py
    payment_service.py
    booster_service.py
  infrastructure/
    __init__.py
    repositories.py
    inventory_gateway.py
    game_dollar_gateway.py
    payment_gateway.py
    subscription_resolver.py
    rollout.py
    notifications.py
  tasks.py
  tests/
```

## Frontend Target Structure

```text
diaweb/frontend/modules/factory/
  api.ts
  types.ts
  constants.ts
  assetManifest.ts
  hooks/
    useFactoryState.ts
    useFactoryMutations.ts
    useFactoryTimers.ts
  components/
    FactoryShell.tsx
    FactoryHeader.tsx
    FactoryScene.tsx
    FactoryHotspotLayer.tsx
    BuildingInfoBubble.tsx
    FactoryWarehouseScreen.tsx
    ResourceWorkshopScreen.tsx
    ProductionWorkshopScreen.tsx
    CompartmentScreen.tsx
    FactoryInventoryDrawer.tsx
    FactoryUpgradeDialog.tsx
    DemolitionDialog.tsx
    SlotTokenDialog.tsx
    SubscriptionDialog.tsx
    FactoryToastStack.tsx
    FactoryOnboardingOverlay.tsx
    FactoryUnavailableState.tsx
    InDevelopmentPanel.tsx
  styles/
    factory.css

diaweb/frontend/app/[lang]/(cabinet)/factory/
  page.tsx
  warehouse/page.tsx
  workshops/[workshopKey]/page.tsx
  workshops/[workshopKey]/compartments/[compartmentKey]/page.tsx

diaweb/frontend/app/api/cabinet/factory/
  _utils.ts
  state/route.ts
  catalog/route.ts
  ...command route handlers...

diaweb/frontend/public/factory/
  maps/
  buildings/
  warehouse/
  resources/
  production/
  subscriptions/
  ui/
  effects/
  navigation/
```

## API Contract Target

```text
GET  /v1/cabinet/factory/catalog
GET  /v1/cabinet/factory/state
POST /v1/cabinet/factory/open
POST /v1/cabinet/factory/levels/upgrade
POST /v1/cabinet/factory/buildings/{building_key}/build
POST /v1/cabinet/factory/buildings/{building_key}/resource/upgrade
POST /v1/cabinet/factory/buildings/{building_key}/production/build
POST /v1/cabinet/factory/compartments/{compartment_key}/upgrade
POST /v1/cabinet/factory/warehouse/transfer-to-storage
POST /v1/cabinet/factory/warehouse/transfer-to-inventory
POST /v1/cabinet/factory/craft-jobs
POST /v1/cabinet/factory/craft-jobs/{job_id}/collect
POST /v1/cabinet/factory/craft-jobs/{job_id}/cancel   # queued/not-started jobs only
POST /v1/cabinet/factory/impulses/claim
POST /v1/cabinet/factory/slot-tokens/assemble
POST /v1/cabinet/factory/payments/checkout
GET  /v1/cabinet/factory/payments/checkout/{public_checkout_reference}
```

## Data Model Target

- `factory_profiles`: user, level, status, catalog version, tutorial/onboarding state.
- `factory_buildings`: user, building key, resource level/status, production status, build/upgrade timestamps, accrual timestamps.
- `factory_compartments`: user, building key, compartment key, level, status, repair timestamp, early-access snapshot.
- `factory_craft_jobs`: user, building/compartment, line index, queue order, recipe key, status, timestamps, catalog snapshot, input/output/modifier snapshots.
- `factory_warehouse_balances`: user, resource key, warehouse quantity, storage quantity, last accrual, stopped state. For game dollars this table may store only uncollected/pending factory accrual; the spendable balance remains the existing `BotUser.dao_balans`/`gaming_balance`.
- `factory_ledger_entries`: source, reason, direction, quantity, balance before/after if available, related entity, idempotency key.
- `factory_command_idempotency`: user, command type, request key, request hash, result JSON, status, timestamps.
- `factory_payment_orders`: factory purchase intent, payment session link, target action, quote snapshot, finalization status.
- `factory_booster_hires`: employee/booster type, scope, start/end, effect snapshot.
- `factory_impulse_claims` if Task 12A chooses factory-owned claim tracking instead of safely extending the existing activity/award flow.

Use short explicit PostgreSQL names for constraints and indexes, especially composite indexes, because identifiers are limited to 63 bytes.

## Tasks

### Phase 0: Scope Lock And Contract Decisions

- [x] Task 1: Resolve factory economic ambiguities and write a short implementation note inside this plan before coding.
  - Deliverable: amend this plan's `Open questions` into concrete decisions for `$` price kinds, existing game-dollar usage (`BotUser.dao_balans` / `UserRead.gaming_balance`), XDV debit source, subscription expiry behavior, active-craft expiry behavior, entity mapping, payment path, impulse claim ownership, rollout flag names, no-guest policy, and whether the queued-only cancel endpoint remains public.
  - Files: `.ai-factory/plans/feature-factory-web-engine.md`; no product code.
  - LOGGING REQUIREMENTS: no runtime logging; record decisions with source doc references and mark unresolved items as explicit blockers.
  - Dependency notes: blocks tasks 2, 2A, 5, 8, 11, 12A, 13, 15, 16, 20, 22, 25, and 32A.

- [x] Task 2: Define backend/frontend contract envelope for state, commands, idempotency, errors, and visual keys.
  - Deliverable: compact API contract section in backend schemas and frontend types that uses `server_time`, `catalog_version`, `available_actions`, `lock_reasons`, `missing_requirements`, `visual_key`, stable error codes, selected idempotency transport, disabled-rollout response, and auth-only behavior.
  - Files: `diaverseapi/app/factory/schemas.py`, `diaweb/frontend/modules/factory/types.ts`.
  - LOGGING REQUIREMENTS: plan error codes with log-safe payload fields; no sensitive resource balances in ERROR logs.
  - Dependency notes: depends on task 1.

- [x] Task 2A: Define rollout, route protection, cache, and navigation policy.
  - Deliverable: record backend/frontend feature flag names, default disabled/enabled behavior per environment, direct deep-link behavior, private cache policy, cabinet navigation entry decision, and no guest fallback behavior.
  - Files: `.ai-factory/plans/feature-factory-web-engine.md`, later `diaverseapi/app/core/settings.py`, `diaverseapi/app/factory/infrastructure/rollout.py`, `diaweb/frontend/proxy.ts`, `diaweb/frontend/next.config.ts`, cabinet navigation files.
  - LOGGING REQUIREMENTS: backend INFO when command/state is blocked by rollout once per request; frontend no noisy logs, only development DEBUG for unavailable state rendering.
  - Dependency notes: depends on tasks 1 and 2; blocks tasks 3, 29, 32A, 33, and 44.

### Phase 1: Backend Skeleton, Catalog, And Validation

- [x] Task 3: Create the new `diaverseapi/app/factory` module skeleton and register its router.
  - Deliverable: importable empty module, `GET /v1/cabinet/factory/catalog`, `GET /v1/cabinet/factory/state`, auth-required dependencies, no-store responses, rollout guard, and router registration in `app/routers/v1/endpoints.py`.
  - Files: `diaverseapi/app/factory/**`, `diaverseapi/app/routers/v1/endpoints.py`, `diaverseapi/app/core/settings.py` if feature flag config lives there.
  - LOGGING REQUIREMENTS: DEBUG on state/catalog entry, INFO on first profile auto-create/open only, INFO/WARNING for rollout-disabled access according to existing logging style, WARNING for malformed catalog or unavailable dependency.
  - Dependency notes: use clean module name `app/factory`; do not revive deleted legacy factory. Must require the current authenticated cabinet user; no guest profile creation.

- [x] Task 4: Build catalog schema, loader, validator, and versioned `factory_catalog.v1.yaml`.
  - Deliverable: Pydantic/SQLModel-compatible catalog schema for full levels 1-8 mechanics, buildings, resource parts, production parts, compartments, recipes, prices, durations, resource rates, package pricing, level 6/7 slot-token requirements, unlock gates, early access, subscriptions, boosters, visual keys, and in-development flags.
  - Files: `diaverseapi/app/factory/catalog/schema.py`, `loader.py`, `validator.py`, `data/factory_catalog.v1.yaml`.
  - LOGGING REQUIREMENTS: INFO on catalog version loaded; DEBUG validation counts by entity type; ERROR with catalog path/version when validation fails.
  - Dependency notes: backend catalog must ingest the full mechanics tables for levels 1-8; frontend route scope can still prioritize level 1-2 playable screens and level 8 map rendering.

- [x] Task 5: Normalize money/resource kinds and rounding policy.
  - Deliverable: value objects for `impulse`, `xdv`, existing `game_dollar`, `real_money`, `brick`, resource quantities, fractional accrual scaling, and display serialization. `game_dollar` must represent the existing gaming balance, not a new factory-local wallet.
  - Files: `diaverseapi/app/factory/domain/money.py`, `pricing.py`, `schemas.py`, `diaverseapi/app/factory/infrastructure/game_dollar_gateway.py`, catalog data.
  - LOGGING REQUIREMENTS: DEBUG when calculating rounded quantities/prices; WARNING when catalog has unsupported price kind; never log raw payment provider secrets.
  - Dependency notes: depends on task 1. Must handle comma decimals from docs such as `3,3` and fractional production rates. Use Decimal-style normalization for game dollars; avoid float-only arithmetic around `BotUser.dao_balans` even if the legacy field is currently Float.

- [x] Task 6: Add backend catalog unit tests and validation fixtures.
  - Deliverable: tests that load the full catalog, validate all visual keys, ensure levels 1-8 exist, verify no duplicate keys, and check critical values from the docs including level progression gates, slot-token requirements, package pricing, early-access penalties, and key level 1/2 recipes.
  - Files: `diaverseapi/app/factory/tests/test_catalog.py`.
  - LOGGING REQUIREMENTS: tests should assert validation errors include catalog version/path but not noisy full catalog dumps.
  - Dependency notes: depends on tasks 4 and 5.

### Phase 2: Database Models, Migrations, And Lifecycle Safety

- [x] Task 7: Implement SQLModel models for new factory state.
  - Deliverable: models for profiles, buildings, compartments, craft jobs, warehouse balances, ledger entries, idempotency, payment orders, and booster hires.
  - Files: `diaverseapi/app/factory/models.py`.
  - LOGGING REQUIREMENTS: no model-level logging; add model comments/docstrings only where constraints are non-obvious.
  - Dependency notes: use short index/constraint names and explicit `ondelete` behavior.

- [x] Task 8: Create Alembic migration for new factory tables.
  - Deliverable: migration under `diaverseapi/migrations/versions/` with short constraint/index names, no destructive changes to unrelated tables, compatibility with current Alembic graph conventions, and graph/head sentinel coverage.
  - Files: `diaverseapi/migrations/versions/*factory*.py`, `diaverseapi/migrations/env.py` if needed, `diaverseapi/tests/test_alembic_graph.py` or equivalent migration graph sentinel.
  - LOGGING REQUIREMENTS: migration itself should not log; verification must capture SQL output errors if DDL generation fails.
  - Dependency notes: depends on task 7. Run PostgreSQL DDL compilation check, not just `alembic heads`.

- [x] Task 9: Add factory user deletion and merge handling.
  - Deliverable: deletion removes/cascades new factory rows; merge either transfers single-owner state safely or blocks/handles conflicting active factory state according to task 1 decision; security coverage sentinels prove new `factory_*` tables cannot be missed by future delete/merge changes.
  - Files: `diaverseapi/app/security/usecases.py`, possible factory repository helpers, `diaverseapi/tests/test_merge_account_coverage.py`, `diaverseapi/tests/test_delete_user_fk_coverage.py`, security tests.
  - LOGGING REQUIREMENTS: INFO for factory delete/merge summary counts; WARNING for conflict/unsupported merge cases; ERROR only for unexpected DB failures.
  - Dependency notes: do not remove existing legacy cleanup until confirmed no longer needed.

- [x] Task 10: Add repository layer with row locks and idempotency primitives.
  - Deliverable: repository methods for loading/locking profile, balances, jobs, idempotency records, and ledger writes.
  - Files: `diaverseapi/app/factory/infrastructure/repositories.py`.
  - LOGGING REQUIREMENTS: DEBUG for lock acquisition paths and idempotency replay; INFO for command record completion; WARNING for request hash mismatch.
  - Dependency notes: all command services must use these methods instead of direct scattered queries.

### Phase 3: Inventory, Subscriptions, Payments, And Notifications

- [x] Task 11: Implement `FactoryInventoryGateway`.
  - Deliverable: safe debit, credit, reserve, refund, and balance snapshot API over existing resource rows and economy adapters. Use `UserResource` for true resource balances (`impulse`, `token_details`, `slot_token`, bullets, galaglue, acorns, gears, bricks, DNA, production entities where applicable); use the current XDV balance/debit path or introduce an explicit adapter for XDV; use `GameDollarBalanceAdapter` over existing `BotUser.dao_balans`/`gaming_balance` for game-dollar generation and spend.
  - Files: `diaverseapi/app/factory/infrastructure/inventory_gateway.py`, `diaverseapi/app/factory/infrastructure/game_dollar_gateway.py`, possibly existing XDV balance adapter files, item/resource catalog integration files.
  - LOGGING REQUIREMENTS: INFO for successful debit/credit/refund summaries with source and idempotency key; DEBUG for balance checks; WARNING for insufficient resources; ERROR for invariant violations.
  - Dependency notes: depends on task 1 entity mapping and task 10. Must not bypass ledger. Do not fake XDV or game dollars as `UserResource` rows if the current economy uses dedicated balance fields/services.

- [x] Task 12: Implement factory ledger writes for every inventory/warehouse/payment-relevant movement.
  - Deliverable: every debit, reserve, refund, grant, warehouse transfer, craft collect, autocollect, demolition refund, and payment finalization creates an audit entry.
  - Files: `diaverseapi/app/factory/infrastructure/inventory_gateway.py`, `repositories.py`, `models.py`.
  - LOGGING REQUIREMENTS: DEBUG for ledger entry details in development; INFO command-level movement summary; ERROR on missing ledger for committed inventory mutation.
  - Dependency notes: depends on task 11.
  - Implementation note: foundational inventory movements now write ledger entries through `FactoryRepository.write_ledger_entry`; command-specific tests in later tasks must assert warehouse/payment/craft services use this gateway rather than direct mutations.

- [x] Task 12A: Implement impulse collection and step adapter.
  - Deliverable: deterministic daily impulse claim flow with 1 impulse per real step, 30,000 daily cap, replay-safe collection, clear day boundary, state fields for cap/claimed/available/next reset, and integration with the selected activity/award source or a factory-owned claim table.
  - Files: `diaverseapi/app/factory/services/impulse_service.py`, `diaverseapi/app/factory/infrastructure/inventory_gateway.py`, selected activity/steps/award integration files, `diaverseapi/app/factory/models.py` if `factory_impulse_claims` is needed.
  - LOGGING REQUIREMENTS: INFO for successful claim summary with claimed amount and idempotency key; DEBUG for step/cap calculation; WARNING for no available steps or stale claim request; ERROR for negative claim/invariant failures.
  - Dependency notes: depends on tasks 1, 10, 11, and 12. Blocks state snapshot, command tests, mobile handoff, and end-to-end smoke.

- [x] Task 13: Implement `FactorySubscriptionResolver` and modifier engine.
  - Deliverable: resolver for `factory_step_pass_pro` and `factory_trademaster`; modifiers for resource production, slot-token drops, build speed, queue, autocollect, multi-lines, craft price/duration/cooldown, line-use gating, queue reset/refund, and autocollect shutdown on expiry.
  - Files: `diaverseapi/app/factory/infrastructure/subscription_resolver.py`, `domain/modifiers.py`.
  - LOGGING REQUIREMENTS: DEBUG resolved features and modifier snapshot; INFO on subscription transition detected during command/state settlement; WARNING when subscription expiry causes queue reset/refund.
  - Dependency notes: do not reuse shop StepPass resolver blindly; use existing subscription tables/features. Building extra lines is allowed without subscription, but using extra lines/queues/autocollect requires the active subscription feature.
  - Implementation note: added pure `FactoryModifierSnapshot` logic backed by catalog multipliers, active feature precedence (`Trademaster` over `Step Pass Pro`), line/queue/autocollect gates, level-6 Trademaster craft/cooldown reductions, DB resolver over existing `user_subscriptions` and `subscription_feature_assignments`, timezone-aware expiry projection, transition logging hooks, and focused tests.

- [x] Task 14: Integrate slot-token drop modifiers with chest/loot source only if required by current product flow.
  - Deliverable: implement or explicitly gate the slot-token-details drop source in the actual chest/loot path, including base probability/math from the mechanics doc, no-sub x1, Step Pass Pro x5, Trademaster x10, and calibration tests against expected monthly totals. Use `FactorySlotTokenDropService` or a safely parameterized generic service; prove existing event-token drops still behave the same.
  - Files: likely `diaverseapi/app/chests/**`, `diaverseapi/app/loot_boxes/**`, `diaverseapi/app/factory/services/slot_token_service.py`, `diaverseapi/app/factory/infrastructure/subscription_resolver.py`, event-token regression tests.
  - LOGGING REQUIREMENTS: INFO when slot-token drop multiplier is applied; DEBUG on selected subscription feature; WARNING if reward source cannot apply the modifier.
  - Dependency notes: depends on tasks 4, 11, and 13 and requires source verification before edit.
  - Implementation note: added `FactorySlotTokenDropService` on the chest opening reward path, mapped chest kinds to catalog keys, restored token-detail awards via existing `AwardKind.token_details`/`TokenDetailsAwardProcessor`, used expected-value math (`base_probability * subscription_multiplier`) instead of capping high multipliers, and covered x1/x5/x10 plus monthly reference totals. Loot-box sources remain explicitly gated by having no catalog source mapping until product defines probabilities for that separate domain.

- [x] Task 14A: Wire factory resource, award, and loot processor support.
  - Deliverable: ensure `impulse`, `token_details`, and `slot_token` resources are seeded/lookup-safe; add missing `LootBoxAwardKind`/processor support for token details if the drop path uses loot boxes; keep `AwardKind` processors aligned; add tests for resource conversion and processor routing.
  - Files: `diaverseapi/app/shards_and_resources/models.py`, resource seed/bootstrap files, `diaverseapi/app/awards/models.py`, `diaverseapi/app/awards/processor.py`, `diaverseapi/app/loot_boxes/models.py`, `diaverseapi/app/loot_boxes/processor.py`, `diaverseapi/app/loot_boxes/schemas.py`, targeted resource/award/loot tests.
  - LOGGING REQUIREMENTS: INFO only for awarded resource summaries through existing processor logging; DEBUG for route/processor selection if existing style supports it; WARNING for unsupported reward kinds.
  - Dependency notes: depends on tasks 1, 4, and 11. Must not change event-token semantics except through intentional shared abstractions with tests.
  - Implementation note: existing `ResourceType`, `AwardKind`, award processors, and DI registration already covered `impulse`, `token_details`, and `slot_token`; amended the new factory migration to guarantee PostgreSQL enum values and seed rows for these resource lookups; added alignment tests for factory price kinds, resource kinds, award kinds, processors, and migration seed constants. Loot-box token-details support stays gated because Task 14 uses the chest source, not loot boxes.

- [x] Task 15: Implement factory payment adapter/finalizer path.
  - Deliverable: checkout creation for real-money factory actions and idempotent finalizer that applies the pending factory command only after paid status. If generic factory payments are chosen, add `factory` to `CabinetPaymentDomainCode`, provider `domain_codes`, and finalizer registry; if shop-backed checkout is chosen, document and implement the shop item/finalizer route without adding a fake domain.
  - Files: `diaverseapi/app/factory/services/payment_service.py`, `infrastructure/payment_gateway.py`, `diaverseapi/app/cabinet/payments/types.py`, `diaverseapi/app/cabinet/payments/registry.py`, `diaverseapi/app/cabinet/payments/finalizers.py`, new `diaverseapi/app/factory/payment_finalizer.py` if using a `factory` domain, shop files if shop-backed.
  - LOGGING REQUIREMENTS: INFO for checkout created/finalized/replayed; DEBUG for quote/source refs; WARNING for stale/invalid payment order; ERROR for finalization failure with safe context.
  - Dependency notes: depends on tasks 1, 11, 12, and payment-domain decision. If shop-backed checkout is chosen, adapt task to shop item/finalizer contract instead of adding a new domain.
  - Implementation note: implemented the generic authenticated cabinet payment domain `factory` instead of shop-backed pseudo-items. Pay1Time/Zion/Prodamus provider registrations now advertise `factory` while guest factory checkout stays disabled. Added `FactoryPaymentGateway` for source refs, routing, provider quotes, and checkout creation; added `FactoryPaymentService`/`FactoryPaymentFinalizer` for idempotent paid-session finalization, owner/amount/currency/expiry validation, and a paid-command applier contract. Until Task 18 wires the concrete command applier, a paid order without an applier is moved to `review_required` rather than being falsely fulfilled.

- [x] Task 15A: Add factory payment domain and finalizer contract tests.
  - Deliverable: tests proving factory checkout provider capabilities are resolvable, paid sessions finalize idempotently, unsupported providers/domains fail safely, stale payment orders do not mutate factory state, and shop-backed path behaves consistently if selected.
  - Files: `diaverseapi/tests/test_cabinet_payment_sessions.py`, factory payment service tests, selected shop/factory finalizer tests.
  - LOGGING REQUIREMENTS: tests should assert missing/failing finalizers create safe alert/log context where existing cabinet payment tests cover that behavior.
  - Dependency notes: depends on task 15 and blocks integration smoke involving payment checkout.
  - Implementation note: added registry contract assertions to `tests/test_cabinet_payment_sessions.py` for authenticated-only `factory` provider support and finalizer registration. Added `app/factory/tests/test_payment_service.py` covering paid-session finalization through an injected applier, duplicate finalizer replay, missing/stale order review, amount mismatch review, and default missing-applier review. This keeps factory paid sessions from being marked fulfilled unless a real command applier is available.

- [x] Task 16: Implement factory notification/toast event adapter.
  - Deliverable: backend emits non-fatal notification hints for build ready, craft ready, subscription expiry, autocollect disabled, warehouse stopped, slot token assembled, payment completed.
  - Files: `diaverseapi/app/factory/infrastructure/notifications.py`, cabinet notifications integration files if needed.
  - LOGGING REQUIREMENTS: DEBUG notification attempt; WARNING non-fatal notification failure; never fail core command because a notification failed.
  - Dependency notes: UI also receives transient toasts from command/state responses.
  - Implementation note: added typed `FactoryNotificationHintRead` payloads and `FactoryNotificationAdapter`. Persistent factory events reuse existing `CabUserNotificationService` with `source_domain="factory"` and stable idempotency keys; transient events stay in the factory response only. Notification failures are caught and logged as WARNING so core commands can continue.

### Phase 4: Core Backend Domain Commands

- [x] Task 17: Implement state snapshot service.
  - Deliverable: `GET /state` returns complete factory state for UI: server time, profile, map/building state, warehouse, inventory excerpts, active jobs, available actions, lock reasons, requirements, subscription status, next refresh hints, and visual keys.
  - Files: `diaverseapi/app/factory/services/state_service.py`, `domain/view_model.py`, `schemas.py`, `api.py`.
  - LOGGING REQUIREMENTS: DEBUG state build stages and settlement actions; INFO only on first profile open or state repair; WARNING for inconsistent persisted state repaired during read.
  - Dependency notes: depends on tasks 4, 10, 11, 12A, and 13.
  - Implementation note: added `FactoryStateService` and wired `GET /state` through `get_factory_state_service`. The snapshot reads the catalog plus persisted profile/buildings/compartments/jobs/warehouse rows, exposes no-profile `open_factory`, catalog-derived building/compartment map states, user inventory excerpts, warehouse pending balances, subscription state, impulse claim state, active job actions, transient ready/warehouse notifications, and `next_refresh_at` hints. GET does not create a profile; profile creation remains the explicit open command.

- [x] Task 18: Implement factory open and level upgrade commands.
  - Deliverable: open level 1, central building initialization, strict sequential level upgrade 1-8, requirements evaluation, payment/resource debit, and state return.
  - Files: `diaverseapi/app/factory/services/command_service.py`, `building_service.py`, `domain/requirements.py`, `api.py`.
  - LOGGING REQUIREMENTS: INFO command accepted/completed/replayed; DEBUG requirement evaluation; WARNING insufficient requirements/resources; ERROR invariant violations.
  - Dependency notes: level upgrades must support game dollars, real money, and bricks according to task 1 decision.
  - Implementation note: added `FactoryCommandService`, request schemas, `/open`, and `/levels/upgrade`. `GET /state` still does not create a profile; opening is explicit and initializes level 1 plus central warehouse balance rows. Level upgrades are sequential, idempotent, catalog-requirement gated, and support existing game dollars, bricks, or real-money checkout through the registered `factory` payment domain. Real-money payments now store a pending command payload and the default `FactoryPaymentFinalizer` wires to the command service so a paid upgrade can be applied idempotently. Verified with `pytest app/factory/tests -q` (`52 passed`) and `ruff check app/factory`.

- [x] Task 19: Implement building construction, resource upgrades, production construction, and demolition/refund.
  - Deliverable: resource workshop build, resource part upgrade capped by factory level, production part build, 50% demolition refund based on ledger/snapshot, and in-development states.
  - Files: `diaverseapi/app/factory/services/building_service.py`, `domain/policies.py`, `api.py`.
  - LOGGING REQUIREMENTS: INFO build/upgrade/demolish lifecycle; DEBUG cost calculation and modifier snapshot; WARNING blocked action; ERROR if refund cannot be reconciled.
  - Dependency notes: depends on tasks 12, 17, 18.
  - Implementation note: added `FactoryBuildingService`, building command request schemas, endpoints for resource build, resource upgrade, production build, and demolition. Resource construction debits catalog `impulse` + XDV costs, resource upgrades debit catalog XDV and are capped by factory level, production-building construction debits catalog construction costs including slot tokens, and demolition refunds 50% from stored spend snapshots with whole-resource rounding. The service preflights all multi-price balances before debit to avoid partial spends, records spend snapshots for later refund, blocks resource-building production activation until the resource part exists, and blocks demolition when active/queued jobs exist. Verified with `pytest app/factory/tests -q` (`58 passed`) and `ruff check app/factory`.

- [x] Task 20: Implement warehouse lazy accrual and transfer commands.
  - Deliverable: passive resource and existing game-dollar generation with 10-hour cap, stopped state, transfer to storage, transfer to user inventory/gaming balance, Trademaster autocollect behavior, and future inventory-full placeholder. Generated game dollars must credit existing `BotUser.dao_balans` through `GameDollarBalanceAdapter` when collected/autocollected; pending factory accrual is not a new spendable wallet.
  - Files: `diaverseapi/app/factory/services/warehouse_service.py`, `diaverseapi/app/factory/infrastructure/game_dollar_gateway.py`, `domain/timers.py`, `api.py`.
  - LOGGING REQUIREMENTS: DEBUG accrual calculations; INFO transfer/autocollect summary with balance before/after IDs but no noisy full balance dump; WARNING warehouse stopped or inventory capacity blocked; ERROR negative balance/invariant failure.
  - Dependency notes: depends on tasks 11, 12, 12A, 13, and 17.
  - Implementation note: added `FactoryWarehouseService`, `FactoryWarehouseTransferRequest`, and endpoints `/warehouse/transfer-to-storage` and `/warehouse/transfer-to-inventory`. Settlement is lazy and server-time based: active resource buildings accrue into factory pending balances up to the 10-hour cap, stopped state is represented on warehouse balances, transfer-to-storage moves pending into factory storage and resets stopped state, and transfer-to-inventory credits only whole resource units while leaving fractional remainder in storage. Factory game-dollar accrual starts from level 6 and credits the existing game-dollar balance only on inventory transfer/autocollect through `FactoryInventoryGateway`. Trademaster autocollect is wired on storage transfer. Verified with `pytest app/factory/tests -q` (`62 passed`) and `ruff check app/factory`.

- [x] Task 21: Implement compartment unlock and upgrade commands.
  - Deliverable: compartment levels 1-7, package 1-5 purchase, levels 6/7 token requirements, early-access x2 penalties, automatic normalization at the regular unlock factory level, upgrade locks, and requirements for factory progression.
  - Files: `diaverseapi/app/factory/services/building_service.py`, `domain/requirements.py`, `domain/pricing.py`, `api.py`.
  - LOGGING REQUIREMENTS: INFO unlock/upgrade completion; DEBUG package/level price calculation; WARNING blocked/insufficient token actions.
  - Dependency notes: depends on tasks 5, 11, 18.
  - Implementation note: added a dedicated `FactoryCompartmentService` rather than expanding `building_service.py`, because compartment purchases now have their own payment/finalization and line-unlock rules. The service supports package 1-5 purchases, sequential single-level upgrades, level 6/7 purchases with 1 `slot_token`, existing `game_dollar` spend, brick conversion from USD catalog prices, real-money checkout with non-real token debit on finalization, active/queued craft upgrade locks, and early-access x2 metadata for future craft modifiers. Level upgrade finalization now normalizes persisted compartment `early_access` flags once the factory reaches the regular unlock level, and state reads no longer keep stale early-access badges. Added endpoint `POST /buildings/{building_key}/compartments/{compartment_key}/upgrade`, schema request models, repository helper, paid-command dispatcher, and unit coverage. Verified with `pytest app/factory/tests -q` (`69 passed`), `pytest app/factory/tests tests/test_cabinet_payment_sessions.py -q` (`74 passed`), and `ruff check app/factory`.

- [x] Task 22: Implement craft jobs, queues, collect, cancel, cooldowns, and subscription expiry settlement.
  - Deliverable: craft start with reservation, queue up to 5 with subscription, line index support, ready/collect/cooldown lifecycle where cooldown starts on collect, queued/not-started cancel/refund only, active-craft cancel rejection, autostart next queue item after cooldown, and subscription expiry reset/refund rules.
  - Files: `diaverseapi/app/factory/services/crafting_service.py`, `domain/timers.py`, `domain/modifiers.py`, `api.py`.
  - LOGGING REQUIREMENTS: INFO job state transitions and refunds; DEBUG timer/modifier/reservation details; WARNING collect too early, cooldown active, subscription expired; ERROR double-collect or missing reservation invariant.
  - Dependency notes: depends on tasks 11, 12, 12A, 13, 20, and 21.
  - Implementation note: added `FactoryCraftingService`, `FactoryCraftJobCreateRequest`, `FactoryCraftJobActionRequest`, and `quote_factory_timer`. Craft start now settles stale jobs, validates building/compartment/line/recipe state, reserves wired resource inputs, starts immediately or creates a subscription-gated queue entry, and snapshots subscription/modifier/early-access metadata. Job collection credits wired outputs and starts cooldown only on collect. Queued cancel refunds reserved inputs and deliberately skips pre-cancel autostart settlement so a user can remove a not-started queued job. Running/ready/collected jobs cannot be cancelled. State reads now lazily settle ready jobs, cooldown autostart, and expired subscription-dependent queued/running jobs with refunds. Generic catalog recipe parsing supports resource-wired inputs/outputs now; unsupported entity recipes are blocked with a stable action error until dedicated entity adapters are implemented instead of silently debiting or granting nothing. Added `/craft-jobs`, `/craft-jobs/{job_id}/collect`, and `/craft-jobs/{job_id}/cancel` endpoints plus focused tests. Verified with `pytest app/factory/tests/test_crafting_service.py -q` (`8 passed`), `pytest app/factory/tests/test_crafting_service.py app/factory/tests/test_state_service.py -q` (`11 passed`), `pytest app/factory/tests -q` (`77 passed`), `pytest app/factory/tests tests/test_cabinet_payment_sessions.py -q` (`82 passed`), and `ruff check app/factory`.

- [x] Task 23: Implement brick workshop special mechanics.
  - Deliverable: brick craft accepts selected pet fragment, supports 25% luck x3 or 50% with subscription, 5% explosive fragment repair for 12 hours, repair state blocks craft.
  - Files: `diaverseapi/app/factory/services/crafting_service.py`, `domain/policies.py`, catalog recipe entries, tests.
  - LOGGING REQUIREMENTS: INFO special outcome applied; DEBUG random seed/context and selected input class without sensitive data; WARNING craft blocked by repair.
  - Dependency notes: depends on task 22. Randomness must be server-side and auditable.
  - Implementation note: added `domain/policies.py` with pure brick outcome policy and server-side random rolls in `FactoryCraftingService`. Brick craft now requires a selected pet fragment rarity via `input_overrides`, reserves exactly that fragment through `FactoryInventoryGateway`, snapshots luck/explosion rolls in `output_snapshot.brick_special`, applies 25% x3 output by default and 50% x3 with active factory subscription, and uses 5% explosive outcome to set the compartment into 12-hour repair on collect without crediting bricks. Repair state blocks new craft and expired repair is normalized during command/state settlement. Added `rare_pet_fragment`, `epic_pet_fragment`, and `legendary_pet_fragment` as supported `ResourceType` values plus migration enum/resource seeds and state balance excerpts. Verified with `pytest app/factory/tests/test_policies.py app/factory/tests/test_crafting_service.py app/factory/tests/test_inventory_gateway.py app/factory/tests/test_award_resource_support.py -q` (`26 passed`), `pytest app/factory/tests -q` (`85 passed`), `pytest app/factory/tests tests/test_cabinet_payment_sessions.py -q` (`90 passed`), and `ruff check app/factory app/shards_and_resources/models.py migrations/versions/factory_web_state_20260525.py`.

- [x] Task 24: Implement slot-token assembly.
  - Deliverable: assemble slot token from token details/ingredients, idempotent debit/grant, missing requirements response, and immediate inventory update.
  - Files: `diaverseapi/app/factory/services/slot_token_service.py`, `api.py`, catalog recipe entries.
  - LOGGING REQUIREMENTS: INFO slot token assembled/replayed; DEBUG ingredient checks; WARNING missing ingredients; ERROR debit/grant mismatch.
  - Dependency notes: depends on tasks 11, 12, and 14A.
  - Implementation note: extended `slot_token_service.py` with `FactorySlotTokenService.assemble_slot_token`, added `FactorySlotTokenAssembleRequest`, dependency wiring, and endpoint `POST /v1/cabinet/factory/slot-tokens/assemble`. Assembly uses catalog `slot_token.assembly_inputs`, preflights all ingredient balances before mutation, debits `token_details`, `rare_evogen`, and `synthesis_core` through `FactoryInventoryGateway`, credits `slot_token`, writes idempotency response payloads, replays without duplicate movements, and returns immediate state. Added `rare_evogen` plus `synthesis_core` seed coverage to factory resource support so required ingredients resolve through the existing `UserResource` path. Verified with `pytest app/factory/tests/test_slot_token_service.py app/factory/tests/test_inventory_gateway.py app/factory/tests/test_award_resource_support.py -q` (`17 passed`), `pytest app/factory/tests -q` (`88 passed`), `pytest app/factory/tests tests/test_cabinet_payment_sessions.py -q` (`93 passed`), and `ruff check app/factory app/shards_and_resources/models.py migrations/versions/factory_web_state_20260525.py`.

- [x] Task 25: Implement employees/boosters backend support.
  - Deliverable: hire speed/discount/output boosters for factory scopes, duration 1 day to 1 month, no same-type stacking per workshop, active/expired/unavailable states, and payment by existing game dollars through `GameDollarBalanceAdapter`.
  - Files: `diaverseapi/app/factory/services/booster_service.py`, `diaverseapi/app/factory/infrastructure/game_dollar_gateway.py`, `domain/modifiers.py`, `models.py`, `api.py`.
  - LOGGING REQUIREMENTS: INFO booster hired/expired; DEBUG modifier composition; WARNING duplicate same-type hire; ERROR invalid duration or payment mismatch.
  - Dependency notes: can be deferred behind feature flag if MVP needs backend/UI skeleton only, but schema should reserve the model.
  - Implementation note: added catalog-driven employee boosters for speed, output, and cost effects with explicit game-dollar duration prices (`1`, `7`, `30` days) and no new factory-only currency. Implemented `FactoryBoosterService`, `POST /v1/cabinet/factory/boosters/hire`, active/expired settlement, no same-effect stacking per scope, scope validation for buildings/compartments, idempotent hire replay/conflict handling, existing `GameDollarBalanceAdapter` debit flow via `FactoryInventoryGateway`, state serialization, and booster modifier composition for craft cost, duration, and output. Verified with targeted booster/catalog/crafting/state tests (`28 passed`), full factory tests (`92 passed`), factory + payment session tests (`97 passed`), and targeted Ruff across factory modules.

### Phase 5: Backend Tests And Safety Gates

- [x] Task 26: Add backend command tests for idempotency, locking assumptions, and invalid transitions.
  - Deliverable: tests for repeated POST replay, request hash mismatch, insufficient resources, impulse daily cap/replay, collect too early, double collect, cooldown-starts-on-collect, queued cancel/refund, active cancel rejection, subscription expiry refund, early-access normalization, warehouse cap, and demolition refund.
  - Files: `diaverseapi/app/factory/tests/test_commands.py`, `test_warehouse.py`, `test_crafting.py`, `test_subscriptions.py`.
  - LOGGING REQUIREMENTS: tests assert important warnings/errors are emitted for blocked actions where practical.
  - Dependency notes: depends on phases 2-4.
  - Implementation note: extended backend safety-gate coverage in existing service tests instead of adding duplicate files. Added command idempotency replay, locked idempotency, request-hash mismatch conflict, early-access normalization after level upgrade, collect-too-early, double-collect prevention, and impulse claim daily-cap/replay coverage. Existing suite already covered insufficient resources, cooldown-on-collect, queued cancel/refund, active cancel rejection, subscription-expiry refund, warehouse cap, and demolition refund. Verified with targeted command/crafting/impulse/warehouse/building tests (`37 passed`), full factory tests (`99 passed`), and Ruff across factory modules.

- [x] Task 27: Add backend API and schema tests.
  - Deliverable: tests for route registration, response envelope shape, state snapshot serialization, error codes, auth requirements, rollout-disabled behavior, and no guest factory profile creation.
  - Files: `diaverseapi/app/factory/tests/test_api.py`.
  - LOGGING REQUIREMENTS: tests should not depend on noisy DEBUG logs except explicit warning/error assertions.
  - Dependency notes: depends on task 17 and core API tasks.
  - Implementation note: added `app/factory/tests/test_api.py` covering v1 route registration, private no-store catalog/state envelopes, command response serialization, auth failure short-circuiting before command services, rollout-disabled `503` response shape, impulse claim API success/profile-missing behavior, and request schema validation. Closed a contract gap by adding `POST /v1/cabinet/factory/impulses/claim`, `FactoryImpulseClaimRequest`, and the impulse service dependency; the endpoint returns a command envelope with claimed amount, current impulse claim state, replay metadata, and refreshed factory state after successful claims. Verified with API/impulse tests (`12 passed`), full factory tests (`108 passed`), factory + payment session tests (`113 passed`), and Ruff across factory modules.

- [x] Task 28: Add migration and DDL verification notes/scripts if missing.
  - Deliverable: documented verification commands and successful local check for `alembic heads`, migration upgrade SQL compilation, Alembic graph sentinel, deletion/merge FK coverage sentinels, and factory tests.
  - Files: plan file, `diaverseapi/tests/test_alembic_graph.py`, `diaverseapi/tests/test_merge_account_coverage.py`, `diaverseapi/tests/test_delete_user_fk_coverage.py`, and optionally `diaverseapi/docs/` if docs checkpoint creates backend notes.
  - LOGGING REQUIREMENTS: capture migration failures with revision identifiers in implementation notes; no runtime code logging.
  - Dependency notes: required by PostgreSQL identifier-limit planning guard.
  - Implementation note: added `test_factory_web_state_explicit_identifiers_fit_postgresql_limit` to `tests/test_alembic_graph.py`, scanning the factory Alembic source for explicit constraint/index names and asserting every identifier fits PostgreSQL's 63-byte limit. Verified `alembic heads` -> `factory_web_state_20260525 (head)` and `alembic upgrade pet_events_comments_20260525:factory_web_state_20260525 --sql` compiled successfully. Verified Alembic graph + merge-account metadata sentinels with `pytest tests/test_alembic_graph.py tests/test_merge_account_coverage.py -q` (`12 passed`) and Ruff on the migration/test/factory files. `tests/test_delete_user_fk_coverage.py` was attempted but requires a live local PostgreSQL; this workstation has no running PostgreSQL and no `docker` executable, so that DB-backed sentinel remains a required CI/pre-merge command rather than a local pass in this session.

### Phase 6: diaweb BFF, Types, And API Client

- [x] Task 29: Add `diaweb` BFF proxy utilities and route handlers for factory.
  - Deliverable: same-origin `/api/cabinet/factory/*` routes forwarding cookies, language, timezone, Telegram platform headers, selected idempotency transport from Task 2, and Set-Cookie like cabinet shop BFF. Use `cache: "no-store"` and private response headers for every state/command route.
  - Files: `diaweb/frontend/app/api/cabinet/factory/_utils.ts`, route files under `app/api/cabinet/factory/**`.
  - LOGGING REQUIREMENTS: DEBUG upstream start/success in non-production; WARNING upstream non-2xx; ERROR transport failure; include endpoint path and method only, not full payload with resources.
  - Dependency notes: follow `app/api/cabinet/shop/_utils.ts` pattern. Depends on tasks 2 and 2A.
  - Implementation note: added `frontend/app/api/cabinet/factory/_utils.ts` and same-origin route handlers for catalog, state, open, level upgrade, building resource/production/demolition commands, compartment upgrade, warehouse transfers, impulse claim, craft start/collect/cancel, slot-token assembly, and booster hire. The proxy forwards cabinet cookies, `Accept-Language`, `X-TimeZone`, Telegram platform, and request id headers; uses `cache: "no-store"`; copies safe upstream response headers/Set-Cookie through shared BFF cache helpers; and returns sanitized `502` JSON on transport failure. Verified with `npm run lint -- app/api/cabinet/factory modules/factory/types.ts`.

- [x] Task 30: Implement frontend factory API client, types, query keys, and React Query hooks.
  - Deliverable: typed `getFactoryState`, `getFactoryCatalog`, command mutations with idempotency key generation, query invalidation, countdown-friendly `server_time` handling.
  - Files: `diaweb/frontend/modules/factory/api.ts`, `types.ts`, `constants.ts`, `hooks/*.ts`.
  - LOGGING REQUIREMENTS: client debug logs for command lifecycle only in development; WARNING normalized API errors; no logging of full inventory payloads in production.
  - Dependency notes: depends on task 2 and task 29.
  - Implementation note: added `modules/factory/constants.ts`, typed API client, query keys, command input/result types, React Query state/catalog hooks, mutation hooks for every current factory command, idempotency key generation, normalized `FactoryApiError`, and `server_time` clock metadata/timer helpers. The client calls same-origin `/api/cabinet/factory/*`, maps camelCase inputs to backend snake_case payloads, updates the cached state from command responses, invalidates factory state queries, and avoids logging full inventory/state payloads. Verified `diaweb/frontend` with `npm run lint -- modules/factory app/api/cabinet/factory` and `npm run typecheck`.

- [x] Task 31: Add frontend tests for BFF and API normalization.
  - Deliverable: Vitest tests for BFF forwarding/caching/error behavior, selected idempotency transport forwarding, malformed JSON handling, Set-Cookie passthrough, timezone/language/platform forwarding, and API payload normalization.
  - Files: `diaweb/frontend/__tests__/app/api/cabinet/factory/**`, `__tests__/modules/factory/**`.
  - LOGGING REQUIREMENTS: tests should assert warnings for upstream failure where existing BFF tests do so.
  - Dependency notes: depends on tasks 29 and 30.
  - Implementation note: added Vitest coverage for factory BFF proxy utilities, catalog/state/command route handlers, no-store cache behavior, forwarded cookie/language/timezone/Telegram/request-id headers, upstream warning/transport failure logging, malformed JSON command forwarding, idempotency payload forwarding, API clock metadata, command snake_case normalization, generated idempotency keys, returned state snapshots, and normalized `FactoryApiError`. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` (`13 passed`), `npm run lint -- modules/factory app/api/cabinet/factory __tests__/app/api/cabinet/factory __tests__/modules/factory`, and `npm run typecheck`.

### Phase 7: Frontend Scene, Temporary Assets, And Core Screens

- [x] Task 32: Add temporary factory asset pack and asset manifest for layered option A.
  - Deliverable: placeholder map backgrounds for levels 1, 2, 8; transparent building layers for core states; resource/action/subscription icons; effects placeholders; typed manifest with coordinates, anchors, hit areas, z-index, density variants (`1x`/`2x`/`3x` or equivalent responsive WebP/PNG), and a documented mapping from Figma pages/groups `A`, `B`, `V`, `G`, `D` to replaceable asset folders.
  - Files: `diaweb/frontend/public/factory/**`, `diaweb/frontend/modules/factory/assetManifest.ts`.
  - LOGGING REQUIREMENTS: no runtime logging for static assets; development WARNING if manifest references a missing asset or unknown visual key.
  - Dependency notes: asset names must be latin/kebab-case and final-art replaceable.
  - Implementation note: added 44 temporary SVG placeholders under `frontend/public/factory/{maps,buildings,resources,production,subscriptions,ui,effects}` covering level 1/2/8 maps, state layers, warehouse, resource/production/subscription/UI/effect placeholders. Added typed `modules/factory/assetManifest.ts` with stable `visualKey` entries, `1x`/`2x`/`3x` source slots, level scenes, normalized hotspot coordinates/anchors/hit areas/z-index, level 8 `map_only` mode, Figma handoff groups `A/B/V/G/D`, lookup helpers, and development manifest validation warnings. Verified `npm run lint -- modules/factory`, `npm run typecheck`, and asset count under `public/factory` -> 44 files.

- [x] Task 32A: Add factory route protection, private cache, navigation, and i18n shell wiring.
  - Deliverable: `/[lang]/factory` is auth-only in proxy classification, included in private cache header suffixes, visible or intentionally gated in cabinet navigation, covered by navigation icon/assets/dictionaries, and tested through proxy/cache/nav component tests. Direct links while rollout-disabled render controlled unavailable state.
  - Files: `diaweb/frontend/proxy.ts`, `diaweb/frontend/next.config.ts`, `diaweb/frontend/modules/cabinet/components/BottomNav.tsx`, `BottomNavIcon.tsx`, `CabinetTopbar.tsx` if applicable, `CabinetRouteTransition.tsx` if ranking is route-based, `diaweb/frontend/modules/i18n/types.ts`, `diaweb/frontend/modules/i18n/dictionaries/*.json`, `diaweb/frontend/__tests__/proxy.test.ts`, `diaweb/frontend/__tests__/next-config-cache.test.ts`, cabinet navigation tests.
  - LOGGING REQUIREMENTS: follow existing proxy auth logging; no production UI logs; development DEBUG only for unavailable direct-link state.
  - Dependency notes: depends on tasks 2A and 32; blocks task 33.
  - Implementation note: added `/[lang]/factory` to auth-only proxy classification, client cabinet route access, and localized private cache suffixes. Added gated factory nav to mobile bottom nav and desktop topbar via `NEXT_PUBLIC_FACTORY_WEB_ENABLED`, hidden for guests, with `nav-factory.svg`, i18n labels, and route-motion rank between shop and offers. Added minimal `/[lang]/factory` page so rollout-disabled direct links render a controlled cabinet empty state with development-only debug logging. Verified `npm run test -- __tests__/proxy.test.ts __tests__/next-config-cache.test.ts __tests__/modules/cabinet/routeAccess.test.ts __tests__/modules/cabinet/BottomNav.test.tsx __tests__/modules/cabinet/CabinetTopbar.test.tsx __tests__/modules/cabinet/CabinetRouteTransition.test.tsx __tests__/modules/cabinet/Sidebar.test.tsx __tests__/modules/cabinet/CabinetLayout.test.tsx __tests__/modules/cabinet-profile/CabinetProfilePage.test.tsx` -> 87 passed, `npm run lint -- ...` -> no errors (existing next/image mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 33: Implement mobile-first factory shell and route structure.
  - Deliverable: `/[lang]/factory`, warehouse, workshop, and compartment routes inside cabinet layout; bottom nav entry or cabinet entrypoint per product navigation decision; A18 first-entry onboarding overlay with 4 tips, skip/complete persistence, and no repeated forced tutorial after completion.
  - Files: `diaweb/frontend/app/[lang]/(cabinet)/factory/**`, `modules/cabinet/components/BottomNav.tsx`, `BottomNavIcon.tsx`, `modules/factory/components/FactoryOnboardingOverlay.tsx`, i18n labels if needed.
  - LOGGING REQUIREMENTS: no noisy UI logs; DEBUG route-level state load only in development; WARNING when required route param is unknown.
  - Dependency notes: depends on tasks 30, 32, and 32A.
  - Implementation note: added server route pages for `/[lang]/factory`, `/factory/warehouse`, `/factory/workshops/[buildingKey]`, and `/factory/workshops/[buildingKey]/compartments/[compartmentKey]`. Added `FactoryShell`, `FactoryUnavailableState`, and `FactoryOnboardingOverlay` with mobile-first 430px column layout, state loading/error/unopened handling, route tabs, summary metrics, warehouse/workshop/compartment placeholders, development DEBUG state-load logging, and WARNING for unknown route params. A18 onboarding uses exactly 4 tips, skip/done controls, local `profile_id` persistence, and respects backend `profile.onboarding_completed` when it becomes available. Added factory i18n copy in `ru/en` dictionaries. Verified targeted factory/nav/proxy/cabinet tests -> 95 passed, `npm run lint -- ...` -> no errors (existing `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 34: Implement `FactoryScene` layered renderer.
  - Deliverable: background map + building layers + effect overlays + accessible clickable hotspots + info bubbles; supports bounded mobile swipe/pan, responsive hotspot scaling, levels 1, 2, 8, and states locked/ruins/building/ready/active/upgrade/repair/disabled/in-development.
  - Files: `diaweb/frontend/modules/factory/components/FactoryScene.tsx`, `FactoryHotspotLayer.tsx`, `BuildingInfoBubble.tsx`, styles.
  - LOGGING REQUIREMENTS: development WARNING for missing manifest/state mapping; DEBUG selected building interactions only behind dev flag.
  - Dependency notes: do not hardcode coordinates in JSX; use manifest. Level 8 is map-only in this iteration, so hotspot actions must not imply complete level 8 interior screens.
  - Implementation note: added `FactoryScene`, `FactoryHotspotLayer`, `BuildingInfoBubble`, and `factoryScene.module.css`. The renderer uses `FactoryLevelScene`/hotspots from `assetManifest`, renders background map, building/state/effect layers, accessible hotspot links/buttons, focus/hover info bubbles, bounded pointer pan, level 8 `map_only` disabled hotspots, in-development disabled state mapping, development WARNING for missing manifest/state mappings, and interaction DEBUG only when `NEXT_PUBLIC_FACTORY_DEBUG_INTERACTIONS=true`. Integrated the scene into `FactoryShell` map view. Verified `npm run test -- ... FactoryScene/FactoryShell/nav/proxy/cabinet` -> 99 passed, `npm run lint -- modules/factory app/[lang]/(cabinet)/factory __tests__/modules/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 35: Implement central warehouse screen.
  - Deliverable: A3 screen with warehouse/storage sections, 10-hour stop countdown, empty/stopped/autocollect states, transfer actions, future inventory-full state placeholder.
  - Files: `diaweb/frontend/modules/factory/components/FactoryWarehouseScreen.tsx`, route page.
  - LOGGING REQUIREMENTS: DEBUG command submit/success in development; WARNING API command failures with code; no full balance dumps.
  - Dependency notes: depends on tasks 20 and 30.
  - Implementation note: added a backend state-contract enhancement for warehouse timing metadata (`last_accrual_at`, `stop_at`, `remaining_stop_seconds`, `cap_seconds`) and included future warehouse stop timestamps in `next_refresh_at`, because the A3 countdown cannot be correct from pending/stored quantities alone. Added `FactoryWarehouseScreen` and wired the warehouse route through `FactoryShell`; the screen renders central warehouse hero, pending/storage resource sections, stopped and Trademaster autocollect states, exact 10-hour stop countdown, transfer-to-storage and transfer-to-inventory actions with development-safe DEBUG/WARNING logs, empty state, and future inventory-full placeholder. Added focused component coverage for countdown/actions/empty state and state-service assertions for warehouse timing metadata. Verified `pytest app/factory/tests -q` -> 108 passed, `ruff check app/factory` -> passed, `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 28 passed, `npm run lint -- modules/factory app/[lang]/(cabinet)/factory __tests__/modules/factory __tests__/app/api/cabinet/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 36: Implement resource workshop screen.
  - Deliverable: A5 template with resource part state, build/upgrade/progress/demolition entry, production part card, in-development card, and level caps.
  - Files: `diaweb/frontend/modules/factory/components/ResourceWorkshopScreen.tsx`, route page.
  - LOGGING REQUIREMENTS: development DEBUG for selected workshop and action; WARNING unknown state/visual key.
  - Dependency notes: depends on tasks 19, 30, and 32.
  - Implementation note: added `ResourceWorkshopScreen` and wired workshop routes through `FactoryShell`. The A5 screen renders the resource workshop hero, manifest-backed visual/state art, resource part status/level/output, catalog-driven construction and XDV upgrade costs, build/upgrade actions, factory-level upgrade caps, progress placeholder from server metadata when available, a disabled demolition entry reserved for the Task 39 confirmation dialog, production part state, production build entry for available parts such as brick production, and in-development/no-production cards. Added development DEBUG logging for selected workshop and submitted/succeeded/failed actions plus WARNING logs for unknown resource state or missing visual keys. Extended factory i18n dictionaries and added focused component coverage for active upgrade, level-cap blocking, ruined build costs, brick production activation, and unknown state/visual warnings. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 33 passed, `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory'` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 37: Implement production workshop and compartment screens.
  - Deliverable: A6/A7 templates with production build, early access badge, compartment cards, material selection entry, craft timer/ready/cooldown/repair, queue block, collect action, queued-slot remove/refund action menu, no active-craft cancel affordance, and critical placeholder.
  - Files: `ProductionWorkshopScreen.tsx`, `CompartmentScreen.tsx`, route pages.
  - LOGGING REQUIREMENTS: DEBUG craft command lifecycle in development; WARNING blocked API action with reason; ERROR only unexpected UI invariant failure.
  - Dependency notes: depends on tasks 21-23 and 30.
  - Implementation note: added shared catalog view helpers, `ProductionWorkshopScreen`, `CompartmentScreen`, and the dedicated `/factory/workshops/[buildingKey]/production` route. A6 now renders production hero/state art, production build costs/actions using existing impulse/XDV/slot-token resources, early-access badge, catalog/state merged compartment cards, active/ready/queued/cooldown/repair indicators, collect and queued remove/refund actions, safe disabled open/upgrade placeholders for Task 39, and no active-craft cancel affordance. A7 renders parameters, input/output/brick table, temporary material selection entry, craft start through the existing `inputOverrides` API contract, ready collect, cooldown/repair, queue remove/refund, critical placeholder, and DEBUG/WARNING/ERROR logging boundaries. Existing A5 production entry now opens A6 before A7. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 42 passed, `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory' app/api/cabinet/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 38: Implement inventory drawer and material picker.
  - Deliverable: A10 factory inventory drawer/material picker over the existing backend/mobile inventory contract, with filters for resources, pet fragments, token ingredients, products, and missing requirement hints.
  - Files: `FactoryInventoryDrawer.tsx`, supporting picker components/types.
  - LOGGING REQUIREMENTS: DEBUG selected material in development without full inventory logging; WARNING incompatible item selection.
  - Dependency notes: depends on backend state inventory excerpts and task 37. Must reuse existing inventory/resource truth from backend/mobile flows; do not introduce a separate `factory_inventory`, web-only inventory domain, new factory dollars, new XDV, or duplicated balance source.
  - Implementation note: added `FactoryInventoryDrawer` as the A10 factory section over existing `FactoryStateSnapshot.balances` excerpts, filtering out warehouse balances and using only existing `metadata.source=user_inventory`/balance keys for quantities. The drawer supports browse mode from the factory header, category filters for resources, pet fragments, slot tokens, token details, and products, item detail preview, empty-category states, and selection mode from A7. `CompartmentScreen` now opens the drawer for material selection, shows selected materials in the input card, blocks start/queue when required balances are missing, displays missing material hints, and sends selected material keys through the existing `inputOverrides` contract without creating any new inventory domain. Added i18n copy and focused coverage for browse mode, selection mode, brick fragment selection, and header wiring. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 44 passed, `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory' app/api/cabinet/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 39: Implement upgrade, demolition, slot-token, subscription, booster, and in-development dialogs.
  - Deliverable: A4, A8, A9, A11, A12, A15, A17 dialogs/panels with command wiring, backend lock reasons, subscription no-sub/Step Pass Pro/Trademaster states, and navigation to the existing subscription shop/manage flow.
  - Files: `FactoryUpgradeDialog.tsx`, `DemolitionDialog.tsx`, `SlotTokenDialog.tsx`, `SubscriptionDialog.tsx`, `InDevelopmentPanel.tsx`, booster components.
  - LOGGING REQUIREMENTS: DEBUG open/submit/success in development; WARNING blocked action; no payment payload logs.
  - Dependency notes: depends on relevant backend tasks and API hooks.
  - Implementation note: added the Task 39 dialog/panel layer in `diaweb` without introducing new currencies or inventory domains. `FactoryShell` now exposes factory-level upgrade, subscription, slot-token assembly, and existing-inventory shortcuts. `ResourceWorkshopScreen`, `ProductionWorkshopScreen`, and `CompartmentScreen` now open shared upgrade/demolition dialogs instead of disabled placeholders, show shared in-development panels, and include building/compartment scoped booster panels. `FactoryUpgradeDialog` wires factory/resource/compartment commands and checkout metadata without logging payment payloads; `DemolitionDialog` wires the existing demolition command and backend lock reasons; `SlotTokenDialog` assembles from existing inventory balances only; `SubscriptionDialog` renders no-sub/Step Pass Pro/Trademaster states and links to the existing shop/profile flows; `FactoryBoosterPanel` hires employees through the existing game-dollar `hire_booster` command. Added focused `FactoryDialogs.test.tsx` coverage and refreshed screen mocks/expectations. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 49 passed, `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory' app/api/cabinet/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 40: Implement toast stack and animation hooks.
  - Deliverable: A16 toast stack with grouped/collapsed display when more than 3 notifications are visible, plus GSAP/CSS animations for build, upgrade, demolition, warehouse transfer, craft progress, ready ping, collect, cooldown, subscription activation, slot-token assembly, level transition, early-access normalization, level 8 ambient, repair/explosion, in-development, and crit placeholder.
  - Files: `FactoryToastStack.tsx`, `hooks/useFactoryAnimations.ts`, component styles.
  - LOGGING REQUIREMENTS: no animation spam; development WARNING if animation target/ref missing; DEBUG only for diagnosing animation sequence failures.
  - Dependency notes: use existing GSAP dependency and keep animations reduced-motion aware.
  - Implementation note: added `FactoryToastStack` for A16 backend notification hints with newest-three rendering, duplicate compaction, severity styling, `aria-live`, and collapsed `+N` summary for more than three visible items. Added `hooks/useFactoryAnimations.ts` with `deriveFactoryAnimationEvents`, reduced-motion guard, one-time development warnings for missing animation roots/targets, debug-only sequence diagnostics, and lazy GSAP playback. The hook maps backend notification codes plus state markers to build, upgrade, demolition, warehouse transfer, craft progress, ready ping, collect, cooldown, subscription activation, slot-token assembly, level transition, early-access normalization, level 8 ambient, repair/explosion, in-development, and critical-placeholder targets. `FactoryShell`, scene, warehouse, resource workshop, production workshop, and compartment screens now expose stable `data-factory-animation-target` hooks. Added `FactoryAnimations.test.tsx` for toast collapse and animation-event derivation. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 51 passed, `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory' app/api/cabinet/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

### Phase 8: Frontend Tests, Accessibility, And Browser Verification

- [x] Task 41: Add frontend unit/component tests for factory screens.
  - Deliverable: tests for scene rendering by state, map pan/hotspot alignment assumptions, unknown visual fallback, warehouse actions, craft lifecycle states, no active-craft cancel UI, queued-slot remove/refund UI, onboarding completion, toast collapse, queue/subscription expiry messages, slot-token dialog, and error rendering.
  - Files: `diaweb/frontend/__tests__/modules/factory/**`.
  - LOGGING REQUIREMENTS: tests may assert warnings for missing manifest mapping; avoid snapshots that include huge asset manifests.
  - Dependency notes: depends on phases 6-7.
  - Implementation note: audited the existing factory frontend test suite against the Task 41 checklist and filled the remaining gaps. Added bounded map pan coverage in `FactoryScene.test.tsx`, controlled `FactoryShell` error/retry rendering, and queue/subscription expiry toast-message assertions in `FactoryAnimations.test.tsx`. Existing tests already cover scene state rendering, disabled/fallback state art, warehouse actions, craft lifecycle, no active-craft cancel affordance, queued-slot remove/refund actions, onboarding completion/persistence, toast collapse, slot-token dialog submit, and API error normalization. Verified `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 54 passed, `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory' app/api/cabinet/factory` -> no errors (test `next/image` mock warnings only), and `npm run typecheck` -> passed.

- [x] Task 42: Add responsive and accessibility verification.
  - Deliverable: check 390x844, narrow mobile, and desktop centered column; hotspots keyboard accessible; dialogs focus-trapped; text not overlapping; prefers-reduced-motion respected.
  - Files: frontend components/styles and test files as needed.
  - LOGGING REQUIREMENTS: no production logging; document any browser-console warnings fixed during verification.
  - Dependency notes: use Playwright/browser after implementation, especially for layered map nonblank rendering.
  - Implementation note: added a shared `useFactoryDialogFocusTrap` hook and wired it into upgrade, demolition, slot-token, subscription, and existing-inventory drawer dialogs. Added focused accessibility coverage for dialog Tab cycling, Escape close, inventory drawer keyboard close, hotspot focus/bubble behavior, reduced-motion media-query handling, and responsive shell constraints (`mx-auto`, `w-full`, `max-w-[430px]`, mobile padding, desktop centered column). Verification: `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 58 passed; `npm run lint -- modules/factory __tests__/modules/factory 'app/[lang]/(cabinet)/factory' app/api/cabinet/factory` -> no errors, 8 existing `next/image` warnings from test mocks; `npm run typecheck` -> passed. Browser viewport smoke was intentionally skipped after the user explicitly said not to verify in browser; the temporary dev server started for that check was stopped and port 3100 was confirmed closed.

- [x] Task 43: Add final frontend build/type/lint verification.
  - Deliverable: pass `npm run lint`, `npm run typecheck`, targeted Vitest, and `npm run build` or documented blockers.
  - Files: no new product files unless fixes are needed.
  - LOGGING REQUIREMENTS: record command failures in implementation notes with exact command and concise error summary.
  - Dependency notes: depends on frontend tasks.
  - Implementation note: completed the final frontend gate for current factory work. Verification: `npm run lint` -> passed with 65 existing warnings across the broader frontend, mostly `@next/next/no-img-element` in tests/legacy visual surfaces plus unrelated hook/a11y warnings; `npm run typecheck` -> passed; `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 58 passed; `npm run build` -> passed on Next.js 16.2.1/Turbopack, with factory pages and BFF routes emitted as dynamic routes. No product code changes were required for Task 43 beyond the Task 42 fixes already applied.

### Phase 9: Cross-Repo Integration, Docs, And Release Readiness

- [x] Task 44: Add end-to-end integration smoke path.
  - Deliverable: local flow: unauthenticated factory deep link redirects to login, authenticated user opens factory through navigation, rollout-disabled direct link is controlled, onboarding completes, resource workshop builds, impulse claim obeys daily cap, warehouse accrues/transfers, brick craft starts/collects, active craft has no cancel path, queued item can be removed/refunded, slot token blocked/success state works, subscription state renders, and payment checkout stub or real provider-safe path finalizes idempotently.
  - Files: backend tests/frontend tests or manual verification notes as appropriate.
  - LOGGING REQUIREMENTS: backend INFO logs should show command ids and idempotency; frontend console should be clean except intentional dev DEBUG.
  - Dependency notes: depends on tasks 12A, 15A, 32A, and both repos being runnable.
  - Implementation note: completed the integration smoke path without browser/Playwright after the user explicitly said not to verify in browser. Added `docs/tasks/fabric/factory-web-integration-smoke.md` with a requirement-by-requirement evidence map across frontend route/nav/BFF/component tests and backend API/service/payment tests. Added frontend regression coverage for controlled `rollout_enabled=false` factory state in `FactoryShell.test.tsx`. Verification: frontend smoke command `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory __tests__/proxy.test.ts __tests__/modules/cabinet/routeAccess.test.ts __tests__/modules/cabinet/BottomNav.test.tsx __tests__/modules/cabinet/CabinetTopbar.test.tsx` -> 102 passed; backend smoke command `.\.venv\Scripts\python.exe -m pytest app/factory/tests/test_api.py app/factory/tests/test_building_service.py app/factory/tests/test_impulse_service.py app/factory/tests/test_warehouse_service.py app/factory/tests/test_crafting_service.py app/factory/tests/test_slot_token_service.py app/factory/tests/test_subscriptions.py app/factory/tests/test_payment_service.py tests/test_cabinet_payment_sessions.py -q` -> 58 passed, 193 existing dependency/deprecation warnings; targeted frontend lint -> no errors, 10 existing `next/image` mock warnings; `npm run typecheck` -> passed.

- [x] Task 45: Update project/user/developer documentation.
  - Deliverable: docs describing factory architecture, API contract, rollout/auth/cache/navigation policy, catalog editing rules, payment-domain decision, resource/drop processor wiring, impulse collection ownership, asset pack/manifest requirements, Figma/art handoff checklist, mobile-app boundary, mobile developer frontend handoff, and support/debug procedures.
  - Files: likely `docs/tasks/fabric/*`, `docs/features/factory.md` or equivalent root docs, plus repo-local docs if useful.
  - LOGGING REQUIREMENTS: no runtime logging; docs must include where to inspect logs/ledger for support.
  - Dependency notes: docs checkpoint is mandatory by plan settings.
  - Implementation note: added canonical root documentation `docs/features/factory.md` and linked it from `docs/README.md`. The doc covers web/backend ownership, API/BFF contract, rollout/auth/cache/navigation, catalog editing rules, existing currency/inventory boundaries, factory payment finalizer decision, resource/drop processor wiring, impulse ownership, temporary asset manifest requirements, Figma/art handoff checklist, mobile app/frontend handoff, support/debug procedures, and verification commands. Existing `docs/tasks/fabric/factory-web-integration-smoke.md` remains the smoke evidence appendix. Verification: `powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1` -> OK, 73 markdown files checked, 114 local markdown links checked, 0 warnings, 0 errors.

- [x] Task 46: Run targeted GBrain sync after meaningful docs/code changes.
  - Deliverable: source-scoped or full workspace GBrain sync so future AI sessions see the new factory architecture.
  - Files: no product code; may update local GBrain state outside git-tracked source.
  - LOGGING REQUIREMENTS: record sync command/status in final implementation summary; do not auto-capture raw conversations.
  - Dependency notes: run after docs and code stabilize.
  - Implementation note: ran targeted local GBrain sync after factory docs/code updates. Commands: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1 -SourceId diaverse-aif,diaweb-code -SkipDryRun` after Task 42; `... -SourceId diaverse-aif -SkipDryRun` after Task 43; `... -SourceId diaverse-docs,diaverse-aif,diaweb-code -SkipDryRun` after Task 44; `... -SourceId diaverse-docs,diaverse-aif -SkipDryRun` after Task 45. All completed successfully with no embeddings and no conversation capture; GBrain reported existing large-doc content-sanity warnings only.

- [x] Task 47: Final cross-repo verification and cleanup.
  - Deliverable: grouped status, tests, migration checks, browser smoke, branch summary, residual risks, and commit readiness for `diaweb` and `diaverseapi`.
  - Files: no new product files unless final fixes are required.
  - LOGGING REQUIREMENTS: final summary must mention any failed/skipped verification command and why.
  - Dependency notes: do not commit root docs/plans with product repo commits; keep commits per repo.
  - Implementation note: completed final cross-repo verification and cleanup without browser/Playwright per direct user instruction. Removed temporary `diaweb/factory-dev-3100.*.log` files and confirmed no dev server remained on port 3100. Backend checks: `pytest app/factory/tests -q` -> 108 passed; `pytest tests/test_cabinet_payment_sessions.py tests/test_alembic_graph.py -q` -> 15 passed; `ruff check app/factory app/routers/v1/endpoints.py app/security/usecases.py app/security/exceptions.py app/core/features.py app/core/settings.py app/cabinet/payments app/shards_and_resources/models.py tests/test_cabinet_payment_sessions.py tests/test_alembic_graph.py tests/test_merge_account_coverage.py` -> passed; `alembic heads` -> `factory_web_state_20260525 (head)`; `alembic upgrade pet_events_comments_20260525:factory_web_state_20260525 --sql` -> compiled successfully. Broader merge safety command `pytest tests/test_cabinet_payment_sessions.py tests/test_alembic_graph.py tests/test_merge_account_coverage.py -q` had 16 passed and 1 failed because `test_merge_account_coverage.py` reports pre-existing non-factory `cab_crypton_*` and `club_*` tables that are not classified in the merge-account sentinel; this was recorded as a residual cross-domain blocker rather than hidden in the factory change. Frontend checks: `npm run typecheck` from `diaweb/frontend` -> passed; `npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory` -> 59 passed. Previous final frontend gate remains valid: `npm run lint` -> passed with existing warnings and `npm run build` -> passed. Current product branches are `diaweb` and `diaverseapi` on `feature/factory-web-engine`; root docs/plan changes remain in the workspace coordination repo. Browser smoke is intentionally skipped by instruction.

## Verification Plan

diaverseapi:
- `.\.venv\Scripts\python.exe -m pytest app/factory tests`
- `.\.venv\Scripts\python.exe -m pytest app/security tests` for deletion/merge safety, adjusted to available test layout
- targeted tests for `GameDollarBalanceAdapter`: loads `BotUser.dao_balans`, credits factory-generated game dollars, debits employee/booster prices, rejects insufficient balance, and does not create `UserResource` rows or a parallel factory wallet.
- `.\.venv\Scripts\python.exe -m pytest tests/test_alembic_graph.py tests/test_merge_account_coverage.py tests/test_delete_user_fk_coverage.py`
- `.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_payment_sessions.py` plus factory payment/finalizer tests
- targeted event-token/slot-token regression tests covering `AwardKind`, `LootBoxAwardKind`, processors, and drop services
- `.\.venv\Scripts\python.exe -m alembic heads`
- `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
- `.\.venv\Scripts\python.exe -m ruff check app/factory app/routers/v1/endpoints.py app/security/usecases.py`

diaweb:
- `npm run lint`
- `npm run typecheck`
- `npm run test -- factory`
- targeted BFF tests under `__tests__/app/api/cabinet/factory`
- `npm run test -- proxy next-config-cache BottomNav CabinetTopbar`
- `npm run build`
- browser smoke at mobile `390x844` and desktop centered layout; verify layered map is nonblank and hotspots align.

Cross-repo:
- Verify same-origin BFF headers/cookies/timezone forwarding.
- Verify `/factory` is auth-only, included in private cache rules, and present/gated in cabinet navigation.
- Verify rollout-disabled behavior is stable on backend and frontend.
- Verify backend route path and frontend BFF path match.
- Verify idempotency keys are generated/forwarded/replayed.
- Verify state snapshot supports UI without frontend reimplementing backend gates.
- Verify factory payment domain is fully registered or shop-backed path is explicitly used end to end.
- Verify XDV debit uses the canonical XDV balance path and is not accidentally stored as a normal resource row.
- Verify game-dollar generation/spend uses existing `BotUser.dao_balans` / `UserRead.gaming_balance`, not a new factory-only currency.
- Verify impulse claim honors 1 step = 1 impulse and daily cap 30,000.
- Verify slot-token drop modifiers are either implemented in the real chest/loot source with calibration tests or explicitly feature-gated with a documented blocker.
- Verify active craft cannot be cancelled, queued jobs can be removed/refunded before start, and cooldown begins only after collect.
- Verify onboarding, toast collapse, map pan/swipe, and level 8 map-only behavior in browser smoke.
- Run targeted GBrain sync after completion.

## Commit Plan

- **Commit 1 - diaverseapi** (tasks 3-10 plus rollout skeleton): `feat: add factory domain skeleton and catalog`
- **Commit 2 - diaverseapi** (tasks 11-16 plus 12A, 14A, 15A): `feat: wire factory inventory subscriptions and payments`
- **Commit 3 - diaverseapi** (tasks 17-25): `feat: implement factory commands and timers`
- **Commit 4 - diaverseapi** (tasks 26-28): `test: cover factory backend engine`
- **Commit 5 - diaweb** (tasks 29-31): `feat: add factory bff and client hooks`
- **Commit 6 - diaweb** (tasks 32-40 plus 32A): `feat: build factory web interface`
- **Commit 7 - diaweb** (tasks 41-43): `test: cover factory frontend flows`
- **Commit 8 - root docs or affected repos** (tasks 45-47): `docs: document factory architecture and rollout`

## Risk Register

- Inventory mismatch risk: factory touches many resource/entity systems; mitigate with `FactoryInventoryGateway`, ledger, snapshots, and tests.
- Payment ambiguity risk: `$` is overloaded in docs; resolve before implementing purchases.
- Payment registry drift risk: adding a factory checkout without updating `CabinetPaymentDomainCode`, provider `domain_codes`, and finalizer registry creates paid sessions that cannot finalize; mitigate with registry/finalizer tests.
- Game-dollar source drift risk: factory could accidentally create a second "game dollar" balance; mitigate with `GameDollarBalanceAdapter`, tests against `BotUser.dao_balans`, and a no-new-currency catalog/resource check.
- XDV balance drift risk: incorrectly treating XDV as a resource row can split balances; mitigate with a canonical XDV adapter and tests against existing balance semantics.
- Route exposure/cache risk: adding `/factory` without proxy auth and private cache rules can expose private state; mitigate with proxy/cache tests before UI release.
- Navigation rollout risk: hidden direct links or enabled nav while backend is disabled create broken entrypoints; mitigate with shared rollout policy and nav tests.
- Event-token collision risk: slot-token drops are similar to existing event-token drops; mitigate with separate service or parameterized shared service plus event-token regression tests.
- Subscription race risk: expiry can happen while jobs/queues are active; settle subscription state at every state/command entry.
- Catalog drift risk: active jobs must store snapshots and `catalog_version`.
- Timer drift risk: never trust client countdown; all collection/cooldown decisions use server time.
- Impulse ownership risk: step data may be owned outside factory; mitigate by deciding ownership in Task 1 and testing 1 step = 1 impulse, daily cap 30,000, and replay behavior.
- Spec mismatch risk: designer brief forbids active-craft cancellation and requires onboarding/map pan/toast collapse; tests must lock these UI states.
- Loot economy risk: slot-token details affect chest/loot economy outside factory API; do not mark subscriptions complete until this source is implemented or explicitly feature-gated.
- Asset replacement risk: use manifest and visual keys from day one so final assets do not require component rewrites.
- Merge/delete risk: new tables must be included immediately in security cleanup/merge logic.
- PostgreSQL DDL risk: short explicit constraint names and SQL compilation check required.
- Scope risk: full 1-8 mechanics are large; backend catalog must carry full mechanics, while frontend UI priority remains level 1-2 playable screens and level 8 map-only rendering.

## Definition Of Done

- `diaverseapi` exposes `/v1/cabinet/factory` with full level 1-8 catalog data, state, and all MVP commands.
- Factory backend and frontend are rollout-gated, auth-only, and covered by route/cache/navigation tests.
- Every mutating command is idempotent, transactional, logged, and ledgered.
- Factory payment checkout is either fully registered as `factory` across cabinet payment types/providers/finalizers or deliberately implemented through shop-backed checkout with tests.
- Game-dollar prices, generation, employee/booster hires, and UI balances use the existing gaming balance (`BotUser.dao_balans` / `UserRead.gaming_balance`); no new factory-only game-dollar wallet or resource type is introduced.
- XDV uses the canonical balance/debit path; resource rows and award/loot processors cover `impulse`, `token_details`, and `slot_token` without breaking event-token behavior.
- Impulse collection supports 1 step = 1 impulse, daily cap 30,000, deterministic reset, and replay-safe collection.
- Running/active crafts cannot be cancelled; queued/not-started jobs can be removed/refunded; cooldown starts only on collect.
- Factory state can be rendered by `diaweb` without frontend-side business-rule duplication.
- `diaweb` has mobile-first factory routes, layered map renderer with bounded pan/swipe, placeholder assets, onboarding A18, key screens A1-A18 coverage for levels 1-2, and final level 8 map-only state.
- Tests cover catalog validation, slot-token drop/modifier rules or feature gate, command invariants, BFF forwarding, frontend state rendering, onboarding, toast collapse, and key user flows.
- Docs explain backend architecture, frontend asset manifest, Figma/art handoff, mobile-app boundary, and support/debug paths.
- GBrain is synced after docs/code stabilize.
