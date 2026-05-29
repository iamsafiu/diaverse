# Implementation Plan: Raids Mechanics v1

Branch: feature/raids-mechanics
Created: 2026-05-28

## Settings
- Testing: yes
- Logging: verbose
- Docs: yes
- Roadmap Linkage: none, `.ai-factory/ROADMAP.md` is not present

Assumption: the user asked to proceed directly with a full plan and branch setup, so this plan uses the recommended defaults: tests included, verbose development logging, mandatory docs checkpoint.

## Workspace Mode
- Mode: multi-repo full
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Source documents:
  - `docs/tasks/raids/raids-mechanics.md`
  - `docs/tasks/raids/raids-gameplay-guide.md`
- Knowledge: local GBrain attempted first for docs/code lookup, then raw source verified because current code source search has little raid coverage.

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `feature/raids-mechanics` | clean at `95843e9` | cabinet UI, BFF routes, mobile raid screen |
| diaverseapi | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `feature/raids-mechanics` | clean at `11bac3bc` | raid domain, DB, API, rewards, payments |
| aibot | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | unchanged `dev` | clean | not affected |
| club10000-bot | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | unchanged `dev` | clean | not affected |

## Branch Setup Completed
- `diaweb`: local `dev` updated from `origin/dev`, branch `feature/raids-mechanics` created from updated `dev`.
- `diaverseapi`: local `dev` fast-forwarded from `origin/dev`, branch `feature/raids-mechanics` created from updated `dev`.
- Root `diaverse`: no branch switch; root repo remains coordination/docs only.

## Product Decisions To Implement
- DCR is not used in v1 raid UI or mechanics.
- Game dollars may appear in HUD as a general balance only; they do not pay for raids, drop as rewards, or determine slots.
- Entry currencies: XDV for basic/subscription raids, USDT for USDT raids.
- Ransom currency: XDV.
- Basic XDV and USDT raids last 24 hours; XDV with subscription lasts 12 hours automatically.
- Locations: Rusty Wastelands, Oasis, Radioactive Cave.
- Streak: +1% per successful raid start in same location, capped per location; successful start in another location resets previous location after payment and run creation.
- Active runs use streak snapshot from start time.
- Oasis XDV discount: +5% per next Oasis XDV raid down to 50% of base price; reset 7 days after automatic completion of last Oasis raid if no new Oasis raid starts.
- Slot limit: profile grade table plus up to 5 permanent token slots; USDT mode has no mechanical slot limit.
- Synthesis Core and Slot Token are location-gated; access mode multipliers apply only where the resource can drop.
- Chest roll model: one roll per chest rarity per pet per raid, chance capped at 100%, base quantity 1, crit doubles that chest to 2.
- Traps: per-pet after completion, 7-day death timer, XDV ransom or 50% rescuer attempt.
- Pets in raid, trap, pack, rent, or rescue must be unavailable for incompatible actions.
- `raids` is a first-class cabinet payment domain for USDT mode, not a standalone callback surface.
- Raid state must participate in account merge/delete safety and in cross-domain pet mutation guards.

## Architecture Summary
- `diaverseapi` currently has only legacy `RaidVoucher` / `UserRaidVoucher` in `app/raids/models.py`. Keep those tables for compatibility and add new raid v1 tables alongside them.
- Follow the proven factory pattern for a large cabinet domain:
  - `app/raids/catalog/*` for static mechanics
  - `app/raids/domain/*` for formulas and pure rules
  - `app/raids/infrastructure/*` for repositories, balance adapters, notification/payment bridges
  - `app/raids/services/*` for state, commands, settlement, rescue
  - `app/raids/api.py`, `app/raids/dependencies.py`, `app/raids/schemas.py`
  - tests under `app/raids/tests/`
- Reuse cabinet payment, account lifecycle, and user-character mutation patterns instead of creating isolated raid-only flows.
- `diaweb` should mirror the factory frontend pattern:
  - `frontend/modules/raids/*`
  - BFF routes under `frontend/app/api/cabinet/raids/*`
  - cabinet page under `frontend/app/[lang]/(cabinet)/raids/page.tsx`
  - nav/i18n/assets added to existing cabinet structures.
- Treat `/[lang]/raids` as a game/fullscreen cabinet route, similar to factory, so generic cabinet chrome and promo overlays do not fight the raid HUD.

## Backend API Contract
Base prefix: `/v1/cabinet/raids`

Endpoints:
- `GET /catalog` - static locations, modes, prices, slot table, reward tables, visual keys.
- `GET /state` - server time, HUD balances, profile slot state, locations, active/completed/trapped runs, available pets, notifications.
- `POST /start` - start one or more pet raids in one location/mode with idempotency key.
- `POST /runs/{run_id}/claim` - claim completed run rewards and resolve/return per-pet results.
- `POST /traps/{trap_id}/ransom` - pay XDV ransom and release trapped pet.
- `POST /traps/{trap_id}/rescue` - send rescuer pet with 50% outcome.
- `POST /slot-tokens/unlock` - spend Slot Token resource to unlock permanent XDV token slot.
- Existing cabinet payment finalizer hook for domain `raids` - finalize USDT order and start/activate paid raid.

All command endpoints must return a `RaidCommandResponse` with `status`, `idempotency_key`, optional updated `state`, user-facing `errors`, and `notifications`.

## Tasks

### Phase 1: Backend Domain Foundation

- [x] Task 1: Add raid catalog and validator.
  - Files:
    - `diaverseapi/app/raids/catalog/schema.py`
    - `diaverseapi/app/raids/catalog/loader.py`
    - `diaverseapi/app/raids/catalog/validator.py`
    - `diaverseapi/app/raids/catalog/data/raids_catalog.v1.yaml`
    - `diaverseapi/app/raids/tests/test_catalog.py`
  - Deliverable:
    - Encode all location, mode, duration, slot table, prices, streak caps, trap chances, chest chances, crit chances, special loot rules, pet rarity mapping, special pet abilities, Oasis discount rules, and token-slot cap from the docs.
    - Validate that special loot is location-gated and that all chest chances/resources are non-negative.
  - Logging requirements:
    - `DEBUG [raids.catalog] loaded version/path/counts`.
    - `ERROR [raids.catalog] parse/validation failure path/version/error`.
    - No secrets or user data in catalog logs.

- [x] Task 2: Add raid v1 persistence models and Alembic migration.
  - Files:
    - `diaverseapi/app/raids/models.py`
    - `diaverseapi/migrations/versions/<revision>_raid_mechanics_v1.py`
    - `diaverseapi/app/raids/tests/test_models.py`
  - Deliverable:
    - Preserve legacy `RaidVoucher` and `UserRaidVoucher`.
    - Add `RaidProfile`, `RaidRun`, `RaidParticipant`, `RaidTrap`, `RaidRescueAttempt`, `RaidIdempotencyRecord`, and optional `RaidPaymentOrder`.
    - Use short explicit PostgreSQL index/constraint names.
    - Model run/participant statuses: `active`, `completed`, `claimed`, `trapped`, `rescuing`, `released`, `lost`, `cancelled`.
    - Store snapshots: catalog version, mode, location, price, streak percent, Oasis discount, subscription state, reward/trap roll metadata.
    - Ensure raid models are imported into SQLModel metadata so migration, merge-coverage, and Alembic graph tests can see every new table.
  - Logging requirements:
    - No model-level logging.
    - Migration should be deterministic and reversible where practical.
  - Dependency: Task 1.

- [x] Task 3: Add raid schemas, error codes, action codes, and disabled response.
  - Files:
    - `diaverseapi/app/raids/schemas.py`
    - `diaverseapi/app/raids/exceptions.py`
    - `diaverseapi/app/raids/infrastructure/rollout.py`
    - `diaverseapi/app/core/settings.py`
    - `diaverseapi/app/core/features.py`
  - Deliverable:
    - Define `RaidCatalogResponse`, `RaidStateResponse`, `RaidCommandResponse`, `RaidLocationRead`, `RaidSlotRead`, `RaidPetRead`, `RaidRunRead`, `RaidTrapRead`, `RaidRewardRead`.
    - Add error codes for disabled, catalog unavailable, invalid mode/location, pet unavailable, insufficient XDV, payment required, slot limit reached, run not ready, trap expired, rescue blocked, idempotency conflict.
    - Add `RAIDS_WEB_ENABLED` / backend rollout equivalent, matching factory disabled-response pattern.
  - Logging requirements:
    - `DEBUG [raids.rollout] snapshot resolved enabled=<bool>`.
    - `WARNING [raids.api] disabled route requested user=<uuid> route=<name>`.
  - Dependency: Task 1.

- [x] Task 4: Add repository and idempotency infrastructure.
  - Files:
    - `diaverseapi/app/raids/infrastructure/repositories.py`
    - `diaverseapi/app/raids/tests/test_repositories.py`
  - Deliverable:
    - CRUD and locking helpers for profiles, runs, participants, traps, rescue attempts, idempotency records, and payment orders.
    - Idempotency behavior mirrors factory: acquire, replay completed response, reject request hash mismatch.
    - Use `FOR UPDATE` for command flows that debit balances, reserve pets, release traps, or claim rewards.
  - Logging requirements:
    - `DEBUG [raids.repo] idempotency acquired/replayed/locked`.
    - `WARNING [raids.repo] idempotency conflict`.
    - Include user/profile/run ids, never raw payment provider payloads.
  - Dependency: Task 2.

### Phase 2: Backend Rules And Services

- [x] Task 5: Implement pure calculation rules.
  - Files:
    - `diaverseapi/app/raids/domain/pricing.py`
    - `diaverseapi/app/raids/domain/slots.py`
    - `diaverseapi/app/raids/domain/streaks.py`
    - `diaverseapi/app/raids/domain/rewards.py`
    - `diaverseapi/app/raids/domain/traps.py`
    - `diaverseapi/app/raids/tests/test_domain_rules.py`
  - Deliverable:
    - XDV price by location and pet rarity.
    - USDT price by location.
    - Subscription duration 12h, other modes 24h.
    - Grade slot table plus token slots, max +5.
    - Streak snapshot and reset decision.
    - Oasis discount calculation and reset deadline.
    - XP, resource, chest, crit, special loot, trap, ransom, and rescue formulas.
    - Deterministic roll function taking injected RNG/seed for tests.
  - Logging requirements:
    - Pure functions should not log.
    - Return structured metadata for services to log decisions at boundaries.
  - Dependency: Tasks 1-2.

- [x] Task 6: Implement balance, resource, XP, subscription, and pet availability gateways.
  - Files:
    - `diaverseapi/app/raids/infrastructure/xdv_gateway.py`
    - `diaverseapi/app/raids/infrastructure/resource_gateway.py`
    - `diaverseapi/app/raids/infrastructure/subscription_resolver.py`
    - `diaverseapi/app/raids/infrastructure/pet_gateway.py`
    - `diaverseapi/app/raids/tests/test_gateways.py`
  - Deliverable:
    - Reuse existing BotUser-backed XDV semantics from factory where possible.
    - Do not use game dollars for raid debits or slot logic.
    - Credit resources to `UserResource` for bullet/galaglue/nuclear_acorn/synthesis_core/slot_token.
    - Credit XP directly to the participating `UserCharacter`, not only the active pet; do not blindly reuse `AddUserCharacterExperienceUseCase` because it targets the active pet.
    - Exclude pets in pack, rent/rent_out/on_market, active raid, trapped, rescue, deleted.
    - Expose a shared raid pet-usage reader so other character/pack/rent flows can block raid-locked pets without duplicating status queries.
    - Resolve active subscription feature using existing subscription tables; map to raid subscription mode.
  - Logging requirements:
    - `DEBUG [raids.xdv] balance loaded/debited/credited`.
    - `INFO [raids.reward] resources/xp credited user=<uuid> participant=<uuid>`.
    - `WARNING [raids.pet] unavailable pet reason=<code>`.
    - `WARNING [raids.xdv] insufficient balance`.
  - Dependency: Task 5.

- [x] Task 6A: Add cross-domain pet action guards for raid-locked pets.
  - Files:
    - `diaverseapi/app/raids/infrastructure/pet_gateway.py`
    - `diaverseapi/app/characters/usecases/utils.py`
    - `diaverseapi/app/characters/usecases/set_user_character_active.py`
    - `diaverseapi/app/characters/usecases/rent_character.py`
    - `diaverseapi/app/characters/usecases/merge_user_characters.py`
    - `diaverseapi/app/packs/usecases/update_pack.py`
    - `diaverseapi/app/packs/usecases/fix_pack.py`
    - `diaverseapi/app/raids/tests/test_pet_action_guards.py`
  - Deliverable:
    - Block pack, rent-out/on-market, active-pet switching where it conflicts, and merge actions for pets in active raid, trap, rescue, or lost raid state.
    - Keep the guard centralized behind a raid pet-usage helper so non-raid domains do not query raid tables ad hoc.
    - Preserve existing pack/rent semantics for pets with no raid state.
    - Cover both directions: raid service excludes pack/rent pets, and pack/rent/merge services exclude raid-locked pets.
  - Logging requirements:
    - `WARNING [raids.pet_guard] blocked external action action=<code> pet=<uuid> raid_state=<code>`.
    - No repeated logs from read-only list screens.
  - Dependency: Tasks 4 and 6.

- [x] Task 7: Implement `RaidStateService`.
  - Files:
    - `diaverseapi/app/raids/services/state_service.py`
    - `diaverseapi/app/raids/tests/test_state_service.py`
  - Deliverable:
    - Build full screen state for frontend: catalog version, server time, HUD balances, locations, streaks, Oasis discount, slot counts, token slot progress, active/completed/trapped runs, available pets and unavailable reasons.
    - Set `next_refresh_at` to nearest raid completion, trap expiry, or Oasis discount reset.
    - Include chest/special-loot zero states so UI can display greyed-out loot.
    - Apply safe passive transitions when state is read: completed runs become claimable, expired traps become lost, and Oasis discount reset is reflected without requiring a background job.
  - Logging requirements:
    - `DEBUG [raids.state] build start/end user=<uuid> runs=<n> traps=<n>`.
    - `INFO [raids.state] passive settlement applied user=<uuid> completed=<n> expired_traps=<n>`.
    - `WARNING [raids.state] catalog/profile mismatch recovered`.
  - Dependency: Tasks 4-6.

- [x] Task 8: Implement `RaidCommandService.start_raid`.
  - Files:
    - `diaverseapi/app/raids/services/command_service.py`
    - `diaverseapi/app/raids/tests/test_command_start.py`
  - Deliverable:
    - Validate mode/location/pets/idempotency.
    - Enforce one-location mass start in v1.
    - Enforce XDV slot limit for XDV modes, no mechanical limit for USDT.
    - Debit XDV for basic/subscription modes.
    - For USDT mode, create payment order and return `payment_required` unless provider finalization already exists.
    - Apply streak reset and increment only after successful payment/order creation according to mode semantics.
    - Persist run and participants with snapshots and completion time.
  - Logging requirements:
    - `INFO [raids.command] start requested user/location/mode/pet_count/idempotency`.
    - `DEBUG [raids.command] slot calculation/streak decision/price snapshot`.
    - `INFO [raids.command] run started run=<uuid> completes_at=<iso>`.
    - `WARNING [raids.command] blocked reason=<code>`.
  - Dependency: Task 7.

- [x] Task 9: Implement completion, claim, and reward settlement.
  - Files:
    - `diaverseapi/app/raids/services/settlement_service.py`
    - `diaverseapi/app/raids/tests/test_settlement_service.py`
  - Deliverable:
    - Mark eligible participants complete when `completes_at <= now`.
    - On claim, calculate rewards once, store reward snapshot, credit XP/resources/special loot, roll chests and crits, then roll trap.
    - If trap triggers, hold rewards if product requires, or credit rewards and mark pet trapped; choose and document one behavior. Recommended: reward is credited, pet still enters trap after raid result.
    - Support idempotent repeated claim without duplicate credits.
    - Explicitly document behavior for users who return long after completion: claim remains idempotent, trap expiry is evaluated before release actions, and no rewards are double-credited.
  - Logging requirements:
    - `INFO [raids.settlement] participant settled/claimed/trapped`.
    - `DEBUG [raids.settlement] reward roll metadata`.
    - `ERROR [raids.settlement] credit failure with run/participant ids`.
  - Dependency: Task 8.

- [x] Task 10: Implement trap, ransom, rescue, expiry, and lost-pet flows.
  - Files:
    - `diaverseapi/app/raids/services/trap_service.py`
    - `diaverseapi/app/raids/tests/test_trap_service.py`
  - Deliverable:
    - Create trap with 7-day `expires_at`.
    - Ransom cost = 3x XDV entry price snapshot.
    - Rescue attempt requires an available rescuer pet, locks it, rolls 50%.
    - Success releases trapped pet and rescuer; failure traps rescuer with its own 7-day timer and ransom snapshot.
    - Expired traps mark pet `lost`; implementation must choose whether this sets `UserCharacter.is_deleted=true` or a safer new raid-lost flag. Recommended v1: mark raid participant/trap lost and do not hard-delete until product confirms irreversible pet deletion mechanics.
  - Logging requirements:
    - `INFO [raids.trap] ransom paid/release`.
    - `WARNING [raids.trap] rescue failed rescuer=<uuid> trap=<uuid>`.
    - `WARNING [raids.trap] trap expired pet=<uuid>`.
    - `ERROR [raids.trap] inconsistent trap state`.
  - Dependency: Task 9.

- [x] Task 11: Implement token-slot unlock service.
  - Files:
    - `diaverseapi/app/raids/services/slot_token_service.py`
    - `diaverseapi/app/raids/tests/test_slot_token_service.py`
  - Deliverable:
    - Spend 1 `ResourceType.slot_token` for +1 permanent XDV token slot.
    - Enforce max +5 token slots per account.
    - Return updated state and clear errors for insufficient token or already maxed.
  - Logging requirements:
    - `INFO [raids.slot_token] unlocked user=<uuid> total=<n>`.
    - `WARNING [raids.slot_token] blocked reason=<code> available=<n> unlocked=<n>`.
  - Dependency: Tasks 5-7.

- [x] Task 12: Implement USDT payment integration.
  - Files:
    - `diaverseapi/app/raids/services/payment_service.py`
    - `diaverseapi/app/raids/payment_finalizer.py`
    - `diaverseapi/app/cabinet/payments/types.py`
    - `diaverseapi/app/cabinet/payments/registry.py`
    - `diaverseapi/app/cabinet/payments/finalizers.py`
    - `diaverseapi/app/raids/tests/test_payment_service.py`
    - `diaverseapi/tests/test_cabinet_payment_sessions.py`
  - Deliverable:
    - Create raid payment orders for 4/8/12 USDT by location.
    - Store provider code/reference, request language, payment metadata, and pending run payload.
    - On paid callback/finalization, start the raid idempotently with no traps and no slot limit.
    - Add `raids` to the cabinet payment domain type and to supported provider domain codes.
    - Register a raid payment finalizer in the shared cabinet finalizer registry.
    - Keep guest payment disabled for raids unless product explicitly approves guest raid starts.
    - Add registry tests equivalent to the existing factory domain/finalizer tests.
  - Logging requirements:
    - `INFO [raids.payment] order created/finalized`.
    - `WARNING [raids.payment] duplicate/expired/invalid provider state`.
    - `ERROR [raids.payment] paid order failed to start raid`.
  - Dependency: Task 8.

- [x] Task 12A: Add account lifecycle and pending-payment safety for raid tables.
  - Files:
    - `diaverseapi/app/security/usecases.py`
    - `diaverseapi/tests/test_merge_account_coverage.py`
    - `diaverseapi/tests/test_user_deletion.py`
    - `diaverseapi/app/raids/tests/test_account_lifecycle.py`
  - Deliverable:
    - Classify every new raid table with a `users.uuid` foreign key in merge-account coverage.
    - Delete or cascade raid state safely during user deletion, preserving audit/payment rows where existing project policy requires it.
    - Transfer or reject raid state during account merge using factory-style conflict rules.
    - Block delete/merge when the user has pending raid payment orders in paid/processing/awaiting states.
    - Cover active runs, traps, idempotency records, and raid payment orders.
  - Logging requirements:
    - `INFO [security.raids] delete/merge raid state user=<uuid> counts=<dict>`.
    - `WARNING [security.raids] pending raid payment blocks delete/merge user=<uuid> order=<uuid>`.
  - Verification:
    - Passed: `python -m ruff check app/security/usecases.py app/security/exceptions.py app/raids/tests/test_account_lifecycle.py tests/test_merge_account_coverage.py tests/test_user_deletion.py`.
    - Passed: `python -m pytest tests/test_merge_account_coverage.py -q`.
    - Blocked locally by unavailable PostgreSQL: `python -m pytest app/raids/tests/test_account_lifecycle.py tests/test_user_deletion.py::test_deletion_blocks_pending_raid_payment -q` failed before test logic with `ConnectionRefusedError` on `localhost:5432`.
  - Dependency: Tasks 2 and 12.

- [x] Task 13: Implement raid notification hints and cabinet notification persistence.
  - Files:
    - `diaverseapi/app/raids/infrastructure/notifications.py`
    - `diaverseapi/app/raids/tests/test_notifications.py`
  - Deliverable:
    - Emit non-fatal notifications for run complete, trap created, trap expiring, trap lost, rescue result, token slot unlocked, USDT payment complete.
    - Add notification hint objects to state/command responses.
    - Use cabinet notification service where appropriate.
  - Logging requirements:
    - `DEBUG [raids.notifications] hint built`.
    - `INFO [raids.notifications] persisted code=<code>`.
    - `WARNING [raids.notifications] persistence failed non_fatal=true`.
  - Verification:
    - Passed: `python -m ruff check app/raids/infrastructure/notifications.py app/raids/services/state_service.py app/raids/services/settlement_service.py app/raids/services/trap_service.py app/raids/services/slot_token_service.py app/raids/services/payment_service.py app/raids/tests/test_notifications.py app/raids/tests/test_settlement_service.py app/raids/tests/test_trap_service.py app/raids/tests/test_slot_token_service.py app/raids/tests/test_payment_service.py`.
    - Passed: `python -m pytest app/raids/tests/test_notifications.py app/raids/tests/test_settlement_service.py app/raids/tests/test_trap_service.py app/raids/tests/test_slot_token_service.py app/raids/tests/test_payment_service.py -q`.
  - Dependency: Tasks 7, 9, 10, 12.

### Phase 3: Backend API Wiring And Verification

- [x] Task 14: Add raid API routes and dependencies.
  - Files:
    - `diaverseapi/app/raids/api.py`
    - `diaverseapi/app/raids/dependencies.py`
    - `diaverseapi/app/routers/v1/endpoints.py`
    - `diaverseapi/app/raids/tests/test_api.py`
  - Deliverable:
    - Register `/v1/cabinet/raids`.
    - Add NoStore route behavior.
    - Authenticate via `get_current_user`.
    - Return disabled response when rollout flag is off.
    - Wrap catalog load errors as 503.
  - Logging requirements:
    - `DEBUG [raids.api] catalog/state requested`.
    - `INFO [raids.api] command requested route=<name> user=<uuid> idempotency=<key>`.
    - `WARNING [raids.api] command blocked code=<code>`.
  - Verification:
    - Passed: `python -m ruff check app/raids/api.py app/raids/dependencies.py app/routers/v1/endpoints.py app/raids/tests/test_api.py`.
    - Passed: `python -m pytest app/raids/tests/test_api.py -q`.
  - Dependency: Tasks 3, 7-13, and 12A.

- [x] Task 15: Add backend integration tests for full player paths.
  - Files:
    - `diaverseapi/app/raids/tests/test_raids_flow.py`
    - `diaverseapi/app/raids/tests/conftest.py`
  - Deliverable:
    - Cover base XDV Wastelands start -> complete -> claim.
    - Cover subscription 12-hour mode.
    - Cover Oasis discount and reset snapshot.
    - Cover streak reset between locations.
    - Cover trap ransom and rescue success/failure.
    - Cover token slot unlock.
    - Cover USDT payment-required and payment-finalized paths.
    - Cover pet unavailable in pack/rent/active raid/trap in both directions, including attempts to rent/pack/merge raid-locked pets.
    - Cover user deletion/merge behavior when raid state or pending raid payments exist.
  - Logging requirements:
    - Tests should assert key log calls for blocked flows where feasible via `caplog`.
    - Test fixtures should not log secrets or raw provider payloads.
  - Implementation note:
    - Local PostgreSQL is unavailable in this workspace, so the committed flow suite uses real raid services with in-memory repository/gateway fakes and leaves true DB integration execution for the backend quality gate when PostgreSQL is running.
  - Verification:
    - Passed: `python -m ruff check app/raids/tests/test_raids_flow.py`.
    - Passed: `python -m pytest app/raids/tests/test_raids_flow.py -q`.
  - Dependency: Tasks 6A, 12A, and 14.

- [x] Task 16: Backend migration and quality gate.
  - Files:
    - No new files unless migration needs correction.
  - Deliverable:
    - Run targeted raid test suite.
    - Run ruff on all changed raid files.
    - Run Alembic head check.
    - Run PostgreSQL SQL compile check for the new migration to catch identifier length issues.
    - Run merge-account coverage and Alembic graph/identifier tests that include raid tables.
  - Commands:
    - `.\.venv\Scripts\python.exe -m pytest app\raids\tests -q`
    - `.\.venv\Scripts\python.exe -m pytest tests\test_merge_account_coverage.py tests\test_user_deletion.py tests\test_alembic_graph.py -q`
    - `.\.venv\Scripts\python.exe -m ruff check app\raids app\routers\v1\endpoints.py app\core\settings.py app\core\features.py`
    - `.\.venv\Scripts\python.exe -m alembic heads`
    - `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
  - Logging requirements:
    - No code logging; capture command output in implementation notes.
  - Verification:
    - Passed: `python -m pytest app/raids/tests -q --ignore=app/raids/tests/test_account_lifecycle.py` -> 64 passed.
    - Passed: `python -m ruff check app/raids app/routers/v1/endpoints.py app/core/settings.py app/core/features.py app/security/usecases.py app/security/exceptions.py tests/test_merge_account_coverage.py tests/test_user_deletion.py tests/test_cabinet_payment_sessions.py`.
    - Passed: `python -m alembic heads` -> `raid_mechanics_v1_20260528 (head)`.
    - Passed: `python -m alembic upgrade runtime_settings_20260528:raid_mechanics_v1_20260528 --sql`.
    - Passed: `python -m pytest tests/test_merge_account_coverage.py tests/test_alembic_graph.py -q` -> 16 passed.
    - Blocked locally by unavailable PostgreSQL: `python -m pytest tests/test_user_deletion.py::test_deletion_blocks_pending_raid_payment app/raids/tests/test_account_lifecycle.py -q` failed before test logic with `ConnectionRefusedError` on `localhost:5432`.
  - Dependency: Tasks 1-15 plus Tasks 6A and 12A.

### Phase 4: Frontend BFF, Types, And Routing

- [x] Task 17: Add raids BFF proxy routes.
  - Files:
    - `diaweb/frontend/app/api/cabinet/raids/_utils.ts`
    - `diaweb/frontend/app/api/cabinet/raids/catalog/route.ts`
    - `diaweb/frontend/app/api/cabinet/raids/state/route.ts`
    - `diaweb/frontend/app/api/cabinet/raids/runs/start/route.ts`
    - `diaweb/frontend/app/api/cabinet/raids/runs/[runId]/claim/route.ts`
    - `diaweb/frontend/app/api/cabinet/raids/traps/[trapId]/ransom/route.ts`
    - `diaweb/frontend/app/api/cabinet/raids/traps/[trapId]/rescue/route.ts`
    - `diaweb/frontend/app/api/cabinet/raids/slot-tokens/unlock/route.ts`
    - `diaweb/frontend/__tests__/app/api/cabinet/raids/proxy-utils.test.ts`
    - `diaweb/frontend/__tests__/app/api/cabinet/raids/route.test.ts`
  - Deliverable:
    - Mirror factory BFF pattern.
    - Forward cookies, language, timezone, Telegram platform, request id.
    - Copy safe upstream headers and set no-store cache.
    - Add route-handler import tests for every raids BFF file so missing App Router route segments are caught before deployment.
    - Verify dynamic `runId`/`trapId` params are encoded correctly.
  - Logging requirements:
    - `DEBUG [raids/bff] upstream start/success` in development.
    - `WARN [raids/bff] upstream failed`.
    - `ERROR [raids/bff] transport failure`.
  - Verification:
    - Passed: `npm test -- --run __tests__/app/api/cabinet/raids` -> 2 files, 7 tests.
    - Passed: `npm run lint -- app/api/cabinet/raids __tests__/app/api/cabinet/raids`.
  - Dependency: Task 14 can be in parallel after endpoint contract is stable.

- [x] Task 18: Add frontend raid types, API client, query hooks, and mutations.
  - Files:
    - `diaweb/frontend/modules/raids/types.ts`
    - `diaweb/frontend/modules/raids/api.ts`
    - `diaweb/frontend/modules/raids/constants.ts`
    - `diaweb/frontend/modules/raids/time.ts`
    - `diaweb/frontend/modules/raids/hooks/useRaidState.ts`
    - `diaweb/frontend/modules/raids/hooks/useRaidMutations.ts`
    - `diaweb/frontend/modules/raids/hooks/useRaidClock.ts`
    - `diaweb/frontend/modules/raids/index.ts`
    - `diaweb/frontend/__tests__/modules/raids/raids-api.test.ts`
    - `diaweb/frontend/__tests__/modules/raids/raid-time.test.ts`
  - Deliverable:
    - Type the backend contract.
    - Add query keys and polling based on `next_refresh_at`.
    - Add idempotency key helper.
    - Mutations update raid state cache and invalidate notification queries.
    - Add a shared clock helper that derives active-run progress, trap death countdowns, and rescue timers from `server_time`, `completes_at`, `expires_at`, and `next_refresh_at`.
    - Avoid refetching every second; UI ticks may update locally while network polling follows `next_refresh_at` and mutation results.
  - Logging requirements:
    - `DEBUG [raids] query/mutation start/success` in development.
    - `WARN [raids] mutation failed status/code/message`.
    - Avoid logging full pet lists or provider payloads.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids` -> 2 files, 11 tests.
    - Passed: `npm run lint -- modules/raids __tests__/modules/raids`.
    - Passed: `npm run typecheck`.
  - Dependency: Task 17.

- [x] Task 19: Add route, rollout constant, cabinet navigation, icon, and i18n.
  - Files:
    - `diaweb/frontend/app/[lang]/(cabinet)/raids/page.tsx`
    - `diaweb/frontend/modules/raids/constants.ts`
    - `diaweb/frontend/modules/cabinet/routeAccess.ts`
    - `diaweb/frontend/modules/cabinet/components/CabinetLayout.tsx`
    - `diaweb/frontend/modules/cabinet/components/CabinetRouteTransition.tsx`
    - `diaweb/frontend/modules/cabinet/components/BottomNavIcon.tsx`
    - `diaweb/frontend/modules/cabinet/components/BottomNav.tsx`
    - `diaweb/frontend/modules/cabinet/components/CabinetTopbar.tsx`
    - `diaweb/frontend/modules/shop/hooks/useShopPromoOffer.ts`
    - `diaweb/frontend/modules/i18n/types.ts`
    - `diaweb/frontend/modules/i18n/dictionaries/ru.json`
    - `diaweb/frontend/modules/i18n/dictionaries/en.json`
    - `diaweb/frontend/public/cabinet/nav-raids.svg`
  - Deliverable:
    - Add `/[lang]/raids`.
    - Require auth for raids route.
    - Treat raids as a fullscreen/game cabinet route in layout and route transitions, similar to factory.
    - Exclude raids from generic shop promo overlays and any chrome that would cover the HUD.
    - Add bottom/top navigation item without breaking mobile width; if 5 tabs become too dense, use feature gate or replace less relevant tab based on product decision.
    - Add `NEXT_PUBLIC_RAIDS_WEB_ENABLED` behavior.
    - Add proxy/access tests for `/ru/raids` and rollout-disabled behavior.
  - Logging requirements:
    - `DEBUG [raids/page] shell route rendered/rollout disabled` in development.
    - No production console noise.
  - Verification:
    - Passed: `npm test -- --run __tests__/app/cabinet-raids-page.test.tsx __tests__/modules/cabinet/routeAccess.test.ts __tests__/proxy.test.ts __tests__/next-config-cache.test.ts __tests__/modules/shop/useShopPromoOffer.test.tsx __tests__/modules/cabinet/BottomNav.test.tsx __tests__/modules/cabinet/CabinetTopbar.test.tsx __tests__/modules/cabinet/CabinetLayout.test.tsx __tests__/modules/cabinet/Sidebar.test.tsx` -> 9 files, 88 tests.
    - Passed: `npm run lint -- "app/[lang]/(cabinet)/raids" modules/raids/constants.ts modules/cabinet/routeAccess.ts modules/cabinet/components/CabinetLayout.tsx modules/cabinet/components/CabinetRouteTransition.tsx modules/cabinet/components/BottomNavIcon.tsx modules/cabinet/components/BottomNav.tsx modules/cabinet/components/CabinetTopbar.tsx modules/shop/hooks/useShopPromoOffer.ts modules/i18n/types.ts __tests__/app/cabinet-raids-page.test.tsx __tests__/modules/cabinet/routeAccess.test.ts __tests__/proxy.test.ts __tests__/next-config-cache.test.ts __tests__/modules/shop/useShopPromoOffer.test.tsx __tests__/modules/cabinet/BottomNav.test.tsx __tests__/modules/cabinet/CabinetTopbar.test.tsx __tests__/modules/cabinet/CabinetLayout.test.tsx __tests__/modules/cabinet/Sidebar.test.tsx` -> 0 errors, 2 existing test mock image warnings.
    - Passed: `npm run typecheck`.
  - Dependency: Task 18.

### Phase 5: Frontend Raid Experience

#### Raid UI Composition Guardrail

Frontend implementation MUST follow `docs/tasks/raids/raids-gameplay-guide.md` as the UX source of truth, especially sections `Базовая Экранная Структура` and `Экран 1-8`.

- Do not drift into a different screen composition.
- The raids page is a mobile-first fullscreen 9:16 game screen.
- The visual center of the screen is one large vertical raid map, not a dashboard, feed, landing page, or table-first layout.
- Header/HUD is compact and shows XDV, USDT, and game dollars only as balances.
- Do not show DCR anywhere in the raids UI for this iteration.
- Location cards live inside the central raid map: three collapsed biome cards by default; when one is selected, it expands into the main working area and the other locations collapse into compact strips.
- Pet selection uses a bottom drawer/carousel opened from empty slots; it is not a separate full page.
- Results, confirmation, trap, ransom, and rescue states are modal/drawer overlays over the same raid map composition.
- Visual style must stay dark futuristic cyber/game UI with biome-specific accents: Wastelands orange/amber, Oasis turquoise/emerald, Cave toxic green/violet.

- [x] Task 20: Build `RaidShell` mobile layout and HUD.
  - Files:
    - `diaweb/frontend/modules/raids/components/RaidShell.tsx`
    - `diaweb/frontend/modules/raids/components/RaidHud.tsx`
    - `diaweb/frontend/modules/raids/components/RaidUnavailableState.tsx`
    - `diaweb/frontend/modules/raids/components/raidShell.module.css`
    - `diaweb/frontend/__tests__/modules/raids/RaidShell.test.tsx`
  - Deliverable:
    - 9:16 mobile-first raid screen.
    - Header shows XDV, USDT, game dollars as general balance only; no DCR text.
    - Central area is the large raid map from `raids-gameplay-guide.md`; do not replace it with a dashboard/table/card-feed composition.
    - Bottom nav remains usable with safe-area padding.
    - Loading, empty, error, disabled states.
  - Logging requirements:
    - `DEBUG [raids.ui] render state status=<status>` in development only.
    - `WARN [raids.ui] missing critical state`.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids/RaidShell.test.tsx __tests__/app/cabinet-raids-page.test.tsx` -> 2 files, 8 tests.
    - Passed: `npm test -- --run __tests__/modules/raids` -> 3 files, 16 tests.
    - Passed: `npm run lint -- "app/[lang]/(cabinet)/raids" modules/raids/components modules/raids/index.ts modules/i18n/types.ts __tests__/modules/raids/RaidShell.test.tsx __tests__/app/cabinet-raids-page.test.tsx`.
    - Passed: `npm run typecheck`.
  - Dependency: Task 19.

- [x] Task 21: Build collapsed and expanded location cards.
  - Files:
    - `diaweb/frontend/modules/raids/components/RaidLocationStack.tsx`
    - `diaweb/frontend/modules/raids/components/RaidLocationCard.tsx`
    - `diaweb/frontend/modules/raids/components/RaidLocationDetail.tsx`
    - `diaweb/frontend/modules/raids/components/RaidModeTabs.tsx`
    - `diaweb/frontend/__tests__/modules/raids/RaidLocationStack.test.tsx`
  - Deliverable:
    - Three collapsed location cards sit inside the central raid map.
    - Expanded location takes the main map area and collapses the other locations into compact strips.
    - Show streak, rarity marker, special loot availability, chest chances with capped/effective chances, trap/crit stats, Oasis discount timer.
    - Mode tabs: Basic XDV, Subscription XDV, USDT.
  - Logging requirements:
    - `DEBUG [raids.ui] location selected location=<key> mode=<mode>`.
    - No repeated logging on every timer tick.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx __tests__/app/cabinet-raids-page.test.tsx` -> 3 files, 12 tests.
    - Passed: `npm run lint -- modules/raids/components modules/raids/index.ts modules/i18n/types.ts __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx __tests__/app/cabinet-raids-page.test.tsx`.
    - Passed: `npm test -- --run __tests__/modules/raids` -> 4 files, 20 tests.
    - Passed: `npm run typecheck`.
  - Dependency: Task 20.

- [x] Task 22: Build slots grid and pet picker drawer.
  - Files:
    - `diaweb/frontend/modules/raids/components/RaidSlotGrid.tsx`
    - `diaweb/frontend/modules/raids/components/RaidSlotCard.tsx`
    - `diaweb/frontend/modules/raids/components/RaidPetDrawer.tsx`
    - `diaweb/frontend/modules/raids/components/RaidPetCard.tsx`
    - `diaweb/frontend/__tests__/modules/raids/RaidPetDrawer.test.tsx`
  - Deliverable:
    - XDV modes show slot count from state; USDT shows batch list and `Add pet`.
    - Empty slots open drawer.
    - Pet drawer filters rare/epic/legendary.
    - Pet cards show computed entry cost, availability status, pack/rent/raid/trap states, and correct red/green affordability.
    - Token slot unlock action visible when applicable.
  - Logging requirements:
    - `DEBUG [raids.ui] pet drawer opened/filter changed`.
    - `WARN [raids.ui] pet selection blocked reason=<code>`.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids/RaidPetDrawer.test.tsx __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx` -> 3 files, 12 tests.
    - Passed: `npm run lint -- modules/raids/components modules/raids/index.ts modules/i18n/types.ts __tests__/modules/raids/RaidPetDrawer.test.tsx __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx __tests__/app/cabinet-raids-page.test.tsx`.
    - Passed: `npm test -- --run __tests__/modules/raids` -> 5 files, 23 tests.
    - Passed: `npm run typecheck`.
  - Dependency: Task 21.

- [x] Task 23: Build confirmation, active timer, result, trap, ransom, and rescue flows.
  - Files:
    - `diaweb/frontend/modules/raids/components/RaidConfirmDialog.tsx`
    - `diaweb/frontend/modules/raids/components/RaidActiveRunCard.tsx`
    - `diaweb/frontend/modules/raids/components/RaidResultModal.tsx`
    - `diaweb/frontend/modules/raids/components/RaidTrapCard.tsx`
    - `diaweb/frontend/modules/raids/components/RaidRescueDrawer.tsx`
    - `diaweb/frontend/__tests__/modules/raids/RaidFlows.test.tsx`
  - Deliverable:
    - Confirmation shows price, duration 24/12h, trap chance, crit chance, streak reset warning.
    - Active slot shows timer/progress and `ускорение x2` indicator for subscription, not a button.
    - Result modal shows XP, resources, chest rolls, crit x2, special loot zero/nonzero states.
    - Trap card shows death timer, ransom amount, rescue warning, rescue picker.
    - Mutations call backend and update query cache.
    - Dialogs and drawers must not reset scroll position or focus when local timer ticks rerender countdown text.
  - Logging requirements:
    - `DEBUG [raids.ui] confirm opened/command submitted`.
    - `INFO [raids.ui] command result status=<status>` in development.
    - `WARN [raids.ui] command failed code=<code>`.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids/RaidFlows.test.tsx __tests__/modules/raids/RaidPetDrawer.test.tsx __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx` -> 4 files, 15 tests.
    - Passed: `npm run lint -- modules/raids/components modules/raids/index.ts modules/i18n/types.ts __tests__/modules/raids/RaidFlows.test.tsx __tests__/modules/raids/RaidPetDrawer.test.tsx __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx __tests__/app/cabinet-raids-page.test.tsx`.
    - Passed: `npm test -- --run __tests__/modules/raids` -> 6 files, 26 tests.
    - Passed: `npm run typecheck`.
  - Dependency: Tasks 18, 22.

- [x] Task 24: Add raid visual assets and responsive polish.
  - Files:
    - `diaweb/frontend/modules/raids/assets.ts`
    - `diaweb/frontend/public/raids/*`
    - `diaweb/frontend/modules/raids/components/raidShell.module.css`
  - Deliverable:
    - Biome-specific visual language: Wastelands orange/amber, Oasis turquoise/emerald, Cave toxic green/violet.
    - Use existing resource icons for bullet/galaglue/nuclear_acorn/synthesis_core/slot_token when possible.
    - Ensure no text overflow at mobile widths.
    - Avoid DCR labels and avoid cards-inside-cards.
  - Logging requirements:
    - No runtime logging for static asset resolution unless missing asset fallback occurs.
    - `WARN [raids.assets] missing visual key` in development.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids/raid-assets.test.ts __tests__/modules/raids/RaidFlows.test.tsx __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx` -> 4 files, 15 tests.
    - Passed: `npm run lint -- modules/raids __tests__/modules/raids/raid-assets.test.ts __tests__/modules/raids/RaidFlows.test.tsx __tests__/modules/raids/RaidLocationStack.test.tsx __tests__/modules/raids/RaidShell.test.tsx`.
    - Passed: `npm test -- --run __tests__/modules/raids` -> 7 files, 28 tests.
    - Passed: `npm run typecheck`.
  - Dependency: Tasks 20-23.

- [x] Task 25: Frontend test and browser verification.
  - Files:
    - `diaweb/frontend/__tests__/modules/raids/*.test.tsx`
    - `diaweb/frontend/__tests__/app/api/cabinet/raids/*.test.ts`
  - Deliverable:
    - Unit tests for cost display, slot limits, DCR absence, game-dollar HUD label semantics, subscription 12h duration, trap/rescue buttons, result modal, and BFF proxy failures.
    - Composition tests or snapshots should assert the core layout contract: compact HUD, central raid map, location stack/detail inside the map, bottom drawer for pet selection, and no DCR text.
    - Route-handler import tests must fail if any raids BFF route file is missing or no longer exports the expected HTTP method.
    - Clock tests must prove local countdown/progress ticks do not trigger per-second refetches.
    - Manual browser verification for `/ru/raids` at mobile and desktop widths after implementation.
  - Commands:
    - `npm test -- --run __tests__/modules/raids __tests__/app/api/cabinet/raids`
    - `npm run lint -- modules/raids app/api/cabinet/raids app/[lang]/(cabinet)/raids modules/cabinet modules/shop/hooks/useShopPromoOffer.ts`
    - `npm run typecheck`
  - Logging requirements:
    - Tests should assert warning logs for failed mutations and BFF upstream failures where practical.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids __tests__/app/api/cabinet/raids` -> 9 files, 40 tests.
    - Passed: `npm run lint -- modules/raids app/api/cabinet/raids "app/[lang]/(cabinet)/raids" modules/cabinet modules/shop/hooks/useShopPromoOffer.ts __tests__/modules/raids __tests__/app/api/cabinet/raids`.
    - Passed: `npm run typecheck`.
    - Browser: checked `http://localhost:3000/ru/raids` at 390x844 and 1280x900. Unauthenticated route redirects through the cabinet auth guard; with Playwright-mocked auth/session/user and mocked raids state, the current already-running dev server renders the fullscreen rollout-disabled state because it was started without `NEXT_PUBLIC_RAIDS_WEB_ENABLED=true`. Full raid-map composition is covered by component tests in this task.
  - Dependency: Tasks 17-24.

### Phase 6: Cross-Repo Docs, Operations, And Release Safety

- [x] Task 26: Documentation checkpoint.
  - Files:
    - `docs/tasks/raids/raids-mechanics.md`
    - `docs/tasks/raids/raids-gameplay-guide.md`
    - Optional implementation notes under `docs/tasks/raids/`
  - Deliverable:
    - Update docs if implementation changes any rule or scope.
    - Add API contract notes if final endpoint names differ.
    - Preserve the product decisions: no DCR, game dollars HUD-only, XDV/USDT economics.
  - Logging requirements:
    - No code logging; record verification commands in daily/internal log.
  - Verification:
    - Updated `raids-mechanics.md` with the v1 implementation contract: backend endpoints, frontend BFF routes, rollout flags, and UI guardrails.
    - Updated `raids-gameplay-guide.md` to replace stale "backend does not implement" wording with current `feature/raids-mechanics` implementation status.
    - GBrain search attempted first for docs lookup, but local native search timed out; exact source files were verified directly.
  - Dependency: Tasks 16 and 25.

- [x] Task 27: End-to-end verification and GBrain sync.
  - Files:
    - No code files unless fixes are found.
  - Deliverable:
    - Backend tests, frontend tests, lint, typecheck, docs health.
    - Targeted GBrain sync for changed code/docs sources.
    - Confirm branch status in `diaweb`, `diaverseapi`, and root docs repo.
  - Commands:
    - `powershell -ExecutionPolicy Bypass -File scripts\docs-health.ps1`
    - `powershell -ExecutionPolicy Bypass -File scripts\gbrain-sync.ps1 -SourceId diaverse-docs`
    - `powershell -ExecutionPolicy Bypass -File scripts\gbrain-sync.ps1 -SourceId diaverseapi-code`
    - `powershell -ExecutionPolicy Bypass -File scripts\gbrain-sync.ps1 -SourceId diaweb-code`
  - Logging requirements:
    - No code logging; capture command outputs in final implementation notes.
  - Verification:
    - Passed: `npm test -- --run __tests__/modules/raids __tests__/app/api/cabinet/raids` -> 9 files, 40 tests.
    - Passed: `npm run lint -- modules/raids app/api/cabinet/raids "app/[lang]/(cabinet)/raids" modules/cabinet modules/shop/hooks/useShopPromoOffer.ts __tests__/modules/raids __tests__/app/api/cabinet/raids`.
    - Passed: `npm run typecheck`.
    - Passed: `.\.venv\Scripts\python.exe -m ruff check app\raids app\routers\v1\endpoints.py app\core\settings.py app\core\features.py`.
    - Passed: `.\.venv\Scripts\python.exe -m alembic heads` -> `raid_mechanics_v1_20260528 (head)`.
    - Partial/backend infra blocker: `.\.venv\Scripts\python.exe -m pytest app\raids\tests -q` -> 64 passed, 3 failed in `app/raids/tests/test_account_lifecycle.py` because local PostgreSQL refused connection (`ConnectionRefusedError [WinError 1225]`). The failures occur while opening DB sessions, before raid assertions.
    - Passed with warning: `powershell -ExecutionPolicy Bypass -File scripts\docs-health.ps1` -> 76 markdown files, 124 links, 0 errors, 1 existing warning for `docs\tasks\fabric\lvl1\lvl1.md` missing H1.
    - Passed: targeted GBrain sync for `diaverse-docs`, `diaverseapi-code`, and `diaweb-code`; docs sync imported changed raid docs and warned that large raid/fabric docs may need splitting later.
    - Status confirmed: `diaweb` and `diaverseapi` clean on `feature/raids-mechanics`; root repo has only root-owned docs/plan/daily changes plus pre-existing unrelated untracked patch files and a modified `docs/daily/2026-05-28-safiu.md`.
  - Dependency: Tasks 1-26.

## Commit Plan
- **diaverseapi Commit 1** after Tasks 1-4: `feat(raids): add raid catalog and persistence foundation`
- **diaverseapi Commit 2** after Tasks 5-7 and 6A: `feat(raids): implement raid rules state and pet guards`
- **diaverseapi Commit 3** after Tasks 8-14 and 12A: `feat(raids): add raid commands payments traps and lifecycle safety`
- **diaverseapi Commit 4** after Tasks 15-16: `test(raids): cover raid mechanics backend flows`
- **diaweb Commit 1** after Tasks 17-19: `feat(raids): add cabinet raid routes and client`
- **diaweb Commit 2** after Tasks 20-24: `feat(raids): build mobile raid interface`
- **diaweb Commit 3** after Task 25: `test(raids): cover raid frontend flows`
- **root Commit** after Tasks 26-27 if docs/daily/plan files are committed: `docs(raids): plan raid mechanics implementation`

## Verification Plan
- `diaverseapi`
  - `.\.venv\Scripts\python.exe -m pytest app\raids\tests -q`
  - `.\.venv\Scripts\python.exe -m pytest tests\test_merge_account_coverage.py tests\test_user_deletion.py tests\test_alembic_graph.py -q`
  - `.\.venv\Scripts\python.exe -m ruff check app\raids app\routers\v1\endpoints.py app\core\settings.py app\core\features.py`
  - `.\.venv\Scripts\python.exe -m alembic heads`
  - `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
- `diaweb`
  - `npm test -- --run __tests__/modules/raids __tests__/app/api/cabinet/raids`
  - `npm run lint -- modules/raids app/api/cabinet/raids app/[lang]/(cabinet)/raids modules/cabinet modules/i18n modules/shop/hooks/useShopPromoOffer.ts`
  - `npm run typecheck`
  - Browser check `/ru/raids`: mobile 390x844 and desktop, verify nonblank screen, no overlap, no DCR text, timers render.
- Root docs
  - `powershell -ExecutionPolicy Bypass -File scripts\docs-health.ps1`
  - Targeted GBrain sync for `diaverse-docs`, `diaverseapi-code`, `diaweb-code`.

## Risks And Explicit Follow-Ups
- USDT payment finalization depends on current cabinet payment abstractions; implementation should reuse existing payment finalizer patterns rather than inventing a separate callback surface.
- Irreversible pet deletion on trap expiry is high-risk; v1 should mark raid state lost and defer hard-delete unless product explicitly confirms.
- Navigation may become crowded with shop/factory/raids/offers/profile/staff; implement with a feature gate and verify mobile widths before shipping.
- Reward/chest economy may need balancing after telemetry; v1 implements the documented roll model and leaves global daily caps out unless tests show runaway output.
- Existing legacy voucher tables remain in place; do not remove or repurpose them in this feature.
