[Back to Docs README](../README.md)

# Редлист

Product name: **Редлист**.

Technical/API name: `step_restrictions`.

This document defines the Diaverse Redlist restriction used when a user is caught inflating steps. It is separate from the legacy auth blacklist.

## Policy

| Area | Behavior |
| --- | --- |
| Legacy auth blacklist | Blocks authentication/access. Do not reuse it for step cheating. |
| Redlist restriction | User keeps login/access, but step-derived progress and rewards are neutralized. |
| First offense | Temporary restriction for 14 days from DB activation time. |
| Second and later offense | Permanent restriction. |
| Duplicate activation while active | Idempotent: no new offense and no extension. |
| Manual revoke | Ends the active restriction, but offense history remains. Future activation still escalates from history. |

Staff API lives in `diaverseapi` under `/v1/admin/step-restrictions` and requires RBAC permissions:

- `step-restrictions:read`
- `step-restrictions:manage`

## Step cap and durable eligibility

When restriction is active:

- incoming daily steps are capped at `10_000`;
- the current day is marked `step_eligible = false`;
- `step_restriction_id` records provenance where the model supports it;
- expiry/revoke does not retroactively make restricted days eligible.

This is intentionally durable. Historical rebuilds, deferred jobs, snapshots, SQL functions, and aggregate queries must filter by `step_eligible = true`.

## Blocked reward and progress surfaces

Restricted steps must not produce:

- XDV from step actions, Club missions, step passes, Advent/daily rewards, achievements, notifications, referrals, or aggregate income paths;
- loot boxes/chests from step thresholds or period rewards;
- factory impulses or other step-powered factory bonuses;
- pet, gladiator, skin, rental, referral, clan, or income modifier benefits derived from restricted steps.

Existing balances, already credited assets, and published historical artifacts are not clawed back by this restriction. Any clawback must be a separate reviewed operation.

## League, clan, and Club behavior

During an active restriction:

- personal league goal/rank is frozen; the user is not promoted or demoted by restricted days;
- personal ratings and league calculations use eligible activity only;
- clan ratings exclude restricted users instead of showing them as zero-ranked;
- Diaverse Club/Club10000 snapshots store restricted rows as ineligible and zero-step;
- Club autofill does not run for restricted members;
- Club live rankings, leaderboard snapshots, season results, and rating reward materialization exclude restricted users;
- a buddy pair is excluded from pair rankings and pair step rewards if either member is restricted;
- Club daily/pair mission XDV is unavailable while the actor or required pair member is restricted.

Manual `ClubMembership.leaderboard_enabled` remains independent and must not be toggled by temporary step restrictions.

## Audit, cache, and expiry

Every activation, revoke, and expiry writes a `step_restriction_events` row with actor, target, reason, offense number, permanence, and timestamp metadata. Reasons are bounded and normalized before persistence.

Restriction checks may be cached. Activation, revoke, account merge, and expiry invalidation must clear affected user cache keys.

Temporary expiry is handled by the step restriction expiry sweep. Exact `expires_at` boundary uses DB time semantics: a temporary restriction is active while `expires_at > now`.

## Rollback and release checks

Rollback should preserve user access. If a deployment must be reverted, ensure:

1. auth remains independent from `step_restrictions`;
2. migrations are not partially rolled back while code expects `step_eligible` columns;
3. SQL functions/triggers are compared with `pg_get_functiondef`/trigger definitions before and after deploy;
4. current-day restricted activity and Club snapshots remain ineligible unless a reviewed remediation script changes them.

Minimum staging smoke matrix:

- first offense creates a 14-day temporary restriction;
- expired/revoked first offense followed by activation creates a permanent restriction;
- duplicate active activation is idempotent;
- manual revoke ends the current restriction and preserves offense history;
- login still works;
- a step sync above `10_000` is capped and marked ineligible;
- direct/deferred XDV, boxes, impulses, passes, achievements, referrals, rentals, income, clan, and Club rewards are zero;
- personal league progression is frozen;
- personal, clan, Club individual, and Club pair rankings exclude restricted users/pairs.

## See Also

- [Diaverse Club Runbook](../club.md) — Club snapshots, leaderboards, AI image publication, and Club10000 ownership.
- [Cabinet RBAC Guide](cabinet/rbac-guide.md) — staff permission model.
- [Factory Web](factory.md) — factory surfaces affected by step-powered impulses.
