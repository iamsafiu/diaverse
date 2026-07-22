---
owner: workspace
status: canonical
domain: referrals
source_of_truth: diaverseapi + diaweb
last_reviewed: 2026-07-22
review_after: 2026-10-22
---

# Referral Structure Rollout And Rollback

## Purpose

This runbook controls the rollout of Referral Structure V1 in `diaverseapi` and `diaweb`. It is intentionally conservative: schema and code may be deployed while every referral runtime flag remains off. Production activation requires a separate approved change record with an owner, release SHA, cohort and rollback operator.

This rollout does not include `diaverse-mobile`, does not rewrite existing Teams/Fives commands, and never creates a second referral graph. `team_referral_chains` remains the only adjacency graph.

## Current Release State

As of 2026-07-22:

- backend and web implementation is complete on `feature/referral-structure`;
- backend migration, PostgreSQL concurrency, economics, load and Teams/Fives regression gates passed;
- focused web contract/security/accessibility tests, typecheck, scoped lint and production build passed;
- all 12 backend runtime flags default to `false`;
- a local in-memory drill proved default-off, a three-flag read-only canary state and return to all-off;
- no production flag was changed and no production cohort was enrolled.

## Hard Invariants

Stop rollout immediately if any invariant cannot be demonstrated:

1. One referred user has at most one current parent edge.
2. No self-edge or graph cycle exists.
3. Existing Teams/Fives behavior and protected commands remain unchanged.
4. Page view, login and registration never attribute without explicit consent.
5. An entitlement, provider fact, refund and ledger mutation is idempotent by its durable business key.
6. Legacy and V2 economic owners cannot pay the same program/relationship twice.
7. DCR is derived only from reconciled paid amount, pinned FX/ruleset/edge snapshots and the canonical DCR ledger.
8. Rollback preserves graph history, audit, entitlements, ledger and outbox rows.

## Runtime Flags

All flags live in runtime settings and default off in `diaverseapi/app/referrals/feature_flags.py`.

| Flag | Enables | Initial rollout rule |
| --- | --- | --- |
| `referrals.read_enabled` | Authenticated referral read APIs | First user-facing flag; internal cohort only |
| `referrals.links_enabled` | Link creation and server-side intent resolution | Enable after clean-URL/cookie verification |
| `referrals.attribution_write_enabled` | Explicit-consent claim acceptance and graph writes | No economics at first |
| `referrals.qualification_enabled` | Activity candidate/day processing | Shadow before materialization |
| `referrals.reward_materialization_enabled` | XDV/resource/DCR entitlement creation | XDV/resources before DCR projection |
| `referrals.claim_enabled` | User reward claims | Only after ledger reconciliation passes |
| `referrals.reactivation_enabled` | Reactivation preview/confirm and move lifecycle | Manual-review canary first |
| `referrals.dcr_projection_enabled` | Paid/refund fact projection into referral DCR | Last economic adapter flag |
| `referrals.staff_write_enabled` | Staff decisions, holds, reward operations and ruleset publish | Read-only staff first |
| `referrals.teams_compat_enabled` | Referral-owned Teams compatibility adapter | Only after protected regression suite |
| `referrals.legacy_shadow_enabled` | Legacy/canonical shadow comparison | Read-only; required before cutover |
| `referrals.legacy_economic_cutover_enabled` | Approved imported cohort economic cutover | Last legacy flag; requires zero mismatch |

The web routes are deployable without a separate browser flag. Backend gates remain authoritative and return stable disabled reasons while the relevant backend flag is off.

## Roles And Approval

Every production transition needs:

- release owner;
- database/migration operator;
- referral domain operator;
- payment/DCR reviewer for economic stages;
- rollback operator who is not simultaneously executing the transition;
- approved release SHA and cohort definition;
- observation window and explicit go/no-go criteria.

An approval record contains only release SHA, flag name, old/new boolean, cohort label, aggregate counters, operator role and decision timestamp. Do not include tokens, identities, user lists, payment payloads, secrets or infrastructure commands.

## Preflight

### 1. Repository And Release Integrity

- Confirm the intended `diaverseapi` and `diaweb` release SHAs.
- Confirm `diaverse-mobile` is absent from the change set.
- Confirm `git diff <base> -- app/teams` is empty for protected backend commands/services.
- Confirm `git diff <base> -- frontend/modules/fives-admin frontend/app/[lang]/staff/fives` is empty.
- Confirm the focused backend and web verification gates correspond to the release SHAs.

### 2. Migration Safety

Run from `diaverseapi` with the environment's normal secret injection. Do not paste environment values into logs.

```powershell
.\.venv\Scripts\python.exe -m alembic heads
.\.venv\Scripts\python.exe -m alembic current
.\.venv\Scripts\python.exe -m alembic upgrade <referral-down-revision>:<referral-head> --sql
```

Expected:

- one repository Alembic head: `merge_ref_pet_heads_20260722`; the referral branch terminates at `ref_legacy_import_20260722` before the no-op merge with the concurrent pet-fatigue branch;
- every new PostgreSQL identifier is shorter than 63 bytes;
- referral revision SQL compiles in both directions in the verified test environment;
- deployment applies additive DDL before referral workers or flags are enabled.

Known pre-existing baseline issue: a clean bootstrap through the repository's entire historical migration chain on a brand-new empty database currently fails before the referral range in `ff952927ffe2_added_achivements.py`. That historical revision imports the current Achievement ORM and can reference `icon_disabled` before the later migration adds it. The referral revision range itself was compiled and exercised. Until the historical bootstrap is repaired separately, verify upgrades from the real environment's current revision and keep a schema backup/restore point; do not claim empty-database full-history bootstrap support.

### 3. All-Off Baseline

Read all 12 runtime settings and record booleans only. The expected initial state is `false` for every flag. Do not infer state from web visibility.

Verify while all flags are off:

- existing Teams/Fives flows remain healthy;
- referral write endpoints return the stable disabled contract;
- referral workers do not lease/process new work;
- no referral entitlement or ledger row is created;
- deployed web routes do not expose an opaque link token in URL, JSON, error UI or logs.

## Staged Rollout

Advance one stage at a time. Reset the observation window whenever an alert fires or a flag changes.

### Stage 0 — Additive Schema, All Flags Off

1. Deploy backend schema/code.
2. Deploy web code.
3. Keep all 12 flags off.
4. Verify migrations, route health, worker idle behavior and Teams/Fives baselines.

Rollback: roll back application code if necessary, but retain additive tables and rows. Do not downgrade schema during an incident unless a reviewed migration-specific recovery plan requires it.

### Stage 1 — Inventory And Legacy/Fives Dry Run

The following commands are read-only by default:

```powershell
.\.venv\Scripts\python.exe -m app.commands.referral_legacy_audit
.\.venv\Scripts\python.exe -m app.commands.referral_legacy_backfill --batch-size 500 --max-rows 1000
```

Review only safe counts/checksums: candidates, imported, quarantined, conflicts and inventory hashes. Never publish raw function definitions or user rows.

Exit criteria:

- graph inventory is understood;
- quarantine/conflict policy is approved;
- no existing Fives invariant changed;
- dry-run is repeatable with the same inventory checksum.

### Stage 2 — Backfill And Shadow Comparison

1. Run bounded backfill with `--apply` only after dry-run approval.
2. Resume by recorded `run_id` if interrupted; do not restart an unknown inventory.
3. Enable only `referrals.legacy_shadow_enabled` for comparison.
4. Run:

```powershell
.\.venv\Scripts\python.exe -m app.commands.referral_legacy_shadow --cohort-size 1000 --cohort-name imported --require-zero
.\.venv\Scripts\python.exe -m app.commands.referral_legacy_reconcile
```

Exit criteria: zero unexplained read mismatch, duplicate payout and economic ownership conflict for the approved cohort.

### Stage 3 — Read-Only Internal Cohort

Enable `referrals.read_enabled` for a bounded internal cohort. If the compatibility projection is required for that cohort, enable `referrals.teams_compat_enabled` independently after its regression gate.

Validate `/partners`, bounded depth/cursor reads, Mentor projection, staff read-only cases/rulesets/invariants and privacy allowlists. Keep `referrals.staff_write_enabled` off.

### Stage 4 — Link Capture And Explicit Consent Without Economics

1. Enable `referrals.links_enabled` for the cohort.
2. Verify opaque token capture into the bounded secure cookie and immediate clean redirect.
3. Enable `referrals.attribution_write_enabled` only after preview/decline behavior is correct.
4. Keep qualification, reward materialization, claims, reactivation and DCR off.

Validate first-link ownership, cross-device authenticated first-wins, self/cycle rejection, expiry equality and explicit accept/decline.

### Stage 5 — Qualification And Staff Review Shadow

1. Enable `referrals.qualification_enabled` for accepted cohort edges.
2. Compare three distinct UTC days, Bronze I threshold and 2,500 accepted-step boundary.
3. Expose staff read-only queue and safe risk summaries.
4. Enable `referrals.staff_write_enabled` only for named roles after preview, reason, confirmation, idempotency and audit checks.

No reward claims are enabled in this stage.

### Stage 6 — Capped XDV And Resource Canary

1. Enable `referrals.reward_materialization_enabled` for a capped cohort/ruleset with DCR projection still off.
2. Reconcile deterministic entitlement business keys and existing XDV/resource gateway outcomes.
3. Enable `referrals.claim_enabled` only after duplicate/replay tests and aggregate ledger checks pass.

Stop on any duplicate credit, non-deterministic resource amount or ledger mismatch.

### Stage 7 — Reactivation Manual-Review Canary

Enable `referrals.reactivation_enabled` for manual-review cases only. Verify strict `>90` inactivity, inclusive 365-day cooldown, current-edge optimistic version and subtree preservation. Expand beyond manual review only after zero cycle/multi-parent events.

### Stage 8 — DCR Projection Last

Before enabling `referrals.dcr_projection_enabled`, every approved payment/refund adapter must demonstrate:

- trusted provider evidence and exact paid amount/currency;
- immutable source, FX, ruleset and edge snapshots;
- duplicate callback/replay idempotency;
- held entitlement timing;
- pre-claim refund reduction/cancellation;
- post-claim compensating DCR debit and insufficient-balance recovery case.

Enable DCR for the smallest approved cohort. Keep real-money facts separate from virtual DCR spending. Any failed refund recovery, amount/currency mismatch or ledger mismatch immediately disables DCR projection and claims.

### Stage 9 — Legacy Economic Cutover

This stage is independent and last for imported cohorts.

1. Keep `referrals.legacy_shadow_enabled` on.
2. Require a zero-mismatch shadow report and clean reconciliation.
3. Dry-run the cohort:

```powershell
.\.venv\Scripts\python.exe -m app.commands.referral_legacy_cutover --program-version <version> --cohort-size 100 --cohort-name economic-canary
```

4. Enable `referrals.legacy_economic_cutover_enabled` only for the approved apply window.
5. Re-run with `--apply`, reconcile immediately, then observe before cohort expansion.

Legacy fields/functions remain available through the full reconciliation window. Do not delete them as part of rollout.

## Observability And Alert Gates

Monitor bounded counters and age/latency gauges for:

- claim terminal states and attribution conflicts;
- self-edge, cycle, multi-parent and current-edge uniqueness failures;
- outbox ready/retry/dead-letter counts and oldest age;
- qualification lag and duplicate day candidates;
- entitlement held/claimable/claimed/expired/withheld states;
- payment/refund projection and recovery outcomes;
- legacy shadow mismatch and duplicate payout counters;
- oldest open review/SLA age;
- database deadlocks/retry exhaustion;
- depth-five and cursor read p95.

Immediate page and rollout stop:

- duplicate economic credit;
- graph cycle or multi-parent state;
- ledger mismatch;
- failed refund recovery;
- legacy/V2 double owner;
- migration divergence or unexplained Teams/Fives regression.

## Non-Destructive Rollback

Rollback is flag-first and narrow:

1. Disable the flag that introduced the failing behavior.
2. For economic uncertainty, also disable `referrals.claim_enabled`; disable `referrals.reward_materialization_enabled` or `referrals.dcr_projection_enabled` only as required by the incident.
3. Pause referral workers while retaining ready/retry/dead-letter outbox rows.
4. Preserve edges, edge events, claims, audit, risk cases, entitlements, purchase/refund facts and ledger rows.
5. Reconcile durable state and idempotency keys before resuming.
6. Rebuild only derived projections such as Mentor/read models.
7. Correct money/resources with approved compensating entries, never row deletion or in-place history edits.
8. Record the release SHA, flag transition, affected cohort label, safe aggregate counters and rollback result.

### Rollback Matrix

| Symptom | First flags off | Preserve/reconcile |
| --- | --- | --- |
| Link/cookie/privacy defect | `links_enabled`, then `attribution_write_enabled` | Existing reservations/claims; clear only via normal terminal/expiry rules |
| Graph invariant defect | `attribution_write_enabled`, `reactivation_enabled`, `staff_write_enabled` | Edges/events/audit; run invariant checks before repair |
| Qualification defect | `qualification_enabled`, `reward_materialization_enabled` | Activity evidence; rebuild derived qualification only |
| XDV/resource mismatch | `claim_enabled`, `reward_materialization_enabled` | Entitlements and gateway/ledger records; compensate |
| DCR/refund defect | `dcr_projection_enabled`, `claim_enabled` | Purchase/refund projections, DCR ledger and recovery cases |
| Staff mutation defect | `staff_write_enabled` | Cases/decisions/audit; staff reads may remain on |
| Legacy mismatch/double owner | `legacy_economic_cutover_enabled` | Shadow reports, ownership records and reconciliation evidence |
| Read latency/privacy defect | `read_enabled` | Graph remains; tune/rebuild projection offline |

## Rollback Drill

Before each production cohort:

1. Confirm 12/12 flags off in the target environment baseline.
2. Enable only the stage's approved flags for a synthetic/internal cohort.
3. Verify allowed APIs/workers and confirm every later economic flag remains off.
4. Disable the stage flags.
5. Verify workers stop leasing new work, disabled APIs return stable reasons, durable rows remain and Teams/Fives still pass.
6. Record aggregate before/after counts and the rollback outcome.

The 2026-07-22 local drill exercised the flag decision layer in memory: 12 default-off, three read-only canary flags on, then 12 off again. It did not access or mutate a production runtime-settings store.

## Post-Rollout Verification

- Run graph invariant and legacy reconciliation checks.
- Reconcile entitlement totals with XDV/resource/DCR ledgers.
- Verify payment and refund facts against canonical provider inbox/session state.
- Verify protected Teams/Fives regression tests and unchanged paths.
- Verify clean referral URLs and absence of opaque values in browser/server logs.
- Sync `diaverse-docs`, `diaverse-aif`, `diaverseapi-code` and `diaweb-code` in local GBrain.

## Related Documents

- [Referral Structure V1](../features/referral-structure.md)
- [Referral Structure Architecture](../architecture/referral-structure.md)
- [DCR Web Commerce Rollout](../tasks/dcr/web-commerce-rollout.md)
- [Tribute Shop API Runbook](../payments/tribute-runbook.md)
