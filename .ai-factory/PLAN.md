# Implementation Plan: Telegram Codex Ops Agent

Branch: none
Created: 2026-06-26
Mode: fast plan, no branch creation

## Settings

- Testing: yes
- Logging: verbose for the new ops-agent flows, safe and sanitized for production
- Docs: yes
- Roadmap: none found in `.ai-factory/ROADMAP.md`
- GBrain: use local GBrain first for architecture/code navigation and run targeted sync after meaningful docs/code changes
- Runtime: deploy as an internal Telegram ops bot on the trusted bots server; no public Codex web UI or exposed app-server
- LLM/Codex: use a server-side Codex/GPT runner abstraction; exact CLI/SDK install command must be verified against current official OpenAI docs during implementation

## Goal

Build an internal Telegram operations agent for Diaverse. A trusted operator can tag the bot in Telegram with a support task, for example:

```text
@diaverse_ops_bot пользователь 123 оплатил, но начисление не пришло. Проверь и реши.
```

The bot should:

- create an ops case and remember the full lifecycle in a sanitized case memory;
- look up a simple text playbook library before doing fresh investigation;
- look up similar past cases from the case database;
- run safe diagnostics against Diaverse services, read-only database access, and code context;
- use a Codex/GPT session on the server to analyze cause and propose a fix;
- request approval according to action risk before product mutations;
- execute only registered audited repair actions through `diaverseapi`, not arbitrary production write SQL;
- auto-author missing repair actions as code when no existing action can safely solve a repeated problem;
- return a Telegram summary: what was repaired, why it broke, what code/config should be fixed, and what was stored for next time;
- speak in a light internal humorous tone while keeping money, security, approvals, and audit records factual.

## Research Context

Local `.ai-factory/RESEARCH.md` active summary now covers this feature (`Telegram Codex ops-agent interaction modes`), so its chat/case-mode decisions are carried into Task 1 and the Telegram runtime tasks.

Context gathered for this plan:

- GBrain docs confirm that the workspace is a coordination repo and cross-repo implementation belongs in child repositories.
- Existing Telegram/bot deployment patterns already live in `aibot`, `club10000-bot`, and `diaverse-auth-bot`.
- Existing signed internal HTTP patterns exist between `aibot` and `diaverseapi` for Club10000 delivery.
- `diaverseapi` already owns cabinet payments, payment sessions, finalizers, RBAC, and cabinet logging.
- The safest MVP is an `aibot` ops-agent runtime that calls narrow signed `diaverseapi` ops endpoints for diagnostics and approved actions.
- The knowledge base should stay simple: Markdown playbooks are the source of truth for "how to solve this class of issue"; the database stores concrete case history, action runs, and links back to playbook ids.
- The agent may receive broad read-only database access for investigation, but product mutations still go through registered actions or generated action code that passed automated safety gates.
- The Telegram bot should support both free-form Chat mode and operational Case mode. Casual chat must not create cases or execute repair actions unless the message is classified as an incident or the operator explicitly uses `/ops`.

## Affected Repositories

- `aibot`: primary MVP runtime for Telegram ops agent, Codex runner adapter, case memory, voice layer, orchestration, tests, and deployment entrypoint.
- `diaverseapi`: owner of safe signed diagnostics/actions for payment investigations and audited repairs.
- root `diaverse`: this plan, cross-repo docs/runbooks, GBrain sync, and daily work entry.
- `diaweb`: no MVP implementation; possible future staff dashboard for ops cases.
- `diaverse-mobile`: no MVP implementation.
- `diaverse-content`: no MVP implementation.
- `club10000-bot`: no MVP implementation unless future Club10000-specific case actions are added.
- `diaverse-auth-bot`: no MVP implementation.

## Architecture Decisions

1. Telegram is the operator UI, not the authority for product mutations.
2. `aibot` owns the MVP runtime because it already has Python, aiogram, OpenAI settings, database access, worker/API patterns, and bots-server deployment.
3. `diaverseapi` remains the owner of product state changes. The agent never runs arbitrary write SQL against production.
4. The agent can use a dedicated read-only database role for investigation. That role may inspect known product schemas but cannot run DDL, `INSERT`, `UPDATE`, `DELETE`, locks, or long-running statements.
5. Codex runs inside a controlled server runner with a dedicated workspace, least-privilege credentials, and read-only defaults for diagnostics.
6. Playbooks are Markdown files plus a small YAML index. They are the primary knowledge base because they are easy for humans and AI to read, diff, review, and update.
7. Case memory stores concrete sanitized incidents, fingerprints, action results, closure summaries, and links to playbook ids. It does not duplicate the full playbook body into the database.
8. If no registered action can solve a repeated issue, Codex may auto-author a new action as code without manual code review, but only inside a generated patch/worktree path that must pass automated policy checks, tests, static denylist checks, migration checks when relevant, and feature-flag activation before runtime use.
9. A generated action cannot grant itself arbitrary authority. It must be registered with metadata: owner, risk level, preview support, idempotency, allowed service calls, tests, rollback notes, and audit fields.
10. Production execution uses registered actions only. Risk policy decides whether execution needs Telegram approval, automatic approval, or break-glass handling; all paths require idempotency keys and audit events.
11. Similar-case lookup uses playbook index matching first, exact/fingerprint DB lookup second, then safe full-text search. Embeddings or pgvector can be added later behind an explicit privacy/config decision.
12. The Telegram bot supports two modes:
    - Chat mode for ordinary conversation, lightweight Codex/LLM responses, playbook explanations, and case summaries without repair execution.
    - Case mode for operational incidents, playbook selection, similar-case lookup, read-only diagnostics, Codex investigation, and action preview/execute by risk policy.
13. Free-form Telegram messages are intent-classified before routing. Explicit commands override inference.
14. Follow-up messages should resume an existing Codex thread or case where possible instead of starting a fresh run for every message.
15. Humorous tone is a Telegram rendering layer only. Approval prompts, audit records, security errors, and money-impacting confirmations stay factual.
16. The implementation should be extractable into a future standalone `diaverse-ops-agent` repo if the runtime grows beyond `aibot`.

## Commit Plan

- **Commit 1** (after tasks 1-3): `docs(ops): define Codex ops agent contracts`
- **Commit 2** (after tasks 4-6): `feat(api): add ops diagnostics and action registry`
- **Commit 3** (after tasks 7-10): `feat(aibot): add playbooks, case memory, and Telegram runtime`
- **Commit 4** (after tasks 11-15): `test(ops): verify generated actions and rollout`

## Tasks

### Phase 1: Contracts And Safety Model

- [x] Task 1: Document the ops-agent architecture and runbook
  - Files:
    - `docs/architecture/ops-agent.md`
    - `docs/runbooks/ops-agent.md`
    - `docs/README.md`
  - Deliverable:
    - define the Telegram -> `aibot` -> Codex runner -> `diaverseapi` flow;
    - define supported MVP case type: "paid but not credited";
    - define the text playbook system: `playbooks/index.yml` plus one Markdown file per problem class;
    - define read-only database investigation rules;
    - define action registry, generated-action safety gates, approval levels, rollback expectations, incident closure format, and case-memory rules;
    - define Chat mode vs Case mode, intent classification, thread persistence, and the required `/chat`, `/ops`, `/case`, `/status`, `/close`, and `/mode chat|ops` commands;
    - define the Telegram tone policy with examples of allowed light humor and disallowed jokes around harm, money loss, access, security, or approvals.
  - Logging:
    - no runtime logging;
    - docs must not include secrets, private server inventory, internal IPs, credentials, raw provider payloads, or raw production data.
  - Dependencies:
    - none

- [x] Task 2: Define shared ops API contracts and schemas
  - Files:
    - `diaverseapi/app/ops_agent/schemas.py`
    - `diaverseapi/app/ops_agent/__init__.py`
    - `aibot/app/ops_agent/schemas.py`
    - `aibot/app/ops_agent/__init__.py`
  - Deliverable:
    - define request id, case id, actor id, chat id, target user/payment identifiers, playbook id, fingerprint, idempotency key, approval id, action kind, and sanitized diagnostic payloads;
    - define action registry metadata: risk level, supports preview, idempotency scope, required guards, allowed service methods, required tests, rollback notes, and audit fields;
    - define generated-action proposal metadata: proposed action id, missing capability, code patch path, test command list, safety gate result, activation status, and failure reason;
    - define common response envelopes for diagnostics, proposed action, generated action proposal, approval required, action executed, and action rejected;
    - include versioned contract fields so the bot and API can evolve without silent breakage.
  - Logging:
    - schemas should separate safe log fields from raw payload fields;
    - never log Telegram message text, provider payloads, auth headers, env values, or full stack traces with secrets.
  - Dependencies:
    - Task 1

- [x] Task 3: Add environment/config preflight for the ops agent
  - Files:
    - `aibot/core/config.py`
    - `aibot/.env.example`
    - `diaverseapi/app/core/settings.py`
    - `diaverseapi/.env.example`
  - Deliverable:
    - add disabled-by-default flags for ops-agent bot, signed internal ops API, Codex runner, and optional memory embeddings;
    - add read-only database connection settings for investigation, separate from application write credentials;
    - add allowlisted Telegram chat/user ids;
    - add HMAC key id/secret settings for `aibot` -> `diaverseapi`;
    - add Codex runner workspace, `CODEX_HOME`, timeout, concurrency, sandbox mode, generated-action worktree, generated-action policy, and auto-activation settings;
    - fail closed when required config is missing.
  - Logging:
    - startup logs may report enabled/disabled feature flags and redacted key ids;
    - never print tokens, HMAC secrets, OpenAI/Codex credentials, database URLs, or Telegram bot tokens.
  - Dependencies:
    - Task 1

### Phase 2: `diaverseapi` Safe Ops Surface And Action Registry

- [x] Task 4: Add signed internal ops-agent API auth and router
  - Files:
    - `diaverseapi/app/ops_agent/security.py`
    - `diaverseapi/app/ops_agent/api.py`
    - `diaverseapi/app/main.py` or existing API router registration file
    - `diaverseapi/tests/test_ops_agent_security.py`
  - Deliverable:
    - implement HMAC verification with timestamp, key id, body digest, request id, replay window, and structured rejection reasons;
    - register internal-only routes behind feature flag;
    - align implementation with existing signed internal API patterns already used for Club10000 integrations.
  - Logging:
    - log safe rejection reason, request id, key id, route, and timestamp skew;
    - do not log signatures, secrets, raw request bodies, auth headers, or target user PII.
  - Dependencies:
    - Tasks 2-3

- [x] Task 5: Implement read-only payment diagnostics endpoint
  - Files:
    - `diaverseapi/app/ops_agent/payment_diagnostics.py`
    - `diaverseapi/app/ops_agent/api.py`
    - `diaverseapi/tests/test_ops_agent_payment_diagnostics.py`
  - Deliverable:
    - support lookup by safe identifiers: internal user id, Telegram id when mapped safely, payment session id, public checkout reference, or provider invoice id when allowed;
    - return sanitized `CabinetPaymentSession` state: `status`, `finalization_status`, `domain_code`, `source_ref`, `idempotency_key`, timestamps, finalizer errors, related claim/unlock/order state, and safe alert ids;
    - include a diagnosis summary such as `paid_not_finalized`, `finalizer_failed`, `review_required`, `already_granted`, `not_paid`, or `not_found`;
    - never return raw provider callback payloads by default.
  - Logging:
    - log diagnostic request id, case id, actor id, lookup type, result code, and duration;
    - do not log payment provider raw payloads, cards, emails, phone numbers, secrets, or full Telegram text.
  - Dependencies:
    - Task 4

- [x] Task 6: Implement action registry and payment repair actions
  - Files:
    - `diaverseapi/app/ops_agent/action_registry.py`
    - `diaverseapi/app/ops_agent/payment_actions.py`
    - `diaverseapi/app/ops_agent/api.py`
    - `diaverseapi/app/cabinet/payments/service.py`
    - relevant domain finalizer tests under `diaverseapi/tests/`
  - Deliverable:
    - implement a typed action registry with action id, risk level, owner, preview support, idempotency scope, guard list, allowed service methods, required audit fields, and rollback notes;
    - add a preview endpoint that explains what action would happen and which guards passed/failed;
    - add execute endpoint for narrow actions:
      - retry existing finalizer for paid sessions;
      - mark review-needed sessions with a structured ops note;
      - optional MVP manual repair only through domain-specific service methods when all invariants pass;
    - require risk-policy result, idempotency key, and case id for every mutation;
    - support Telegram approval for high-risk actions and automatic approval only for action ids explicitly marked safe by registry metadata and automated policy;
    - write `CabLogEvent`/alert entries for preview and execution.
  - Logging:
    - log action kind, case id, payment session id, domain code, approval id, idempotency key, before/after status, and result;
    - do not log raw SQL, raw provider payloads, secrets, or unredacted user contact data.
  - Dependencies:
    - Tasks 4-5

### Phase 3: `aibot` Playbooks, Read-Only DB, And Case Memory

- [x] Task 7: Add lightweight case database, text playbooks, and repository
  - Files:
    - `aibot/migrations/20260626_0001_ops_agent_cases.sql`
    - `aibot/db/models.py`
    - `aibot/db/repositories/ops_agent_repo.py`
    - `aibot/app/ops_agent/playbooks/index.yml`
    - `aibot/app/ops_agent/playbooks/payments/paid-not-credited.md`
    - `aibot/app/ops_agent/playbooks/README.md`
    - `aibot/tests/test_ops_agent_repo.py`
  - Deliverable:
    - add tables:
      - `ops_agent_cases`
      - `ops_agent_messages`
      - `ops_agent_actions`
      - `ops_agent_artifacts`
      - `ops_agent_action_proposals`
    - do not store full playbook bodies in the database; store `playbook_id`, path, version/hash, and case links only;
    - add a starter playbook for "paid but not credited" with symptoms, fingerprints, checks, allowed actions, forbidden actions, repair workflow, and Telegram text examples;
    - store case type, status, fingerprint, target domain, playbook id, sanitized summary, root cause, resolution, code pointers, linked artifacts, generated action proposal ids, and follow-up tasks;
    - add indexes for status, case type, domain, fingerprint, playbook id, action proposal status, and created_at.
  - Logging:
    - repository logs should use case id, fingerprint, status, and safe action ids;
    - do not log raw Telegram messages, secrets, raw stack traces with sensitive values, or full user/payment payloads.
  - Dependencies:
    - Tasks 1-3

- [x] Task 8: Implement sanitizer, playbook retrieval, read-only DB inspector, and case memory
  - Files:
    - `aibot/app/ops_agent/sanitizer.py`
    - `aibot/app/ops_agent/memory.py`
    - `aibot/app/ops_agent/playbooks.py`
    - `aibot/app/ops_agent/read_only_db.py`
    - `aibot/tests/test_ops_agent_memory.py`
  - Deliverable:
    - sanitize Telegram messages and diagnostics before storage;
    - compute stable fingerprints from case type, domain, failure state, finalizer code, and known error category;
    - read `playbooks/index.yml` first and load the most relevant Markdown playbook by tag/symptom/fingerprint;
    - search similar DB cases by exact fingerprint after playbook matching, then safe full-text/trigram search;
    - provide a read-only DB inspector with query allowlist/denylist, statement timeout, row limit, and no write/DDL statements;
    - return playbook instructions, previous resolution steps, safe DB observations, and code pointers to the Codex prompt;
    - keep embeddings disabled until an explicit privacy review enables them.
  - Logging:
    - log retrieval strategy, playbook id, match count, top score/fingerprint, DB query template id, row count, and duration;
    - do not log raw user text, raw SQL with values, secrets, full provider payloads, query result payloads, or full case transcripts.
  - Dependencies:
    - Task 7

- [x] Task 9: Implement signed Diaverse ops client in `aibot`
  - Files:
    - `aibot/app/ops_agent/diaverse_client.py`
    - `aibot/tests/test_ops_agent_diaverse_client.py`
  - Deliverable:
    - reuse the signed HTTP style already used by existing `aibot` internal clients;
    - support diagnostics, action registry fetch, action preview, action execute, generated-action proposal status, and health check;
    - add retries only for safe idempotent calls;
    - provide structured errors for auth failure, timeout, not found, guard failed, and upstream unavailable.
  - Logging:
    - log request id, case id, endpoint name, result code, retry count, and duration;
    - do not log HMAC signatures, secrets, request bodies containing identifiers beyond safe ids, or raw upstream response bodies.
  - Dependencies:
    - Tasks 4-6

### Phase 4: Telegram Runtime And Codex Runner

- [x] Task 10: Implement the Telegram ops-agent runtime
  - Files:
    - `aibot/app/ops_agent/main.py`
    - `aibot/app/ops_agent/handlers.py`
    - `aibot/app/ops_agent/settings.py`
    - existing `aibot` runtime/entrypoint files as needed
    - `aibot/tests/test_ops_agent_handlers.py`
  - Deliverable:
    - support mention-based case creation in allowlisted chats;
    - support Chat mode and Case mode;
    - classify free-form Telegram messages as casual chat, incident/support request, or explicit command;
    - support commands: `/chat`, `/ops`, `/case`, `/approve`, `/cancel`, `/status`, `/close`, `/mode`, `/playbook`;
    - persist active thread mapping by Telegram chat/thread/user id, active Codex thread id, and optional active case id;
    - resume existing Codex threads for follow-up messages when possible;
    - show staged updates: case created, similar cases found, diagnostics done, approval needed, action executed, root cause summary;
    - run as a dedicated runtime role such as `COPYWRITING_RUNTIME_ROLE=ops-agent-bot`.
  - Logging:
    - log chat id hash, user id hash, case id, command, authorization decision, and handler duration;
    - do not log Telegram bot token, raw message text, private chat content, or unredacted Telegram ids unless explicitly classified as safe internal ids.
  - Dependencies:
    - Tasks 7-9

- [x] Task 11: Add the Russian humorous voice renderer with guardrails
  - Files:
    - `aibot/app/ops_agent/voice.py`
    - `aibot/tests/test_ops_agent_voice.py`
  - Deliverable:
    - add tone modes: `calm`, `default`, `spicy`;
    - render internal Telegram messages with light humor, for example:
      - "Платеж нашли, начисление пока притворяется мебелью. Проверяю finalizer."
      - "Похожий случай уже был: тот же домен, та же стадия падения. Беру старую карту сокровищ."
    - force factual templates for approvals, failed repairs, security issues, access denials, and money-impacting confirmations;
    - keep all stored/audit summaries non-jokey.
  - Logging:
    - no special runtime logs for text rendering beyond template id if needed;
    - never log raw generated joke candidates or private incident details.
  - Dependencies:
    - Task 10

- [x] Task 12: Implement Codex runner abstraction
  - Files:
    - `aibot/app/ops_agent/codex_runner.py`
    - `aibot/app/ops_agent/prompting.py`
    - `aibot/app/ops_agent/action_authoring.py`
    - `aibot/tests/test_ops_agent_codex_runner.py`
  - Deliverable:
    - support a minimal runner command such as `codex exec` or an SDK-backed runner behind one interface;
    - verify the exact server install/auth flow against official OpenAI docs during implementation;
    - run with a dedicated `CODEX_HOME`, isolated workspace, timeouts, bounded concurrency, and read-only defaults;
    - inject only sanitized case data, selected playbook text, similar-case summaries, read-only DB observations, GBrain/doc pointers, code pointers, and diagnostic responses;
    - capture structured artifacts: proposed root cause, code pointers, recommended patch, tests to run, and repair recommendation;
    - when no action exists, let Codex generate a new action patch in an isolated worktree with registry metadata, preview/execute implementation, tests, playbook update, and rollback notes;
    - run automated generated-action gates before activation: formatting, type/lint checks, targeted tests, denylist scan for raw write SQL and unsafe imports, required audit fields, idempotency checks, and registry risk-policy validation;
    - allow no-manual-review activation only after all generated-action gates pass and the action risk is within configured auto-activation policy;
    - avoid exposing a public Codex app server.
  - Logging:
    - log runner id, case id, model/runner alias, timeout, exit code, artifact ids, generated action id, safety gate result, and duration;
    - do not log prompts containing private data, raw model output before sanitization, API keys, OAuth tokens, raw DB rows, or full environment.
  - Dependencies:
    - Tasks 7-9

- [x] Task 13: Wire the case lifecycle orchestrator
  - Files:
    - `aibot/app/ops_agent/orchestrator.py`
    - `aibot/app/ops_agent/handlers.py`
    - `aibot/tests/test_ops_agent_orchestrator.py`
  - Deliverable:
    - implement lifecycle:
      1. create case from Telegram;
      2. classify free-form messages into Chat mode or Case mode;
      3. in Chat mode, answer or resume a lightweight Codex thread without repair execution;
      4. in Case mode, sanitize and store message;
      5. select and read the best matching Markdown playbook;
      6. retrieve similar DB cases;
      7. run read-only DB and `diaverseapi` diagnostics;
      8. ask Codex for analysis if playbooks/diagnostics are insufficient;
      9. generate action preview if a registered action exists;
      10. if no action exists, start generated-action authoring, run automated gates, and activate only if policy allows;
      11. request Telegram approval only when the action risk policy requires it;
      12. execute registered safe action;
      13. save sanitized closure summary, playbook update candidate, and generated action proposal outcome;
      14. send final Telegram report.
    - ensure retries do not duplicate repairs.
  - Logging:
    - log state transitions, case id, action id, result code, and duration per step;
    - do not log raw user messages, raw SQL, secrets, raw payment payloads, or full Codex prompts.
  - Dependencies:
    - Tasks 10-12

### Phase 5: Verification, Deployment, And Rollout

- [x] Task 14: Add focused automated tests and safety checks
  - Files:
    - `diaverseapi/tests/test_ops_agent_*.py`
    - `aibot/tests/test_ops_agent_*.py`
  - Deliverable:
    - cover HMAC auth, replay rejection, diagnostics result codes, action registry metadata, approval/idempotency guards, finalizer retry, audit write, playbook selection, read-only DB denylist, memory sanitizer, retrieval, Telegram auth, voice guardrails, Codex runner mock, generated-action gates, and orchestrator lifecycle;
    - add regression tests for the "paid but not credited" case.
  - Logging:
    - test logs may include case ids and assertion details;
    - fixtures must not include real tokens, real payment payloads, raw user PII, or production ids.
  - Dependencies:
    - Tasks 4-13

- [x] Task 15: Add deployment docs and runtime wiring
  - Files:
    - `aibot/docker-compose.prod.yml` or existing compose/runtime files
    - `aibot/Dockerfile` or existing entrypoint files if needed
    - `aibot/docs/ops-agent.md`
    - `docs/runbooks/ops-agent.md`
    - `docs/infrastructure/deployment-matrix.md` if deployment ownership changes
  - Deliverable:
    - add an ops-agent service/role for the bots server;
    - document Codex install/auth verification, dedicated runtime user, `CODEX_HOME`, workspace path, sandbox mode, read-only DB credentials, generated-action worktree, timeout, and rollback;
    - document Telegram bot token setup, allowlist setup, HMAC setup, action auto-activation policy, and dry-run rollout;
    - add a smoke-test checklist for dev bot, playbook lookup, read-only DB diagnostics, generated-action dry run, approval dry-run when policy requires it, and one controlled repair in staging.
  - Logging:
    - deployment logs may include service name, role, health status, and redacted config presence;
    - do not log tokens, secrets, raw env values, server private IPs, SSH paths, or credential file paths in public docs.
  - Dependencies:
    - Tasks 1-14

## Verification Plan

Run from `diaverseapi`:

```powershell
.\.venv\Scripts\python.exe -m pytest tests\test_ops_agent_*.py -q
.\.venv\Scripts\python.exe -m ruff check app\ops_agent tests
```

If `diaverseapi` adds an Alembic migration:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

Run from `aibot`:

```powershell
.\.venv\Scripts\python.exe -m pytest tests\test_ops_agent_*.py -q
.\.venv\Scripts\python.exe -m ruff check app db tests
```

Migration verification for `aibot`:

- apply the new SQL migration to a local/test database using the existing migration workflow;
- verify rollback strategy manually if the project has no rollback migration convention;
- verify indexes and constraints exist for case lookup and idempotency.
- verify the read-only DB role cannot run `INSERT`, `UPDATE`, `DELETE`, `DDL`, lock-heavy statements, or unbounded queries.

Runtime smoke checks:

- start `diaverseapi` with signed ops API enabled in a non-production environment;
- start `aibot` as `ops-agent-bot` with a dev Telegram bot token and allowlisted chat;
- create a fake "paid but not credited" case;
- verify `/chat` stays in Chat mode and cannot execute actions;
- verify `/ops` creates Case mode explicitly;
- verify free-form incident text is classified into Case mode or asks for confirmation according to configured confidence;
- verify follow-up messages resume the correct active Codex thread or case;
- verify playbook lookup runs before similar-case DB lookup and before Codex;
- verify read-only DB diagnostics work with row limits and timeouts;
- verify diagnostics-only response works without approval;
- verify risk policy blocks mutation until approval when the selected action requires it;
- verify a missing action can produce a generated-action proposal and that unsafe generated code is rejected by automated gates;
- verify repeated `/approve` does not duplicate repair;
- verify closure summary is stored and future similar case finds it.

Codex runner checks:

- verify exact install/auth flow against current official OpenAI docs before server rollout;
- verify the runner can execute in the dedicated workspace with read-only defaults;
- verify prompts and artifacts are sanitized before storage;
- verify timeouts and concurrency limits stop stuck sessions.
- verify generated-action patches cannot activate if tests, denylist, idempotency, audit, registry metadata, or risk policy gates fail.

Docs/GBrain checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1
```

For a narrower sync after implementation, prefer only changed sources such as `diaverse-docs`, `diaverse-aif`, `aibot-code`, and `diaverseapi-code` if the helper supports source-scoped sync.

## Definition Of Done

- Telegram bot accepts allowlisted mentions and creates an ops case.
- Telegram bot also supports free-form Chat mode and separates it from Case mode.
- Free-form messages are classified and commands route directly.
- Follow-up messages resume the right active Codex thread or case when possible.
- The agent checks Markdown playbooks before similar case history and before new investigation.
- Payment diagnostics can use signed `diaverseapi` APIs and a dedicated read-only DB role.
- Any repair action requires registry metadata, risk-policy decision, idempotency key, audit event, and safe service method.
- If no action exists, Codex can author a new action without manual code review, but activation requires automated gates, registry metadata, tests, and configured auto-activation policy.
- The bot returns a useful Russian Telegram report with controlled light humor.
- Case memory stores sanitized closure summaries, playbook ids, playbook update candidates, and generated action proposal outcomes.
- Codex/GPT runner is isolated, timeout-bound, and does not expose a public server.
- Tests cover security, payment diagnostics/actions, playbook retrieval, read-only DB restrictions, memory, Telegram handlers, intent classification, mode switching, thread persistence, voice guardrails, generated-action gates, and orchestration.
- Docs/runbook/deployment notes are updated.
- GBrain is synced after meaningful docs/code changes.
