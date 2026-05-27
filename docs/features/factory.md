# Factory Web

Updated: 2026-05-26
Status: implemented behind authenticated web cabinet rollout

## Overview

Factory is a web-cabinet feature. The browser entrypoint is `diaweb`; the authoritative game logic, timers, balances, idempotency, payments, and persistence live in `diaverseapi`.

Flow:

```text
Browser -> diaweb /api/cabinet/factory/* -> diaverseapi /v1/cabinet/factory/*
```

The mobile app does not own the new factory UI. Mobile remains the owner of its existing native surfaces such as steps, existing inventory display, and other already shipped gameplay screens. Factory state must not be duplicated in the mobile frontend.

## Ownership

| Area | Owner | Notes |
| --- | --- | --- |
| Web UI and BFF | `diaweb/frontend` | Routes under `/{lang}/factory` and same-origin BFF routes under `/api/cabinet/factory/*`. |
| Factory domain | `diaverseapi/app/factory` | State, commands, catalog rules, timers, idempotency, warehouse, crafting, subscriptions, payments, notifications. |
| Existing inventory truth | `diaverseapi` existing resource/inventory tables | Factory consumes and credits existing inventory through `FactoryInventoryGateway`. |
| Existing game dollars | Existing `BotUser.dao_balans` path | Factory boosters and generated game-dollar collection use `GameDollarBalanceAdapter`; no factory-only wallet. |
| Existing XDV | Existing XDV balance path | Factory upgrade pricing uses the existing XDV adapter; no new XDV balance. |
| Temporary web assets | `diaweb/frontend/public/factory` and `modules/factory/assetManifest.ts` | Placeholder art until final Figma/art pack replaces it. |

## Architecture

### Backend

Backend package:

```text
diaverseapi/app/factory/
|-- api.py
|-- schemas.py
|-- models.py
|-- dependencies.py
|-- catalog/
|   |-- data/factory_catalog.v1.yaml
|   |-- loader.py
|   |-- schema.py
|   `-- validator.py
|-- domain/
|   |-- modifiers.py
|   |-- money.py
|   |-- policies.py
|   |-- pricing.py
|   `-- timers.py
|-- infrastructure/
|   |-- game_dollar_gateway.py
|   |-- inventory_gateway.py
|   |-- payment_gateway.py
|   |-- repositories.py
|   |-- rollout.py
|   |-- subscription_resolver.py
|   `-- xdv_gateway.py
`-- services/
    |-- building_service.py
    |-- command_service.py
    |-- crafting_service.py
    |-- impulse_service.py
    |-- payment_service.py
    |-- slot_token_service.py
    |-- state_service.py
    `-- warehouse_service.py
```

Rules:

- Backend is the source of truth for all actions.
- Every command must be idempotent.
- Frontend command buttons are convenience only; backend still validates requirements and state transitions.
- Factory rows store factory-owned progress, not a second copy of player inventory.
- Inventory and payment-relevant movements must go through gateways and ledger writes.

### Frontend

Frontend package:

```text
diaweb/frontend/modules/factory/
|-- api.ts
|-- assetManifest.ts
|-- catalogView.ts
|-- components/
|-- hooks/
|-- constants.ts
`-- types.ts
```

Routes:

```text
/{lang}/factory
/{lang}/factory/warehouse
/{lang}/factory/workshops/{buildingKey}
/{lang}/factory/workshops/{buildingKey}/production
/{lang}/factory/workshops/{buildingKey}/compartments/{compartmentKey}
```

Frontend rules:

- Use `FactoryStateSnapshot` from `/api/cabinet/factory/state` as the UI input.
- Mutations must use the typed command hooks from `modules/factory/hooks/useFactoryMutations.ts`.
- Never calculate spendability, refunds, paid unlocks, queue rights, subscription rights, or craft outcomes only in the browser.
- Do not log full inventory/state payloads in production.
- Keep factory as a mobile-first 430px-centered cabinet column.

## API Contract

Backend API prefix:

```text
/v1/cabinet/factory
```

Same-origin BFF prefix:

```text
/api/cabinet/factory
```

Core read endpoints:

```text
GET /catalog
GET /state
```

Core command endpoints:

```text
POST /open
POST /levels/upgrade
POST /buildings/{buildingKey}/resource/build
POST /buildings/{buildingKey}/resource/upgrade
POST /buildings/{buildingKey}/production/build
POST /buildings/{buildingKey}/demolish
POST /buildings/{buildingKey}/compartments/{compartmentKey}/upgrade
POST /warehouse/transfer-to-storage
POST /warehouse/transfer-to-inventory
POST /impulses/claim
POST /craft-jobs
POST /craft-jobs/{jobId}/collect
POST /craft-jobs/{jobId}/cancel
POST /slot-tokens/assemble
POST /boosters/hire
```

Command contract:

- request body includes `idempotency_key`;
- command response includes command status, state when available, errors, notifications, and metadata;
- command replay must not repeat inventory/payment mutations;
- frontend converts camelCase inputs to backend snake_case through `modules/factory/api.ts`.

State response must include enough data to render without extra per-card calls:

- server time and clock metadata;
- rollout flag;
- profile state;
- map/building/compartment visuals;
- warehouse balances and timing metadata;
- existing user inventory excerpts;
- jobs and available actions;
- subscription state;
- impulse claim state;
- notification hints and next refresh hints.

## Rollout, Auth, Cache, Navigation

Factory is authenticated-only.

Frontend gates:

- `diaweb/frontend/proxy.ts` classifies `/factory` as auth-only.
- `modules/cabinet/routeAccess.ts` marks factory as non-guest.
- `BottomNav` and `CabinetTopbar` show factory only for authenticated users when factory navigation rollout is enabled.

Cache policy:

- factory BFF responses are private and `no-store`;
- frontend React Query may cache in-memory briefly for UX, but backend state remains authoritative;
- route pages are dynamic cabinet pages.

Rollout policy:

- backend disabled rollout returns a controlled factory-disabled envelope;
- frontend `FactoryShell` renders `FactoryUnavailableState` when `rollout_enabled=false`;
- no guest factory profiles, guest payments, or guest factory inventory state are created in the initial implementation.

## Catalog Editing Rules

Catalog source:

```text
diaverseapi/app/factory/catalog/data/factory_catalog.v1.yaml
```

When editing catalog data:

- keep `catalog_version` stable unless the schema/meaning changes;
- run catalog validation tests;
- add visual keys to `diaweb/frontend/modules/factory/assetManifest.ts` or keep a documented fallback;
- do not add a resource kind unless it is supported by `FactoryPriceKind` and inventory/resource mapping;
- check level requirements, early-access rows, prices, generation rates, queue settings, cooldowns, subscription multipliers, and slot-token assembly inputs together;
- keep money rounding in backend domain helpers, not in UI copy.

Recommended checks:

```powershell
.\.venv\Scripts\python.exe -m pytest app/factory/tests/test_catalog.py app/factory/tests/test_award_resource_support.py -q
```

## Currency And Resource Rules

There are no new factory-only currencies.

Use existing balances:

- `game_dollar` is the existing in-game dollar balance, backed by the existing game-dollar storage path.
- `xdv` is the existing XDV balance.
- real money is only a payment rail for configured paid actions, not an in-game balance.

Factory resources/items:

- `impulse`, `slot_token`, `token_details`, pet fragments, evogens, mutagens, nullifiers, biomass, bricks, gears, and other catalog resources are inventory/resource entities.
- Factory may maintain warehouse pending/storage balances, but warehouse is a production buffer, not the player's global inventory.
- Transfer-to-inventory credits existing inventory only through backend gateways.

## Inventory Boundary

Do not create:

- `factory_inventory`;
- web-only inventory rows;
- factory-only dollars;
- a second XDV source;
- frontend-only balance truth.

The web inventory drawer is just an A10 view/picker over existing backend inventory excerpts in `FactoryStateSnapshot.balances`. It filters user inventory balances by `metadata.source=user_inventory` and excludes `warehouse:*` balances.

## Payment Domain Decision

Factory paid actions use the generic cabinet payment session layer with a factory domain code and factory finalizer.

Rules:

- real-money commands create checkout/session metadata and do not mutate paid state until finalization;
- finalizers are idempotent;
- amount/domain mismatch must not apply commands;
- missing command applier marks review-required instead of guessing.

Key tests:

```text
diaverseapi/app/factory/tests/test_payment_service.py
diaverseapi/tests/test_cabinet_payment_sessions.py
```

## Resource And Drop Processor Wiring

Factory resources are wired into existing award/resource infrastructure where needed:

- factory resource enums align with existing `ResourceType`, `AwardKind`, and loot processors;
- slot token/detail drops use catalog-defined keys;
- subscription modifiers affect slot-token detail drops through backend modifier logic;
- web UI only displays resulting state and notification hints.

Before adding a new factory resource, update:

- catalog schema/data;
- `FactoryPriceKind` if needed;
- inventory gateway mapping;
- resource/award processor support;
- migration seed/lookup values if the resource must be persisted in existing resource tables;
- frontend asset manifest and labels.

## Impulse Collection Ownership

Impulse collection is backend-owned.

Rules:

- daily cap, user timezone reset, replay/idempotency, and crediting are handled by `FactoryImpulseService`;
- web calls `/api/cabinet/factory/impulses/claim`;
- mobile app must not implement a separate daily cap or separate impulse wallet;
- existing steps/activity data remains outside `diaweb`, exposed only through backend adapters.

## Asset Pack And Manifest Requirements

Temporary assets live under:

```text
diaweb/frontend/public/factory/
```

Manifest:

```text
diaweb/frontend/modules/factory/assetManifest.ts
```

Current asset groups:

- maps for levels 1, 2, and 8;
- building state layers: locked, ruins, building, ready, active, upgrade, repair, disabled;
- central warehouse;
- resource icons;
- production/entity icons;
- subscription badges;
- UI icons;
- static animation frames/effects.

Asset replacement rules:

- preserve manifest keys or update all call sites/tests together;
- prefer deterministic file names and stable visual keys;
- keep maps and hotspot hit areas in sync;
- use SVG/bitmap formats supported by Next static assets;
- keep accessibility labels in UI dictionaries, not image filenames.

## Figma And Art Handoff Checklist

When final art is delivered:

- map images for levels 1, 2, and 8;
- separate building/cell states for all required states;
- warehouse/central storage art;
- resource and production icons;
- subscription badges: no sub, Step Pass Pro, Trademaster;
- UI action icons: queue, autocollect, timer, cooldown, repair, collect, upgrade, demolition;
- static animation frames for build, collect, repair/explosion, slot-token assembly, level 8 final state;
- hotspot coordinates for every map level;
- safe mobile crop guidance for 390px width;
- source Figma node/page references if available.

After replacement:

```powershell
npm run test -- __tests__/modules/factory
npm run lint -- modules/factory __tests__/modules/factory
npm run typecheck
```

## Mobile App Boundary And Handoff

What mobile frontend should do:

- keep existing inventory display and existing game-dollar/XDV surfaces aligned with backend truth;
- continue existing steps/activity flows as currently owned by mobile/backend;
- show factory-related inventory items if the existing inventory screen already lists resource entities;
- use backend-provided labels/icons where the mobile inventory already supports remote/resource assets.

What mobile frontend should not do for this phase:

- do not build a native factory screen;
- do not create a separate factory inventory;
- do not create factory-only game dollars or XDV;
- do not locally simulate factory production, timers, queue, subscription effects, paid unlocks, or craft outcomes;
- do not call web BFF routes from mobile; mobile should use backend/mobile API contracts if factory surfaces are introduced later.

If mobile later needs factory entrypoints, define a separate mobile API handoff from `diaverseapi`; do not reuse `diaweb` BFF routes.

## Support And Debug Procedures

Primary checks:

1. Confirm rollout/auth:
   - frontend proxy classification;
   - backend rollout flag;
   - user has authenticated cabinet session.
2. Inspect backend command response:
   - `status`;
   - `idempotency_key`;
   - `errors`;
   - `metadata`;
   - returned `state`.
3. Inspect factory ledger/movement records for inventory/payment-relevant changes.
4. Inspect cabinet payment session/finalizer state for paid actions.
5. Inspect cabinet notifications if persistent factory notifications are expected.

Logging expectations:

- backend command logs should include command/action IDs and idempotency keys;
- backend logs must not dump full inventory payloads;
- frontend production logs should not include full state/inventory;
- frontend dev-only debug flags:
  - `NEXT_PUBLIC_FACTORY_DEBUG_INTERACTIONS=true`
  - `NEXT_PUBLIC_FACTORY_DEBUG_ANIMATIONS=true`

Common symptoms:

| Symptom | First place to check |
| --- | --- |
| Factory link missing | `NEXT_PUBLIC_FACTORY_WEB_ENABLED`, auth state, `BottomNav`/`CabinetTopbar` rollout props |
| Direct link redirects to login | auth cookies/session and `proxy.ts` auth-only rules |
| Factory unavailable | backend rollout envelope and `FactoryUnavailableState` |
| Button disabled | backend `available_actions` and `lock_reasons` |
| Balance seems wrong | existing inventory/gateway/ledger, not frontend cache |
| Paid action did not apply | cabinet payment session status and factory finalizer |
| Craft result missing | craft job status, collect command response, inventory ledger |
| Subscription benefits missing | subscription resolver state and modifier snapshot |

## Verification

Current smoke evidence is tracked in:

```text
docs/tasks/fabric/factory-web-integration-smoke.md
```

Useful command set:

```powershell
# diaweb
npm run lint
npm run typecheck
npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory
npm run build

# diaverseapi
.\.venv\Scripts\python.exe -m pytest app/factory/tests -q
.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_payment_sessions.py -q
.\.venv\Scripts\python.exe -m ruff check app/factory
.\.venv\Scripts\python.exe -m alembic heads
```

Browser smoke was intentionally skipped on 2026-05-26 by user request. Run it later before release if the user allows browser verification.
