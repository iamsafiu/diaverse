# Implementation Plan: PvP Combat & Consequences (Part 2)

Branch: `feature/pvp-world-recon` (existing implementation worktrees; no branch switch)
Logical feature slug: `feature/pvp-combat-consequences`
Created: 2026-07-27

## Settings

- Testing: yes
- Logging: standard
- Docs: yes
- Delivery: vertical slices; training combat before destructive consequences
- Clients: web production slice only; mobile remains a later parity plan
- Realtime: polling plus deadline reconciliation; no WebSocket/SSE dependency
- Browser verification: no Playwright
- Build verification: no production build command
- Git: no commits, checkout, branch creation, merge, reset, or stash during implementation
- Rollout: default-off flags for combat, consequences, and permanent death

## Workspace Mode

- Mode: multi-repo full
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain via `scripts\gbrain.ps1`, verified against the source documents and current worktree code
- Product repositories are independent git repositories; the workspace root owns only the master plan and cross-repo documentation

## Existing Worktree Contract

- Backend worktree: `C:\Users\Indigo\Desktop\diaverse-worktrees\pvp-world-recon\diaverseapi`
- Web worktree: `C:\Users\Indigo\Desktop\diaverse-worktrees\pvp-world-recon\diaweb`
- Both worktrees are on `feature/pvp-world-recon`.
- Both contain the uncommitted Part-1 implementation and must be reused exactly as requested.
- Part 2 is implemented on top of that working state; it must not recreate, replace, or discard Part-1 files.
- The root plan is intentionally named for the logical Part-2 feature even though the physical worktrees remain on the Part-1 branch.
- Before each implementation session, inspect both worktrees with `git status --short`; unexpected non-PvP changes are a stop condition.
- The current Alembic head could not be resolved during planning without loading the repository environment. Resolve it inside the implementation environment before creating the Part-2 revision.

## Repository Matrix

| Repository | Execution path | Affected | Physical branch | Current status | Role |
| --- | --- | --- | --- | --- | --- |
| workspace root | `C:\Users\Indigo\Desktop\diaverse` | yes | current root branch | dirty, unrelated work present | master plan and living docs only |
| diaverseapi | `C:\Users\Indigo\Desktop\diaverse-worktrees\pvp-world-recon\diaverseapi` | yes | `feature/pvp-world-recon` | dirty with Part 1 | combat authority, persistence, timers, consequences, integrations |
| diaweb | `C:\Users\Indigo\Desktop\diaverse-worktrees\pvp-world-recon\diaweb` | yes | `feature/pvp-world-recon` | dirty with Part 1 | web PvP UI and same-origin BFF |
| diaverse-mobile | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | unchanged | not used by this plan | mobile parity deferred |
| aibot | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | unchanged | unrelated work may exist | no PvP ownership |
| diaverse-content | `C:\Users\Indigo\Desktop\diaverse\diaverse-content` | no | unchanged | not inspected for this plan | no PvP ownership |
| diaverse-ai-cofounder | `C:\Users\Indigo\Desktop\diaverse\diaverse-ai-cofounder` | no | unchanged | archived/R&D | no runtime ownership |
| club10000-bot | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | unchanged | not used by this plan | no PvP ownership |
| diaverse-auth-bot | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | unchanged | not used by this plan | no PvP ownership |

## Research Context

Sources:

- `.ai-factory/RESEARCH.md` Active Summary for the Part-1 foundation;
- `.ai-factory/RESEARCH.md`, session `2026-07-27 00:00 — PvP architecture and Part 1 boundary`;
- `C:\Users\Indigo\Downloads\КАРТА.doc`;
- `C:\Users\Indigo\Downloads\PvP+Diaverse+2.doc`;
- current uncommitted Part-1 code in the two PvP worktrees.

Goal:

- Complete the web PvP loop from attack preparation through flight, battle, return, settlement, recovery, and audit.
- Release deterministic training combat before enabling irreversible economic consequences.
- Reuse the Part-1 world, profiles, geometry, scouting dossier, polling clock, BFF, and feature-module boundaries.

Constraints:

- The backend remains server-authoritative.
- Continue the existing `diaverseapi/app/pvp` bounded context; do not introduce another service.
- No event sourcing, workflow engine, generic game mission framework, PostGIS, WebSocket/SSE platform, or client-side battle calculation.
- Do not reinterpret historical scouting attempts or move existing map coordinates.
- Use immutable combat snapshots, versioned rules, idempotent transitions, stable lock order, and transactional settlement.
- Large armies of 500 or more pets must use the same rules without one-row-per-hit persistence.
- Private army, inventory, hospital, loot, and battle-seed data must never enter public map/search projections or logs.
- Destructive effects remain disabled until training combat, migration, concurrency, and replay gates pass.

Decisions already clarified:

- A round targets an active production building.
- Damage pauses that building's production compartments while preserving material reservations, unfinished orders, ready output, and resource production.
- Repair level is the maximum built production-compartment level for the damaged building; use level `1` only when no built production compartment exists.
- New Exchange buy/sell orders are blocked for the defender from attack registration until battle result or final pre-battle cancellation; existing orders continue and may be cancelled, and immediate purchases of existing orders remain allowed.
- Loot includes produced objects still in Factory buildings/ready storage, not the main inventory and not unfinished production.
- The same-attacker/same-Factory 24-hour cooldown starts at terminal operation completion; a recalled attack also creates the cooldown.
- There is no product-level upper limit on attacking army size.
- Hospital waiting and active treatment remain separate dossier fields and become real projections in Part 2.
- A protected player's first three self-started standard-intent attacks execute as consequence-free training; the third ends early protection for subsequent attacks.
- Calibration players match only other calibration players. Calibration suppresses loot, Factory damage, Hospital intake, and death, but keeps the standard PvP token/rating result because the source specification excludes only destructive consequences for calibration.
- Post-battle attacker return uses the accepted attack's effective one-way flight duration; a recalled return uses only the elapsed outbound duration as stated in the source.

## Product Delivery Boundary

### Included

- Server preview and selection of attacker army, mandatory active pet and Pack members, optional additional pets, roles, layers, heroes, power, locks, and flight time.
- Optional small/medium/large flight accelerator consumption once canonical asset keys are available.
- Idempotent attack registration, outbound flight, incoming-attack notification, recall before 50%, return, and terminal cooldown.
- Defender Exchange order-creation guard and cross-activity pet locks.
- Defender snapshot at actual arrival using all then-available eligible pets.
- Up to 12 deterministic rounds with simultaneous damage.
- Secret attacker/defender production-building choices, 45-second deadlines, saved automatic sequences, and automatic fallback.
- Rhino `Ram`, Hippo `Bastion`, and Elephant `Battle Rush` hero abilities.
- Retreat between rounds.
- Training, calibration, and standard battle modes with their distinct reward/consequence policies.
- Immutable battle report with layer summaries and expandable per-pet detail.
- Factory production damage, paused craft timers, repair, and 8-hour post-defeat protection.
- Hospital intake, automatic free treatment for the strongest 30%, paid treatment, 24-hour treatment, seven-day treatment-start deadline, and permanent-death processing behind a separate flag.
- Resource and ready-product theft, PvP tokens, rating mutation, daily loss cap, newbie protection, calibration, contour, rating, and strength eligibility.
- Polling/read reconciliation and a minute sweeper that can catch up deterministic deadlines without changing results.
- Cabinet notifications for attack arrival, battle result, hospital deadlines/completion, repair completion, and permanent-death warning/result.
- Web UI and BFF integration in the existing PvP feature.
- Root living contract and rollout/rollback documentation.

### Explicitly excluded

- Mobile client implementation.
- Realtime WebSocket/SSE transport.
- PvP token shop or token spending mechanics; this plan creates an auditable balance/reward contract only.
- Alliances, group attacks, spectating, chat, seasons, leaderboards, tournaments, or replay sharing.
- Multiple simultaneous incoming attacks on one Factory.
- Destruction or theft from the main inventory.
- Damage to resource-production parts of Factory buildings.
- Automatic cancellation of old Exchange orders.
- New pet, mutation, Factory, Exchange, or XDV economy redesigns.
- Arena support when no canonical arena activity exists in the current backend.
- Production rollout, production database mutation, or deployment without separate operator authorization.

## Delivery Strategy

### Part 2A — Training Combat Core

Deliver army selection, attack lifecycle, locks, flight/recall, snapshots, deterministic rounds, automatic choices, retreat, return, and battle reports. All battles run without Factory damage, loot, hospital intake, permanent death, token rewards, or rating mutation.

This is the first releasable Part-2 checkpoint and is enabled only for internal/staff users.

### Part 2B — Standard Consequences

Add Factory damage/repair, hospital, loot, rewards, rating, cooldown/protection settlement, and standard-match eligibility. Enable each destructive capability behind independent server-side gates after training evidence passes.

Frontend and backend are delivered together inside each vertical slice. Do not finish all backend consequence work before exposing and testing its user-visible state.

## Architecture

```text
diaweb /[lang]/pvp
       /[lang]/pvp/battles/[battleId]
       /[lang]/pvp/reports/[battleId]
       /[lang]/pvp/hospital
          |
          v
same-origin /api/cabinet/pvp/*
          |
          v
diaverseapi /v1/cabinet/pvp/*
          |
          +--> versioned PvP catalog
          +--> pure combat engine
          +--> attack/battle/hospital/settlement services
          +--> PvP repositories and immutable snapshots
          |
          +--> narrow gateways
                 +--> Characters / Pack / Raids availability
                 +--> Exchange order-creation guard
                 +--> Factory production damage and loot
                 +--> XDV / inventory / PvP token ledger
                 +--> Cabinet notifications
```

Dependency rules:

- API handlers authenticate, validate, map typed errors, and shape responses only.
- Pure combat code imports no FastAPI, SQLAlchemy session, repository, clock, random global, or frontend type.
- Services own orchestration and transaction boundaries.
- Repositories own SQL and row-lock acquisition.
- Factory owns production/job state; PvP owns the causal damage record and calls a narrow Factory service.
- Characters own canonical pet state; PvP owns temporary combat/hospital locks and exposes them through a shared availability policy.
- Exchange owns order behavior; it calls a narrow PvP account guard before creating a new buy or sell order.
- The existing XDV and inventory stores remain canonical. PvP never maintains a shadow XDV/resource/item balance.
- Battle reports are projections from snapshots, rounds, settlement, damage, and hospital records; do not duplicate a mutable report document.

## State Machines

### Attack operation

```text
registered (outbound)
  |-- recall before 50% --> recalling --> completed
  `-- arrival -----------> in_battle --> returning --> completed

registered -- guarded validation failure before acceptance --> no row/no charge
registered/in_battle/returning -- retryable worker failure --> same state + retry
irrecoverable invariant failure --> failed + locks retained for operator recovery
```

- `registered` is the persisted outbound-flight state and starts the defender Exchange guard.
- Recall is accepted only while `now < recall_cutoff_at`.
- Recalled and post-battle attackers remain pet-locked until `completed_at`.
- Defender Exchange blocking ends when a battle result is fixed or a recalled/pre-battle operation is finally cancelled, not when the attacker's return ends.
- Cooldown is recorded from `completed_at` for both battle and recall paths.
- `failed` never silently releases assets or locks; an explicit idempotent recovery command is required.

### Battle

```text
waiting_choices
  |-- both choices submitted
  |-- choice_deadline reached
  v
resolving_round
  |-- terminal win/retreat/round 12 --> settling --> completed
  `-- non-terminal ------------------> waiting_choices (next round)
```

- Missing choices are selected from the persisted automatic sequence.
- Reconciliation may process several expired offline rounds in one transaction, but each round keeps its own logical deadline, choices, seed-derived rolls, and result.
- The result is identical whether rounds resolve immediately, on read, or in the sweeper.

### Hospital entry

```text
awaiting_treatment --> treating --> recovered
         |
         `-- treatment deadline --> dead
```

- Free entries enter `treating` immediately.
- Paid entries remain `awaiting_treatment` until one successful idempotent XDV charge.
- `dead` is enabled only when both consequences and permanent-death flags are on.

### Factory damage

```text
damaged --> repairing --> repaired
```

- Damage settles Factory state at the battle timestamp, then freezes remaining production time.
- Repair restores the exact preserved production state and resumes remaining timers.
- Ready jobs/items remain ready and can participate in the one-unit loot selection.

## Versioned Combat Rules Contract

Create `pvp_catalog.v2` while retaining the ability to interpret `pvp_catalog.v1` records.

`pvp_catalog.v2` must include:

- inherited world, geometry, scouting, contour, and public visual rules;
- accelerator keys and reductions: small `20%`, medium `35%`, large `50%`;
- minimum accelerated flight time `5` minutes;
- recall cutoff `50%`;
- normalized mutation bonuses: common `3%`, rare `6%`, epic `9%`, legendary `12%`, divine `16%` per mutation level;
- rarity normalization to the common combat factor `2`;
- role bases:
  - rare Guardian: health `1000`, damage `70`;
  - legendary Assault: health `500`, damage `140`;
  - epic Ranged: health `700`, damage `100`;
- pet power: `round(sqrt(max_health × damage))`;
- layer order: front, assault, ranged, command;
- hero rank bands `1..7`, per-round chance `15%..33%`;
- Rhino, Hippo, and Elephant effect curves from the source specification;
- round choice duration `45` seconds;
- maximum rounds `12`;
- matched-building attacker multiplier `0.50`;
- strength ratio `0.85..1.15`;
- rating difference maximum `200`;
- newbie protection `14` days and early end after the third self-started standard attack;
- calibration battle count `5`;
- same-target cooldown `24` hours from terminal completion;
- defender post-loss protection `8` hours;
- repair cost `500 × N` XDV and duration `60 × N` minutes;
- free hospital share `30%`, treatment duration `24` hours, paid-start deadline `7` days;
- paid treatment cost `max(100, ceil(start_power / 10) × 10)` XDV;
- resource theft `3%` and game-day cap `5%`;
- one ready-production unit on attacker victory when available;
- winner/loser PvP tokens `100/20` for calibration and standard battles;
- winner/loser rating delta `+20/-20` for calibration and standard battles;
- a versioned game-day timezone for daily loss caps, default `Europe/Moscow` unless product configuration already defines the canonical game timezone.

Combat `Cpvp`:

```text
Ccore = ClevelXdv × Kavatar × KpilotLevel
Mpvp = 1 + normalized_mutation_bonus × mutation_level
Cpvp = Ccore × 2 × Mpvp
```

Rules:

- `Cpvp` uses `Decimal`, six stored fractional digits, and no displayed-income reverse calculation.
- Pet rarity determines role/layer, not potential power after normalization.
- Evolution does not affect `Cpvp`, health, damage, power, matching, treatment, or abilities.
- Part-1 scouting power/role projections must be corrected to use this same implementation.
- Existing `pvp_catalog.v1` scouting attempts retain their stored output and are not rerolled.

## Persistence Outline

Use relational rows for identities, states, ownership, timers, locks, and per-pet snapshots. Use versioned JSONB only for immutable rule snapshots, round-resolution detail, automatic sequences, and settlement line items.

### Extend `pvp_profiles`

- PvP token balance.
- Standard attacks started during newbie protection.
- Defender protection until.
- Calibration battles remaining.
- Saved defender automatic building sequence.
- Last standard-battle timestamps only when needed for indexed eligibility; do not add denormalized fields that can be queried safely from attacks.
- Initialize newbie protection from canonical `User.created_at + 14 days`, not from first PvP-map visit.
- Initialize calibration to five completed battles and backfill existing Part-1 profiles deterministically; rerunning the backfill must not reset progressed profiles.

### `pvp_attacks`

- attacker/defender profiles and users;
- mode: training, calibration, standard;
- status and terminal reason;
- idempotency key and request fingerprint;
- catalog/combat/geometry versions;
- distance, base/effective flight minutes, accelerator key;
- registered, arrival, recall-cutoff, recall, return, result, and completion timestamps;
- attacker and defender army-snapshot IDs;
- battle ID;
- attacker automatic sequence;
- cooldown anchor.

Constraints:

- one active incoming operation per defender via a short partial unique index;
- permanent unique `(attacker_profile_id, idempotency_key)` plus stored request fingerprint, including after terminal completion;
- attacker and defender differ;
- monotonic timestamp checks;
- short explicit PostgreSQL identifiers below 63 bytes.

### `pvp_army_snapshots` and `pvp_pet_snapshots`

Army header:

- owner, side, contour, captured time, total power;
- active pet ID, ordered Pack IDs, active hero IDs;
- layer totals and automatic sequence;
- immutable rule snapshot/version.

Per pet:

- canonical pet/owner/species IDs;
- immutable presentation fields needed by historical reports, including safe display name/title, species label, and skin reference;
- rarity, role, level, mutation rarity/level;
- XDV source components, normalization factors, `Cpvp`;
- active/Pack position, active-hero flag, layer and deterministic order;
- max health, initial health, damage, power.

### `pvp_battle_pet_states`

- mutable battle-local state keyed by battle and pet snapshot;
- current health, alive flag, and last updated round;
- unique `(battle_id, pet_snapshot_id)` and indexed battle/layer reads;
- never overwrite immutable army/pet snapshots while rounds progress.

### `pvp_battles` and `pvp_rounds`

Battle:

- attack ID, status, round number, logical choice deadline;
- seed/seed version stored server-side;
- result, winner, reason, settled/completed timestamps;
- compact current layer-health projection for efficient reads.

Round:

- round number and status;
- manual/automatic choice for each side;
- revealed target and attacker multiplier;
- base/final packets and hero rolls/effects;
- versioned JSONB resolution detail with per-layer/per-pet damage iterations;
- pre/post layer summaries and resolved timestamp.

Unique `(battle_id, round_number)` prevents duplicate resolution.

### `pvp_pet_locks`

- pet, owner, attack/battle, side, lock reason, acquired/released timestamps;
- partial unique active lock per pet;
- indexed owner and operation lookups.

### `pvp_factory_damage`

- battle/defender/Factory profile, building key;
- derived repair level, cost, duration;
- preserved production/compartment/job state reference;
- damage, repair-start, repair-complete timestamps and status.

### `pvp_factory_output_claims`

- unique settlement/job/output-unit claim used when one ready product is stolen;
- stable output index and snapshotted product identity;
- collection subtracts claimed units and can never grant them again;
- concurrent collect/theft is serialized under the documented Factory lock order.

### `pvp_hospital_entries`

- battle, pet, owner, side;
- start-of-battle `Cpvp` and power;
- free-treatment rank and flag;
- snapshotted hospital/death policy version and `death_policy_enabled_at_intake`;
- status, treatment cost, start deadline, start/completion/death timestamps;
- partial unique active hospital entry per pet.

### `pvp_settlements` and `pvp_resource_daily_caps`

Settlement:

- unique battle ID;
- mode/result;
- resource/product loot line items;
- token/rating deltas;
- damage and hospital references;
- applied timestamp and rules version.

Daily cap:

- defender, resource key, game-day key/timezone;
- first-theft vulnerable amount;
- maximum and already-applied loss;
- unique defender/resource/day.

No separate mutable report table is required.

## Transaction and Lock Order

Use one documented stable order for operations that can overlap:

1. involved `PvpProfile` rows sorted by UUID;
2. `PvpAttack` and `PvpBattle`;
3. pet lock rows and canonical `UserCharacter` rows sorted by UUID;
4. Factory profile/building/compartment/job/balance rows;
5. daily-cap and settlement rows;
6. canonical XDV/inventory/token ledger rows.

Requirements:

- Attack registration and Exchange order creation both lock the defender's `PvpProfile` before checking/creating their state, preventing an order/attack race.
- Settlement is one database transaction and is idempotent by `battle_id`.
- External notifications are recorded after the durable state change and may retry independently.
- New PvP orchestration and its new gateways may not commit internally; legacy services with internal commits must be wrapped or bypassed through transaction-safe boundaries rather than broadly refactored.
- A retry either observes the already-applied transition or performs it once.

## API Contract Outline

Extend `/v1/cabinet/pvp`:

- `GET /catalog` — v2 combat rules and safe presentation metadata.
- `GET /state` — own profile, capabilities, active outgoing/incoming operations, hospital/damage summaries.
- `POST /attacks/preview` — server preview for target, selected optional pets, accelerator, power, eligibility, locks, and time.
- `POST /attacks` — idempotent registration.
- `GET /attacks` — paginated own outgoing/incoming history and active operations.
- `GET /attacks/{attack_id}` — authorized operation projection.
- `POST /attacks/{attack_id}/recall` — idempotent recall before cutoff.
- `GET /army-options?target_profile_id=...&cursor=...&limit=...` — mandatory active/Pack pets returned separately plus cursor-paginated optional/locked pets with safe reasons and filters.
- `POST /preferences/building-sequence` — update saved defender automatic sequence outside active battle.
- `GET /battles/{battle_id}` — authorized current round/layer projection and deadlines.
- `POST /battles/{battle_id}/rounds/{round_number}/choice` — idempotent secret choice.
- `POST /battles/{battle_id}/retreat` — idempotent attacker retreat between rounds.
- `GET /battles/{battle_id}/report` — authorized summary plus paginated/expandable detail.
- `GET /hospital` — paginated active/history entries.
- `POST /hospital/{entry_id}/treatment` — idempotent paid treatment start.
- `GET /factory-damage` — own active/history damage.
- `POST /factory-damage/{damage_id}/repair` — idempotent repair start.

Contract rules:

- All private endpoints are authenticated, owner/participant-authorized, and `no-store`.
- Mutation endpoints require an idempotency key in the typed request body, consistently with Part 1; the BFF does not invent or translate a second header contract.
- Secret round choices are never returned to the other side before reveal.
- Battle seed and future rolls are not exposed before terminal completion.
- Public map/search responses remain allowlisted and do not gain private combat fields.
- Typed errors use stable codes such as `pet_locked`, `target_busy`, `strength_mismatch`, `rating_mismatch`, `newbie_training_only`, `cooldown_active`, `recall_window_closed`, `round_closed`, `not_participant`, `exchange_blocked_by_incoming_attack`, `treatment_deadline_expired`, and `consequences_disabled`.

## Logical Commit Checkpoints

Implementation commits are disabled by the user. The checkpoints below are grouping boundaries for review and status only; `$aif-implement` must not run `git add` or `git commit`.

- **Checkpoint 1 — Tasks 1-3:** combat contract, persistence, deterministic engine.
- **Checkpoint 2 — Tasks 4-7:** locks, attack lifecycle, round orchestration, backend reports.
- **Checkpoint 3 — Tasks 8-10:** web training-combat vertical slice.
- **Checkpoint 4 — Tasks 11-13:** Factory, hospital, and settlement consequences.
- **Checkpoint 5 — Tasks 14-16:** consequences UX, operational recovery, docs, verification, and rollout gates.

If commits are authorized later, suggested messages are:

- `feat(pvp): add deterministic combat core`
- `feat(pvp): add attack lifecycle and battle api`
- `feat(pvp): add web combat experience`
- `feat(pvp): add combat consequences`
- `docs(pvp): document combat rollout`

## Tasks

### Phase 1: Contract, persistence, and deterministic engine

- [x] **Task 1: [diaverseapi] Reconcile Part-1 projections with the canonical Part-2 combat catalog and formulas.**
  - Deliverable:
    - preserve `pvp_catalog.v1` for historical Part-1 records and add a version-aware `pvp_catalog.v2`;
    - transcribe all combat, hero, matching, accelerator, hospital, repair, loot, reward, protection, and cooldown values into typed catalog schemas;
    - correct the provisional Part-1 `Cpvp` implementation so mutation normalization is included and rarity is normalized rather than amplified;
    - derive Guardian/Ranged/Assault role from rarity as required by the battle specification, not from `PetClass`;
    - make dossier power, role counts, strongest pets, army preview, defender snapshot, and battle engine consume one canonical pet-stat projector;
    - keep completed scouting facts immutable; only newly observed facts use the corrected rules version.
  - Expected behavior:
    - rare, epic, and legendary pets with the same level/mutation/user coefficients produce equal potential power but different health/damage roles;
    - all numerical examples from sections 4-8 of the source specification pass as golden vectors;
    - evolution never changes combat output;
    - invalid or missing v2 rules fail closed with actionable validation errors.
  - Files:
    - `diaverseapi/app/pvp/catalog/schema.py`;
    - `diaverseapi/app/pvp/catalog/loader.py`;
    - `diaverseapi/app/pvp/catalog/validator.py`;
    - new `diaverseapi/app/pvp/catalog/data/pvp_catalog.v2.yaml`;
    - `diaverseapi/app/pvp/domain/power.py`;
    - new `diaverseapi/app/pvp/domain/pet_stats.py`;
    - `diaverseapi/app/pvp/infrastructure/pet_gateway.py`;
    - focused catalog/power/dossier tests.
  - Tests:
    - catalog v1/v2 loading and unknown-version rejection;
    - rarity/mutation normalization;
    - health, damage, power, layer, hero-rank, chance, and effect golden examples;
    - no mutation/evolution edge cases;
    - corrected future dossier projection without rewriting stored facts.
  - Logging:
    - INFO once for loaded catalog/combat versions;
    - WARNING for invalid/unsupported versions;
    - no per-pet, coefficient, balance, or private snapshot logs.
  - Dependency: existing Part-1 code in the reused backend worktree.

- [x] **Task 2: [diaverseapi] Add combat, snapshot, lock, hospital, damage, and settlement persistence in one PostgreSQL-safe Part-2 migration.**
  - Deliverable:
    - add the models and constraints described in Persistence Outline;
    - keep `PvpPetSnapshot` immutable and persist changing health only in `PvpBattlePetState`;
    - persist report presentation fields in snapshots so historical reports never depend on mutable/deleted Character rows;
    - extend `PvpProfile` only with durable profile-owned state;
    - initialize/backfill newbie protection from canonical account creation time and calibration to five without resetting profiles that already progressed;
    - implement repositories for row locking, active-operation claims, snapshots, rounds, lock acquisition/release, hospital due claims, damage, settlement, and daily caps;
    - import every model in Alembic metadata;
    - create a revision from the actual current head after the uncommitted Part-1 migration;
    - use short explicit names for every index, foreign key, unique constraint, and check.
  - Expected behavior:
    - database constraints reject duplicate active incoming attacks, permanent attacker/idempotency-key reuse, duplicate round resolution, duplicate battle-pet state, duplicate active pet/hospital locks, duplicate ready-output claims, duplicate settlement, and duplicate daily cap;
    - snapshots and terminal settlement history cannot be mutated through normal service APIs;
    - deleting or renaming a canonical pet cannot erase or rewrite an authorized historical report;
    - due-row queries support `FOR UPDATE SKIP LOCKED`;
    - Part-1 tables and data remain compatible.
  - Files:
    - `diaverseapi/app/pvp/models.py`;
    - `diaverseapi/app/pvp/infrastructure/repositories.py`;
    - `diaverseapi/migrations/env.py`;
    - new `diaverseapi/migrations/versions/<revision>_pvp_combat_consequences.py`;
    - `diaverseapi/tests/test_alembic_graph.py`;
    - `diaverseapi/app/pvp/tests/test_models.py`;
    - `diaverseapi/app/pvp/tests/test_repositories.py`.
  - Tests:
    - model constraints, partial indexes, cascade/restrict behavior, enum round trips;
    - active-operation and active-pet-lock concurrency;
    - immutable snapshot versus mutable battle-state behavior;
    - deterministic profile initialization/backfill rerun;
    - terminal attack idempotency replay and fingerprint conflict;
    - settlement/daily-cap idempotency;
    - offline DDL compilation and identifier-length assertions.
  - Logging:
    - repository DEBUG only for operation IDs, states, row counts, and retries;
    - WARNING on optimistic/idempotency conflicts;
    - never log JSON snapshots, seeds, army membership, loot details, or balances.
  - Depends on Task 1.

- [x] **Task 3: [diaverseapi] Implement the pure deterministic battle engine and replay contract.**
  - Deliverable:
    - implement immutable domain inputs/outputs for pet snapshots, layers, hero rolls, choices, rounds, and terminal results;
    - implement simultaneous packet creation, modifier order, `Decimal` plus explicit `ROUND_HALF_UP` integer rounding, even layer distribution, deterministic remainder ordering, overkill redistribution, and layer transitions;
    - derive hero rolls from battle seed, round number, owner, and hero ID; a hero alive at round start contributes even if reduced to zero in the same simultaneous round;
    - provide one versioned domain RNG derivation for hero rolls, automatic/fallback building selection, and later loot selection using battle seed plus stable context labels;
    - implement matched-building `0.50`, retreat, mutual destruction, attacker/defender victory, and 12-round defender survival;
    - return compact layer summaries plus detailed iteration data suitable for JSONB persistence;
    - add a replay function that validates a saved battle without database access.
  - Expected behavior:
    - the same inputs always produce byte-equivalent normalized round output;
    - a pet alive at round start contributes damage even when reduced to zero in that round;
    - excess damage is never lost before the command layer is exhausted;
    - armies with 500+ pets use bounded-memory algorithms and do not select one random target.
  - Files:
    - new `diaverseapi/app/pvp/domain/combat.py`;
    - new `diaverseapi/app/pvp/domain/heroes.py`;
    - new `diaverseapi/app/pvp/domain/rounding.py`;
    - new `diaverseapi/app/pvp/domain/replay.py`;
    - focused pure-domain tests and fixtures.
  - Tests:
    - every source-document example;
    - empty layers, one pet, mutual destruction, overkill across all layers, remainder ordering;
    - all hero combinations and chance thresholds;
    - `.5` golden cases proving `ROUND_HALF_UP` rather than Python banker rounding;
    - stable context-separated RNG results for hero, fallback, and loot decisions;
    - round 12, retreat, and invalid input invariants;
    - deterministic replay and a seeded 500-vs-500 performance case.
  - Logging:
    - pure engine performs no logging;
    - caller logs one INFO round summary and ERROR invariant failures with IDs/counts only;
    - seed, choices before reveal, and per-pet data are never logged.
  - Depends on Task 1.

### Phase 2: Training combat backend

- [x] **Task 4: [diaverseapi] Build canonical army options, immutable snapshots, and cross-activity pet locking.**
  - Deliverable:
    - expose mandatory active-pet and ordered Pack membership plus optional eligible pets;
    - deduplicate pets that are both mandatory and explicitly selected;
    - build attacker snapshots at registration and defender snapshots at arrival;
    - calculate command heroes and layers from the actual active pet/Pack positions at each snapshot time;
    - add one shared `assert_pet_action_available`-style policy that composes existing Raid locks with PvP/Hospital locks and is called by Characters, Packs, Raids, rent/market actions, level/evolution/mutation/nullifier/merge changes, Exchange escrow/listing, and background mutation resolution;
    - reject pets with unresolved pending mutations at snapshot selection unless the mutation is first resolved through the canonical boundary;
    - acquire attacker locks at registration, defender locks at arrival, atomically convert zero-health battle locks to hospital locks without a release/reacquire gap, and release surviving locks at their correct lifecycle boundary;
    - return typed lock reasons instead of relying on client inference.
  - Expected behavior:
    - attacker pets cannot be mutated, transferred, listed, rented, raided, or reused until return completes;
    - defender pets remain mutable during flight but are frozen after the defender snapshot;
    - pets in raid, rent/market, hospital, another battle, or deleted state cannot enter a snapshot;
    - Hospital intake atomically clears current active-pet and Pack membership; recovery returns the pet as inactive/unpacked and never silently restores old placement;
    - active pet and Pack changes after attacker registration do not rewrite the attacker snapshot;
    - lock acquisition is all-or-nothing and deadlock-safe.
  - Files:
    - `diaverseapi/app/pvp/infrastructure/pet_gateway.py`;
    - new `diaverseapi/app/pvp/services/army_service.py`;
    - new `diaverseapi/app/pvp/services/lock_service.py`;
    - `diaverseapi/app/characters/usecases/**` entry points that mutate selected pets;
    - `diaverseapi/app/packs/usecases/**`;
    - `diaverseapi/app/raids/infrastructure/pet_gateway.py` and raid start/team guards;
    - `diaverseapi/app/exchange/external/inventory_service.py` and pet-listing/escrow entry points;
    - `diaverseapi/app/characters/services/mutation_resolution_service.py`;
    - Character/Pack/Raid/PvP lock tests.
  - Tests:
    - mandatory/optional deduplication and unlimited army size;
    - active/Pack hero priority and ordered slots;
    - attacker/defender snapshot timing;
    - every guarded mutation/activity;
    - battle-lock to Hospital-lock conversion and active/Pack cleanup;
    - attack-vs-Exchange-escrow and attack-vs-background-mutation races;
    - concurrent two-attack and attack-vs-raid lock races.
  - Logging:
    - INFO for lock acquire/release counts and operation transition;
    - WARNING for lock conflicts with safe reason codes;
    - no pet names, complete pet ID arrays, snapshot statistics, or user identity in logs.
  - Depends on Tasks 1-2.

- [x] **Task 5: [diaverseapi] Implement attack preview/registration, Exchange blocking, accelerator consumption, flight, recall, return, and cooldown.**
  - Deliverable:
    - implement server preview and idempotent registration with contour, strength, rating, protection, calibration-pair, cooldown, working-building, active-target, and pet validations;
    - resolve canonical small/medium/large accelerator asset keys through an inventory gateway, consume at registration, and never refund after acceptance;
    - if no approved accelerator assets exist, create stable provisionable asset definitions without inventing a purchase flow;
    - persist exact distance and flight rules/version;
    - lock attacker pets and create only the attacker snapshot at registration;
    - lock the defender profile in the same transaction so Exchange cannot race a new order;
    - add a narrow PvP guard to `OrderService.create_sell_order` and `create_buy_order`; keep existing-order execution/cancellation available;
    - implement recall before 50%, proportional return duration, arrival/return reconciliation, lock release, and cooldown from terminal completion;
    - send incoming/recall/return notifications from durable state.
  - Expected behavior:
    - identical idempotency replay, including after terminal completion, returns the same attack with no second asset consumption;
    - conflicting fingerprint returns a stable conflict;
    - rejected registration consumes nothing and creates no locks;
    - one Factory has at most one active incoming attack;
    - Exchange order creation and attack registration have a deterministic winner under concurrency;
    - recalled attacks never create battle, loot, or hospital rows but still incur cooldown.
  - Files:
    - new `diaverseapi/app/pvp/services/attack_service.py`;
    - new `diaverseapi/app/pvp/infrastructure/accelerator_gateway.py`;
    - new `diaverseapi/app/pvp/infrastructure/exchange_guard.py`;
    - `diaverseapi/app/exchange/orders/service.py`;
    - `diaverseapi/app/exchange/orders/dependencies.py`;
    - canonical inventory/resource definitions only if required;
    - `diaverseapi/app/pvp/dependencies.py`;
    - attack/Exchange/concurrency tests.
  - Tests:
    - preview/registration parity;
    - no/three accelerator timings and minimum five minutes;
    - recall boundary immediately before/at/after 50%;
    - idempotency and asset rollback;
    - same-target cooldown from terminal completion, including recall;
    - Exchange old-order allowed/new-order blocked and race tests.
  - Logging:
    - INFO for accepted attack, recall, arrival, return, completion, and safe counts/timestamps;
    - WARNING for eligibility/idempotency/lock conflicts by code;
    - ERROR for transition failure with attack ID and state only;
    - no private army, inventory quantity, exact loot, or balance payloads.
  - Depends on Tasks 2 and 4.

- [x] **Task 6: [diaverseapi] Implement defender arrival snapshot, round deadlines, choices, auto-sequences, retreat, and reconciliation.**
  - Deliverable:
    - create defender snapshot atomically when outbound flight reaches arrival;
    - start round 1 immediately with a logical 45-second deadline;
    - support saved defender and per-attack attacker automatic building sequences;
    - accept each participant's secret idempotent choice only for the current open round;
    - resolve when both choices exist or the logical deadline passes;
    - derive automatic/fallback building choice from the versioned battle RNG over a stable sorted list of currently working buildings and persist the selected outcome;
    - support attacker retreat only between rounds;
    - advance up to 12 rounds, record all resolution data, and create a training settlement with no consequences;
    - if the defender snapshot is empty at arrival, still open round 1: defender damage is zero, normal manual/automatic choices apply, and attacker victory uses the chosen/fallback building rather than inventing an out-of-round target;
    - if no working production building exists at arrival despite registration-time validation, transition to audited consequence-free `target_unavailable`, start return, keep the consumed accelerator non-refundable, and start the normal cooldown at terminal completion;
    - extend the current PvP worker to claim due flights, rounds, returns, and later consequence records in bounded `SKIP LOCKED` batches, then process every claimed operation in an isolated transaction so one poison item cannot roll back the batch;
    - persist bounded retry metadata (`attempt_count`, `next_retry_at`, safe `last_error_code`) and move only irrecoverable invariant failures to `failed` with locks retained;
    - reconcile on authorized reads so UI polling can resolve a just-expired 45-second round without waiting for the minute sweeper;
    - catch up multiple offline automatic rounds while preserving their logical deadlines.
  - Expected behavior:
    - a missing player never blocks a battle indefinitely;
    - a late duplicate choice cannot alter a resolved round;
    - the other player's secret choice is hidden until resolution;
    - concurrent read, worker, and second-choice resolution apply a round once;
    - a failed/recoverable operation with retained locks remains active for incoming-operation and Exchange guards until audited recovery reaches a safe terminal state;
    - training completion releases defender locks, starts attacker return, and changes no economy/rating/hospital/Factory state.
  - Files:
    - new `diaverseapi/app/pvp/services/battle_service.py`;
    - new `diaverseapi/app/pvp/services/reconciliation_service.py`;
    - `diaverseapi/app/pvp/tasks.py`;
    - `diaverseapi/app/core/broker_app.py`;
    - `diaverseapi/app/pvp/dependencies.py`;
    - battle/reconciliation concurrency tests.
  - Tests:
    - arrival snapshot timing and changed defender composition;
    - choice secrecy, duplicate/conflicting choices, exact deadline boundary;
    - manual/manual, manual/auto, auto/auto rounds;
    - invalid/damaged building fallback;
    - empty defender snapshot and no-current-working-building edge behavior;
    - retreat and 12-round survival;
    - offline catch-up, one-item failure isolation, retry scheduling, and worker/read race.
  - Logging:
    - INFO per lifecycle transition and resolved round summary with counts/result;
    - WARNING for stale choice, invalid sequence item, or skipped duplicate transition;
    - ERROR for invariant/reconciliation failure with IDs/state;
    - no secret choice before reveal, seed, or per-pet result logging.
  - Depends on Tasks 2-5.

- [x] **Task 7: [diaverseapi] Expose typed combat APIs, participant-safe projections, battle reports, notifications, and rollout capabilities.**
  - Deliverable:
    - add combat schemas and endpoints from API Contract Outline;
    - extend capabilities with independent `combat`, `consequences`, and `permanent_death` flags;
    - project active outgoing/incoming operations, cursor-paginated/filterable optional army options with mandatory active/Pack pets separated, flight/round clocks, and next actions;
    - build a report projection from snapshots and rounds with layer-first summaries and cursor-paginated pet details;
    - build historical pet labels/skins/stats only from immutable snapshot fields, never from live Character joins;
    - expose only aggregate opposing layers while a battle is active; full opposing composition is participant-visible only in the terminal report;
    - expose seed/replay metadata only after completion and only to participants;
    - add participant authorization and stable typed error mapping;
    - emit idempotent Cabinet notifications for incoming attack, recall, battle start, result, and return;
    - keep map/search/public profile responses private-field-free.
  - Expected behavior:
    - Attack becomes enabled only when both backend and web combat capabilities allow it;
    - non-participants receive no existence/detail leak;
    - report totals reconcile exactly with saved round results and replay;
    - training reports clearly state that no consequences were applied;
    - repeated notification retries do not duplicate user-visible messages.
  - Files:
    - `diaverseapi/app/pvp/api.py`;
    - `diaverseapi/app/pvp/schemas.py`;
    - `diaverseapi/app/pvp/exceptions.py`;
    - `diaverseapi/app/pvp/dependencies.py`;
    - `diaverseapi/app/pvp/infrastructure/notifications.py`;
    - `diaverseapi/app/core/settings.py`;
    - `diaverseapi/app/core/features.py`;
    - focused API/privacy/report/notification tests.
  - Tests:
    - endpoint validation and typed body idempotency keys;
    - actor/defender/outsider authorization;
    - active opponent-composition/choice secrecy and completed-report visibility;
    - army-options cursor/filter behavior for 500+ optional pets;
    - report/replay reconciliation;
    - feature-flag matrix and no public leakage.
  - Logging:
    - INFO for mutation outcomes and report-generation duration/counts;
    - WARNING for authorization/disabled-capability/invalid-transition codes;
    - do not log request bodies, report payloads, seed, choices, or identities.
  - Depends on Tasks 3, 5, and 6.

### Phase 3: Training combat web slice

- [x] **Task 8: [diaweb] Extend the PvP BFF, types, API client, query keys, polling clocks, and route contract for combat.**
  - Deliverable:
    - proxy every combat GET/POST path through the existing same-origin catch-all BFF with auth forwarding and `no-store`;
    - add strict TypeScript contracts for army options, previews, attacks, battles, choices, reports, capabilities, and typed errors;
    - add query keys and hooks with 10-second travel polling and short active-round polling;
    - use server clock metadata for every deadline/progress calculation;
    - preserve typed request-body idempotency keys unchanged through the BFF and explicitly allowlist every new PvP mutation path/method;
    - invalidate only affected state/map/profile/attack/battle queries after mutation;
    - add default-off `NEXT_PUBLIC_PVP_COMBAT_ENABLED`; consequence visibility follows backend capabilities.
  - Expected behavior:
    - browser code never calls `diaverseapi` directly;
    - mutation replay reuses one client idempotency key;
    - hidden/disabled capability produces a stable unavailable state;
    - polling stops in terminal/background-inactive states and resumes safely.
  - Files:
    - `diaweb/frontend/app/api/cabinet/pvp/**`;
    - `diaweb/frontend/modules/pvp/types.ts`;
    - `diaweb/frontend/modules/pvp/api.ts`;
    - `diaweb/frontend/modules/pvp/queryKeys.ts`;
    - `diaweb/frontend/modules/pvp/constants.ts`;
    - new `diaweb/frontend/modules/pvp/hooks/usePvpAttacks.ts`;
    - new `diaweb/frontend/modules/pvp/hooks/usePvpBattle.ts`;
    - `diaweb/frontend/.env.example`;
    - BFF/client/hook tests.
  - Tests:
    - proxy allowlist/method/body/error behavior and unchanged body idempotency keys;
    - query-key canonicalization;
    - server clock and deadline edge cases;
    - polling enable/disable and mutation invalidation;
    - idempotency reuse.
  - Logging:
    - no routine production console logging;
    - development-only safe route/status diagnostics;
    - normalized UI errors contain codes but no private response dump.
  - Depends on Task 7.

- [x] **Task 9: [diaweb] Implement army builder, preview, attack confirmation, flight/recall, and incoming-operation UX.**
  - Deliverable:
    - enable Attack from the existing `PvpFactoryCard` when capability and target eligibility permit;
    - add an army builder with mandatory active-pet/Pack block, optional pet selection, role/layer/hero badges, selected counts, total power, locks, and no artificial size cap;
    - consume cursor-paginated optional-pet pages, keep selected IDs in a stable `Set` across pages/filters, and avoid adding a virtualization dependency;
    - add PvP hero rank/chance/effect presentation to the existing reusable pet-card content and to the incoming-attack preparation surface, not only the army builder;
    - add accelerator selection and server preview of flight, power ratio, rating/contour/protection, and affected pets;
    - require an explicit final confirmation before registration;
    - extend active operations with outgoing/incoming flight, exact arrival, progress, recall availability, and safe status;
    - display Exchange-block explanation to defenders without implying old orders were cancelled;
    - show clear training/calibration/standard labels.
  - Expected behavior:
    - mandatory pets cannot be accidentally removed and duplicates appear once;
    - server rejection updates stale availability without losing the user's recoverable selection;
    - recall disappears exactly at the server-projected cutoff;
    - no private defender army data appears beyond owned dossier facts;
    - active/Pack mandatory rows remain visible independently of optional-list pagination;
    - keyboard and screen-reader users can build and confirm an army.
  - Files:
    - `diaweb/frontend/modules/pvp/components/PvpFactoryCard.tsx`;
    - `diaweb/frontend/modules/pvp/components/PvpActiveOperations.tsx`;
    - new `PvpArmyBuilder.tsx`;
    - new `PvpAttackConfirmDialog.tsx`;
    - new `PvpFlightOperationCard.tsx`;
    - the existing reusable Character/Raid pet-card content used by owned-pet surfaces;
    - related hooks/types/styles;
    - focused component/accessibility tests.
  - Tests:
    - mandatory/optional selection and deduplication;
    - large list behavior;
    - selection persistence across cursor pages/filters and hero data on all required pet surfaces;
    - preview errors and confirmation;
    - accelerator/recall states;
    - incoming/outgoing/training labels and accessibility.
  - Logging:
    - no army composition or target data in console;
    - development WARNING only for malformed server projection or missing localization.
  - Depends on Task 8.

- [x] **Task 10: [diaweb] Implement the active battle screen, secret choices, automatic sequence, retreat, and immutable report UI.**
  - Deliverable:
    - add `/[lang]/pvp/battles/[battleId]` and `/[lang]/pvp/reports/[battleId]`;
    - show layer-first army summaries, round number, deadline, working buildings, own secret selection, submitted/waiting/revealed states, multiplier, hero effects, and health changes;
    - support saved automatic defender sequence outside battle and per-attack attacker sequence;
    - support idempotent retreat confirmation between rounds;
    - poll/reconcile active battle without realtime infrastructure;
    - render completed reports by round with cursor-loaded expandable per-pet details sourced from immutable historical snapshots and a consequence-free training summary;
    - preserve usable mobile-width responsive layout for the web client without implementing the native app.
  - Expected behavior:
    - opponent choice is invisible until reveal;
    - expired rounds transition through server truth and never resolve locally;
    - double submit/retreat does not duplicate actions;
    - 500-pet reports render summarized first and do not mount all detail rows;
    - renamed, retired, or dead canonical pets do not change historical report content;
    - focus, announcements, timers, and reduced-motion behavior are accessible.
  - Files:
    - new `diaweb/frontend/app/[lang]/(cabinet)/pvp/battles/[battleId]/page.tsx`;
    - new `diaweb/frontend/app/[lang]/(cabinet)/pvp/reports/[battleId]/page.tsx`;
    - new battle/report components and CSS under `diaweb/frontend/modules/pvp/`;
    - `diaweb/frontend/modules/i18n/dictionaries/ru.json`;
    - `diaweb/frontend/modules/i18n/dictionaries/en.json`;
    - `diaweb/frontend/modules/i18n/types.ts`;
    - focused route/component tests.
  - Tests:
    - hidden/submitted/revealed choices;
    - timer and polling transitions;
    - automatic sequence editing/fallback presentation;
    - retreat;
    - layer summary/detail expansion;
    - training report and accessibility.
  - Logging:
    - no console logging of choices, battle state, report data, or errors with response bodies;
    - development WARNING for contract/version mismatch only.
  - Depends on Tasks 8-9 and backend Task 7.

### Phase 4: Standard consequences

- [x] **Task 11: [diaverseapi] Implement Factory production damage, paused jobs, loot-safe ready state, and repair.**
  - Deliverable:
    - add a narrow Factory-owned PvP damage service invoked by settlement;
    - settle `FactoryWarehouseBalance` and craft jobs to the battle-result timestamp under Factory row locks before calculating damage or vulnerable output;
    - calculate defender resource vulnerability from pending plus stored Factory production only, explicitly excluding canonical main inventory;
    - leave resource-production status/accrual unchanged;
    - mark the selected working building's production part/compartments as PvP damaged/repairing while preserving previous states;
    - preserve materials, reservations, unfinished orders, queue order, and ready items;
    - represent theft of one unit from a multi-quantity ready job through a durable unique output claim/debit so later collection cannot grant the stolen unit;
    - serialize hourly autocollect/manual collect, ready-output claim, and damage settlement under the documented Factory lock order;
    - freeze remaining time for running jobs and resume it after repair without granting or losing elapsed production;
    - derive repair level from the maximum built production-compartment level;
    - atomically charge repair XDV and reconcile repair completion;
    - exclude damaged buildings from future round targets and block new standard attacks when no working production building remains.
  - Expected behavior:
    - ready output remains collectable unless the one selected loot unit is stolen;
    - resource accrual continues;
    - unfinished production neither progresses during damage nor restarts from zero;
    - retrying damage or repair cannot double-pause, double-charge, or shift timers twice;
    - concurrent collect/autocollect and theft have one deterministic winner and preserve total quantities;
    - Factory APIs expose a typed PvP damage/repair reason.
  - Files:
    - new `diaverseapi/app/factory/services/pvp_damage_service.py`;
    - `diaverseapi/app/factory/models.py`;
    - `diaverseapi/app/factory/services/crafting_service.py`;
    - `diaverseapi/app/factory/services/state_service.py`;
    - `diaverseapi/app/factory/infrastructure/repositories.py`;
    - `diaverseapi/app/pvp/infrastructure/factory_gateway.py`;
    - `diaverseapi/app/pvp/services/reconciliation_service.py`;
    - Factory/PvP tests and Part-2 migration columns where required.
  - Tests:
    - running/queued/ready/empty job cases;
    - resource production unaffected;
    - maximum-compartment repair level and no-compartment fallback;
    - idempotent damage/repair and concurrent collect/autocollect/ready-output theft/repair;
    - multi-quantity ready-job partial claim followed by collection;
    - all buildings damaged and restored eligibility.
  - Logging:
    - INFO for damage/repair transition with safe building key, level, and job counts;
    - WARNING for invalid preserved state or duplicate transition;
    - no material quantities, ready item identities, XDV balance, or user identity.
  - Depends on Tasks 2, 5, and 6.

- [x] **Task 12: [diaverseapi] Implement Hospital intake, free/paid treatment, recovery, lock projection, and guarded permanent death.**
  - Deliverable:
    - create one Hospital entry for every zero-health pet of either side in a consequence-enabled battle;
    - rank each owner's wounded pets by start power, then `Cpvp`, level, mutation level, and stable pet ID;
    - automatically start free 24-hour treatment for `ceil(wounded × 0.30)` strongest pets;
    - give all others a seven-day treatment-start deadline and snapshot their cost;
    - atomically charge XDV once when paid treatment starts;
    - reconcile treatment completion and return recovered pets to availability;
    - snapshot the death-policy version and enabled state at intake;
    - expire untreated entries through the canonical Character deletion/retirement service only when `death_policy_enabled_at_intake` is true, while retaining PvP audit history;
    - project real waiting/treating counts into the two existing scouting dossier producers;
    - notify before deadline, on treatment completion, and on death without duplicate messages.
  - Expected behavior:
    - capacity and simultaneous treatments are unlimited;
    - starting treatment just before deadline is valid and completion may occur after the deadline;
    - a hospital pet cannot enter raid, market/rent, Pack/active selection, another battle, or progression;
    - consequences enabled with permanent death disabled leaves expired entries safely blocked for operator/product rollout, never silently alive or deleted;
    - enabling permanent death later never retroactively kills entries admitted while it was disabled; any legacy conversion requires an explicit separately reviewed operator migration;
    - repeated workers/read reconciliation apply each transition once.
  - Files:
    - new `diaverseapi/app/pvp/services/hospital_service.py`;
    - `diaverseapi/app/pvp/infrastructure/hospital_gateway.py`;
    - `diaverseapi/app/pvp/services/dossier_service.py`;
    - canonical Character retirement/deletion boundary;
    - `diaverseapi/app/pvp/tasks.py`;
    - hospital/lock/notification tests.
  - Tests:
    - 1, 7, 500 wounded rounding and deterministic tie order;
    - free and paid 24-hour treatment;
    - minimum/rounded costs;
    - deadline boundary and permanent-death flag matrix;
    - enable/disable/re-enable rollout proving non-retroactive death policy;
    - availability integration and dossier counts;
    - concurrency/idempotency.
  - Logging:
    - INFO aggregated intake/treatment/recovery/death counts by battle/owner-safe IDs;
    - WARNING for overdue entry while permanent death is disabled;
    - ERROR for canonical retirement failure;
    - no pet names, XDV balances, costs per user, or hospital lists.
  - Depends on Tasks 2, 4, and 6.

- [x] **Task 13: [diaverseapi] Implement atomic standard settlement: loot, tokens, rating, protections, calibration, cooldown, and consequence flags.**
  - Deliverable:
    - initialize missing profile lifecycle state from Task 2 and determine/snapshot battle mode at registration using the explicit precedence: if either participant is protected, training; otherwise if both have calibration remaining, calibration; otherwise standard;
    - reject mixed calibration/non-calibration standard matching with a stable eligibility code;
    - count accepted self-started standard-intent attacks during newbie protection, including a later recall, and end only the attacker's protection after the third without turning that third battle destructive;
    - decrement calibration for both participants only after a completed calibration battle, never on preview, rejection, recall, or failed recovery;
    - apply no damage, hospital, death, loot, token, or rating mutation in training;
    - match calibration players only to calibration players and apply token/rating results while suppressing loot, Factory damage, Hospital intake, and death;
    - on standard attacker victory, settle Factory production first, then compute each resource theft as `floor(current_vulnerable × 0.03)` and its daily cap as `floor(first_successful_vulnerable × 0.05)`;
    - anchor the game-day cap only on a positive successful theft, apply `min(theft, remaining_cap)`, and keep the anchor immutable for later thefts that day;
    - choose at most one ready-production unit uniformly across all unclaimed ready units using stable job/output/unit ordering plus the versioned battle RNG, without expanding an unbounded in-memory list, and persist the selected output claim;
    - exclude main inventory and unfinished production;
    - debit only the defender's Factory production state and credit the attacker's canonical main resource/item inventory within the same transaction;
    - award PvP tokens `100/20` and rating `+20/-20` through auditable idempotent ledger effects;
    - apply loser rating as `actual_delta = -min(20, current_rating)` and persist/report that actual delta;
    - apply 8-hour defender protection after defeat and 24-hour same-attacker/same-target cooldown from terminal completion;
    - create one settlement row and call Hospital/Factory effects once;
    - keep consequence and permanent-death gates independently reversible.
  - Expected behavior:
    - settlement is all-or-nothing under retries and concurrent Factory collection;
    - daily cap uses the first positive successful theft's vulnerable amount for the configured game day; zero theft never anchors the day;
    - an empty ready-product pool yields no product and does not fail settlement;
    - loser rating never violates the database lower bound and the ledger/report show the actual floored delta;
    - disabling consequences turns all newly registered operations into explicit consequence-free mode and does not reinterpret in-flight snapshots;
    - settlement report totals match canonical ledgers and balances.
  - Files:
    - new `diaverseapi/app/pvp/services/settlement_service.py`;
    - new/extended PvP Factory/inventory/XDV/token gateways;
    - `diaverseapi/app/pvp/services/attack_service.py`;
    - `diaverseapi/app/pvp/services/battle_service.py`;
    - `diaverseapi/app/pvp/services/profile_service.py`;
    - `diaverseapi/app/pvp/infrastructure/repositories.py`;
    - settlement/ledger/concurrency tests.
  - Tests:
    - training/calibration/standard matrix, including calibration-only pairing and calibration token/rating effects;
    - account-created-at newbie boundary, mixed-calibration rejection, completed-only calibration decrement, and third accepted standard-intent transition including recall;
    - 3% floor, positive-anchor-only 5% day cap, repeated theft, and game-day boundary;
    - concurrent collect/theft and empty loot;
    - deterministic ready-product selection/claim and token/rating exact deltas/floor;
    - 8-hour/24-hour boundary;
    - failure injection proving transaction rollback and retry.
  - Logging:
    - INFO one settlement summary with battle ID, mode, outcome, line-item counts, and applied flags;
    - WARNING for capped/empty loot or disabled irreversible effects;
    - ERROR for rollback/reconciliation failure;
    - no exact resource quantities, product identity, token/balance totals, or private inventory payloads.
  - Depends on Tasks 5-6 and 11-12.

- [x] **Task 14: [cross-repo] Expose consequence APIs and implement Factory damage, Hospital, rewards, protection, and final report UX.**
  - Deliverable:
    - add backend hospital/damage/repair/treatment endpoints and consequence projections;
    - extend battle reports with damage, repair, wounded pets, free-treatment selection, paid costs/deadlines, loot, tokens, rating, and mode;
    - add `/[lang]/pvp/hospital` with waiting/treating/history states and paid-treatment confirmation;
    - add Factory/PvP damage and repair cards using the canonical server clock;
    - show protection, calibration, cooldown, Exchange blocking, consequence-disabled, and permanent-death-disabled states in map cards and operations;
    - update dossier rendering so the two Hospital facts receive real values without changing their keys;
    - add RU/EN typed localization and accessible irreversible-action warnings.
  - Expected behavior:
    - users can understand and act on every time-sensitive consequence from the web product;
    - paid treatment and repair have explicit cost confirmation and idempotent retry;
    - report values match backend settlement and do not expose opponent-only private state beyond the completed participant report;
    - irreversible warning text appears only when permanent death is actually enabled;
    - disabled flags remove actions but preserve readable historical reports.
  - Files:
    - `diaverseapi/app/pvp/api.py`;
    - `diaverseapi/app/pvp/schemas.py`;
    - backend consequence API tests;
    - new `diaweb/frontend/app/[lang]/(cabinet)/pvp/hospital/page.tsx`;
    - new/extended PvP consequence components/hooks/types;
    - `diaweb/frontend/modules/pvp/components/PvpDossier.tsx`;
    - Factory integration component only where the current Factory shell exposes status;
    - RU/EN dictionaries and focused Vitest tests.
  - Tests:
    - owner/participant authorization;
    - treatment/repair idempotency and error states;
    - deadline clocks and feature-flag matrix;
    - report/dossier rendering;
    - keyboard, screen-reader, reduced-motion, and narrow-width states.
  - Logging:
    - backend logs mutation outcomes by safe IDs/codes only;
    - frontend has no production console logging of hospital, loot, repair, or report payloads;
    - never log user-facing exact private balances or inventory.
  - Depends on Tasks 7-10 and 11-13.

### Phase 5: Documentation, verification, and rollout gates

- [x] **Task 15: [diaverseapi] Add audited reconciliation recovery, scheduler coverage, and rollout diagnostics.**
  - Deliverable:
    - add a read-only operator audit command that reports aggregate counts and maximum lag for due, retrying, failed-with-locks, stuck-flight, stuck-round, stuck-return, Hospital, repair, and settlement records;
    - add explicit idempotent resume/reconcile and safe-cancel commands that re-lock canonical rows in the documented order, validate the full operation contract, and either complete a valid transition or preserve locks with a safe failure code;
    - never expose a generic force-unlock path; asset locks are released only by a proven terminal transition or reviewed safe-cancel policy;
    - keep recoverable and failed-with-retained-lock operations active in incoming-operation, pet-availability, and Exchange guards;
    - register every due-operation scheduler in `broker_app.py` and add a registration test covering task name, cadence, and default-off feature behavior;
    - emit aggregate structured diagnostics using existing logging/command infrastructure; do not introduce a new observability platform.
  - Expected behavior:
    - one poison operation does not block later batch items;
    - rerunning audit/resume/safe-cancel commands is idempotent;
    - recovery cannot duplicate a round, settlement, notification, reward, damage, treatment, repair, return, or cooldown;
    - a disabled scheduler/capability fails closed while read-only diagnostics remain available;
    - rollout gates can distinguish ordinary lag, retry backlog, and irrecoverable invariant failures without reading private payloads.
  - Files:
    - `diaverseapi/app/pvp/tasks.py`;
    - `diaverseapi/app/pvp/services/reconciliation_service.py`;
    - new `diaverseapi/app/commands/pvp_combat_audit.py`;
    - new `diaverseapi/app/commands/pvp_combat_recover.py`;
    - `diaverseapi/app/core/broker_app.py`;
    - focused command, scheduler, recovery, and concurrency tests.
  - Tests:
    - scheduler registration/cadence and feature-disabled behavior;
    - independent transaction behavior with one poison item between valid items;
    - retry backoff and monotonic claim timestamps;
    - resume and safe-cancel idempotency with locks retained until terminal proof;
    - Exchange/incoming/pet guards while an operation is failed with retained locks;
    - aggregate diagnostics omit private snapshots, choices, seed, balances, loot identities, pet names, and connection data.
  - Logging:
    - INFO aggregate processed/retried/recovered/cancelled counts and max lag;
    - WARNING aggregate stuck/retry counts by safe state/error code;
    - ERROR irrecoverable invariant failure by safe operation ID/state only.
  - Depends on Tasks 2, 4-6, and 11-13.

- [ ] **Task 16: [cross-repo] Document the combat contract and execute non-browser, non-build verification and staged safety gates.**
  - Docs deliverable:
    - create `docs/features/pvp-combat-consequences.md` covering ownership, state machines, API, persistence, formulas, locking, privacy, training/standard modes, Factory, Hospital, settlement, flags, monitoring, and rollback;
    - update `docs/features/pvp-world-recon.md` Part-2 link/boundary;
    - update `.ai-factory/ARCHITECTURE.md`, `docs/README.md`, and relevant file-map navigation;
    - add a concise PvP combat operations/rollback runbook;
    - route the mandatory docs checkpoint through `$aif-docs`.
  - Backend verification from the reused backend worktree:
    - use the main repository venv only as an interpreter if the worktree has no `.venv`;
    - `python -m pytest app/pvp/tests app/factory/tests app/exchange/tests app/raids/tests tests/test_alembic_graph.py -q` with focused selections first;
    - `python -m ruff check` for changed PvP/Factory/Exchange/Raids/Characters/core files;
    - `python -m compileall -q app/pvp`;
    - `python -m alembic heads`;
    - `python -m alembic upgrade <part1_revision>:<part2_revision> --sql`;
    - real-PostgreSQL concurrency/load tests only against an explicitly confirmed disposable database.
  - Frontend verification from the reused web worktree:
    - targeted Vitest suites under `frontend/__tests__/modules/pvp`, BFF tests, and PvP route tests;
    - `npm test` only if targeted tests pass and time/resources permit;
    - `npm run typecheck`;
    - `npm run lint`;
    - do not run Playwright;
    - do not run `npm run build`.
  - Invariant/performance gates:
    - deterministic replay for stored fixtures;
    - 500-vs-500 engine and report projection;
    - no N+1 snapshot/report/hospital queries;
    - attack-vs-Exchange, attack-vs-raid, duplicate choice, duplicate worker, collect-vs-loot, treatment, repair, and settlement races;
    - query plans for active incoming, due operation/round/hospital/repair, report page, and daily cap;
    - fail closed when flags are disabled.
  - Rollout:
    1. migrate with every new flag off;
    2. validate catalog/replay and Part-1 world/scouting regression;
    3. enable training combat for internal/staff only;
    4. validate flight, recall, offline rounds, reports, locks, Exchange guard, and stuck-operation reconciliation;
    5. enable training combat for a small stable web cohort;
    6. enable standard consequences internally with permanent death still off;
    7. validate Factory, Hospital, loot caps, ledgers, rating, repair, and rollback;
    8. enable permanent death only after a separate explicit operator approval and deadline-notification evidence;
    9. widen the web cohort only after error, latency, stuck-state, and ledger-reconciliation gates pass.
  - Rollback:
    - disable permanent death first, then consequences, then combat registration;
    - allow existing accepted operations to reconcile according to their snapshotted mode, or run the documented safe-cancel procedure before disabling workers;
    - never drop snapshots, rounds, settlement, damage, hospital, or cooldown history during operational rollback;
    - never release `failed` operation locks without an audited recovery command.
  - Cross-repo:
    - `git diff --check` and file-scoped review in backend, web, and workspace root;
    - confirm only the reused PvP worktrees were modified;
    - confirm no commits were created;
    - run targeted GBrain sync for `diaverseapi-code`, `diaweb-code`, `diaverse-docs`, and `diaverse-aif`.
  - Logging:
    - tests and operator commands must not print secrets, connection strings, environment values, seeds, private snapshots, exact inventories, or real balances;
    - rollout checks use aggregated counts/statuses and safe operation IDs only.
  - Depends on Tasks 1-15.

## Verification Plan

### diaverseapi

- Catalog/formula golden tests.
- Pure engine/replay tests.
- API authorization/privacy tests.
- Pet/account lock and lifecycle concurrency tests.
- Factory pause/resume/repair tests.
- Hospital/death flag tests.
- Settlement/ledger/daily-cap tests.
- Alembic graph and offline PostgreSQL DDL compilation.
- Ruff and compileall.
- Disposable-PostgreSQL query-plan/load verification only after explicit database confirmation.

### diaweb

- BFF proxy tests.
- Type/API/query/clock hook tests.
- Army, operations, battle, report, Hospital, repair, and dossier component tests.
- Accessibility checks expressible in Vitest/jsdom.
- TypeScript and ESLint.
- No Playwright and no production build.

### Cross-repo

- Version/capability matrix.
- Part-1 map/scouting regression.
- Attack-to-Exchange lock race.
- Attack-to-Raid/Character/Pack lock race.
- Flight/round/return deadline reconciliation.
- Battle replay to report equality.
- Settlement to Factory/inventory/token/rating equality.
- Feature-disable and rollback behavior.
- Targeted GBrain sync after meaningful code/docs changes.

## Acceptance Criteria

- Part-1 world, search, route, and scouting remain functional and private.
- All new combat uses `pvp_catalog.v2`; historical v1 records remain readable.
- One canonical `Cpvp`/role projector is used by scouting, matching, snapshots, and battle.
- Existing and newly created PvP profiles receive deterministic account-age newbie protection and five-battle calibration without reset on backfill reruns.
- Attack registration is idempotent, consumes an accelerator once, and creates locks once.
- An attacker idempotency key remains unique after terminal completion, and every mutation replays through its typed body key.
- Defender can prepare during flight, but the defender snapshot is immutable after arrival.
- Immutable snapshots never carry mutable current health; battle progression survives restart through explicit battle-pet state.
- New Exchange buy/sell orders are transactionally blocked during incoming attack; existing orders and direct execution/cancellation remain allowed.
- Attacker recall works only before 50%, returns for elapsed outbound duration, receives no loot, and still starts cooldown at completion.
- Every round is deterministic, secret until reveal, limited to 45 seconds logically, and reconciles once.
- Offline users progress through saved automatic sequences without a realtime transport.
- A battle ends only by the specified elimination, mutual-destruction, retreat, or 12-round rule.
- Training battles never mutate Factory, Hospital, loot, tokens, or rating.
- Calibration battles mutate tokens/rating but never Factory, Hospital, loot, or pet life state.
- Standard settlement applies once and is transactionally consistent across all affected stores.
- Factory damage pauses only production, preserves state, and resumes exact remaining time after repair.
- Hospital free 30%, paid treatment, deadline, recovery, and guarded death follow the source formulas.
- Enabling permanent death cannot reinterpret Hospital entries admitted while death was disabled.
- Loot excludes main inventory and unfinished production, respects 3%/5% limits, and steals at most one ready unit.
- PvP tokens and rating changes are auditable and idempotent.
- Reports reproduce the stored battle and remain usable for 500+ pets.
- Public APIs/logs never leak private army, hospital, inventory, choice, seed, or settlement details.
- Combat, consequences, and permanent death can be independently stopped by flags.
- Due work is processed per operation, schedulers are registration-tested, and failed-with-lock operations require audited idempotent recovery or safe cancellation.
- All permitted verification passes without Playwright or production build.
- No commits or branch/worktree changes are made.

## Implementation Handoff

Run `$aif-implement` from the workspace root with this plan only after:

1. confirming both reused PvP worktrees still contain only the expected Part-1 changes;
2. completing or explicitly accepting the remaining Part-1 operator gates that are prerequisites for combat;
3. resolving the actual Alembic head in a safe environment without exposing production credentials;
4. confirming no real PostgreSQL test can point at production;
5. retaining `PVP_COMBAT_ENABLED`, `PVP_CONSEQUENCES_ENABLED`, and `PVP_PERMANENT_DEATH_ENABLED` as default-off;
6. acknowledging that implementation remains on `feature/pvp-world-recon` because the user explicitly requested the same worktrees;
7. preserving the no-commit, no-Playwright, and no-build constraints.
