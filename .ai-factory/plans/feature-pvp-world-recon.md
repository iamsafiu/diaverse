# Implementation Plan: PvP World & Recon (Part 1)

Branch: `feature/pvp-world-recon`
Created: 2026-07-27

## Settings

- Testing: yes
- Logging: standard
- Docs: yes
- Delivery: multi-repo vertical slices; backend contract slightly ahead of frontend
- Rollout: default-off, web-first, separate gates for world/map and paid scouting

## Workspace Mode

- Mode: multi-repo full
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain sources via `scripts\gbrain.ps1`, verified against raw source
- Product repositories: separate git repositories; the workspace root is coordination/docs only

## Branch Safety

- The shared branch ref `feature/pvp-world-recon` was created in `diaweb` from `78b54418` and in `diaverseapi` from `860d07a6`.
- No checkout, stash, reset, commit, or modification of the existing dirty working trees was performed.
- Existing Referral/Crypton work remains outside the PvP branch refs.
- Before implementation, use clean isolated worktrees for both child repositories or wait until the other agent finishes and then switch both repositories to the shared branch.
- The Alembic down revision must be resolved again at implementation time because another backend change may add a newer migration head.

## Repository Matrix

| Repository | Path | Affected | Branch | Git status at planning | Role |
| --- | --- | --- | --- | --- | --- |
| workspace root | `C:\Users\Indigo\Desktop\diaverse` | yes | current root branch | dirty, unrelated work present | master plan and feature docs |
| diaweb | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `feature/pvp-world-recon` ref created, not checked out | dirty on `master`, unrelated Referral/Crypton work | web UI and same-origin BFF |
| diaverse-mobile | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | none | clean | explicitly deferred |
| diaverseapi | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `feature/pvp-world-recon` ref created, not checked out | dirty on `main`, unrelated Referral work | PvP domain, persistence, API, timers |
| aibot | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | none | dirty, unrelated work | no PvP responsibility |
| diaverse-content | `C:\Users\Indigo\Desktop\diaverse\diaverse-content` | no | none | clean | no PvP responsibility |
| diaverse-ai-cofounder | `C:\Users\Indigo\Desktop\diaverse\diaverse-ai-cofounder` | no | none | not inspected; archived/R&D | no runtime responsibility |
| club10000-bot | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | none | clean | no PvP responsibility |
| diaverse-auth-bot | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | none | clean | no PvP responsibility |

## Research Context

Source: `.ai-factory/RESEARCH.md` (Active Summary)

Topic: `PvP World & Recon` — first implementation part for the Diaverse web product.

Goal:
- Deliver a finite player map, public PvP profiles, search/filtering, routes, and persistent scouting dossiers.
- Establish only the minimum stable mechanics and persistence required by this epic and the later combat epic.

Constraints:
- Source requirements: `C:\Users\Indigo\Downloads\КАРТА.doc` and `C:\Users\Indigo\Downloads\PvP+Diaverse+2.doc`.
- Part 1 affects only `diaverseapi`, `diaweb`, and root-owned documentation.
- Use the current FastAPI/SQLModel/PostgreSQL and Next.js/TanStack Query patterns.
- No microservice, PostGIS, map tile service, WebSocket/SSE, event sourcing, or generic mission framework.
- Server owns coordinates, visibility, timings, outcomes, and privacy boundaries.
- Map is a bounded `1000 × 1000` game plane rendered with DOM/CSS/SVG.
- Coordinates are public; scouting has ten equal fields by splitting hospital waiting and active-treatment counts.

Decisions:
- Dedicated backend bounded context: `diaverseapi/app/pvp`.
- Two rollout capabilities: world/map and paid scouting.
- Versioned JSON-compatible YAML catalog for world/scouting rules.
- Persisted immutable scouting attempts plus an updatable current fact per dossier field.
- Polling, API deadline reconciliation, and a minute TaskIQ sweeper.
- Attack is visibly unavailable until Part 2; no fake combat transition.

Open product input:
- Final art asset/direction for the map. Implementation must support a versioned background without coupling coordinates to image pixels.

## Product Scope

### Included

- PvP profile bootstrap with starting rating `1000` and minimal protection/calibration projection.
- Server assignment of immutable integer Factory coordinates in `[0, 999]`.
- Reserved central zone `X=400..599`, `Y=400..599`.
- Initial batched placement of existing active/open Factories and immediate placement of newly available Factories.
- Public world bootstrap, viewport markers/clusters, public Factory card, route/distance projection.
- Search by public pilot name, stable internal UUID, `X:Y`, and `X, Y`.
- Nearest eligible targets, limited to 30, and Part-1-compatible filters.
- Scouting confirmation, `100 XDV` atomic charge, timed drone operation, route/progress display.
- `65%` information success, `30%` independent detection, ten equal field choices.
- Persistent dossier, attempt history, timestamps, stale-data labeling, rediscovery overwrite semantics.
- Defender notification when a drone is detected.
- Responsive and accessible web experience behind default-off flags.

### Explicitly deferred to Part 2

- Army selection, accelerator consumption for armies, attack registration, recall, incoming attack market locks.
- Battle snapshots, rounds, choices, abilities, combat report, retreat, settlement, rating mutation.
- Factory disruption/repair, loot transfer, PvP tokens, cooldown enforcement.
- Hospital entries, treatment, permanent death, character activity locks.
- Mobile client.
- Realtime transport.
- Army-related map filters and marker states.

## Architecture

```text
diaweb /[lang]/pvp
        |
        v
same-origin /api/cabinet/pvp/* BFF
        |
        v
diaverseapi /v1/cabinet/pvp/*
        |
        +--> pvp catalog + pure geometry/placement/power policies
        |
        +--> pvp services/repository --> pvp_profiles
        |                            --> pvp_scout_attempts
        |                            --> pvp_scout_facts
        |
        +--> narrow gateways --> Factory / Characters / Raids availability
                             --> XDV balance / Cabinet notifications
```

Dependency rules:

- API endpoints perform authentication, validation, error mapping, and response shaping only.
- PvP domain functions are pure and cannot import FastAPI, SQLAlchemy sessions, or frontend concepts.
- PvP services own transactions and orchestration.
- Cross-domain reads go through PvP-owned gateways; private values never enter generic map projections.
- Factory activation calls a narrow idempotent PvP placement integration hook. No general event bus is introduced for this feature.
- The existing Factory XDV adapter may be wrapped by a PvP gateway for Part 1; do not refactor all XDV consumers during this epic.
- Hospital scouting producers return typed zero counts until Part 2 introduces actual hospital entries; the dossier contract must not change later.

## Versioned Rules Contract

`pvp_catalog.v1` must contain:

- world bounds, `world_version`, reserved-zone bounds;
- sector size `100`, five-least-populated placement choice, placement version;
- distance: `sqrt((x1-x2)^2 + (y1-y2)^2)`;
- base flight minutes: `ceil(5 + distance / 20)`;
- scouting cost: `100 XDV`;
- scouting duration: `max(2 minutes, ceil(base flight minutes / 4))`;
- information success: `65%`;
- drone detection: `30%`;
- ten equally weighted fact keys;
- public response schema/rules version and visual keys.

The ten scouting facts are:

1. Defensive army power with `±10%` obfuscation.
2. Total defending pet count.
3. Counts of Guardians, Ranged, and Assault pets.
4. Ten strongest defending pets with species, level, mutation, and `Cpvp`.
5. Active Rhino, Hippo, and Elephant heroes.
6. Working and damaged production buildings.
7. Vulnerable resource-stock range.
8. Number of ready production units.
9. Pets in hospital awaiting treatment.
10. Pets whose treatment has started.

Coordinates, distance, and base flight time are public and are not a scouting fact.

## API Contract Outline

Backend and BFF paths should align around:

- `GET /catalog`
- `GET /state`
- `GET /map?min_x=&max_x=&min_y=&max_y=&zoom_bucket=&filters=`
- `GET /search?q=&cursor=&limit=`
- `GET /nearby?cursor=&limit=30&filters=`
- `GET /profiles/{profile_id}`
- `GET /profiles/{profile_id}/route`
- `GET /profiles/{profile_id}/dossier`
- `GET /scouting/attempts/{attempt_id}`
- `GET /scouting/history?profile_id=&cursor=`
- `POST /scouting/attempts`

All responses include `schema_version` and `server_time`. Private endpoints use no-store response semantics. The map endpoint returns a bounded discriminated union of `factory` and `cluster`; it never returns all Factories in one response.

## Persistence Outline

### `pvp_profiles`

- one row per available `FactoryProfile`;
- unique `factory_profile_id`;
- immutable `world_version`, `x`, `y`, placement version;
- rating default `1000`;
- minimal newbie/calibration counters/timestamps needed for public status;
- DB checks for bounds and reserved-zone exclusion;
- unique `(world_version, x, y)`;
- short explicit indexes for viewport/sector queries.

### `pvp_scout_attempts`

- actor/target PvP profile IDs;
- status and terminal result;
- idempotency key plus request fingerprint;
- catalog/rules/geometry versions;
- distance, base-flight, scouting-duration, departure/arrival snapshots;
- server-generated success, selected-field, and detection rolls stored once;
- fact payload is read from the target at completion, not at departure;
- partial unique index allowing only one active actor-to-target drone;
- complete attempt history retained.

### `pvp_scout_facts`

- dossier owner, target profile, field key;
- typed JSON value validated at write/read boundaries;
- observed/updated timestamp and source attempt ID;
- unique current fact per `(owner, target, field_key)`;
- rediscovery replaces the current value while the attempt history remains immutable.

## Commit Plan

- **Commit 1 — diaverseapi, after Tasks 1-3:** `feat(pvp): add world profiles and placement`
- **Commit 2 — diaverseapi, after Tasks 4-6:** `feat(pvp): add map and scouting APIs`
- **Commit 3 — diaweb, after Tasks 7-9:** `feat(pvp): add world map discovery`
- **Commit 4 — diaweb, after Tasks 10-11:** `feat(pvp): add scouting dossier and cabinet entry`
- **Commit 5 — workspace root, after Task 12:** `docs(pvp): document world and recon rollout`

Commits are suggestions for later implementation. This planning run does not commit existing or new work.

## Tasks

### Phase 1: Versioned mechanics and persistence

- [x] **Task 1: [diaverseapi] Add the PvP module, versioned catalog, pure geometry/contour/power rules, and rollout capabilities.**
  - Deliverable:
    - scaffold `app/pvp` with `api.py`, `dependencies.py`, `exceptions.py`, catalog loader/schema/validator, domain modules, and package exports;
    - add JSON-compatible `app/pvp/catalog/data/pvp_catalog.v1.yaml` containing the exact world/scouting contract above;
    - implement pure coordinate bounds, Euclidean distance, base-flight, scouting-duration, placement-sector, and contour policies;
    - implement a pure `Cpvp`/defensive projection from raw canonical XDV components using `Decimal` and explicit rounding; do not reverse-engineer the final displayed income modifier;
    - add `PVP_WORLD_ENABLED` and `PVP_SCOUTING_ENABLED` default-off settings/capabilities, plus a PvP-specific stable cohort resolver for internal/staff and percentage rollout when required.
  - Expected behavior:
    - invalid catalogs fail startup/tests with actionable errors;
    - world rules and exact formula examples from the specification have golden tests;
    - stable cohort bucketing uses SHA-256 and a configured salt, never Python `hash()`;
    - world can be enabled while paid scouting remains disabled.
  - Files:
    - new `diaverseapi/app/pvp/**`;
    - `diaverseapi/app/core/settings.py`;
    - `diaverseapi/app/core/features.py`;
    - focused tests under `diaverseapi/app/pvp/tests/`;
    - canonical mechanics references `diaverseapi/app/characters/pet_modifier_cache.py` and `diaverseapi/app/income/mechanics.py` only where extraction/reuse is required.
  - Tests:
    - catalog validation/version rejection;
    - reserved-zone/bounds;
    - distance and time examples;
    - contour thresholds;
    - `Cpvp` golden vectors and rarity-normalization invariants;
    - deterministic rollout buckets.
  - Logging:
    - INFO once when the catalog/version and rollout capability are resolved;
    - WARNING for invalid/unknown versions and disabled capabilities;
    - no per-pet calculation logs and no balance/private snapshot payloads.
  - Dependency: none.

- [x] **Task 2: [diaverseapi] Add PvP profile/scouting persistence and a PostgreSQL-safe Alembic migration.**
  - Deliverable:
    - implement `PvpProfile`, `PvpScoutAttempt`, and `PvpScoutFact` with enums, constraints, relationships, and short explicit index/constraint names;
    - import PvP models in `migrations/env.py`;
    - create one migration from the actual head at implementation time;
    - cover the table graph, partial active-scout index, coordinate uniqueness, and JSON fact storage.
  - Expected behavior:
    - one Factory has one PvP profile and one coordinate per world;
    - the central zone and out-of-bounds coordinates are rejected at DB level;
    - one actor can have only one in-flight drone to the same target but may scout different targets;
    - idempotency keys are unique per actor and conflicting fingerprints are detectable;
    - fact upserts cannot create duplicate current fields.
  - Files:
    - `diaverseapi/app/pvp/models.py`;
    - `diaverseapi/app/pvp/infrastructure/repositories.py`;
    - `diaverseapi/migrations/env.py`;
    - new `diaverseapi/migrations/versions/<revision>_pvp_world_recon.py`;
    - `diaverseapi/tests/test_alembic_graph.py`;
    - `diaverseapi/app/pvp/tests/test_models.py`;
    - `diaverseapi/app/pvp/tests/test_repositories.py`.
  - Tests:
    - constraints and cascade behavior;
    - real-Postgres concurrent uniqueness/partial-index cases;
    - short identifier assertions under PostgreSQL's 63-byte limit.
  - Logging:
    - repository DEBUG may record profile/attempt IDs, status, versions, and retry counts;
    - WARNING for collision/idempotency conflict;
    - never log fact JSON, inventories, usernames, or balances.
  - Depends on Task 1.

- [x] **Task 3: [diaverseapi] Implement concurrency-safe profile placement, Factory activation integration, and resumable initial backfill.**
  - Deliverable:
    - implement the five-least-populated-sector placement algorithm and transactional coordinate reservation;
    - use `INSERT ... ON CONFLICT DO NOTHING RETURNING`/equivalent retry semantics rather than check-then-insert;
    - add an idempotent Factory activation hook so a newly available Factory receives a coordinate immediately;
    - add `app/commands/pvp_backfill_profiles.py` with dry-run, batch size, seed, cursor/resume, and audit summary;
    - shuffle existing Factories server-side with a deterministic operator-supplied seed so registration date does not determine position.
  - Expected behavior:
    - repeated or concurrent bootstrap returns the same profile;
    - no coordinate enters the central zone;
    - the four reserved sectors and full sectors are excluded;
    - placement is balanced across the five least-populated eligible sectors;
    - a failed batch can resume without moving existing coordinates.
  - Files:
    - `diaverseapi/app/pvp/domain/placement.py`;
    - `diaverseapi/app/pvp/services/profile_service.py`;
    - `diaverseapi/app/pvp/infrastructure/repositories.py`;
    - `diaverseapi/app/commands/pvp_backfill_profiles.py`;
    - the exact Factory profile/open application boundary identified during implementation under `diaverseapi/app/factory/services/`;
    - related PvP/Factory tests.
  - Tests:
    - collision retries;
    - concurrent first access;
    - distribution/central-zone invariants;
    - dry-run and resumability;
    - immediate placement on Factory availability.
  - Logging:
    - INFO per batch with scanned/created/existing/conflict/error counts and placement version;
    - WARNING when sectors are near/full or retries are exhausted;
    - no per-user names or bulk coordinate dumps.
  - Depends on Tasks 1-2.

### Phase 2: Server-authoritative map and scouting

- [x] **Task 4: [diaverseapi] Implement privacy-safe map, profile, search, route, and nearest-target read APIs.**
  - Deliverable:
    - add authenticated no-store router registration at `/v1/cabinet/pvp`;
    - implement `catalog`, `state`, bounded viewport `map`, `search`, `nearby`, public `profile`, and `route` services/endpoints;
    - use bounding-box SQL and integer cluster cells, not PostGIS;
    - sort nearest targets by squared distance and cap at 30;
    - expose only `public_username`, safe avatar URL, stable UUID, coordinates, distance/time, rating, contour, public protection/status, active-own-scout indicator, last dossier timestamp, and discovered-field count;
    - return attack capability as disabled with a stable `combat_not_available` reason in Part 1.
  - Expected behavior:
    - viewport requests return bounded `factory | cluster` objects and `has_more`/refinement metadata;
    - dense views remain clustered instead of returning thousands of markers;
    - name search uses safe public identity fields; internal UUID and both coordinate formats work;
    - filters never reveal power, pet count, economy, production, or hospital state;
    - army-only filters are absent/deferred rather than returning fabricated data.
  - Files:
    - `diaverseapi/app/pvp/api.py`;
    - `diaverseapi/app/pvp/schemas.py`;
    - `diaverseapi/app/pvp/dependencies.py`;
    - `diaverseapi/app/pvp/services/map_service.py`;
    - `diaverseapi/app/pvp/infrastructure/user_gateway.py`;
    - `diaverseapi/app/pvp/infrastructure/factory_gateway.py`;
    - `diaverseapi/app/routers/v1/endpoints.py`;
    - focused service/API/privacy/load tests.
  - Tests:
    - viewport bounds/clusters/limits;
    - partial/exact/UUID/coordinate search;
    - nearest ordering and max 30;
    - own/other/newbie/different-contour statuses;
    - explicit response allowlist and no private field leakage.
  - Logging:
    - INFO for endpoint outcome/status and slow-query threshold breaches;
    - DEBUG only for safe bounds, zoom bucket, filters, result counts, and duration;
    - do not log search text, public names, coordinates in bulk, or response bodies.
  - Depends on Tasks 1-3.

- [x] **Task 5: [diaverseapi] Build typed scouting snapshot gateways and the ten-field dossier projection.**
  - Deliverable:
    - implement narrow pet/raid-availability, Factory, inventory, hospital, XDV, and public identity gateways;
    - calculate defending availability and `Cpvp` from canonical character state without mutating pets or creating combat locks;
    - produce the exact ten typed field payloads and apply the `±10%` defensive-power obfuscation once;
    - query only the selected field producer at completion so one scouting result does not materialize all hidden target data;
    - represent both hospital fields as typed zero counts until Part 2 connects real hospital persistence.
  - Expected behavior:
    - top-ten pets are ordered by calculated strength with deterministic tie-breaking;
    - roles and active hero slots use canonical Character/pack state;
    - Factory facts distinguish active/damaged production buildings and count ready products without exposing main inventory;
    - all payloads pass field-specific Pydantic validation before persistence;
    - dossier reads cannot access another scout owner's facts.
  - Files:
    - `diaverseapi/app/pvp/infrastructure/pet_gateway.py`;
    - `diaverseapi/app/pvp/infrastructure/factory_gateway.py`;
    - `diaverseapi/app/pvp/infrastructure/inventory_gateway.py`;
    - `diaverseapi/app/pvp/infrastructure/hospital_gateway.py`;
    - `diaverseapi/app/pvp/infrastructure/xdv_gateway.py`;
    - `diaverseapi/app/pvp/services/dossier_service.py`;
    - `diaverseapi/app/pvp/schemas.py`;
    - focused tests.
  - Tests:
    - each of ten payload variants;
    - unavailable raid pets;
    - empty Factory/production/hospital states;
    - deterministic ordering and obfuscation bounds;
    - owner isolation and malformed persisted payload rejection.
  - Logging:
    - INFO only for completed snapshot field key, attempt ID, and target profile ID;
    - WARNING for unavailable/malformed source state;
    - never log pet lists, `Cpvp` arrays, resources, ready products, or fact payloads.
  - Depends on Tasks 1-4.

- [x] **Task 6: [diaverseapi] Implement atomic scouting start, timed reconciliation, detection notification, dossier/history APIs, and idempotency.**
  - Deliverable:
    - accept `idempotency_key` and target profile, revalidate eligibility, calculate route/timing, and charge exactly `100 XDV` in the same transaction as attempt creation;
    - lock actor/target in stable UUID order and rely on DB uniqueness for the active actor-target rule;
    - generate information/detection/field rolls once with an injected secure RNG and persist them before departure;
    - at arrival, capture only the selected target fact, upsert the current dossier fact, complete the immutable attempt, and create a detected-drone notification when applicable;
    - add read-path deadline reconciliation plus `app/pvp/tasks.py` and minute `pvp_scouting-reconcile` TaskIQ scheduling using `FOR UPDATE SKIP LOCKED`;
    - expose attempt, active operations/routes, cursor-paginated history, and dossier endpoints.
  - Expected behavior:
    - rejected preflight does not charge XDV;
    - accepted flights are not rerolled by retries, worker restarts, or repeated reads;
    - same key/same request returns the original attempt; same key/different target returns conflict;
    - rediscovery updates timestamp/value but leaves attempt history;
    - failure shows `Новых данных нет` and preserves old facts;
    - detection is independent of information success;
    - API reads can finalize overdue operations before the next minute sweep.
  - Files:
    - `diaverseapi/app/pvp/services/scouting_service.py`;
    - `diaverseapi/app/pvp/services/dossier_service.py`;
    - `diaverseapi/app/pvp/infrastructure/repositories.py`;
    - `diaverseapi/app/pvp/infrastructure/notifications.py`;
    - `diaverseapi/app/pvp/tasks.py`;
    - `diaverseapi/app/pvp/api.py`;
    - `diaverseapi/app/core/broker_app.py`;
    - focused unit/API/real-Postgres concurrency tests.
  - Tests:
    - eligibility and no-charge rejection;
    - balance rollback and insufficient XDV;
    - concurrent duplicate start;
    - idempotent replay/conflict;
    - exact timing;
    - success/failure/repeated field/detection combinations;
    - double worker/read reconciliation;
    - notification idempotency and privacy.
  - Logging:
    - INFO for accepted/completed attempts, safe IDs, timings, result status, field key, and detection flag;
    - WARNING for eligibility/idempotency/insufficient-balance conflicts;
    - ERROR with exception context on transaction/task failure;
    - no balance values, random roll values, fact payloads, or private target state.
  - Depends on Tasks 2, 4-5.

### Phase 3: Typed web integration and map engine

- [x] **Task 7: [diaweb] Add the PvP route contract, same-origin BFF, typed API client, query keys, clocks, and rollout gates.**
  - Deliverable:
    - add `frontend/modules/pvp/{constants,types,api,queryKeys,index}.ts`;
    - add hooks for bootstrap/map/scouting/server clock;
    - add thin `/api/cabinet/pvp/*` route handlers and local `_utils.ts` proxy following Raids' cookie/timezone/request-ID/no-store behavior;
    - add `NEXT_PUBLIC_PVP_WORLD_ENABLED` and `NEXT_PUBLIC_PVP_SCOUTING_ENABLED`, while treating backend capabilities as final authority;
    - canonicalize bounds, zoom buckets, filters, search, cursors, and query keys;
    - forward `AbortSignal` for stale viewport cancellation and normalize server errors.
  - Expected behavior:
    - browser calls never target `diaverseapi` directly;
    - cookies and supported headers are forwarded safely;
    - no-store/private cache headers survive BFF responses;
    - failed scouting never causes optimistic local XDV deduction;
    - world-disabled and scouting-disabled states are distinct.
  - Files:
    - new `diaweb/frontend/modules/pvp/**` contract/hook files;
    - new `diaweb/frontend/app/api/cabinet/pvp/**`;
    - `diaweb/frontend/.env.example`;
    - BFF/API/query tests.
  - Tests:
    - proxy headers/status/body/set-cookie/cache;
    - URL/query canonicalization;
    - error normalization;
    - query key stability and abort behavior;
    - separate rollout gates.
  - Logging:
    - development DEBUG for safe method/path/status/duration and query result counts;
    - WARN/ERROR for upstream failures without response bodies, cookies, search text, or dossier data;
    - production logging remains environment-controlled.
  - Depends on backend Tasks 4 and 6 API contract.

- [x] **Task 8: [diaweb] Implement the finite 1000×1000 map camera, server-cluster viewport, markers, routes, and controls without a map library.**
  - Deliverable:
    - implement a clipped responsive viewport with one `translate3d + scale` world transform;
    - add pure camera clamp/coordinate/zoom functions plus pointer drag, wheel zoom, keyboard movement, and pinch support;
    - render server markers as accessible HTML buttons and routes/central zone through SVG/CSS;
    - debounce viewport queries around 200 ms, keep previous data, cancel stale requests, and never cluster all Factories client-side;
    - implement My Factory, current center coordinates, cluster zoom, saved-camera return, and active-drone progress overlay;
    - use a neutral versioned background/grid until final art is supplied.
  - Expected behavior:
    - camera cannot leave the world bounds;
    - selecting a cluster zooms into its bounds;
    - routes show start, target, ETA, remaining time, and state without continuous per-coordinate animation;
    - status is not communicated by color alone;
    - active data polls at a calm baseline and uses local server-time-adjusted ticks for countdowns.
  - Files:
    - `diaweb/frontend/modules/pvp/hooks/usePvpMapCamera.ts`;
    - `diaweb/frontend/modules/pvp/hooks/usePvpClock.ts`;
    - `diaweb/frontend/modules/pvp/components/PvpWorldShell.tsx`;
    - `PvpMapViewport.tsx`, `PvpMarkerLayer.tsx`, `PvpRouteLayer.tsx`, `PvpMapControls.tsx`, `PvpActiveOperations.tsx`;
    - `diaweb/frontend/modules/pvp/components/pvpWorld.module.css`;
    - `diaweb/frontend/public/pvp/**`;
    - focused tests.
  - Tests:
    - coordinate transforms, clamp, zoom anchor, pointer/pinch/keyboard controls;
    - cluster selection and dense viewport behavior;
    - central zone;
    - route/progress/server clock;
    - accessible marker names/focus and non-color status cues;
    - stale request cancellation.
  - Logging:
    - development DEBUG for zoom bucket, safe bounds, fetch cancellation, and result counts;
    - WARNING for malformed server geometry/unknown marker variants;
    - no per-frame/pointer-move or per-marker production logs.
  - Depends on Task 7.

- [x] **Task 9: [diaweb] Implement search, filters, nearest targets, and the privacy-safe public Factory card.**
  - Deliverable:
    - add search UI for name/UUID/two coordinate formats with bounded result list;
    - implement Part-1 filters, nearest targets up to 30, result-to-camera navigation, and camera restore;
    - add public Factory card with Public/Scouting tabs, explicit preliminary statuses, and discovered-count summary;
    - leave Attack visibly disabled with localized `combat_not_available` copy;
    - omit/defer army-only filters and never derive hidden target strength from client data.
  - Expected behavior:
    - ambiguous names show avatar, public name, UUID, and coordinates;
    - search choice centers and opens the selected Factory;
    - filters affect only server-visible public/own-operation state;
    - protected/unavailable Factories remain visible under All Factories but not default nearest targets;
    - no hidden field appears in DOM, logs, query cache keys, or error copy.
  - Files:
    - `diaweb/frontend/modules/pvp/components/PvpSearchPanel.tsx`;
    - `PvpFiltersPanel.tsx`, `PvpNearestTargets.tsx`, `PvpFactoryCard.tsx`;
    - related hooks/types/tests.
  - Tests:
    - all search forms/ambiguity/empty/error states;
    - filter and nearest behavior;
    - camera return;
    - public allowlist and attack-disabled state;
    - protected and different-contour presentations.
  - Logging:
    - development DEBUG for action type and result count only;
    - WARNING for normalized API failures;
    - never log raw search strings, selected usernames, or Factory private state.
  - Depends on Tasks 7-8.

### Phase 4: Scouting UX, cabinet integration, and release gates

- [x] **Task 10: [diaweb] Implement scouting confirmation, active operation progress, persistent dossier, and history.**
  - Deliverable:
    - show cost, calculated duration, randomness, possible duplicate fact, detection risk, and final confirmation before POST;
    - generate/reuse one idempotency key per user submission and disable duplicate submit;
    - display active route/progress/ETA and reconcile completion through polling plus server time;
    - show `N из 10`, latest report, cursor-paginated attempt history, per-field observed timestamp, and stale-snapshot label;
    - render the two hospital fields separately;
    - invalidate viewport/profile/dossier/active-operation queries after accepted and completed attempts.
  - Expected behavior:
    - no optimistic balance change;
    - failed preflight preserves UI/balance state and shows a localized reason;
    - repeat discovery refreshes the field rather than creating a duplicate card;
    - failed attempts show `Новых данных нет` without clearing previous facts;
    - a reload resumes the same active operation and dossier.
  - Files:
    - `diaweb/frontend/modules/pvp/hooks/usePvpScouting.ts`;
    - `diaweb/frontend/modules/pvp/components/PvpDossier.tsx`;
    - `PvpScoutConfirmDialog.tsx`, `PvpActiveOperations.tsx`;
    - related types/API/tests.
  - Tests:
    - confirmation copy and idempotency;
    - pending/double-submit/server rejection;
    - success/failure/repeated field;
    - separate hospital facts;
    - timers, polling, reload, invalidation, pagination;
    - focus trap and keyboard behavior.
  - Logging:
    - development DEBUG for safe attempt ID/status and query invalidations;
    - WARNING for normalized failures;
    - never log dossier payloads, XDV balance, target pet data, or idempotency key.
  - Depends on Tasks 7 and 9 plus backend Task 6.

- [x] **Task 11: [diaweb] Add the PvP cabinet entry, wide fullscreen layout, localization, responsive behavior, and navigation tests.**
  - Deliverable:
    - add `frontend/app/[lang]/(cabinet)/pvp/page.tsx` with rollout/unavailable states;
    - add route access, proxy recognition, bottom navigation/icon, transitions, and a dedicated wide PvP fullscreen mode;
    - do not reuse the current narrow `9:16` game fullscreen constraint;
    - add complete Russian/English typed dictionary entries, robots exclusion, env examples, and nav asset;
    - validate desktop, tablet, mobile, safe-area, reduced-motion, keyboard, and color-vision behavior.
  - Files:
    - `diaweb/frontend/proxy.ts`;
    - `diaweb/frontend/modules/cabinet/routeAccess.ts`;
    - `diaweb/frontend/modules/cabinet/components/BottomNav.tsx`;
    - `BottomNavIcon.tsx`, `CabinetRouteTransition.tsx`, `CabinetLayout.tsx`;
    - `diaweb/frontend/modules/i18n/types.ts`;
    - `diaweb/frontend/modules/i18n/dictionaries/ru.json`;
    - `diaweb/frontend/modules/i18n/dictionaries/en.json`;
    - `diaweb/frontend/app/robots.ts`;
    - `diaweb/frontend/public/cabinet/<pvp-nav-asset>`;
    - route/layout/navigation tests.
  - Tests:
    - world/scouting flag combinations;
    - route guards/proxy/nav active state;
    - wide fullscreen behavior;
    - typed translations and no raw keys;
    - representative responsive/accessibility states.
  - Logging:
    - development DEBUG for safe route and rollout state;
    - WARNING for missing capability/translation/assets;
    - no new high-volume production logs.
  - Depends on Tasks 8-10.

- [ ] **Task 12: [cross-repo] Document the contract, prove migration/concurrency/performance, and execute staged rollout verification.**
  - Progress 2026-07-27: living docs, navigation, offline migration compile,
    opt-in disposable-PostgreSQL concurrency/load tests, unit/type/lint gates,
    and GBrain sync are complete. Real-PostgreSQL execution, query-plan/p95
    evidence, backfill, staged production rollout, and production rollback drill
    remain operator gates; no production mutation was authorized in this run.
  - Docs deliverable:
    - create `docs/features/pvp-world-recon.md` covering ownership, API/data privacy, formulas, ten facts, rollout, backfill, reconciliation, monitoring, rollback, and Part-2 boundary;
    - update `docs/README.md` and relevant architecture/file-map navigation;
    - route the mandatory docs checkpoint through `$aif-docs`.
  - Backend verification from `diaverseapi`:
    - `.\.venv\Scripts\python.exe -m pytest app/pvp/tests tests/test_alembic_graph.py -q`
    - `.\.venv\Scripts\python.exe -m ruff check app/pvp app/routers/v1/endpoints.py app/core/features.py app/core/settings.py app/core/broker_app.py`
    - `.\.venv\Scripts\python.exe -m compileall -q app/pvp`
    - `.\.venv\Scripts\python.exe -m alembic heads`
    - `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
    - run real-Postgres concurrency/load tests only against a confirmed disposable test database.
  - Frontend verification from `diaweb/frontend`:
    - `npm test -- __tests__/modules/pvp __tests__/app/api/cabinet/pvp __tests__/app/cabinet-pvp-page.test.tsx`
    - `npm run typecheck`
    - `npm run lint`
    - `npm test`
    - `npm run build`
  - Performance deliverable:
    - add a seeded real-Postgres map/scouting load test following existing `tests/*_concurrency_and_load_db.py` patterns;
    - inspect query plans for viewport, cluster, search, nearest, due-attempt claim, and dossier history;
    - prove bounded response sizes and no N+1 per marker/fact;
    - agree a production p95 budget before enabling the public cohort; initial engineering target is `<300 ms` for normal viewport/search reads on the representative seeded dataset, not a release promise without measurements.
  - Rollout:
    1. apply schema and run dry-run/backfill audit;
    2. execute batched coordinate backfill with world/scouting disabled;
    3. enable world for internal/staff users;
    4. validate privacy, clustering, search, route timing, error rate, and query latency;
    5. enable world for a small stable cohort;
    6. enable scouting for internal/staff, validate XDV idempotency/task completion/notifications;
    7. enable scouting for a small cohort, then general web only after acceptance gates pass.
  - Rollback:
    - disable scouting first, then world through flags;
    - retain coordinates, attempts, and facts for replay/audit;
    - stop the PvP scheduler if needed;
    - do not drop tables or reroll coordinates during an operational rollback.
  - Cross-repo checks:
    - `git diff --check` and file-scoped diff review separately in `diaverseapi`, `diaweb`, and workspace root;
    - confirm no Referral/Crypton files entered PvP commits;
    - run targeted GBrain sync for `diaverseapi-code`, `diaweb-code`, `diaverse-docs`, and `diaverse-aif` after meaningful changes.
  - Logging:
    - no new feature logs in the docs/verification task;
    - tests and operational commands must not print secrets, environment values, real balances, usernames, dossier payloads, or production connection strings.
  - Depends on Tasks 1-11.

## Verification Plan

- `diaverseapi`: pure mechanics/catalog tests, API/privacy tests, real-Postgres concurrency tests, Alembic graph/DDL compilation, Ruff, compileall, targeted load/query-plan checks.
- `diaweb`: BFF proxy tests, map geometry/camera tests, component/interaction/accessibility tests, TypeScript, ESLint, full Vitest suite, production Next.js build.
- Cross-repo: contract field/path review, no-store/privacy review, feature-flag matrix, seeded end-to-end scouting clock/reconciliation smoke.
- Knowledge: targeted GBrain sync after code/docs changes.

## Acceptance Criteria

- Every active/open Factory receives exactly one immutable coordinate outside the central reserved zone.
- Existing Factory placement is shuffled, balanced, resumable, and does not encode registration order.
- The web map opens centered on the user's Factory, pans/zooms within bounds, renders server clusters/markers, and never downloads all Factories.
- Search, nearest targets, public cards, routes, and filters expose only explicit public/own-operation fields.
- Public identity search never exposes private `User.username`, Telegram identity, online state, or last-seen data.
- Distance and timing match the versioned formulas and golden examples.
- A scouting start is server-validated, idempotent, and atomically charges `100 XDV` only after acceptance.
- A drone completes once despite retries, concurrent workers, or read reconciliation.
- Success/detection/field choice are generated once; the selected private fact is captured at completion and never rerolled on read.
- The dossier contains exactly ten possible facts, including separate hospital waiting and treatment-started fields.
- Repeated facts replace the current snapshot while immutable attempt history remains available.
- The defender is notified only for detected drones and learns only the allowed scout identity/time.
- Attack remains explicitly unavailable and no combat/Factory damage/loot/hospital mutation/Exchange lock is introduced.
- Backend and frontend flags can disable scouting independently from world browsing.
- Focused and broad verification commands pass; PostgreSQL DDL compiles with identifiers under 63 bytes.
- Rollout can be stopped by flags without deleting coordinates or paid scouting history.

## Implementation Handoff

Run `$aif-implement` only after:

1. choosing clean isolated worktrees or safely switching both child repositories to `feature/pvp-world-recon`;
2. rebasing/updating the branch refs if required;
3. resolving the actual current Alembic head;
4. confirming that test database commands cannot target production.
