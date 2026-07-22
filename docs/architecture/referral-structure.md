---
owner: workspace
status: canonical
domain: referrals
source_of_truth: diaverseapi + diaweb
last_reviewed: 2026-07-22
review_after: 2026-10-21
---

# Referral Structure Architecture

## Decision

Referral Structure is an additive bounded context inside `diaverseapi`, with browser surfaces in `diaweb`. It reuses `team_referral_chains` as the only adjacency graph and adds referral-owned lifecycle/economic records around it. Existing Teams/Fives modules remain compatibility consumers and are not rewritten.

```text
browser
  -> diaweb public landing / cabinet / staff UI
  -> diaweb same-origin BFF
  -> diaverseapi /v1/referrals and /v1/staff/referrals
       -> referral application services and outbox
       -> team_referral_chains (single graph)
       -> referral_* evidence, rules, claims, projections, rewards, risk, audit
       -> existing XDV/resource/DCR ledger boundaries
       -> payment projections from canonical provider facts
```

`diaweb` never computes eligibility, risk, Mentor level or rewards. It renders typed backend decisions and stable reason codes.

## Bounded Contexts And Dependency Direction

| Context | Owns | May depend on |
| --- | --- | --- |
| Referral capture | opaque links, reservations, consent claims | authenticated user identity |
| Referral graph | current/historical edge lifecycle and cycle checks | `team_referral_chains` only |
| Qualification | normalized activity candidates, UTC qualified days | canonical league and accepted-step facts |
| Rewards | entitlements, holds, claims, recoveries | existing currency/resource ledger gateways |
| Payments | normalized purchase/refund projections and FX snapshots | canonical provider/payment facts |
| Risk/review | signals, cases, decisions, economic holds | graph/economic IDs, staff RBAC |
| Read model | privacy-safe structure, metrics and Mentor projection | graph and referral-owned facts |

Dependencies point toward stable domain gateways. Referral code must not import web concerns or mutate balances directly. Provider callbacks remain owned by their current payment modules; referrals consume idempotent normalized facts through adapters/outbox handlers.

## Single-Graph Compatibility

`team_referral_chains` already enforces one current edge per referred user and stores historical statuses. V1 extends its supported relationship vocabulary and lifecycle additively where required, but does not fork the graph.

Rules:

1. New referral writes go through a referral-owned graph service that locks the invitee/current edge and performs self/cycle/current-edge checks.
2. Existing Teams reads continue to use their current service and schemas during rollout.
3. A compatibility adapter maps new states/kinds to the subset understood by Teams. Unknown or economically frozen edges cannot grant Teams or referral rewards accidentally.
4. Shadow comparison proves old and new reads agree for protected fields before any consumer cutover.
5. `legacy_import` and `team_compat` identify provenance; neither implies reward eligibility.
6. No existing Teams command, Fives workflow, team reward formula or team ruleset is rewritten as part of this feature.

This avoids dual-parent drift while allowing referral-specific UTC and economic rules to remain independent of the existing `Europe/Moscow` Teams ruleset.

## Persistence Model

Additive PostgreSQL tables use explicit constraint/index names shorter than 63 bytes. The exact migration set is staged, but the ownership model is fixed:

| Record | Purpose | Mutability |
| --- | --- | --- |
| `referral_rulesets` | immutable UTC product/economic/risk configuration | insert only |
| referral links | hashed token identity, inviter, limits, revoke/expiry | state transitions |
| referral claims | reservation, consent and terminal decision | append/guarded transition |
| `team_referral_chains` | single current/historical graph edge | guarded transition |
| edge events | append-only transition/audit evidence | insert only |
| activity candidates/days | normalized idempotent qualification evidence | append/upsert by business key |
| Mentor projection/history | current and highest-ever derived state | rebuildable projection |
| reward entitlements/recoveries | claimable promises and compensation | append/guarded transition |
| purchase/refund projection | provider-independent economic facts | append/upsert by source key |
| risk signals/cases/decisions | reproducible review evidence | append/guarded transition |
| outbox | durable side effects and retries | leased transition |

Every externally replayable fact has a unique source/business key. Monetary/resource mutations occur only after locking the entitlement and through an existing domain gateway. Outbox handlers are at-least-once; consumers are idempotent.

## Concurrency And Transaction Boundaries

- Link redemption locks or advisory-locks the invitee identity, then validates the reservation and current edge in one transaction.
- First authenticated acceptance wins; concurrent later accept attempts receive the existing terminal decision.
- Reparent/reactivation locks the referred user and affected current edge, validates cycles, creates the new historical edge/event and supersedes the old edge atomically.
- Claim locks the entitlement, rechecks expiry/freeze, invokes an idempotent ledger gateway, then records the terminal result/outbox state.
- Review decisions require an idempotency key and optimistic version/current-state predicate.
- Projection rebuild reads the graph/event history and compares checksums before replacement.

Network calls are not held inside database row-lock transactions. Prepare durable intent/outbox state first, execute the dependency call idempotently, then finalize.

## Time Semantics

All referral timestamps are timezone-aware and normalized to UTC. Calendar days and ISO weeks for attribution, activity and weekly review use UTC. Exact inequalities are canonical:

| Rule | Predicate |
| --- | --- |
| Seven-day attribution | `accepted_at < reserved_at + 7 days` |
| Reactivation inactivity | `last_activity_at < first_link_opened_at - 90 days` |
| Reactivation cooldown | `accepted_at >= previous_accepted_at + 365 days` |
| First DCR rate | `purchase_at < edge_accepted_at + 30 days` |
| Reward claim | `claim_at < claimable_at + configured_window` |
| Hold release | `now >= hold_until` |

Database and application tests must cover one microsecond/second before, exact equality and one unit after each boundary.

## Versioned Rules

The referral catalog is typed and deny-by-default. Publishing computes a canonical JSON checksum and freezes version/schema/effective timestamp. Durable records pin `ruleset_id`; decisions never silently read “latest” during replay.

The V1 catalog includes claim states, edge kinds/statuses, reason codes, activity thresholds, UTC windows, weekly limits, Mentor thresholds, start resource ranges, milestone amounts, DCR rate/FX/rounding/hold/expiry policy, risk bands and campaign flags. Unknown values survive transport as unsupported values but cannot authorize a mutation.

## API Boundaries

Implemented public/authenticated families:

```text
POST /v1/referrals/links
POST /v1/referrals/intents/resolve
POST /v1/referrals/claims/{id}/accept
POST /v1/referrals/claims/{id}/decline
GET  /v1/referrals/claims/{id}/reactivation-preview
POST /v1/referrals/claims/{id}/reactivation-confirm
GET  /v1/referrals/me
GET  /v1/referrals/me/mentor
GET  /v1/referrals/me/structure
GET  /v1/referrals/me/rewards
POST /v1/referrals/rewards/{id}/claim
GET  /v1/admin/referrals/cases
GET  /v1/admin/referrals/cases/{id}
GET  /v1/admin/referrals/moves/{claim_id}/preview
POST /v1/admin/referrals/moves/{claim_id}/approve|reject
POST /v1/admin/referrals/cases/{id}/economics
POST /v1/admin/referrals/rewards/{id}
GET|POST /v1/admin/referrals/rulesets
GET  /v1/admin/referrals/invariants
```

Responses use an envelope with `allowed`, stable `reason_code`, localized `message_key`, `next_action`, typed `data` and request ID. Public endpoints are rate-limited and disclose no inviter private data beyond the explicit allowlist.

The browser never sends raw referral tokens to client analytics or normal logs. `diaweb` captures the query once, exchanges it through a same-origin route, sets a bounded `HttpOnly; Secure; SameSite=Lax` cookie when needed, and removes the token from the URL with `replace` navigation.

## Read Model And Privacy

The “Моя структура” response is a bounded projection, not an unbounded ORM tree. It supports cursor pagination and explicit depth expansion. User-visible node fields are limited to a stable public label/avatar when allowed, relationship status/kind, qualified-day progress and coarse dates. Email, phone, Telegram identifiers, devices, IPs, risk evidence, balances and payment facts are excluded.

Shortest-path social/Fives proximity may be reported up to depth five as a derived view; it does not redefine graph depth or introduce five-level storage columns.

## Feature Flags And Rollout

The 12 backend runtime flags are independent and default off: `read_enabled`, `links_enabled`, `attribution_write_enabled`, `qualification_enabled`, `reward_materialization_enabled`, `claim_enabled`, `reactivation_enabled`, `dcr_projection_enabled`, `staff_write_enabled`, `teams_compat_enabled`, `legacy_shadow_enabled`, and `legacy_economic_cutover_enabled`, all under the `referrals.` namespace. The active-user campaign remains off.

Web routes may be deployed while backend flags are off; backend dependencies return stable disabled decisions. There is no client-side flag that can authorize a server mutation.

Rollout order is additive migration, backfill audit, shadow reads, capture without economics, qualification/read UI, staff review, non-money rewards, payment projection, held DCR, then DCR claims. Rollback disables the affected writer/economic flag and workers; it does not drop tables or delete history.

## Observability And Security

Structured logs contain operation, safe record IDs, request ID, ruleset version/checksum, reason code, transition, counts and duration. Metrics count outcomes by bounded enums. Audit logs record staff decisions without copying evidence payloads.

Forbidden everywhere: raw/hashed referral tokens, auth cookies/JWTs, PII, device/IP identifiers, full provider payloads, credentials, raw evidence, seed material, payment metadata and balance/resource snapshots. Error responses expose stable reason codes, not internal exception or database text.

## Non-Goals

- Mobile implementation, deep links, native storage, analytics or purchase integration.
- Teams/Fives command, admin, reward or ruleset refactor.
- Retroactive economic activation of imported/compatibility edges.
- A new graph store, `ltree` migration or referral microservice.

## See Also

- [Referral Structure V1](../features/referral-structure.md)
- [Referral Structure Rollout And Rollback](../runbooks/referral-structure-rollout.md)
- [Product Master Plan](../product/master-plan.md)
- [Workspace Architecture](../../.ai-factory/ARCHITECTURE.md)
