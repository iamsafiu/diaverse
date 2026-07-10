# Autonomous Editorial System

## Scope

The autonomous editorial system is the evidence-first content operations layer for `diaverse-content`. It can rank opportunities, create draft/revision candidates, review text and visuals, record human labels, evaluate mature outcomes, and propose scoped learning updates.

It does not own public browser staff UI, backend identity, payment truth, or mobile attribution:

| Surface | Owner | Contract |
| --- | --- | --- |
| Content state, drafts, revisions, lessons, policies, visual candidates | `diaverse-content` | Internal APIs under `/internal/v1/content-editor/*`; trusted importer/publisher only |
| Staff browser UI and BFF | `diaweb` | `/ru/staff/content/studio` and `/api/staff/content/content-editor/*` |
| Staff identity and RBAC | `diaverseapi` | `/v1/staff/access/me`; `content:*` and `content.settings:manage` permissions |
| Site visits and content attribution touches | `diaverseapi` | Hash-only ledgers and privacy-suppressed aggregate APIs |
| Private AI Cofounder runtime | `diaverse-ai-cofounder` | Inactive for this system; may keep private ops drafts, but is not in the content publish path |

Production default is draft-only. Autonomous publishing must not be enabled by local test success alone.

## Lifecycle

```text
search/product evidence import
  -> mature outcome evaluation
  -> evidence-backed lesson consolidation
  -> opportunity ranking
  -> draft/revision/hold decision
  -> research, source verification, text critics
  -> visual concept generation and pixel review
  -> hard-policy gate
  -> trusted draft/canary action
  -> human approval and mature outcome snapshot
```

Every episode pins policy, prompt, operator, hard-policy, feature-vector, evidence-snapshot, input, and output hashes. Raw article bodies, prompts, chain-of-thought, browser cookies, JWTs, attribution tokens, and credential values are not learning memory.

## Evidence And Learning Semantics

| State | Meaning | UI / Learning Rule |
| --- | --- | --- |
| `available` | Source exists, cohort/window is mature, and privacy threshold is met. | May be used in score calculations. |
| `unavailable` | Source is not implemented, not configured, or intentionally excluded. | Display as a gap; never coerce to zero. |
| `insufficient_evidence` | Source exists, but sample, freshness, maturity, or confidence is below threshold. | Blocks strong conclusions and automatic negative lessons. |
| `stale` | Evidence exists but is outside freshness policy. | Requires refresh or manual acceptance. |
| `conflicting` | Sources or critics disagree materially. | Requires replan, review, or human decision. |
| `empty` | The source was queried and returned no eligible facts. | Distinct from unavailable; still not evidence of failure unless denominator is mature. |

Lessons are scoped by area, locale, pain cluster, subcluster, search intent, action, feature key, sample size, confidence, and expiry. Model-generated lessons can adjust soft preferences only. They cannot weaken hard policy, source safety, privacy suppression, claim safety, or publish gates.

## Metric Glossary

| Metric | Denominator | Notes |
| --- | --- | --- |
| Search demand | Normalized search observations by query/page/date/device/country. | Imported from GSC/Yandex/manual sources; absent provider data is `unavailable`. |
| Page opportunity | Existing page impressions/clicks/position and freshness. | Used to choose refresh vs new article. |
| Pain coverage | Candidate coverage of normalized pain cluster/subcluster. | Legacy `unknown_legacy` content stays readable but is not a positive modern example. |
| CTA engagement | Consented guide engagement and CTA events. | Raw visitor ids are HMAC-hashed or discarded. |
| Product attribution | Suppressed aggregate cohorts from `diaverseapi`. | No per-user, per-token, or below-threshold data reaches `diaverse-content` or Codex. |
| D1/D7 activity | Claimed content-attribution cohorts with backend activity evidence. | Immature windows return `insufficient_evidence`, not zero. |
| Approved paid users/outcomes | Authenticated paid outcomes in approved backend payment domains. | Guest and unclaimed outcomes remain explicit gaps. |
| Human acceptance | Human decisions and generated-to-published diffs. | Stronger than machine self-evaluation, but not enough alone to rewrite policy. |
| Safety incidents | Hard-policy violations, unsupported claims, image issues, source failures. | Blocks autopublish and can trigger rollback. |

Do not add segment counts together unless the response says the groups are mutually exclusive.

## Content Attribution Privacy

Content attribution is consented and hash-only:

- Browser capture uses a bounded opaque `dattr` token.
- `diaweb` stores it in a short-lived `HttpOnly; Secure; SameSite=Lax` `__Host-dia_content_attribution` cookie.
- Redemption happens after successful browser auth through `POST /api/analytics/content-attribution`.
- `diaverseapi` stores only HMAC token hashes, HMAC anonymous visitor hashes, bounded content dimensions, consent/contract versions, touched/claimed/expiry timestamps, and nullable user FK.
- Touch TTL is configurable; current contract tests use a 30-minute browser cookie and backend bounded claim/touch windows.
- Aggregates suppress groups below `content_attribution_min_cohort_size`.
- Onboarding completion, guest/unclaimed outcomes, and mobile install attribution are explicit `unavailable` states until a safe contract exists.

Raw tokens, browser cookies, JWTs, raw visitor ids, user/payment identifiers, and token/hash values must not appear in logs, UI, BFF upstream headers, or test failure messages.

## Source Safety

Research and source evidence must pass the trusted broker:

- HTTPS only.
- Redirect, size, type, private-IP, and metadata-host protections.
- Prompt-injection phrases in queries, source text, dimensions, or provider payloads are rejected or isolated.
- Every factual claim maps to source evidence or is marked unsupported.
- Source snippets and article bodies are not stored in learning tables.

## Visual Review

Visual generation is candidate-based, not overwrite-based:

- Art direction proposes multiple pain-aware concepts.
- Candidates persist with prompt/model/asset hashes, dimensions, storage URI, alt-text hash, and rejection reason ids.
- Pixel review scores pain relevance, emotional tone, composition, mobile/card crop, uniqueness, accessibility, text/logo artifacts, anatomy defects, medical before/after implications, real-person likeness risk, and RPG residue.
- Rejected candidates regenerate only with targeted guidance inside the configured budget.

## Staff Role Matrix

| Permission | Allows |
| --- | --- |
| `content:read` | Studio status, opportunities, episodes, sources, variants, evaluations, lessons, policies, human decisions |
| `content:edit` | Rerun jobs, cancel mutable episodes, create human decisions |
| `content:publish` | Approve/publish guide, run canary action, rollback guide revision |
| `content.settings:manage` | Activate/rollback policy versions |

`diaweb` BFF denies by default. Browser cookies never go to `diaverse-content`; the BFF mints a short-lived internal JWT after live backend RBAC resolution.

## Feature Flags And Budgets

Feature flags are intentionally split so an incident can disable one subsystem without disabling all content rendering:

- search sync/import
- product outcomes
- lesson activation
- generation
- revisions
- visuals
- publish
- syndication
- global cycle kill switch
- publish kill switch

Budgets cover runtime, retries, repeated issue signatures, token/image/cost ceiling, provider failure, and operator cancellation. Budgets are safety limits, not editorial templates.

## Why AI Cofounder Stays Inactive

`diaverse-ai-cofounder` remains a private Diaverse operations runtime. It may summarize metrics or draft private operational notes, but it is not allowed to publish public learn content, mutate content policy, bypass hard gates, or read unsuppressed attribution data.

The content system keeps its own source-backed, hash-pinned, reviewable workflow in `diaverse-content` so public content state and learning memory stay auditable and rollbackable.

## Verification

Minimum local checks before promotion:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverse-content
npm run typecheck
npm run lint
npm run prisma:validate
npx tsx --test tests/content-autopilot/cycle.test.ts tests/content-autopilot/revision-pipeline.test.ts tests/content-autopilot/hero-image-review.test.ts tests/content-autopilot/publish.test.ts tests/content-autopilot/editorial-pipeline.test.ts tests/security/content-source-injection.test.ts tests/security/artifact-redaction.test.ts
npx tsx scripts/content-autopilot-backtest.ts --fixture tests/fixtures/content-autopilot/shadow-cycle.json --json

cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests/test_content_attribution.py tests/test_content_attribution_auth.py tests/test_alembic_graph.py tests/test_analytics_site.py -q

cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm run typecheck
npx vitest run __tests__/app/api/analytics/content-attribution-route.test.ts __tests__/app/api/staff/content/proxy-utils.test.ts __tests__/app/api/staff/content/auth.test.ts __tests__/proxy.test.ts __tests__/modules/content/EditorialStudioWorkspace.test.tsx __tests__/modules/content/EditorialStudioPolling.test.ts
```
