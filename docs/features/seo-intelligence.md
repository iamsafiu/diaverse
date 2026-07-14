# SEO Intelligence

## Scope

SEO Intelligence is the evidence-first strategy layer for public learn content
owned by `diaverse-content`. It turns verified search demand, content inventory,
SERP/source facts, privacy-safe behavior aggregates, editorial outcomes, machine
reviews, and human decisions into reviewable strategy snapshots.

It does not publish articles, weaken article evidence requirements, or replace
the autonomous editor critics. Its only runtime influence is bounded soft
candidate/brief guidance from an active, approved, fresh snapshot.

## Ownership

| Surface | Owner | Rule |
| --- | --- | --- |
| Analyzer catalog, findings, snapshots, outcome learning | `diaverse-content` | Internal content strategy layer |
| Browser Staff Studio | `diaweb` | Same-origin `/api/staff/content/content-editor/*` BFF only |
| Staff RBAC | `diaverseapi` | `content:read`, `content:edit`, `content:publish`, `content.settings:manage` |
| Public content routes | `diaverse-content` through edge/diaweb SEO integration | `/ru/learn/*` only |
| Search and behavior provider credentials | trusted content worker runtime | Never browser, never committed fixtures |

`diaverse-ai-cofounder` remains out of the public content publish path.

## Analyzer Catalog

The machine-readable manifest lives in
`diaverse-content/content-operator/seo-analysis/coverage-manifest.json`.

Current manifest:

- version: `2026.07.13-v2`
- definitions: 32
- rollout: 31 implemented, 1 not applicable
- required groups: `utility`, `niche`, and `competitor`

The first baseline read-only run uses these five analyzers:

1. `utility.data_validator_normalizer.v1`
2. `niche.03_search_demand.v1`
3. `niche.10_serp_reality.v1`
4. `niche.14_white_space.v1`
5. `niche.17_eeat_trust.v1`

If evidence is unavailable, those analyzers must produce explicit capability
blocked/skipped records. They must not infer demand, ranking, trust, or gaps from
missing providers.

## Data Sources And Semantics

| Source | Used For | Safety Rule |
| --- | --- | --- |
| Google Search Console | verified search demand, page/query outcomes, index inspection | Read-only OAuth; top rows are not a census |
| Yandex Webmaster | aggregate popular queries and pages | Top-list evidence only; absence is not zero demand |
| Yandex Wordstat/manual CSV | non-brand demand seeds | Private inbox only; raw files never committed |
| Yandex Metrica | aggregate behavior windows | Date + canonical path aggregates only; privacy threshold required |
| Published guide inventory | portfolio overlap and canonical coverage | Drafts/staff/internal routes excluded |
| Verified sources/SERP facts | factual support, trust, SERP reality | HTTPS/source broker and prompt-injection filters |
| Editorial outcomes | mature content performance windows | Immature windows are `insufficient_evidence` |
| Machine evaluations | critic results and issue distributions | Reviewer scores are evidence, not self-approval |
| Human decisions | approvals, rejections, rollbacks | Strong signal but still not hard-policy mutation |

Evidence states remain distinct: `available`, `unavailable`,
`insufficient_evidence`, `stale`, `suppressed`, `conflicting`, and `empty` are
not interchangeable.

## Strategy Snapshot Lifecycle

```text
source import / inventory
  -> read-only analyzer plan
  -> read-only analyzer execution
  -> finding validation and human review
  -> draft strategy snapshot synthesis
  -> Staff Studio approve/reject
  -> explicit activation for one scope
  -> bounded candidate/brief influence
  -> outcome learning proposes a superseding draft snapshot
```

Snapshots are immutable. A refresh creates a new draft snapshot with a parent
snapshot id and finding lineage. Rollback creates a new immutable approved
snapshot from a previously approved superseded source; it does not rewrite
history.

## Publication Safety

The publish gate remains monotonic:

- strategy can add blockers, never remove existing blockers;
- legacy/non-strategy episodes do not need strategy lineage;
- strategy-influenced episodes require active approved matching snapshot
  lineage, scope/hash match, freshness, and complete evidence lineage;
- strategy evidence is never article source evidence;
- verified article source evidence, critics, visuals, risk checks, revision
  state, and publish mode still decide publication.

Autopublish must stay off during strategy rollout. Enabling
`CONTENT_AUTOPILOT_AUTOPUBLISH_ENABLED=true` is not sufficient: the trusted
publish gate still requires sufficient article evidence and verified source
evidence.

## Outcome Learning

Outcome learning is proposal-only. It joins mature comparable windows by
canonical guide/path across:

- content outcome snapshots;
- privacy-safe Metrica aggregates;
- search outcome aggregates;
- machine evaluations;
- human decisions.

Before proposing a refresh it requires:

- mature content outcome window;
- minimum sample;
- non-suppressed aggregate behavior data;
- comparable declared windows;
- sufficient confidence;
- no contradictory positive/negative outcome pattern;
- bounded soft-weight delta.

The learner can store new refresh/regression findings and create a superseding
`draft` strategy snapshot. It cannot edit the current snapshot, activate a
snapshot, change hard policy, change source policy, change risk rules, change
publish gates, delete content, or roll back content automatically.

Regression detection creates a rollback-review recommendation for a human; it
does not perform destructive actions.

## Runtime Flags

Safe default:

```env
CONTENT_STRATEGY_ENABLED=false
CONTENT_STRATEGY_COLLECTION_ENABLED=false
CONTENT_STRATEGY_EXECUTION_ENABLED=false
CONTENT_STRATEGY_APPROVAL_ENABLED=false
CONTENT_STRATEGY_CANDIDATE_INFLUENCE_ENABLED=false
CONTENT_STRATEGY_METRICA_ENABLED=false
CONTENT_STRATEGY_SCHEDULER_ENABLED=false
CONTENT_STRATEGY_KILL_SWITCH=false
```

Rollout order:

1. Deploy additive migration and compatible code with all strategy flags off.
2. Run `content:strategy:bootstrap` twice and verify idempotency.
3. Run static health and read-only baseline.
4. Configure/import real evidence.
5. Run database-backed read-only baseline.
6. Create and review a draft strategy snapshot.
7. After explicit human approval, enable shadow candidate influence.
8. Promote one scope at a time to active soft influence.

Kill switches:

- `CONTENT_STRATEGY_KILL_SWITCH=true` stops strategy operations.
- `CONTENT_STRATEGY_CANDIDATE_INFLUENCE_ENABLED=false` removes strategy from
  candidate ranking/brief context.
- `CONTENT_AUTOPILOT_PUBLISH_KILL_SWITCH=true` blocks trusted publishing.
- Disable scheduler/systemd timers for repeated failures.

## Provider Configuration

Search Console:

```env
GSC_SYNC_ENABLED=false
GSC_SITE_URL=
GSC_CLIENT_ID=
GSC_CLIENT_SECRET=
GSC_REFRESH_TOKEN=
GSC_URL_INSPECTION_ENABLED=false
```

Yandex:

```env
YANDEX_WEBMASTER_SYNC_ENABLED=false
YANDEX_WEBMASTER_OAUTH_TOKEN=
YANDEX_WEBMASTER_USER_ID=
YANDEX_WEBMASTER_HOST_ID=
YANDEX_WORDSTAT_SYNC_ENABLED=false
YANDEX_WORDSTAT_OAUTH_TOKEN=
YANDEX_METRICA_SYNC_ENABLED=false
CONTENT_STRATEGY_METRICA_ENABLED=false
YANDEX_METRICA_OAUTH_TOKEN=
YANDEX_METRICA_COUNTER_ID=
YANDEX_METRICA_MINIMUM_SAMPLE=10
```

Raw exports and seed files belong only in ignored private runtime inboxes such
as `.content-search-inbox`; never commit them or paste them into prompts.

## Verification Status, 2026-07-14

Local static verification has passed:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverse-content
npx tsx scripts/content-strategy-health.ts --static-only
npx tsx scripts/content-strategy-cycle.ts --command execute --mode read_only --static-only --force
```

Observed result:

- health: `degraded`, not blocked;
- manifest loaded: 32 definitions, hash
  `17b570a11c9a0e96f843a91d5670a94711333437c6c3355e11c1256d670b187e`;
- registry issues: 0;
- data health: `insufficient` because providers/database inventory were not
  configured in the static environment;
- read-only cycle: 2 utility stages completed, 4 baseline analyzer stages
  capability-blocked/skipped because evidence was unavailable.

Detailed safe report:
`diaverse-content/tests/fixtures/content-strategy/verification-2026-07-14.md`.

This is not approval to activate strategy influence. It proves the system fails
closed without fabricated evidence.

## Required Checks Before Promotion

`diaverse-content`:

```powershell
npm run prisma:validate
npm run db:migrate:deploy   # disposable DB only before production
npm test
npm run typecheck
npm run lint
npm run build
npx tsx scripts/content-strategy-health.ts --static-only
```

`diaweb` staff BFF/UI:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm --prefix . test -- __tests__/modules/content __tests__/app/api/staff/content
npm --prefix . run typecheck
npm --prefix . run lint
npm --prefix . run build
```

Workspace docs:

```powershell
cd C:\Users\Indigo\Desktop\diaverse
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1
```

## Related Documents

- [Autonomous Editorial System](autonomous-editor.md)
- [Content Factory Architecture](../architecture/content-factory.md)
- [Autonomous Editorial Runbook](../runbooks/autonomous-editor.md)
- `diaverse-content/content-operator/search-data/README.md`
- `diaverse-content/content-operator/codex-runbook.md`
