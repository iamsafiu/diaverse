# Plan: Evidence-first SEO Intelligence Layer for Diaverse

Branch: `dev` (fast mode, no new branch)
Date: 2026-07-13
Status: in implementation
Execution file: `.ai-factory/plans/seo-intelligence.md` (isolated from the parallel agent's `.ai-factory/PLAN.md`)

## Settings

- Mode: `fast`
- Testing: yes; unit, integration, contract, adversarial, migration, shadow/backtest, and UI tests are required.
- Logging: verbose structured operational logging through the existing content-autopilot logger; no prompts, article bodies, credentials, raw tokens, visitor identifiers, or sensitive full-text queries in logs.
- Documentation: yes; architecture, feature, operator, data-source, deployment, and rollback documentation are mandatory.
- Task tracking: this Markdown checklist is the progress source of truth because a separate task-creation tool is not available.
- Constraints: no user-imposed implementation limit; preserve all current safety and publication gates.

## Objective

Implement the DrMax 2026 SEO research as a durable, versioned SEO strategy layer above the existing `diaverse-content` intelligence, learning, and editorial pipeline. The layer must collect normalized evidence, execute a typed analyzer DAG, produce human-reviewable strategy snapshots, and influence article selection and briefs only after explicit approval. It must never weaken the existing verified-source, `evidenceStatus=sufficient`, critic, visual, or publication gates.

The first production milestone is not autonomous publishing. It is a read-only baseline run of five analyses with a human-reviewed strategy snapshot and provable zero influence on candidate ranking, generation, or publishing. Controlled influence is enabled only in later rollout tasks.

## Research Context

Copied only from `.ai-factory/RESEARCH.md` Active Summary:

Topic: Integrating DrMax 2026 SEO research and prompt packs into the Diaverse autonomous editor

Goal: Convert the two supplied books and the bundled 25+5 prompt system into a versioned, evidence-first SEO intelligence layer without weakening the existing editorial and publication safety gates.

Constraints:

- This session records architecture and instructions only; no keyword, market, competitor, SERP, community, or content-portfolio analysis has been executed.
- Explore mode allows persistence only in `.ai-factory/RESEARCH.md`; implementation belongs in a later `$aif-plan`/`$aif-implement` flow.
- All strategic conclusions must remain traceable to normalized evidence and explicitly distinguish fact, inference, and hypothesis.
- Existing `evidenceStatus=sufficient`, verified-source, editorial critic, and publication gates must remain intact.
- Platform Ecosystem Analyzer is retained for coverage but is currently `not_applicable` by product decision.

Decisions:

- Build a strategic analyzer DAG above the existing candidate-pool/editorial pipeline instead of embedding the book prompts directly into article generation.
- Add durable analysis runs, findings, evidence links, dependencies, and approved strategy snapshots.
- Treat the 25 niche analyzers and 5 competitor analyzers as versioned prompt definitions with typed inputs/outputs, applicability, evidence policy, validation, budget, and human-review triggers.
- Add Yandex Metrica as privacy-safe behavioral evidence, not as a search-demand observation.
- Keep recommendations that depend on leaked ranking-system labels, fixed SEO quotas, model self-validation, artificial engagement, fake consensus, or unverified external actions out of automation.

Open questions:

- Which analyzer subset becomes the first production slice after the baseline data inventory.
- Which SERP/competitor/community data providers are legally and operationally acceptable for production.
- What approval UI and refresh cadence strategy snapshots need.
- What Metrica aggregation/privacy thresholds are required before behavioral signals can influence decisions.

Success signals:

- Every recommendation can be traced to fresh evidence, prompt version, validation status, and an approved strategy snapshot.
- The autonomous editor can use research outputs while unchanged publish gates still reject unsupported articles.
- Coverage mapping shows every supplied analyzer and major recommendation as implemented, deferred, rejected, or not applicable.

Next step: Create an implementation plan for the SEO intelligence layer, beginning with the coverage manifest, normalized run/finding schema, and a small read-only analyzer slice.

## Repository and Ownership Matrix

| Repository | Role in this plan | Planned changes |
| --- | --- | --- |
| `diaverse` | Cross-repo plan and canonical docs | This plan, feature/architecture/runbook docs, GBrain sync |
| `diaverse-content` | Source of truth for SEO evidence, analyzer execution, strategy snapshots, candidate lineage, and publish safety | Primary implementation, Prisma migration, jobs, internal API, tests |
| `diaweb` | Only browser-facing Staff Editorial Studio and same-origin BFF | BFF allowlist, typed client/hooks, review and approval UI, UI tests |
| `diaverseapi` | Existing privacy-suppressed product-attribution aggregate provider | Read-only dependency; no schema or API change planned |
| `aibot` | Existing internal copywriting service | No change; not used as the strategy source of truth |
| `diaverse-ai-cofounder` | Private draft-only operations runtime | No change; cannot activate strategy or publish |
| `diaverse-mobile`, `club10000-bot`, `diaverse-auth-bot` | Out of scope | No change |

Implementation must preserve unrelated dirty worktrees. In particular, current `diaweb` analytics changes and root documentation changes must not be reverted, staged, reformatted, or folded into this work. `diaverse-content` is currently clean and is the safest first implementation surface.

## Target Architecture

```text
GSC / Yandex Webmaster / Wordstat / curated imports / Metrica aggregates
                              |
                              v
      normalized evidence + capability/data-health registry
                              |
                              v
       versioned analyzer registry -> dependency DAG -> validators
                              |
                              v
       findings: fact | inference | hypothesis + evidence lineage
                              |
                              v
        immutable strategy snapshot -> human review -> activation
                              |
                 approved and fresh snapshots only
                              |
                              v
       candidate ranking -> editorial brief -> existing agent stages
                              |
                              v
   unchanged evidence/critic/visual/publish gates -> canary/autopublish
```

The strategy cycle is separate from the daily article cycle. A missing, expired, rejected, or unapproved strategy snapshot must degrade to the current production behavior, never to permissive automation.

## Non-negotiable Safety Invariants

- `ContentSourceEvidence.verificationStatus`, source freshness, and `evidenceStatus=sufficient` remain hard publication requirements.
- Analyzer output is strategic evidence, not proof for factual claims inside an article.
- Model self-confidence cannot verify evidence or approve a strategy.
- Every finding declares `fact`, `inference`, or `hypothesis`; inferred and hypothetical findings cannot be silently presented as facts.
- Only an immutable, human-approved, active, non-expired strategy snapshot may affect candidate scoring or editorial briefs.
- Strategy weights are soft preferences. They cannot bypass topic policy, source policy, critics, risk classification, quality budgets, or publish mode.
- Yandex Metrica stores only privacy-safe aggregates. It does not enter `ContentSearchObservation`, and no visitor/session/user identifier is persisted.
- SERP, competitor, and community providers remain disabled until their legal terms, access method, freshness, and source policy are explicitly approved.
- The Platform Ecosystem Analyzer stays registered as `not_applicable`; it is not silently omitted.
- No automation for artificial engagement, fabricated consensus, fake links, outreach/spam, leaked ranking labels, fixed keyword quotas, or destructive external SEO actions.
- Browser calls continue through `diaweb` same-origin `/api/staff/content/content-editor/*`; the browser never calls `diaverse-content` directly.
- Database changes are additive and forward-compatible. Runtime flags stay off until migrations and read-only verification pass.

## Complete Analyzer Coverage Manifest

The implementation must keep this catalog machine-readable and versioned. A definition can be `implemented`, `deferred`, `rejected`, `not_applicable`, or `unavailable`; it cannot disappear from coverage.

| ID | Analyzer | Initial rollout |
| --- | --- | --- |
| `utility.project_data_collector.v2` | Universal Project Data Collector v2 | Data inventory foundation |
| `utility.data_validator_normalizer.v1` | Project Data Validator & Normalizer | First read-only slice |
| `niche.01_landscape.v1` | Niche Landscape Analyzer | Full catalog wave 1 |
| `niche.02_market_opportunity.v1` | Market Opportunity Analyzer | Full catalog wave 1 |
| `niche.03_search_demand.v1` | Search Demand Analyzer | First read-only slice |
| `niche.04_trend_discovery.v1` | Trend Discovery Analyzer | Full catalog wave 1 |
| `niche.05_audience_problem.v1` | Audience Problem Analyzer | Full catalog wave 1 |
| `niche.06_audience_segmentation.v1` | Audience Segmentation Analyzer | Full catalog wave 1 |
| `niche.07_jtbd_seo.v1` | JTBD SEO Analyzer | Full catalog wave 1 |
| `niche.08_buyer_journey_query.v1` | Buyer Journey Query Mapper | Full catalog wave 1 |
| `niche.09_terminology_language.v1` | Terminology & Language Analyzer | Full catalog wave 1 |
| `niche.10_serp_reality.v1` | SERP Reality Analyzer | First read-only slice; capability-gated |
| `niche.11_seasonality.v1` | Seasonality Analyzer | Full catalog wave 2 |
| `niche.12_geo_locale.v1` | Geo & Locale Analyzer | Full catalog wave 2 |
| `niche.13_commercial_intent.v1` | Commercial Intent Analyzer | Full catalog wave 2 |
| `niche.14_white_space.v1` | White Space and Current Portfolio Analyzer | First read-only slice |
| `niche.15_buyer_journey_pack_variant.v1` | Buyer Journey Mapper pack variant | Registered as an explicit versioned extension/alias of 08; no duplicate execution unless inputs or outputs differ |
| `niche.16_platform_ecosystem.v1` | Platform Ecosystem Analyzer | `not_applicable` by product decision |
| `niche.17_eeat_trust.v1` | E-E-A-T & Trust Analyzer | First read-only slice |
| `niche.18_entity_landscape.v1` | Entity Landscape Analyzer | Full catalog wave 3 |
| `niche.19_regulatory_risk.v1` | Regulatory & Risk Analyzer | Full catalog wave 3 |
| `niche.20_linkability.v1` | Linkability Potential Analyzer | Full catalog wave 3 |
| `niche.21_entry_difficulty.v1` | Entry Difficulty Analyzer | Full catalog wave 3 |
| `niche.22_monetization_fit.v1` | Monetization Fit Analyzer | Full catalog wave 3 |
| `niche.23_community_voice.v1` | Community Voice Analyzer | Full catalog wave 3; capability-gated |
| `niche.24_content_format_fit.v1` | Content Format Fit Analyzer | Full catalog wave 3 |
| `niche.25_ai_search_opportunity.v1` | AI Search Opportunity Analyzer | Full catalog wave 3 |
| `competitor.01_landscape_mapper.v1` | Competitive Landscape Mapper | Competitor chain |
| `competitor.02_strategy_deconstructor.v1` | Competitor Strategy Deconstructor | Competitor chain |
| `competitor.03_serp_demand_gap.v1` | SERP & Demand Gap Analyzer | Competitor chain |
| `competitor.04_weakness_opportunity.v1` | Weakness & Opportunity Extractor | Competitor chain |
| `competitor.05_strategy_builder.v1` | Competitor-Informed Strategy Builder | Competitor chain; human review required |

## Phase 0 — Contracts, Coverage, and Guardrails

### Task 1 — Create the versioned coverage manifest and analyzer definition contract

- [x] Add a machine-readable manifest covering all 32 entries above: 2 utilities, 25 niche analyzers, and 5 competitor analyzers.
- Deliverable:
  - Define stable analyzer IDs, semantic versions, group, purpose, typed input/output schema references, applicability, dependencies, evidence policy, freshness policy, review triggers, cost/time budgets, rollout state, and research provenance.
  - Adapt the supplied research into operational definitions; do not paste entire copyrighted prompt packs verbatim.
  - Encode analyzer 15 as an explicit extension/alias relationship to analyzer 08 and analyzer 16 as `not_applicable` with a recorded reason.
  - Add a coverage validation utility that fails on duplicate IDs, missing definitions, missing schema files, dependency cycles, or unclassified catalog entries.
- Expected behavior: the manifest gives a deterministic answer for every supplied recommendation: implemented, deferred, rejected, unavailable, or not applicable.
- Files:
  - `diaverse-content/content-operator/seo-analysis/coverage-manifest.json`
  - `diaverse-content/content-operator/seo-analysis/analyzer-definition.schema.json`
  - `diaverse-content/src/lib/content-strategy/contracts.ts`
  - `diaverse-content/src/lib/content-strategy/coverage-manifest.ts`
  - `diaverse-content/tests/content-strategy/coverage-manifest.test.ts`
- Logging: validation logs only manifest version/hash, analyzer counts by state, missing IDs, and schema error codes; never prompt bodies.
- Tests: exact expected ID set, alias semantics, `not_applicable` retention, schema existence, acyclic dependencies, and stable manifest hash.
- Dependencies: none.

### Task 2 — Add feature flags, capability states, source policy, and execution budgets

- [x] Define fail-closed configuration for the SEO strategy subsystem.
- Deliverable:
  - Add master, collection, execution, approval, candidate-influence, Metrica, and scheduler flags; all new behavior defaults off.
  - Define analyzer profiles `lite` and `full` with the same output contracts but different evidence breadth and budgets.
  - Define provider capability states: `ready`, `degraded`, `unavailable`, `not_configured`, `not_applicable`, and `blocked_by_policy`.
  - Add per-run/per-analyzer request, token, cost, time, retry, concurrency, and freshness limits with global kill switches.
  - Add source allowlist/policy metadata for first-party, search-console, search-demand, public-web, competitor, community, and behavior aggregates.
- Expected behavior: missing credentials or unapproved providers produce explicit capability states and skipped analyzers, not zeros, fabricated evidence, or permissive fallback.
- Files:
  - `diaverse-content/.env.example`
  - `diaverse-content/src/lib/content-strategy/config.ts`
  - `diaverse-content/src/lib/content-strategy/source-policy.ts`
  - `diaverse-content/src/lib/content-strategy/budgets.ts`
  - `diaverse-content/tests/content-strategy/config.test.ts`
  - `diaverse-content/tests/content-strategy/source-policy.test.ts`
- Logging: configuration logs flag states, numeric limits, profile, and capability reason codes; secrets and credential presence details are redacted to booleans.
- Tests: invalid values fail closed; disabled flags prevent side effects; budget boundaries; provider states; no secret leakage in log metadata.
- Dependencies: Task 1.

## Phase 1 — Additive Persistence and Migration Safety

### Task 3 — Add durable SEO run, finding, evidence, dependency, snapshot, and behavior models

- [x] Extend Prisma with additive, forward-compatible persistence.
- Deliverable:
  - Add `ContentSeoAnalysisRun`, `ContentSeoFinding`, `ContentSeoFindingEvidence`, `ContentSeoRunDependency`, `ContentStrategySnapshot`, `ContentStrategySnapshotFinding`, and `ContentSeoCoverageManifest`.
  - Add separate `ContentBehaviorImport` and `ContentBehaviorObservation` models for privacy-safe Yandex Metrica aggregates.
  - Represent lifecycle states: `queued`, `collecting_evidence`, `running`, `validating`, `needs_human_review`, `approved`, `rejected`, `superseded`, `failed`, `expired`, and `not_applicable` where relevant.
  - Persist prompt/schema/manifest/input/output hashes, model/version, scope, cutoff/freshness, epistemic status, confidence, review state, timings, tokens, cost, and error codes.
  - Add relational evidence lineage to existing `ContentSourceEvidence` and nullable strategy lineage on `ContentEditorialHypothesis` and `ContentEditorialEpisode`; keep old rows valid without backfill.
  - Use explicit short PostgreSQL table/index/constraint names and indexes for run status, analyzer/scope/freshness, finding status, snapshot activation, evidence lookups, and idempotency keys.
- Expected behavior: every run and recommendation is reproducible and traceable while the pre-existing editor continues to work with all new flags off.
- Files:
  - `diaverse-content/prisma/schema.prisma`
  - `diaverse-content/prisma/migrations/*_add_content_seo_strategy_layer/migration.sql`
  - `diaverse-content/tests/content-learning/schema-foundation.test.ts`
  - `diaverse-content/tests/content-strategy/schema-foundation.test.ts`
- Logging: migration wrapper retains existing start/fail/done events; no row payloads are logged.
- Tests: Prisma validation, relation/delete semantics, unique idempotency keys, index-name length, nullable compatibility, and schema contract tests.
- Dependencies: Tasks 1–2.

### Task 4 — Prove migration safety and bootstrap the manifest without enabling runtime behavior

- [x] Validate the migration against disposable PostgreSQL before any application integration.
- Deliverable:
  - Apply all existing migrations plus the new migration to a clean temporary database.
  - Apply the new migration to a representative pre-migration schema/data snapshot and verify old content/editorial rows remain readable.
  - Run Prisma migration diff/drift checks and record table/index/constraint postconditions.
  - Add an idempotent manifest bootstrap command that stores manifest version/hash and analyzer states only after schema deployment.
  - Document forward-only rollback: disable flags and deploy compatible code; retain additive tables rather than running destructive down SQL.
- Expected behavior: migration deploy is repeatable, has no destructive DDL, requires no table rewrite/backfill, and is safe to deploy before runtime code.
- Files:
  - `diaverse-content/scripts/content-strategy-bootstrap.ts`
  - `diaverse-content/package.json`
  - `diaverse-content/tests/content-strategy/migration.test.ts`
  - `docs/runbooks/autonomous-editor.md`
- Logging: bootstrap logs manifest hash/version, inserted/updated/skipped counts, and migration postcheck counts; no table contents.
- Tests:
  - `npm run prisma:validate`
  - Prisma migrate diff with a disposable shadow database.
  - `npm run db:migrate:deploy` against clean and representative disposable databases.
  - Re-running bootstrap produces no duplicate rows.
- Dependencies: Task 3.

### Task 5 — Implement repositories, lifecycle transitions, idempotency, and supersession

- [x] Build the persistence boundary for strategy data.
- Deliverable:
  - Add typed repository methods for runs, findings, evidence links, dependencies, manifest snapshots, behavior observations, and strategy snapshots.
  - Enforce legal lifecycle transitions and compare-and-set updates for concurrent workers.
  - Derive run keys from analyzer/version/scope/input hash/cutoff/profile and make retries idempotent.
  - Make findings and strategy snapshots immutable after review; revisions create superseding records.
  - Add transaction boundaries so a failed analyzer cannot leave a successful run with partial findings.
- Expected behavior: retries reuse or safely resume equivalent work, concurrent executions do not duplicate findings, and approved history cannot be edited in place.
- Files:
  - `diaverse-content/src/lib/content-strategy/types.ts`
  - `diaverse-content/src/lib/content-strategy/repository.ts`
  - `diaverse-content/src/lib/content-strategy/lifecycle.ts`
  - `diaverse-content/src/lib/content-strategy/run-key.ts`
  - `diaverse-content/tests/content-strategy/repository.test.ts`
  - `diaverse-content/tests/content-strategy/lifecycle.test.ts`
- Logging: run/finding/snapshot IDs, transition names, idempotency outcome, duration, counts, and stable error code; no finding prose.
- Tests: legal/illegal transitions, concurrency conflict, idempotent retry, immutable approved records, supersession, transaction rollback, and database error mapping.
- Dependencies: Tasks 3–4.

## Phase 2 — Evidence Inventory, Providers, and Normalization

### Task 6 — Build the universal project data inventory and data-health snapshot

- [x] Implement `utility.project_data_collector.v2` as a deterministic collector, not an LLM prompt.
- Deliverable:
  - Inventory configured and available GSC, Yandex Webmaster, Wordstat, manual/CSV, verified sources, product-attribution aggregates, guides, sitemap/canonical state, editorial outcomes, and approved policy/lesson inputs.
  - Record availability, owner, period, lag, freshness, row count, confidence, privacy state, and capability reason without copying secrets.
  - Produce a versioned, hashable data-health snapshot used as the root dependency for strategy runs.
  - Treat missing sources as `unknown`/`unavailable`; never coerce missing demand, rank, traffic, or behavior into zero.
- Expected behavior: operators can see exactly which evidence can and cannot support each analyzer before spending model budget.
- Files:
  - `diaverse-content/src/lib/content-strategy/data-inventory.ts`
  - `diaverse-content/src/lib/content-strategy/data-health.ts`
  - `diaverse-content/src/lib/content-strategy/source-adapters.ts`
  - `diaverse-content/tests/content-strategy/data-inventory.test.ts`
- Logging: source category, capability state, period, freshness, row counts, suppression counts, and snapshot hash; no credentials or raw evidence text.
- Tests: fully configured, partially configured, stale, suppressed, and unavailable-source fixtures; deterministic snapshot hash.
- Dependencies: Tasks 2 and 5.

### Task 7 — Implement normalized evidence contracts, epistemic labels, contradiction checks, and freshness rules

- [x] Add a common validation layer used by every analyzer.
- Deliverable:
  - Define normalized evidence references, units, locale/region/device/time dimensions, source reliability, verification, freshness, and privacy status.
  - Require every finding to declare evidence IDs, epistemic status, confidence basis, limitations, and applicability.
  - Detect unsupported numeric claims, incompatible periods/regions/units, duplicate evidence, circular support, source conflicts, and stale inputs.
  - Add contradiction records and review triggers instead of averaging incompatible evidence into false certainty.
  - Sanitize all untrusted source text as data and defend analyzer prompts against embedded instructions.
- Expected behavior: invalid or contradictory inputs move a run to validation failure or human review; they cannot become approved facts.
- Files:
  - `diaverse-content/src/lib/content-strategy/evidence.ts`
  - `diaverse-content/src/lib/content-strategy/validator.ts`
  - `diaverse-content/src/lib/content-strategy/contradictions.ts`
  - `diaverse-content/src/lib/content-strategy/prompt-safety.ts`
  - `diaverse-content/content-operator/seo-analysis/shared-finding.schema.json`
  - `diaverse-content/tests/content-strategy/evidence-validator.test.ts`
  - `diaverse-content/tests/security/content-strategy-source-injection.test.ts`
- Logging: validation rule IDs, evidence hashes/IDs, contradiction categories, freshness state, and counts; never raw imported instructions or full community text.
- Tests: fact/inference/hypothesis rules, stale evidence, region mismatch, unsupported numbers, contradiction fixtures, and prompt-injection payloads.
- Dependencies: Tasks 5–6.

### Task 8 — Add Yandex Metrica as a privacy-safe behavior evidence provider

- [x] Implement aggregate Metrica ingestion separate from search observations.
- Deliverable:
  - Add OAuth/config validation, bounded retries, timeouts, rate-limit handling, period checkpointing, and idempotent imports.
  - Import only canonical page/guide/day-or-period aggregates needed for behavior analysis, such as views, engaged sessions, depth bands, return aggregates, and goal aggregates when configured.
  - Strip query parameters, canonicalize paths, reject user/session/client IDs, and enforce configurable minimum sample/privacy thresholds before storing or exposing rows.
  - Mark suppressed groups and unavailable metrics explicitly; do not manufacture zeros.
  - Add a dedicated sync command and capability/data-health integration.
- Expected behavior: Metrica can support aggregate behavior hypotheses but cannot identify or reconstruct an individual visitor and cannot masquerade as search demand.
- Files:
  - `diaverse-content/src/lib/content-intelligence/providers/yandex-metrica.ts`
  - `diaverse-content/src/lib/content-intelligence/providers/provider-config.ts`
  - `diaverse-content/src/lib/content-strategy/behavior-import.ts`
  - `diaverse-content/scripts/content-metrica-sync.ts`
  - `diaverse-content/.env.example`
  - `diaverse-content/package.json`
  - `diaverse-content/tests/content-intelligence/yandex-metrica.test.ts`
  - `diaverse-content/tests/content-strategy/behavior-import.test.ts`
- Logging: provider, period, aggregate row counts, suppression counts, checkpoint, attempts, status, and request duration; no OAuth token or visitor-level dimensions.
- Tests: configuration, pagination/retries/rate limits, idempotency, canonical paths, privacy suppression, forbidden dimensions, partial failures, and absence from `ContentSearchObservation`.
- Dependencies: Tasks 3, 5–7.

### Task 9 — Add policy-gated SERP, competitor, and community evidence adapters

- [x] Create safe provider interfaces without assuming an unapproved scraper or vendor.
- Deliverable:
  - Define provider-neutral contracts for SERP snapshots, competitor-page snapshots, and community-language evidence.
  - Support a trusted signed/manual snapshot import as the initial fallback, with source URL, retrieval time, terms/provenance metadata, locale, query hash, and content hash.
  - Keep automated providers `not_configured` or `blocked_by_policy` until credentials and legal/operational approval exist.
  - Enforce domain/path allowlists, robots/terms metadata, request budgets, freshness, deduplication, and untrusted-content sanitization.
  - Provide explicit incomplete-capability output so dependent analyzers skip or request human evidence rather than hallucinating.
- Expected behavior: the first baseline can run with curated evidence; no hidden scraping or unauthorized external action is introduced.
- Files:
  - `diaverse-content/src/lib/content-strategy/providers/contracts.ts`
  - `diaverse-content/src/lib/content-strategy/providers/manual-snapshot.ts`
  - `diaverse-content/src/lib/content-strategy/providers/serp.ts`
  - `diaverse-content/src/lib/content-strategy/providers/competitor.ts`
  - `diaverse-content/src/lib/content-strategy/providers/community.ts`
  - `diaverse-content/content-operator/seo-analysis/external-evidence-import.schema.json`
  - `diaverse-content/tests/content-strategy/external-providers.test.ts`
- Logging: provider capability, approved policy ID, source host/hash, period/freshness, request counts, and skip/error codes; no scraped body or cookies.
- Tests: blocked-by-default behavior, signed manual import, allowlist rejection, stale evidence, prompt injection, budget exhaustion, and unavailable dependency propagation.
- Dependencies: Tasks 2 and 7.

## Phase 3 — Analyzer DAG and the First Read-only Strategy Slice

### Task 10 — Implement the analyzer registry, dependency DAG, profiles, and planner

- [x] Turn the manifest into an executable but capability-aware graph.
- Deliverable:
  - Register typed analyzer implementations separately from definitions and validate implementation/version/schema compatibility.
  - Resolve dependencies, applicability, source capabilities, freshness, and `lite`/`full` profile before queueing work.
  - Support whole-project, area, locale, cluster, query, competitor, and guide scopes.
  - Produce an execution plan with estimated requests/tokens/cost/time and human-review requirements before execution.
  - Skip `not_applicable` and unavailable branches with explicit records; prevent dependency cycles and duplicate execution of analyzer 08/15 aliases.
- Expected behavior: identical inputs and manifest produce the same ordered execution plan, while missing capabilities yield transparent partial coverage.
- Files:
  - `diaverse-content/src/lib/content-strategy/registry.ts`
  - `diaverse-content/src/lib/content-strategy/dag.ts`
  - `diaverse-content/src/lib/content-strategy/planner.ts`
  - `diaverse-content/tests/content-strategy/dag.test.ts`
  - `diaverse-content/tests/content-strategy/planner.test.ts`
- Logging: plan ID/hash, selected/skipped analyzer IDs, dependency edges, capability reasons, profile, and estimated budgets.
- Tests: deterministic ordering, cycle detection, alias handling, scope selection, partial capability, budget rejection, and Platform `not_applicable` persistence.
- Dependencies: Tasks 1–2 and 6–9.

### Task 11 — Implement the strict analyzer executor and model-output validation/repair boundary

- [x] Reuse the existing Codex runner patterns through a dedicated strategy executor.
- Deliverable:
  - Build analyzer inputs from evidence IDs and bounded normalized excerpts, never from an unbounded mega-prompt.
  - Require strict JSON schema output and persist prompt/schema/model/input/output hashes and resource usage.
  - Separate model generation from deterministic validation; a model cannot approve or verify its own output.
  - Allow one bounded schema repair attempt for syntactic output failures; semantic/evidence failures require rerun or human review.
  - Apply timeouts, cancellation, retries, concurrency limits, total budgets, redaction, and resumable stage records.
- Expected behavior: invalid, over-budget, canceled, or unsupported analyzer output fails closed and cannot create an approved finding.
- Files:
  - `diaverse-content/src/lib/content-strategy/executor.ts`
  - `diaverse-content/src/lib/content-strategy/model-provider.ts`
  - `diaverse-content/src/lib/content-strategy/output-repair.ts`
  - `diaverse-content/src/lib/content-strategy/redaction.ts`
  - `diaverse-content/content-operator/seo-analysis/shared-analyzer-output.schema.json`
  - `diaverse-content/tests/content-strategy/executor.test.ts`
  - `diaverse-content/tests/content-strategy/output-repair.test.ts`
- Logging: analyzer/run/stage IDs, hashes, model/version, attempt, tokens, cost, duration, cancellation, and stable error code; never full prompts, evidence excerpts, or generated prose.
- Tests: valid output, malformed JSON, semantic failure, unsupported claim, timeout, cancellation, retry, budget exhaustion, redaction, and partial DAG failure.
- Dependencies: Tasks 5, 7, and 10.
### Task 12 — Implement the five baseline analyzers and execute them only in read-only mode

- [x] Implement the mandatory first slice:
  1. Data Validator & Normalizer.
  2. Search Demand Mapper.
  3. SERP Reality Check.
  4. Current Portfolio / White-space Map.
  5. E-E-A-T & Trust Scanner.
- Deliverable:
  - Add versioned prompt definitions, strict schemas, deterministic pre/post-processors, evidence requirements, validation rules, and reviewer triggers for each analyzer.
  - Search demand uses GSC/Yandex Webmaster/Wordstat/manual evidence with explicit source and period distinctions.
  - SERP Reality runs only with approved fresh SERP evidence; otherwise it records `unavailable` and a collection request.
  - Portfolio/white-space compares current guides, canonical URLs, sitemap, themes, search observations, and duplication/cannibalization signals.
  - E-E-A-T/Trust evaluates visible evidence, authorship/source/citation/claim-risk structures, and cannot assert real-world expertise that is not evidenced.
  - Force this milestone to `read_only`; no write path into candidate scores, briefs, policies, articles, or publish decisions.
- Expected behavior: one baseline run produces reviewable findings and gaps with complete evidence lineage and a test proving zero editorial influence.
- Files:
  - `diaverse-content/content-operator/seo-analysis/analyzers/data-validator-normalizer/*`
  - `diaverse-content/content-operator/seo-analysis/analyzers/search-demand/*`
  - `diaverse-content/content-operator/seo-analysis/analyzers/serp-reality/*`
  - `diaverse-content/content-operator/seo-analysis/analyzers/portfolio-white-space/*`
  - `diaverse-content/content-operator/seo-analysis/analyzers/eeat-trust/*`
  - `diaverse-content/src/lib/content-strategy/analyzers/*`
  - `diaverse-content/tests/content-strategy/baseline-analyzers.test.ts`
  - `diaverse-content/tests/fixtures/content-strategy/baseline/*`
- Logging: analyzer ID/version, evidence counts by category, finding counts by epistemic state/risk, validation/review status, duration, and cost.
- Tests: golden fixtures, missing-source behavior, evidence lineage, contradiction handling, deterministic pre/post-processing, and explicit no-influence assertions against candidate ranking and publish decisions.
- Dependencies: Tasks 6–11.

### Task 13 — Build strategy synthesis, human review, activation, expiry, supersession, and rollback

- [x] Convert validated findings into immutable strategy snapshots without automatic activation.
- Deliverable:
  - Synthesize objectives, audience/problem clusters, query/intent clusters, topic/format priorities, exclusions, evidence gaps, risk notes, freshness, and soft ranking/brief suggestions.
  - Preserve supporting and contradicting finding links and distinguish fact/inference/hypothesis in the snapshot.
  - Require an actor, reason, review checklist, manifest version, source cutoff, and strategy hash for approval/activation/rejection/retirement.
  - Allow at most one active snapshot per scope; activation supersedes the previous version transactionally.
  - Expire stale snapshots and provide one-step rollback to a prior still-valid approved snapshot.
  - Baseline snapshot remains review-only until the later influence flag is separately enabled.
- Expected behavior: model output can propose a strategy, but only a staff actor with settings permission can activate it; all history remains auditable.
- Files:
  - `diaverse-content/src/lib/content-strategy/synthesis.ts`
  - `diaverse-content/src/lib/content-strategy/strategy-snapshots.ts`
  - `diaverse-content/src/lib/content-strategy/review-policy.ts`
  - `diaverse-content/content-operator/seo-analysis/strategy-snapshot.schema.json`
  - `diaverse-content/tests/content-strategy/strategy-snapshots.test.ts`
- Logging: snapshot ID/version/hash, scope, source run IDs, actor ID, action, reason code, expiry, and supersession target; no full strategy body.
- Tests: no auto-approval, permission-ready service boundary, one-active-snapshot invariant, stale activation rejection, rollback, supersession, and evidence-link completeness.
- Dependencies: Tasks 5, 7, and 12.

## Phase 4 — Complete the 25+5 Analyzer System

### Task 14 — Implement niche analyzer wave 1: landscape, market, audience, JTBD, journey, and language

- [x] Implement analyzers 01–09 not already delivered in the baseline.
- Deliverable:
  - Niche Landscape, Market Opportunity, Trend Discovery, Audience Problem, Audience Segmentation, JTBD SEO, Buyer Journey Query Mapper, and Terminology & Language.
  - Keep Search Demand analyzer 03 from Task 12 as the shared dependency.
  - Require evidence-based segment/problem labels and record unknowns instead of inventing personas, pains, market sizes, or trends.
  - Build journey/query outputs as strategic clusters, not guaranteed ranking or conversion claims.
- Expected behavior: wave 1 enriches a review snapshot only when sufficient scoped evidence exists.
- Files:
  - `diaverse-content/content-operator/seo-analysis/analyzers/{niche-landscape,market-opportunity,trend-discovery,audience-problem,audience-segmentation,jtbd-seo,buyer-journey-query,terminology-language}/*`
  - `diaverse-content/src/lib/content-strategy/analyzers/*`
  - `diaverse-content/tests/content-strategy/niche-wave-1.test.ts`
- Logging: analyzer/run IDs, source categories, segment/cluster counts, uncertainty and human-review counts, budgets, and validation status.
- Tests: per-analyzer golden/negative fixtures, unsupported market-size rejection, persona fabrication rejection, dependency behavior, and snapshot merge conflicts.
- Dependencies: Tasks 11–13.

### Task 15 — Implement niche analyzer wave 2: SERP, seasonality, geo, commercial intent, white space, and journey variant

- [x] Implement analyzers 10–15 as a coordinated market-reality layer.
- Deliverable:
  - Reuse SERP Reality and White Space from Task 12; add Seasonality, Geo & Locale, and Commercial Intent.
  - Register Buyer Journey Mapper pack variant 15 as a distinct definition extending analyzer 08, with an adapter only if it has genuinely different inputs/outputs.
  - Prevent duplicate findings when 08 and 15 resolve to the same implementation.
  - Separate informational, navigational, comparison, transactional, and post-purchase intent without fixed keyword-density rules.
- Expected behavior: recommendations remain period/region/device/locale aware and declare when demand or SERP evidence is insufficient.
- Files:
  - `diaverse-content/content-operator/seo-analysis/analyzers/{seasonality,geo-locale,commercial-intent,buyer-journey-pack-variant}/*`
  - `diaverse-content/src/lib/content-strategy/analyzers/*`
  - `diaverse-content/tests/content-strategy/niche-wave-2.test.ts`
- Logging: dimensions, evidence periods, intent/seasonality classification counts, alias resolution, and capability skips; no raw sensitive queries.
- Tests: cross-period/region mismatch, locale handling, alias deduplication, insufficient SERP evidence, commercial-intent uncertainty, and no fixed SEO quota behavior.
- Dependencies: Tasks 9–14.

### Task 16 — Implement niche analyzer wave 3 and keep Platform Ecosystem explicitly not applicable

- [x] Implement analyzers 17–25 and register analyzer 16 as `not_applicable`.
- Deliverable:
  - Reuse E-E-A-T & Trust from Task 12; add Entity Landscape, Regulatory & Risk, Linkability Potential, Entry Difficulty, Monetization Fit, Community Voice, Content Format Fit, and AI Search Opportunity.
  - Require human review for regulatory, medical/health-adjacent, monetization, reputation, and external-action recommendations.
  - Community Voice requires approved, sufficiently sampled evidence and stores only bounded normalized aggregates/excerpts.
  - Linkability cannot trigger outreach/link schemes; Monetization Fit cannot invent economics; AI Search Opportunity cannot promise inclusion in AI answers.
  - Persist Platform Ecosystem as `not_applicable` with the product-decision reason in every coverage report.
- Expected behavior: wave 3 produces risk-aware strategic options, never unverified external actions or certainty claims.
- Files:
  - `diaverse-content/content-operator/seo-analysis/analyzers/{entity-landscape,regulatory-risk,linkability,entry-difficulty,monetization-fit,community-voice,content-format-fit,ai-search-opportunity}/*`
  - `diaverse-content/src/lib/content-strategy/analyzers/*`
  - `diaverse-content/tests/content-strategy/niche-wave-3.test.ts`
- Logging: risk/review reason codes, source categories, suppressed community counts, analyzer status, and budget use; no personal/community identities.
- Tests: risk escalation, unverifiable expertise/monetization rejection, community privacy, blocked external actions, AI-search claim safety, and Platform coverage.
- Dependencies: Tasks 9 and 11–15.

### Task 17 — Implement the five-stage competitor analyzer chain

- [x] Implement the full competitor DAG in the required order.
- Deliverable:
  - Competitive Landscape Mapper.
  - Competitor Strategy Deconstructor.
  - SERP & Demand Gap Analyzer.
  - Weakness & Opportunity Extractor.
  - Competitor-Informed Strategy Builder.
  - Require approved competitor/source scopes, fresh snapshots, explicit observed-vs-inferred fields, and evidence links at every stage.
  - Prevent the final builder from running on missing/failed/unreviewed upstream findings; require human review before snapshot inclusion.
  - Avoid copying competitor text, private data, or unverifiable traffic/revenue estimates.
- Expected behavior: the chain can identify evidence-backed gaps while preserving uncertainty and provenance; partial upstream failure cannot be hidden.
- Files:
  - `diaverse-content/content-operator/seo-analysis/competitors/*`
  - `diaverse-content/src/lib/content-strategy/analyzers/competitors/*`
  - `diaverse-content/tests/content-strategy/competitor-chain.test.ts`
- Logging: competitor source IDs/hosts as approved hashes, stage status, dependency IDs, finding counts, inference counts, and review triggers; no copied page bodies.
- Tests: ordered dependencies, partial failure, stale/unapproved source rejection, observed/inferred separation, copyright-safe output constraints, and mandatory final human review.
- Dependencies: Tasks 9–11 and 13.

## Phase 5 — Operations, Internal API, and Staff Studio

### Task 18 — Add strategy cycle scripts, schedules, health checks, and retention

- [x] Operate strategy analysis as a separate bounded workflow from the daily editorial cycle.
- Deliverable:
  - Add commands for inventory, plan/dry-run, execute, validate, synthesize, expire, and health.
  - Add a resumable strategy cycle with distributed lock/idempotency and modes `read_only`, `shadow`, and `active`; default `read_only`.
  - Schedule low-cost data-health checks more frequently than full strategy refreshes; allow per-source/per-analyzer cadence and manual triggers.
  - Extend systemd installer with separate strategy service/timer units, disabled unless explicitly configured.
  - Add cleanup/retention that preserves approved snapshots and lineage while expiring temporary artifacts according to policy.
- Expected behavior: strategy failures do not block the daily content cycle, and daily content execution cannot silently trigger an unbounded full analysis.
- Files:
  - `diaverse-content/scripts/content-strategy-cycle.ts`
  - `diaverse-content/scripts/content-strategy-health.ts`
  - `diaverse-content/scripts/content-strategy-expire.ts`
  - `diaverse-content/scripts/install-content-autopilot-systemd.sh`
  - `diaverse-content/src/lib/content-strategy/cycle.ts`
  - `diaverse-content/src/lib/content-strategy/retention.ts`
  - `diaverse-content/package.json`
  - `diaverse-content/.env.example`
  - `diaverse-content/tests/content-strategy/cycle.test.ts`
- Logging: cycle/run IDs, lock result, stage status, analyzer counts, budget consumption, capability summary, retention counts, duration, and error codes.
- Tests: disabled/default behavior, dry run, lock contention, resume/retry, partial analyzer failure, independent daily-cycle operation, schedule configuration, and retention invariants.
- Dependencies: Tasks 5 and 10–17.

### Task 19 — Expose read, control, review, approval, and rollback operations through internal content-editor APIs

- [x] Add internal API routes using the existing auth, idempotency, pagination, and error conventions.
- Deliverable:
  - Read endpoints for coverage, capabilities/data health, analyzer definitions, run plans/runs/stages, findings/evidence/contradictions, and strategy snapshots.
  - Mutation endpoints for plan/run/retry/cancel, finding review, snapshot approve/reject/activate/retire/rollback, and provider/manual-evidence validation.
  - Keep activation separate from approval and require idempotency keys for mutations.
  - Return redacted summaries and evidence identifiers/metadata; never return credentials, full prompts, private artifacts, or raw visitor data.
  - Extend Editorial Studio status with strategy readiness, active snapshot freshness, blocked capabilities, and last successful baseline/full run.
- Expected behavior: internal APIs provide complete operational control while fail-closing unauthorized, stale, or illegal transitions.
- Files:
  - `diaverse-content/src/lib/internal/content-editor.ts`
  - `diaverse-content/src/app/internal/v1/content-editor/seo-coverage/route.ts`
  - `diaverse-content/src/app/internal/v1/content-editor/seo-capabilities/route.ts`
  - `diaverse-content/src/app/internal/v1/content-editor/seo-runs/**/route.ts`
  - `diaverse-content/src/app/internal/v1/content-editor/seo-findings/**/route.ts`
  - `diaverse-content/src/app/internal/v1/content-editor/strategy-snapshots/**/route.ts`
  - `diaverse-content/src/app/internal/v1/content-editor/status/route.ts`
  - `diaverse-content/tests/content-strategy/internal-api.test.ts`
- Logging: request/actor/idempotency IDs, permission-independent internal action, resource ID, result/status, duration, and reason code; no request body dumps.
- Tests: auth, validation, pagination, redaction, idempotency, lifecycle conflicts, stale activation, cancellation, rollback, and safe error contracts.
- Dependencies: Tasks 5, 13, and 18.

### Task 20 — Extend the `diaweb` BFF allowlist, types, API client, and hooks

- [x] Proxy all new Staff Studio operations through the same-origin content BFF.
- Deliverable:
  - Add exact allowlist patterns and upstream paths for all strategy endpoints.
  - Map reads to `content:read`; run/retry/cancel and finding review to `content:edit`; snapshot approve/activate/retire/rollback to `content.settings:manage`.
  - Add strict TypeScript response/request types, API error normalization, query keys, polling rules, mutation hooks, cache invalidation, and idempotency-key handling.
  - Preserve existing content studio and unrelated analytics behavior.
- Expected behavior: browser access remains same-origin and RBAC-protected; no wildcard proxy path or direct service URL is introduced.
- Files:
  - `diaweb/frontend/app/api/staff/content/_utils.ts`
  - Existing catch-all route under `diaweb/frontend/app/api/staff/content/content-editor/`
  - `diaweb/frontend/modules/content/studio-types.ts`
  - `diaweb/frontend/modules/content/studio-api.ts`
  - `diaweb/frontend/modules/content/studio-hooks.ts`
  - `diaweb/frontend/__tests__/app/api/staff/content/*`
  - `diaweb/frontend/__tests__/modules/content/*`
- Logging: reuse BFF request ID, upstream path template, permission, status, duration, and normalized error kind; never auth cookies, service tokens, or response bodies.
- Tests: allowlist/denylist, permission matrix, upstream path construction, idempotency propagation, query/mutation behavior, polling terminal states, and redacted failures.
- Dependencies: Task 19.

### Task 21 — Add SEO Strategy review and control surfaces to Editorial Studio

- [x] Add operator UI without turning the Studio into a prompt editor.
- Deliverable:
  - Add focused tabs/panels for Data Health, Analyzer Coverage/Runs, Findings & Contradictions, and Strategy Snapshots.
  - Show readiness, evidence freshness, missing capabilities, cost/time estimates, run progress, epistemic labels, supporting/contradicting evidence, and coverage status.
  - Provide dry-run/run/retry/cancel, review, approve/reject, activate/retire/rollback controls with confirmation, reason input, RBAC hints, and safe optimistic/polling behavior.
  - Show `read_only`, `shadow`, or `active` influence state prominently and warn when a snapshot is stale or only partially covered.
  - Keep raw prompts, credentials, and visitor data out of the UI.
- Expected behavior: staff can understand why a strategy exists, what evidence is missing, and whether it can influence generation before activating it.
- Files:
  - `diaweb/frontend/modules/content/components/EditorialStudioWorkspace.tsx`
  - New components under `diaweb/frontend/modules/content/components/seo-strategy/`
  - `diaweb/frontend/modules/content/studio-types.ts`
  - `diaweb/frontend/modules/content/studio-hooks.ts`
  - `diaweb/frontend/__tests__/modules/content/EditorialStudioWorkspace.test.tsx`
  - `diaweb/frontend/__tests__/modules/content/EditorialStudioPolling.test.ts`
  - New SEO Strategy component tests under `diaweb/frontend/__tests__/modules/content/`
- Logging: client telemetry, if present, records action type, resource ID, state, duration, and error kind only; no finding body or evidence excerpt.
- Tests: loading/empty/error/partial states, epistemic and freshness labels, permission-disabled controls, confirmation/reason requirements, polling/cancel/retry, activation/rollback, and regression of existing Studio tabs.
- Dependencies: Task 20.

## Phase 6 — Controlled Integration with the Existing Article Engine

### Task 22 — Add approved-strategy lineage to candidate generation and ranking

- [x] Integrate strategy as a feature-flagged soft input to the existing candidate pool.
- Deliverable:
  - Load only the active, approved, non-expired snapshot matching area/locale/scope.
  - Add bounded soft features for validated problem/query clusters, intent fit, white-space fit, format fit, risk, and evidence gaps.
  - Record snapshot ID/version/hash and contributing finding/evidence IDs on the selected hypothesis/episode.
  - Keep existing candidate origins and add a distinct strategy-derived origin only when a snapshot actually contributes.
  - Preserve cannibalization, topic policy, source evidence, risk, and quality constraints; normalize weights so strategy cannot dominate.
  - With influence flag off, generate byte-equivalent ranking decisions to the pre-integration path for the same fixtures.
- Expected behavior: approved strategy can change priority transparently, but missing/stale/rejected strategy falls back to current behavior and cannot create publish eligibility.
- Files:
  - `diaverse-content/src/lib/content-learning/candidate-pool.ts`
  - `diaverse-content/src/lib/content-learning/candidate-ranking.ts`
  - `diaverse-content/src/lib/content-learning/features.ts`
  - `diaverse-content/src/lib/content-learning/evidence-ledger.ts`
  - `diaverse-content/src/lib/content-strategy/lineage.ts`
  - `diaverse-content/tests/content-strategy/candidate-integration.test.ts`
- Logging: candidate ID, snapshot ID/hash, contributing finding IDs, bounded feature values, fallback reason, and ranking delta; no raw query text or strategy prose.
- Tests: flag-off parity, approved-only use, scope matching, expiry/rejection fallback, bounded weights, cannibalization preservation, and complete persisted lineage.
- Dependencies: Tasks 5, 13, and 18.

### Task 23 — Feed approved strategy into briefs and agent context through bounded typed fragments

- [x] Extend editorial context without replacing current staged agents or creating a mega-prompt.
- Deliverable:
  - Add a compact typed strategy fragment to candidate strategist/planner/researcher inputs: target problem/query/intent, evidence-backed angle, exclusions, risks, format guidance, and evidence IDs.
  - Enforce maximum item/character/token budgets and deterministic ordering.
  - Keep article factual claims dependent on fresh verified source packs; strategic findings alone are not claim evidence.
  - Persist the exact strategy fragment hash in stage/run lineage.
  - Add reviewer checks for brief/strategy mismatch, unsupported expansion, and accidental transformation of hypotheses into facts.
- Expected behavior: agents receive useful strategic direction while current researcher, evidence auditor, critic, editor, final evaluator, and visual stages remain intact.
- Files:
  - `diaverse-content/src/lib/content-autopilot/context-builder.ts`
  - `diaverse-content/src/lib/content-autopilot/editorial-types.ts`
  - `diaverse-content/src/lib/content-autopilot/editorial-pipeline.ts`
  - `diaverse-content/src/lib/content-autopilot/reviewers/search-intent-seo.ts`
  - `diaverse-content/src/lib/content-autopilot/reviewers/source-fact.ts`
  - `diaverse-content/content-operator/editorial-brief.schema.json`
  - Relevant stage prompt documents under `diaverse-content/content-operator/editorial-stages/`
  - `diaverse-content/tests/content-strategy/editorial-context.test.ts`
- Logging: strategy snapshot/fragment hash, evidence ID counts, truncation/budget events, reviewer codes, and stage IDs; no full prompt or article body.
- Tests: bounded context, deterministic order/hash, stale snapshot omission, hypothesis/fact separation, source-pack requirement, reviewer mismatch, and existing pipeline regression.
- Dependencies: Task 22.

### Task 24 — Preserve and extend publication gates without weakening any existing condition

- [x] Add lineage/freshness checks only as additional blocking conditions when strategy influence is used.
- Deliverable:
  - Keep current publish modes and all existing episode, policy, hypothesis, evidence, critic, style, source, revision, and visual checks unchanged.
  - For strategy-influenced episodes, require an active approved snapshot, matching persisted hash/scope, non-expired evidence cutoff, and complete strategy lineage.
  - Do not require strategy for legacy/non-strategy episodes unless the feature is intentionally configured as mandatory later.
  - Add explicit reason codes for missing, stale, mismatched, unapproved, or incomplete strategy lineage.
  - Prove that no new analyzer state can turn an existing blocked publish decision into allowed.
- Expected behavior: strategy integration can add blockers and explanations; it can never remove a blocker or substitute for verified article evidence.
- Files:
  - `diaverse-content/src/lib/content-autopilot/publish-gate.ts`
  - `diaverse-content/src/lib/content-autopilot/publish.ts`
  - `diaverse-content/src/lib/content-autopilot/governance.ts`
  - `diaverse-content/tests/content-autopilot/publish.test.ts`
  - `diaverse-content/tests/guides/publish-gate.test.ts`
  - `diaverse-content/tests/content-strategy/publish-gate-regression.test.ts`
- Logging: publish decision, all blocking reason codes, snapshot/hash match state, evidence status, risk/mode, and guide/run/episode IDs; no draft content.
- Tests: full existing gate regression matrix plus strategy missing/stale/hash mismatch/unapproved cases and a monotonic-safety property test.
- Dependencies: Tasks 22–23.

### Task 25 — Use outcomes and Metrica aggregates for bounded strategy refresh and learning

- [x] Close the loop without allowing noisy analytics to rewrite hard policy.
- Deliverable:
  - Join privacy-safe behavior aggregates, search outcomes, content outcomes, machine evaluations, and human decisions by canonical guide/path and declared windows.
  - Require maturity, minimum sample, privacy, confidence, and comparable-window checks before proposing a strategy refresh.
  - Store refresh findings as new evidence; create a superseding draft snapshot instead of editing or auto-activating the current strategy.
  - Allow only bounded soft-weight proposals; hard policy, source policy, publish gate, and risk rules remain immutable to this learner.
  - Detect regressions and trigger review/rollback recommendations, not automatic destructive content changes.
- Expected behavior: the system learns from aggregate outcomes while low-sample, suppressed, seasonal, contradictory, or immature data cannot activate changes.
- Files:
  - `diaverse-content/src/lib/content-learning/outcome-snapshots.ts`
  - `diaverse-content/src/lib/content-learning/strategy-proposals.ts`
  - `diaverse-content/src/lib/content-learning/confidence.ts`
  - `diaverse-content/src/lib/content-strategy/outcome-learning.ts`
  - `diaverse-content/tests/content-strategy/outcome-learning.test.ts`
- Logging: aggregate window, sample/suppression/maturity states, snapshot IDs, confidence range, proposed bounded deltas, and review reason; no visitor identifiers.
- Tests: threshold boundaries, suppressed/immature/seasonal data, canonical joins, contradictory outcomes, bounded deltas, no hard-policy mutation, and no auto-activation.
- Dependencies: Tasks 8, 13, and 22–24.

## Phase 7 — Verification, Baseline Run, Rollout, and Documentation

### Task 26 — Run the full verification matrix, execute the first read-only analyses, and document rollout

- [ ] Complete implementation only after code, migration, safety, UI, and operational verification pass.
- Status 2026-07-14: code and documentation verification passed; `diaverse-content` was pushed to `dev`, cherry-picked to `main`, deployed on the production content server as release `20260714044620-da9e81b`, and migration `20260713210000_add_content_seo_strategy_layer` was applied with new strategy flags explicitly set to `false`. The read-only baseline analyses, Staff Studio snapshot review, shadow influence, and active-soft rollout gates remain pending.
- Deliverable:
  - Run all unit/integration/contract/adversarial suites in both affected repositories.
  - Run disposable-database migration checks before any dev/prod deployment.
  - Deploy migration with all new flags off, deploy compatible code, bootstrap manifest, and verify health/capabilities.
  - Execute data inventory and the five baseline analyses in `read_only`; review coverage, contradictions, evidence lineage, cost, and missing providers.
  - Create a draft strategy snapshot, review it in Staff Studio, and verify that candidate ranking, generation, and publish decisions remain unchanged.
  - Only after explicit human approval, enable `shadow` candidate influence; compare old/new rankings and briefs without publishing changes.
  - Promote one scope at a time to active soft influence; keep publish mode and existing gate configuration unchanged during rollout.
  - Document rollback/kill switches, migration order, source credentials, Metrica privacy settings, provider approval procedure, refresh cadence, budget alerts, and incident handling.
  - Update GBrain after final source/docs changes.
- Expected behavior: the first five real analyses produce an auditable human-reviewed baseline, and every later influence step is reversible, observable, and independently gated.
- Files:
  - `docs/features/seo-intelligence.md` (new canonical feature document)
  - `docs/features/autonomous-editor.md`
  - `docs/architecture/content-factory.md`
  - `docs/runbooks/autonomous-editor.md`
  - `docs/README.md` (targeted navigation addition only; preserve its current unrelated edits)
  - `diaverse-content/content-operator/codex-runbook.md`
  - `diaverse-content/content-operator/search-data/README.md`
  - `diaverse-content/.env.example`
  - Verification fixtures/reports under `diaverse-content/tests/fixtures/content-strategy/`; do not commit secrets or raw production exports.
- Logging: deployment/cycle IDs, manifest and migration hashes, capability summary, analyzer status/cost/duration, snapshot review actions, shadow deltas, gate reason distributions, rollback events, and health status.
- Tests and commands:
  - In `diaverse-content`: `npm run prisma:validate`, disposable `npm run db:migrate:deploy`, `npm test`, `npm run typecheck`, `npm run lint`, `npm run build`, `npm run content:autopilot:health`, and the new strategy health command.
  - In `diaweb`: `npm --prefix frontend test -- __tests__/modules/content __tests__/app/api/staff/content`, `npm --prefix frontend run typecheck`, `npm --prefix frontend run lint`, and `npm --prefix frontend run build`.
  - At workspace root: `powershell -ExecutionPolicy Bypass -File scripts/docs-health.ps1`, targeted/manual source checks, then `powershell -ExecutionPolicy Bypass -File scripts/gbrain-sync.ps1`.
  - Manual Staff Studio smoke: view coverage/data health, plan read-only run, run/retry/cancel, inspect evidence/contradictions, approve/reject snapshot, activate/rollback in a non-production scope, and verify RBAC-denied states.
  - Safety acceptance: existing publish-gate tests pass unchanged; strategy-influenced fixtures add blockers only; logs/artifacts pass secret and sensitive-data scans.
- Dependencies: Tasks 1–25.

## Rollout Gates

1. **Schema gate:** additive migration passes clean and representative disposable PostgreSQL checks; new flags remain off.
2. **Inventory gate:** source/capability report is complete and missing data is represented as unavailable, never zero.
3. **Read-only gate:** five baseline analyzers finish or explicitly skip, with full evidence lineage and no editorial influence.
4. **Human-review gate:** contradictions and limitations are reviewed; a strategy snapshot is approved by an authorized staff actor.
5. **Shadow gate:** candidate ranking/brief deltas are measured without changing generation or publishing.
6. **Active-soft gate:** approved strategy affects one bounded scope while publish gates and publish mode remain unchanged.
7. **Expansion gate:** remaining niche and competitor analyzers are enabled by capability and risk group, not all at once.
8. **Behavior-learning gate:** Metrica/outcomes influence only draft refresh proposals after privacy, sample, maturity, and confidence checks.

Any failed gate is handled by disabling the relevant flag, preserving audit data, and returning to the last safe behavior. Database rollback is forward-compatible and flag-based; no destructive table drop is part of emergency rollback.

## Commit Plan

Commits remain repository-local and must never include unrelated dirty files.

1. `diaverse-content`: `feat(content-strategy): add analyzer manifest and guarded config` — Tasks 1–2.
2. `diaverse-content`: `feat(content-strategy): add durable strategy persistence` — Tasks 3–5, including the additive Prisma migration.
3. `diaverse-content`: `feat(content-strategy): add evidence inventory and providers` — Tasks 6–9.
4. `diaverse-content`: `feat(content-strategy): add analyzer dag and baseline slice` — Tasks 10–13.
5. `diaverse-content`: `feat(content-strategy): implement full seo analyzer catalog` — Tasks 14–17.
6. `diaverse-content`: `feat(content-strategy): add operations and internal api` — Tasks 18–19.
7. `diaweb`: `feat(content-studio): add seo strategy controls` — Tasks 20–21; stage only content Studio/BFF files, never current analytics work.
8. `diaverse-content`: `feat(content-strategy): integrate approved strategy with editorial pipeline` — Tasks 22–25.
9. `diaverse`, `diaverse-content`, and any affected `diaweb` docs/tests: `docs(content-strategy): document verified rollout` — Task 26, committed separately per repository.

Before each commit: inspect repository-local `git status` and `git diff`, stage explicit paths only, run the task-specific tests, and verify that no secret, production export, generated model artifact, or unrelated user change is included.

## Completion Criteria

- All 26 tasks are checked and all 32 analyzer/utility definitions are accounted for in the machine-readable manifest.
- Additive migration has passed clean and representative disposable PostgreSQL verification and is documented for safe deploy/rollback.
- The five baseline analyses have executed in read-only mode against real configured evidence, or have explicit capability-blocked records with no fabricated output.
- Findings and strategy snapshots have complete run/prompt/schema/manifest/evidence lineage and fact/inference/hypothesis labels.
- Staff can review, approve, activate, expire, supersede, and roll back snapshots through the RBAC-protected Studio.
- Only active approved fresh snapshots can influence candidates/briefs, and the influence is bounded, logged, and reversible.
- Existing evidence, critic, visual, risk, and publish gates remain intact; tests prove monotonic publication safety.
- Metrica data is aggregate, privacy-thresholded, separately stored, and never treated as search-demand evidence.
- SERP/competitor/community automation remains capability- and policy-gated; no unapproved scraper or external action exists.
- Full tests, lint, typecheck, builds, health checks, docs health, and GBrain sync pass.

## Next Command

After reviewing this plan, execute it from the workspace root with:

`$aif-implement "C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\seo-intelligence.md"`
