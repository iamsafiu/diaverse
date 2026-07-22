---
owner: workspace
status: canonical
domain: referrals
source_of_truth: diaverseapi + diaweb
last_reviewed: 2026-07-22
review_after: 2026-10-21
---

# Referral Structure V1

## Implementation Status

Backend and web implementation was completed and verified on 2026-07-22. Production activation remains deny-by-default: all 12 backend runtime flags default off and must follow the independent stages in the [rollout runbook](../runbooks/referral-structure-rollout.md). No mobile implementation or production flag change is part of this checkpoint.

Implemented browser surfaces are public `/[lang]/referral`, authenticated `/[lang]/partners`, granular `/[lang]/staff/referrals`, and same-origin `/api/referrals/pending*`. Implemented backend families are `/v1/referrals/*` and `/v1/admin/referrals/*`. Backend decisions remain authoritative; the web does not calculate eligibility, risk, Mentor level or economics.

## Scope And Ownership

Referral Structure V1 is the authenticated web experience for inviting users, tracking one permanent referral graph, qualifying direct referrals, claiming XDV/DCR rewards, and performing audited staff review.

| Surface | Owner | Contract |
| --- | --- | --- |
| Referral graph, attribution, qualification, rewards, risk, staff API | `diaverseapi` | Canonical business truth |
| Public referral landing, cabinet “Моя структура”, staff console and same-origin BFF | `diaweb` | Browser UI only; no economic decisions |
| Existing Fives/Teams behavior | `diaverseapi/app/teams` and existing web Teams modules | Protected compatibility boundary; no rewrite |
| Mobile experience | `diaverse-mobile` | Not part of V1 implementation |

The one graph is `team_referral_chains`. Referral-owned tables add evidence, claims, rulesets, projections, entitlements, risk cases and audit history around this graph; they do not create a second parent/child graph.

## Fixed V1 Product Rules

### Attribution And Consent

- A link contains an opaque, single-purpose token. Raw token values are never persisted or logged; backend lookup uses a keyed hash.
- Opening the first valid link creates a seven-day reservation. A later inviter cannot replace an unexpired reservation.
- Attribution requires an explicit **Accept** action. Page view, login or registration alone never attributes a user.
- **Decline** immediately releases the reservation. A later valid link may then reserve.
- Before authentication, first-link ownership is limited to the current browser session. V1 cannot reliably preserve anonymous first-link priority across devices or cleared cookies.
- After authentication, the server serializes claims per invitee. The first accepted eligible claim wins across devices.
- A user cannot invite themself, create a cycle, or replace a current edge except through the reactivation flow.

### Link And Claim State Machines

```text
link: active -> exhausted | revoked | expired

claim: reserved -> consent_required -> accepted
                | declined
                | expired
                | revoked
                | rejected
                | pending_review -> accepted | rejected
```

Terminal claim states are immutable. Repeated accept/decline requests with the same idempotency key return the original outcome. `reserved` and `consent_required` expire at `reserved_at + 7 days`; acceptance is allowed while `accepted_at < expires_at`, not when equal.

### Relationship Lifecycle

```text
new_user/team_compat/legacy_import:
  pending_activity -> active
                   -> pending_review -> active | rejected
                   -> blocked

reactivation:
  eligible -> pending_review? -> accepted
           -> rejected
  accepted edge: pending_activity -> active | blocked
  previous current edge: active/pending_activity -> superseded
```

Relationship kinds are `new_user`, `reactivation`, `legacy_import`, and `team_compat`. Imported/compatibility edges are readable but receive no retroactive V1/V2 rewards until an explicit, audited economic activation exists.

### Activity And Qualification

A referred user becomes **active** after three distinct qualified UTC calendar days. Each day requires both:

- league/grade at least **Bronze I** at the accepted activity fact; V1 never grants Bronze I automatically;
- at least **2,500 server-accepted steps** for that UTC day.

Only backend-accepted game/activity facts count. Login, app open, site view and profile update do not count. One qualified day can qualify each separately eligible current relationship for that user; it is not consumed globally.

### Reactivation

Reactivation is allowed only when all are true:

- baseline last qualifying activity is strictly more than 90 days before the first-link timestamp: `last_activity_at < first_link_opened_at - 90 days`;
- the previous accepted reactivation occurred at least 365 days before the new acceptance: `accepted_at >= previous_accepted_at + 365 days`;
- there is no active ban, fraud freeze or unresolved blocking dispute;
- cycle checks pass.

At exactly 90 days the user is not eligible. At exactly the 365-day cooldown boundary the user is eligible. A successful reactivation changes only that user’s parent edge; the user’s descendant subtree stays attached and its inner edges remain unchanged.

### Weekly Review Boundary

For one inviter, the first five accepted new/reactivated relationships in a UTC ISO week may proceed automatically. The sixth and later relationship enters `pending_review`. It still exists in the graph projection but produces no economic entitlement until approved. Review thresholds also include a subtree with at least five active or twenty total descendants.

### Mentor Level

Current Mentor level is derived from direct active referrals:

| Level | Minimum direct active referrals |
| --- | ---: |
| 1 | 1 |
| 2 | 3 |
| 3 | 5 |
| 4 | 10 |
| 5 | 25 |
| 6 | 50 |
| 7 | 100 |

Current level may decrease when qualifying edges are invalidated, blocked or superseded. `highest_ever_level` is monotonic and retained for history; it does not restore current benefits.

## Rewards And Economics

### Invitee Start Reward

An eligible `new_user` relationship creates one deterministic entitlement when attribution is accepted:

- `100 XDV`;
- bullets: deterministic integer in `[5, 15]`;
- galaglue: deterministic integer in `[3, 10]`.

The pseudo-random values are derived from a versioned server seed plus the entitlement business key. Retries and replays produce identical values. The seed and raw derivation material are never returned to clients or logged.

### Inviter XDV Milestones

An inviter earns claimable XDV for the referred user’s qualified active days:

| Qualified day | XDV |
| ---: | ---: |
| 3 | 1,000 |
| 7 | 2,000 |
| 14 | 4,000 |
| 30 | 8,000 |
| every additional 30 days | 8,000 |

Each entitlement has a manual claim window of seven exact 24-hour periods: `claim_at < claimable_at + 7 days`. At equality it is expired. Entitlements are idempotent by relationship, reward type, milestone and ruleset.

### DCR Purchase Reward

Only reconciled, actually paid money qualifies. Coupons, list price and virtual-currency spending are excluded.

```text
normalized_usd_cents = provider paid amount converted by the pinned FX snapshot
rate = 20% when purchase_at < relationship.accepted_at + 30 days, otherwise 10%
raw_dcr = normalized_usd_cents / 100 * rate * 25
entitled_dcr = floor(raw_dcr)
```

The first 30-day rate ends at the exact boundary; a purchase at equality uses 10%. DCR is held for 14 exact days after the reconciled purchase fact and becomes claimable when `now >= hold_until`. It expires unclaimed after 30 exact days: claim requires `claim_at < claimable_at + 30 days`.

Example: a reconciled USD 19.99 purchase in the first period yields `floor(19.99 × 0.20 × 25) = 99 DCR`. The same purchase at the 30-day boundary yields `floor(19.99 × 0.10 × 25) = 49 DCR`.

Refund handling is append-only:

- before claim, reduce or cancel the held/claimable entitlement proportionally using the same pinned FX/rate and floor rule;
- after claim, post a compensating DCR debit through the existing ledger boundary;
- if spendable balance cannot cover the debit, do not fabricate a negative mutation: freeze future referral rewards and open a staff review case for recovery.

### Economically Blocking Flags

The active-user campaign is **off** in V1. Any reward dimension without a published immutable ruleset, reconciliation mapping or supported FX snapshot remains disabled and returns a stable `feature_disabled`/`economic_rule_unavailable` reason. The service must never guess an amount.

## Risk And Staff Policy

| Risk score | Automatic policy |
| ---: | --- |
| 0–29 | Continue normal processing |
| 30–69 | Keep graph visibility; freeze economics and open/refresh review |
| 70–100 | Block move and payout; require staff decision |

Risk signals and decisions are versioned evidence, not destructive edits. The staff console uses granular permissions such as `referrals:read`, `referrals.review:decide`, `referrals.risk:manage`, `referrals.rewards:operate`, and `referrals.rules:read`. It is separate from the Fives admin UI. Every decision records actor, reason code, before/after status, ruleset and idempotency key.

## Ruleset Versioning

- Referral rules are separate from Teams rules because referral calendar boundaries are UTC and referral economics evolve independently.
- A published ruleset is immutable and identified by version, schema version, effective timestamp and canonical SHA-256 checksum.
- Every claim, edge decision, qualification fact, entitlement and risk decision pins its ruleset ID.
- New versions apply prospectively. Replays use the originally pinned version unless an explicit migration command creates audited compensating records.
- Unknown enum values returned to the web are displayed as unsupported state and do not enable actions.

## Deterministic Boundary Examples

| Input | Expected outcome |
| --- | --- |
| Link opened `2026-01-01T00:00:00Z`, accepted `2026-01-08T00:00:00Z` | Rejected as expired; equality is outside the window |
| Last activity `2026-01-01T00:00:00Z`, first link `2026-04-01T00:00:00Z` | Not reactivation-eligible; exactly 90 days |
| Previous reactivation `2025-01-01T00:00:00Z`, new acceptance `2026-01-01T00:00:00Z` | Eligible on cooldown boundary |
| Steps on three UTC dates: `2499`, `2500`, `3000`, all Bronze I | Only two qualified days; remains pending activity |
| Sixth accepted relationship in same UTC ISO week | `pending_review`, no rewards until approval |
| USD 10.00 at day 29 23:59:59 | `50 DCR`, held 14 days |
| USD 10.00 exactly at day 30 | `25 DCR`, held 14 days |

## Observability And Data Safety

Future runtime events may log operation name, request/correlation ID, hashed business key, claim/edge/entitlement/risk-case IDs, state transition, ruleset version, reason code, duration and aggregate count. INFO is for successful durable transitions, WARNING for denied/frozen/review outcomes, ERROR for sanitized dependency or invariant failures, and DEBUG for safe version/checksum diagnostics.

Never log raw referral tokens or token hashes, cookies, JWTs, names, usernames, email/phone, device identifiers, IP addresses, full evidence/provider payloads, payment credentials, provider metadata, seed material, balance snapshots or resource inventory.

## Non-Goals

- No mobile implementation or mobile release work.
- No rewrite/refactor of Teams, Fives, their commands, rewards or admin module.
- No second referral graph and no microservice extraction.
- No retroactive rewards for legacy/imported/team-compatible edges.
- No automatic Bronze I grant and no activity credit for passive product events.
- No active-user campaign in V1.

## See Also

- [Referral Structure Architecture](../architecture/referral-structure.md)
- [Referral Structure Rollout And Rollback](../runbooks/referral-structure-rollout.md)
- [DCR Web Commerce Rollout](../tasks/dcr/web-commerce-rollout.md)
- [Product Master Plan](../product/master-plan.md)
- [Workspace Architecture](../../.ai-factory/ARCHITECTURE.md)
