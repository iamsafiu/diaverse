# Implementation Plan: Content Factory Codex Operator And AI Cofounder Retirement

Branch: none
Created: 2026-06-26
Mode: fast plan, no branch creation

## Settings

- Testing: yes
- Logging: standard
- Docs: yes
- Roadmap: none found in `.ai-factory/ROADMAP.md`
- GBrain/daily: do not update by explicit user instruction

## Goal

Move Diaverse content operations to a simpler model:

- `diaverse-content` is the only active runtime for public content, drafts, metrics,
  article review, and publication.
- Local Codex sessions act as the AI operator. The user periodically connects to the
  server, starts Codex, asks it to analyze metrics, generate topics/articles, and
  import draft-only content.
- The server does not need an LLM API key, Claude CLI OAuth, autonomous schedules,
  Telegram AI Cofounder reporting, or an always-on AI Cofounder bridge.
- `diaverse-ai-cofounder` is retired from the critical path after its useful content
  strategy, topic matrix, prompts, and safety rules are migrated into `diaverse-content`.

## Requirements Snapshot

- Keep article generation draft-only. Generated content must never publish
  automatically.
- Preserve the two content streams:
  - `club`: Club 10000 SEO and paid club funnel.
  - `game`: cold acquisition positioning Diaverse as an MMO-RPG step tracker.
- AI remains an internal production tool, not a public topic cluster.
- Codex must be able to consume content metrics, topic matrix, editorial rules, and
  draft import contracts from inside `diaverse-content`.
- Existing content import and analytics behavior must continue to work.
- AI Cofounder server runtime should be stopped/disabled safely, not destructively
  deleted before the migration is verified.

## Reconnaissance Notes

- The foreign server was rebooted by the user and SSH access was reachable during
  planning with hostname `discontent`.
- `diaverse-content` already has:
  - public learn routes under `src/app/ru/learn/*`
  - admin guide editor under `src/app/admin/guides/*`
  - per-guide analytics under `src/app/admin/guides/[id]/analytics`
  - internal draft import route at `src/app/internal/v1/imports/drafts/route.ts`
  - import parser at `src/lib/internal/imports.ts`
  - metrics helpers under `src/lib/analytics/*`
  - anti-AI text checks under `src/lib/guides/anti-ai-check.ts`
- The current import contract accepts `source_service = aibot | ai-cofounder`.
  The new model should add a neutral source such as `codex` or
  `content-operator`, while keeping `ai-cofounder` as legacy compatibility only
  until old imports are no longer needed.
- `diaverse-ai-cofounder` already contains reusable source material:
  - `projects/diaverse/content-playbook.md`
  - `projects/diaverse/topic-matrix.ru.md`
  - `org/*.md`
  - `agents/diaverse-content-strategist/*`
  - `agents/diaverse-article-drafter/*`
  - `skills/article-writing/references/*`

## Affected Repositories

- `diaverse-content`: primary owner for Codex operator context, metrics exports,
  draft import tooling, dashboard improvements, tests, and docs.
- `diaverse-ai-cofounder`: source-only during migration; then archive/retire runtime
  docs and stop server services.
- root `diaverse`: update workspace AI context/docs so AI Cofounder is no longer
  described as an active runtime dependency.
- `diaweb`, `diaverseapi`, `aibot`, `diaverse-mobile`, `club10000-bot`,
  `diaverse-auth-bot`: not expected to change in this phase.

## Architecture Decisions

1. Use `diaverse-content` as the active content control plane.
2. Use Codex as a manual operator, not a persistent server daemon.
3. Do not require `ANTHROPIC_API_KEY` or Claude CLI auth on the content server.
4. Keep generated drafts reviewable in `/admin/guides/*`.
5. Store content strategy and operator instructions close to the content engine,
   not in a retired AI Cofounder runtime.
6. Keep AI Cofounder GitLab history as an archive first; only delete later if the
   user explicitly confirms after successful content runs.

## Phase 1 - Freeze AI Cofounder Runtime Safely

- [x] Task 1: Inspect the rebooted foreign server and stop only AI Cofounder runtime services
  - Files/repos:
    - operational target: existing AI Cofounder deployment directory on the foreign server
    - optional docs update: `diaverse-ai-cofounder/infrastructure/foreign-server/README.md`
  - Deliverable:
    - confirm SSH access and current service/container state after reboot
    - stop AI Cofounder containers/systemd units/unfinished builds if present
    - disable AI Cofounder autostart/schedules if configured
    - preserve releases, env files, volumes, logs, and GitLab repo history
    - do not touch `diaverse-content` services during this task
  - Logging:
    - log only service names, statuses, container names, command outcomes, and timestamps
    - do not log secrets, env values, private keys, tokens, raw SSH commands with key paths,
      or full server inventory
  - Dependencies:
    - none

- [x] Task 2: Mark AI Cofounder as retired from the active architecture
  - Files/repos:
    - root `.ai-factory/DESCRIPTION.md`
    - root `.ai-factory/ARCHITECTURE.md`
    - possible root docs under `docs/architecture/` if a content factory doc exists
    - optional `diaverse-ai-cofounder/ARCHIVED.md`
  - Deliverable:
    - update architecture wording from active AI Cofounder runtime to archived/R&D source
    - state that content operations now run through `diaverse-content` plus manual Codex sessions
    - remove AI Cofounder from active dependency diagrams and active server runbooks
    - keep a note that the repo is retained only for historical reference until explicit deletion
  - Logging:
    - no runtime logs; commit/diff summary may mention changed files only
    - do not include server addresses, keys, env values, or private infrastructure details
  - Dependencies:
    - Task 1

## Phase 2 - Move Content Brain Into diaverse-content

- [x] Task 3: Create Codex operator context inside `diaverse-content`
  - Files/repos:
    - new `diaverse-content/content-operator/README.md`
    - new `diaverse-content/content-operator/codex-runbook.md`
    - new `diaverse-content/content-operator/content-playbook.ru.md`
    - new `diaverse-content/content-operator/topic-matrix.ru.md`
    - new `diaverse-content/content-operator/claim-safety.md`
    - new `diaverse-content/content-operator/draft-output-contract.md`
  - Deliverable:
    - migrate the useful Club 10000 and MMO-RPG step tracker strategy from AI Cofounder
    - define the exact Codex workflow: analyze metrics -> choose topics -> write drafts
      -> validate/import draft-only -> human review -> publish manually
    - include CTA rules, forbidden claims, public AI-topic ban, and draft-only requirements
    - make the files self-contained so a future Codex session can start from this repo
      without reading `diaverse-ai-cofounder`
  - Logging:
    - no runtime logs; generated docs must avoid secrets, private metrics, hidden formulas,
      antifraud details, and unannounced roadmap
  - Dependencies:
    - Task 2

- [x] Task 4: Add a neutral Codex/content-operator draft source to the import contract
  - Files/repos:
    - `diaverse-content/src/lib/internal/imports.ts`
    - `diaverse-content/tests/content-imports.test.ts`
    - optional `diaverse-content/content-operator/draft-output-contract.md`
  - Deliverable:
    - accept `source_service = codex` or `content-operator` for new manual Codex imports
    - keep `ai-cofounder` accepted only as legacy compatibility, if needed
    - keep `status=draft` and reject `auto_publish` exactly as today
    - update tests to cover the new source service and preserve old idempotency behavior
  - Logging:
    - import logs must remain structured and minimal: request id, actor id, source service,
      draft id, version, import id, guide id, area, locale, status
    - do not log full article bodies, prompts, tokens, secrets, or raw source metadata values
  - Dependencies:
    - Task 3

## Phase 3 - Add Codex-Friendly Metrics And Generation Tooling

- [x] Task 5: Add a content performance service and internal JSON export for Codex
  - Files/repos:
    - new `diaverse-content/src/lib/analytics/content-performance.ts`
    - new `diaverse-content/src/app/internal/v1/analytics/content-performance/route.ts`
    - possible updates to `diaverse-content/src/lib/internal/auth.ts`
    - new or updated tests under `diaverse-content/tests/`
  - Deliverable:
    - provide article-level and stream-level metrics for Codex analysis
    - include area, locale, slug, title, status, published date, guide type, target keyword,
      views, CTA clicks, feedback counts, H1 stats, draft import source, and topic ids
    - support filters for `area`, `locale`, `days`, `status`, and `limit`
    - return empty optional sections safely where Search Console/revenue adapters are not wired yet
  - Logging:
    - log internal export access at INFO with route, actor, request id, filters, row count,
      and duration
    - log validation failures at WARN
    - do not log reader identifiers, raw cookies, authorization headers, env values, or
      full article content
  - Dependencies:
    - Task 4

- [x] Task 6: Add CLI scripts for local/server Codex content runs
  - Files/repos:
    - new `diaverse-content/scripts/content-operator-context.ts`
    - new `diaverse-content/scripts/content-operator-import.ts`
    - update `diaverse-content/package.json`
    - new tests or fixtures under `diaverse-content/tests/`
  - Deliverable:
    - add `pnpm content:operator:context` to export a compact metrics + rules + topic
      context pack for a Codex session
    - add `pnpm content:operator:import` to validate and import generated draft payloads
      through the existing internal draft import contract
    - write generated run artifacts to a gitignored local directory such as
      `.content-runs/<run-id>/`
    - avoid any dependency on server-side LLM API keys
  - Logging:
    - CLI logs should include run id, filters, output paths, imported draft ids, guide ids,
      skipped duplicates, and high-level errors
    - do not print full article bodies by default; allow an explicit preview flag if needed
    - do not log tokens, internal JWTs, cookies, or env values
  - Dependencies:
    - Tasks 3-5

- [x] Task 7: Add a content operations dashboard for stream-level decisions
  - Files/repos:
    - new `diaverse-content/src/app/admin/content-ops/page.tsx`
    - possible new `diaverse-content/src/app/admin/content-ops/ContentOpsView.tsx`
    - reuse `diaverse-content/src/lib/analytics/content-performance.ts`
  - Deliverable:
    - show Club 10000 and game stream health in one admin page
    - surface articles with low CTA rate, high views/no CTA, stale published date,
      missing topic/CTA metadata, and draft backlog
    - show clear next-action labels: update, expand cluster, improve CTA, keep, archive
    - link each row to existing guide edit and per-guide analytics pages
  - Logging:
    - no client logs in normal operation
    - server-side data load may log route, filters, row count, and duration at INFO
    - do not log raw article bodies, private user data, or sensitive headers
  - Dependencies:
    - Task 5

## Phase 4 - Guardrails, Docs, And Verification

- [x] Task 8: Add validation for Codex-generated content payloads and strategy files
  - Files/repos:
    - new `diaverse-content/src/lib/content-operator/validate-draft.ts`
    - new `diaverse-content/tests/content-operator.test.ts`
    - possible updates to `diaverse-content/src/lib/guides/anti-ai-check.ts`
  - Deliverable:
    - validate required fields before import: source service, draft id, title, slug,
      area, locale, target keyword, CTA, markdown hash, topic ids, and source metadata
    - block auto-publish, forbidden claims, public AI-topic framing, hidden mechanics,
      internal formulas, and investment/medical guarantees
    - fail fast with actionable validation messages for Codex to repair the draft
  - Logging:
    - validator logs only rule ids and failed field names
    - do not log full draft text unless an explicit local debug flag is set
  - Dependencies:
    - Tasks 3, 4, and 6

- [x] Task 9: Document the new manual Codex operating flow
  - Files/repos:
    - `diaverse-content/README.md`
    - `diaverse-content/content-operator/codex-runbook.md`
    - root architecture docs from Task 2, if needed
  - Deliverable:
    - document how the user connects to the server, starts Codex, exports metrics,
      asks for analysis, generates drafts, imports drafts, and reviews in admin
    - document required env vars for content imports/analytics only
    - explicitly state that no LLM API key is required on the server for this model
    - document rollback: stop using Codex scripts, keep existing admin/manual editing
  - Logging:
    - no runtime logs; docs must not include secret values, private key paths, server IPs,
      tokens, or raw env values
  - Dependencies:
    - Tasks 1-8

- [x] Task 10: Verify locally and on the server with one dry content run
  - Files/repos:
    - `diaverse-content`
    - operational target: content server deployment
  - Deliverable:
    - run `pnpm test`, `pnpm typecheck`, and targeted content-operator tests
    - run the new metrics/context export command against local or server data
    - create one sample Codex draft payload and import it as `status=draft`
    - confirm the draft appears in admin and is not published
    - confirm AI Cofounder runtime remains stopped/disabled and no schedules are active
  - Logging:
    - verification notes may include command names, pass/fail status, draft/import ids,
      guide ids, and service status
    - do not log full generated article bodies, env values, tokens, private server details,
      or raw SSH command material
  - Dependencies:
    - Tasks 1-9
  - Status 2026-06-26:
    - `pnpm test` passed in `diaverse-content`
    - `pnpm typecheck` passed in `diaverse-content`
    - `pnpm build` passed in `diaverse-content`
    - `pnpm content:operator:import -- --dry-run` passed with a valid Codex draft payload
    - local `pnpm content:operator:context` starts but cannot complete without local DB env;
      server context export passed against the deployed content DB
    - foreign server confirms AI Cofounder runtime remains stopped: no matching Docker
      containers, systemd services, user services, or timers
    - foreign server `diaverse-content-app` and `diaverse-content-db` are healthy after
      redeploy from release `20260626110731`
    - `CONTENT_IMPORTS_ENABLED` was enabled with a backup of the prior env file; real
      internal import succeeded as a draft-only guide with guide id
      `cmqufe9jf0001qog7kos20jni` and import id `cmqufe9kl0003qog7f6z72y94`
    - DB verification confirms the imported guide status is `draft`, area `game`,
      locale `ru`, and source service `codex`
    - post-import `pnpm content:operator:context -- --area game --days 30 --limit 5`
      returned `rowCount=1`, so future Codex runs can see imported draft context

## Verification Plan

- `diaverse-content`
  - `pnpm test`
  - `pnpm typecheck`
  - `pnpm build` if UI/dashboard or route changes are made
  - targeted script smoke:
    - `pnpm content:operator:context -- --days 30 --area game`
    - `pnpm content:operator:import -- --file <local-test-payload>`

- `diaverse-ai-cofounder`
  - no feature build required if only archived docs are changed
  - if code/runtime files are edited, run the smallest relevant existing check

- Server smoke
  - SSH access works after reboot
  - AI Cofounder runtime is stopped/disabled
  - content factory health endpoint remains healthy
  - one draft-only import succeeds
  - no schedules or auto-publish paths are active

## Commit Plan

- **Commit 1 (`diaverse-content`)** after Tasks 3-4:
  - `feat(content): add codex content operator context`
- **Commit 2 (`diaverse-content`)** after Tasks 5-7:
  - `feat(content): add content operator metrics and dashboard`
- **Commit 3 (`diaverse-content`)** after Tasks 6 and 8:
  - `feat(content): add codex draft import tooling`
- **Commit 4 (`diaverse-content`)** after tests/docs:
  - `test(content): cover codex content operator flow`
- **Commit 5 (root `diaverse`)** after Tasks 2 and 9:
  - `docs(workspace): retire ai cofounder runtime`
- **Commit 6 (`diaverse-ai-cofounder`, optional)** if archive docs are edited:
  - `docs(cofounder): mark runtime archived`

## Open Risks

- Existing analytics are mostly first-party guide counters. Search Console, Yandex,
  install attribution, club conversion, and revenue attribution may need later adapters.
- If `diaverse-content` production env does not expose a safe internal import token for
  operator scripts, Task 6 must add or document the minimal env contract.
- The current import source name `ai-cofounder` may exist in historical rows; do not
  rename old DB data in this phase.
- Deleting the AI Cofounder repo immediately would lose useful context and rollback
  options. Archive first, delete only after successful Codex-driven content runs.
- Codex-driven "auto" generation is still manually initiated by the user. True unattended
  generation would require a server-side LLM credential or another hosted AI runtime.

## Definition Of Done

- `diaverse-content` contains all content strategy, topic matrix, safety rules, and
  Codex run instructions needed for future content sessions.
- Codex can export metrics/context, generate draft payloads, validate them, and import
  draft-only articles without AI Cofounder.
- Admin has a stream-level content operations view for deciding what to update,
  expand, or generate next.
- AI Cofounder runtime is stopped/disabled on the foreign server and removed from the
  active architecture.
- No server-side LLM API key is required for the new manual Codex workflow.
- Existing content imports, analytics, admin editing, and publication review still work.
