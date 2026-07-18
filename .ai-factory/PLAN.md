# Implementation Plan: Ops Agent User Stats, Donations, And Permanent Telegram Comment Restriction

Branch: none
Created: 2026-07-17

## Settings

- Testing: yes
- Logging: verbose
- Docs: yes

## Workspace Mode

- Mode: fast multi-repo plan; do not create or switch branches.
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`.
- Affected product repositories: `diaverseapi`, `aibot`.
- Root ownership: this plan and the ops-agent/Club architecture and runbook updates only.
- Knowledge: GBrain was attempted during exploration but timed out; architecture and behavior were verified against raw source, `origin/dev`, the production-mounted workspace, and the live read-only action registry.

## Repository Matrix

| Repository | Affected | Current state | Role |
| --- | --- | --- | --- |
| root `diaverse` | yes | `dev`, dirty | master plan, architecture/runbook updates, GBrain sync |
| `diaverseapi` | yes | `dev`, heavily dirty and behind `origin/dev` | canonical user/payment aggregation, signed diagnostic API, action registry, approval policy, durable Telegram outbox |
| `aibot` | yes | `dev`, dirty in ops-agent files | agent-first user-summary tool use, signed client/helper, approval context, read-only Codex DB helper, Ops Agent Telegram moderation transport |
| `diaweb` | no | preserve | no browser UI requested |
| `diaverse-mobile` | no | preserve | no mobile contract change requested |
| `diaverse-content` | no | preserve | unrelated |
| `club10000-bot` | no | preserve | Club10000 payment state is not the Diaverse user-payment source of truth |
| `diaverse-auth-bot` | no | preserve | no auth transport change required |

## Research Context

Source: current `$aif-explore` session, local/raw source verification, `origin/dev`, production-mounted source, and read-only production runtime inspection. The Active Summary in `.ai-factory/RESEARCH.md` concerns an unrelated SEO task and is intentionally not copied into this plan.

Goal:
- Let the Ops Agent answer user step totals for any requested period.
- When the standalone keyword `донат` is present, also show the user's successful real-money contributions for the fixed last 365 inclusive calendar days.
- Include authenticated/user-linked Club payments in both the total and a separate Club breakdown.
- Add an allowlisted, permanent Telegram discussion-group comment restriction with preview, explicit approval, durable delivery, verification, audit, and rollback. The user remains a member and is not banned from the channel/group.

Decisions:
- Step/payment counting is a signed read-only diagnostic capability, not a mutation action. The permanent Telegram comment restriction is a registered high-risk action.
- Resolve users by canonical user UUID, unique numeric Telegram user ID, or an exact normalized unique Telegram `@username`; ambiguous usernames fail closed instead of being guessed.
- Step range is inclusive and uses the compatibility local-date expression `COALESCE(user_activities.local_date, datetime_to_date_user(created_at, user_id))`; totals reflect stored activity steps, while restriction/capping metadata is reported separately when relevant.
- Donation range is always `today - 364 days` through `today`, inclusive, independently of the requested step period.
- Reuse canonical successful real-money fact semantics: Shop, Advent, Crypton, and Club; normalize USD/USDT to USDT; exclude XDV/DCR, failed/refunded/incomplete payments, duplicate business keys, and manual links without canonical user attribution.
- Report both donation amount and successful payment count, total plus per-source breakdown. Report attribution gaps instead of silently claiming completeness.
- The Telegram target is selected by a server-side `discussion_key`; arbitrary chat IDs from operator text are forbidden. The later supplied ID must identify (or be safely resolved to) the linked discussion supergroup where comments are written; a broadcast-channel ID by itself is not assumed to be sufficient. Moderation remains fail-closed until this mapping is configured.
- Permanent restriction means `restrictChatMember` with all message-sending permissions denied and no `until_date`. It must never call `banChatMember`, remove the user from the chat, or mutate Club membership state.
- The transport resolves its own bot identity with `getMe` and treats that ID as an unconditional protected principal; the Ops Agent/bot, chat creator, configured owners, and protected admins can never be restriction targets. The bot itself must retain administrator status with `can_restrict_members` so it can manage other members.
- The restriction uses a dedicated transport-only outbox command. It is independent of Club payment, presence, buddy, and membership transitions.
- A queued outbox command is not a confirmed restriction. The bot may claim success only after ACK/status evidence.

Constraints and risks:
- The local `diaverseapi` checkout does not currently contain the deployed generic `app/ops_agent` registry even though `origin/dev`, the production-mounted workspace, and the live registry do. Implementation must reconcile the authoritative upstream/deployed files before editing and must not create a second registry under `app/support`.
- Both affected repositories contain substantial unrelated uncommitted work, including overlapping ops-agent, Club, activity, and payment files. Implementation must use file-scoped diffs and must not switch branches, stage, revert, or overwrite unrelated changes.
- The current production Codex operator mode bypasses deterministic read-only routing, runs with a permissive sandbox, inherits sensitive runtime environment, and the `scripts/ops_agent_db.py` helper permits write SQL. Closing these paths is a prerequisite to enabling a high-risk moderation action.
- Current `/approve` persistence keeps target/idempotency but loses `sanitized_input`; a restriction's discussion key/reason could drift or disappear. Approval binding and pending-input persistence must be fixed before the action can execute.
- The linked discussion-group ID, bot identity, and Telegram permissions are intentionally unresolved. Code can be completed fail-closed, but production enablement and any real restriction remain out of scope until the user supplies the ID and explicitly authorizes rollout/smoke execution.

## Commit Plan

- **Commit 1 — `aibot`** (Task 2): `fix(ops-agent): enforce readonly database access`
- **Commit 2 — `diaverseapi`** (Tasks 3-5): `feat(ops-agent): add user activity and donation summary`
- **Commit 3 — `aibot`** (Tasks 6-7): `feat(ops-agent): expose user summaries as an agent tool`
- **Commit 4 — `diaverseapi`** (Tasks 7-8): `feat(ops-agent): add approved telegram comment restriction`
- **Commit 5 — `aibot`** (Tasks 7 and 9): `feat(ops-agent): execute allowlisted moderation commands`
- **Commit 6 — root docs/context** (Task 10): `docs(ops-agent): document user stats and moderation`

## Tasks

### Phase 0: Source And Safety Baseline

- [x] **Task 1: Reconcile authoritative source and protect overlapping dirty work before implementation.**

  Deliverable: compare the relevant local worktree files against `origin/dev` and the production-mounted sources for `diaverseapi/app/ops_agent`, payment fact loaders, Club outbox/ACK handling, and `aibot/app/ops_agent`; record the exact file-level baseline that contains the three live registered actions; preserve all unrelated local changes; identify the transport-only discussion-group command boundary needed for the later supplied `discussion_key`. Do not switch branches, pull into dirty worktrees, stage, deploy, or change runtime configuration.

  Expected behavior: implementation extends the one authoritative registry used by `/internal/ops-agent/actions/*`; no duplicate action surface appears under `app/support`; each overlapping dirty file has an explicit merge strategy; absent channel ID leaves moderation disabled and does not block implementation of read-only user summaries.

  Files: read-only inspection of `diaverseapi/app/ops_agent/**`, `diaverseapi/app/support/ops_api.py`, `diaverseapi/app/activities/**`, canonical payment fact loaders, `diaverseapi/app/club/{enums,outbox,service,internal_api}.py`, `aibot/app/ops_agent/**`, and their focused tests.

  Dependencies: none.

  Logging requirements: add no runtime logs. Preflight output may contain repository, branch, path, commit, dirty-count, configured/permission booleans, and channel alias only. Never print DB URLs, bot tokens, HMAC secrets, raw environment values, Telegram payloads, or unrelated diffs.

  Implementation baseline (2026-07-17): the production-mounted `diaverseapi` checkout is clean for the inspected paths at `f8c263339ced4cbcb5c2177a9bd102a13bb8eb1f`; its three live IDs (`payment.retry_finalizer`, `payment.mark_review_needed`, `finance.manual_payment_link.create`) are defined by `app/ops_agent/action_registry.py` and mirrored by `app/ops_agent/schemas.py`. Those registry files match local `origin/dev`; production differs there only in `app/ops_agent/api.py` and `app/ops_agent/security.py`, so the production commit is the merge base for those edges. Production and local `origin/dev` have identical trees for `app/cabinet/finance` and `app/club`. The local `diaverseapi` branch lacks `app/ops_agent` and is otherwise heavily dirty, so implementation must add/extend the authoritative package from the production baseline and avoid `app/support/ops_api.py`; new stats modules are preferred over rewriting dirty activity/payment/Club files. The local dirty `aibot` ops-agent files match the clean production blobs at `625ed79a829bf176e952af5c9a890989dc94f07b` and will be patched in place; production-only clean files, including `app/clubbot/handlers.py`, must be reconciled before their first edit. No `discussion_key`/linked discussion-group ID is configured yet, so moderation remains disabled; the command must remain transport-only and must not reuse Club membership removal semantics.

### Phase 1: Operator Safety And Approval Integrity

- [x] **Task 2: Make every Codex/operator SQL path technically read-only.**

  Deliverable: change `aibot/scripts/ops_agent_db.py` to accept only validated single-statement `SELECT`/`WITH` reads, use only `OPS_AGENT_READONLY_DATABASE_URL`, set a transaction-local read-only mode and bounded statement timeout, and reject DDL/DML, locking clauses, unsafe functions, comments/multi-statements, or fallback to general/write DSNs. Remove the prompt text that authorizes write SQL and direct all product mutations to registered actions. Run the Codex child with a read-only sandbox and an explicit minimal environment allowlist that excludes general/write DB URLs, Telegram bot tokens, provider secrets, and unrelated service credentials; do not mount writable product worktrees into the child unless a separately reviewed developer-task workflow requires them. Reuse the existing read-only validator where practical instead of maintaining divergent policies.

  Expected behavior: Ops Agent user-summary investigation remains possible through the deterministic signed endpoint; `INSERT`, `UPDATE`, `DELETE`, `CREATE`, and similar statements fail before reaching PostgreSQL; the helper cannot select `OPS_AGENT_DATABASE_URL` or `OPS_AGENT_WRITE_DATABASE_URL`; the Codex subprocess cannot read bot/provider credentials or bypass the orchestrator to call Telegram; product mutations remain available only through orchestrator-mediated registered actions.

  Files: `aibot/scripts/ops_agent_db.py`, `aibot/app/ops_agent/{read_only_db,prompting,codex_runner}.py`, `aibot/docker-compose.prod.yml`, `aibot/.env.example`, and new/focused CLI, runner-environment, and prompt tests.

  Dependencies: Task 1.

  Logging requirements: DEBUG for validation mode, query fingerprint, timeout, and selected read-only env-name only; INFO for successful read with row count/truncation; WARN for policy rejection with stable reason code; ERROR for connection/execution failure. Never log SQL text, DSNs, credentials, returned PII, or environment values.

- [x] **Task 3: Bind approvals to the exact action payload and persist pending action input across `/approve`.**

  Deliverable: add domain-separated approval verification in the authoritative `diaverseapi` ops-agent contract so an approval is bound to case, action, target fingerprint, sanitized-input fingerprint, idempotency key, requesting/approving operator, and expiry; reject arbitrary, expired, replayed, wrong-actor, or payload-drift approvals. In `aibot`, persist `pending_action_input` with the existing pending approval/action/target context and resend the exact sanitized input after `/approve`; add a backward-compatible copywriting DB migration and repository/context wiring.

  Expected behavior: existing medium-risk actions continue to work; high-risk comment-restriction execution cannot be authorized by a non-empty arbitrary approval string; restarts/replies preserve the approved discussion key/reason; `/cancel` and closure clear pending input; one approval cannot authorize a different target or action.

  Files: authoritative `diaverseapi/app/ops_agent/{schemas,api,approvals,payment_actions,finance_actions}.py` as applicable; `aibot/app/ops_agent/{schemas,orchestrator,handlers,telegram_context}.py`; `aibot/db/{models,repositories/ops_agent_repo}.py`; an additive `aibot/migrations/*.sql`; and focused approval/context tests.

  Dependencies: Tasks 1-2.

  Logging requirements: DEBUG for approval issue/verification checkpoints and payload fingerprints; INFO for approval issued, accepted, cancelled, or consumed using case/action identifiers and hashed actor; WARN for expired, replayed, mismatched, or drifted approval; ERROR for persistence failures. Never log approval tokens, HMAC material, full sanitized input, reason text, usernames, numeric Telegram IDs, or raw target payloads.

### Phase 2: Read-Only User Steps And Donation Summary

- [x] **Task 4: Implement canonical user resolution and arbitrary-period step aggregation.**

  Deliverable: add typed user-summary request/response schemas and a read-only use case that resolves exactly one user by UUID or unique numeric `users.tg_user_id`; sums `UserActivity.steps` over an inclusive optional `date_from..date_to` range; uses the compatibility local-date expression for legacy rows; returns total steps, active-day count, effective range, and bounded restriction/capping context without exposing daily raw rows by default. Omitted dates mean all-time steps.

  Expected behavior: any valid requested period works; old rows with null `local_date` remain countable; unknown or ambiguous targets return a safe not-found response; zero activity returns zero rather than an invented result; displayed total semantics remain distinct from reward/rating eligibility.

  Files: new `diaverseapi/app/ops_agent/user_summary.py` or equivalent authoritative module, `diaverseapi/app/ops_agent/schemas.py`, `diaverseapi/app/activities/models.py` only if a reusable expression is missing, `diaverseapi/app/club/activity_dates.py`, and `diaverseapi/tests/test_ops_agent_user_summary.py`.

  Dependencies: Task 1.

  Logging requirements: DEBUG for request ID, hashed target, identity lookup kind, effective date range, and query duration; INFO for lookup/aggregation completion using outcome and `has_activity` only; WARN for missing/ambiguous identity or invalid range; ERROR for aggregation failure. Never log user UUID/TG ID, step totals, active-day counts, auth data, private profile fields, raw activity rows, or unrestricted user payloads.

- [x] **Task 5: Aggregate the user's last-365-day real-money contributions including Club.**

  Deliverable: extend or wrap the canonical Advent, Shop, Crypton, and Club successful payment-fact loaders with database-level user/date filters; deduplicate by business key; normalize USD/USDT source money to USDT through existing finance rules; return total amount, successful payment count, per-source amount/count, exact inclusive UTC window, and attribution warnings. Match Advent through authenticated/imported user ownership rather than string guessing, and include user-linked Club facts in the total plus a distinct `club` breakdown.

  Expected behavior: `today-364..today` is always used when donations are requested, regardless of the step range; failed/refunded/incomplete payments, DCR/XDV spend, unsupported/non-positive money, duplicates, manual links without `user_id`, unimported guest purchases, and unlinked Club payments do not enter the total; excluded/unlinked counts are reported so the bot does not overstate completeness; aggregation does not load a full year for every user and filter in memory.

  Files: `diaverseapi/app/cabinet/shop/payment_facts.py`, `diaverseapi/app/cabinet/offers/advent/payment_facts.py`, `diaverseapi/app/cabinet/offers/crypton/payment_facts.py`, `diaverseapi/app/club/payment_facts.py`, `diaverseapi/app/cabinet/finance/reporting.py` only if a shared filtered helper is needed, the user-summary service/schema, and focused finance/user-summary tests.

  Dependencies: Task 4.

  Logging requirements: DEBUG for source, hashed user target, UTC window, loader duration, and whether facts/dedupe/attribution gaps were present; INFO for aggregate completion and included source codes only; WARN for unsupported money, missing ownership, ambiguous attribution, or skipped facts without user-level amounts/counts; ERROR for a failed source aggregation with source code and request ID. Never log donation amounts, per-user payment counts, provider payloads, checkout/payment URLs, payer PII, tokens, signatures, or raw metadata JSON.

  Implementation note (2026-07-17): all four canonical fact loaders now accept database-level `user_id` plus date filters; the contribution service applies the fixed inclusive `today-364..today` window, source-scoped business-key deduplication, positive-USDT validation, and a four-source total/breakdown. Manual finance links, ownerless generic sessions, and unimported Advent guest orders are disclosed as global-window attribution gaps rather than assigned to a user. User-scoped loader logs suppress amounts, payment counts, and raw fact identifiers. Focused contribution, query-contract, user-summary integration, Advent money-policy, and Crypton regression tests pass.

- [x] **Task 6: Expose the signed read-only user-summary diagnostic contract.**

  Deliverable: add a signed internal endpoint such as `POST /internal/ops-agent/user-summary`, reuse existing request-ID/HMAC/replay protections, accept the canonical target and step range plus `include_donations`, call the step and contribution services, and return one sanitized typed response. Keep this endpoint outside mutation registry preview/execute semantics.

  Expected behavior: invalid signature, stale timestamp, replay, request-ID mismatch, invalid date range, or unsafe/ambiguous target fails closed; `include_donations=false` performs no payment work; `include_donations=true` returns the fixed 365-day result including Club; response contains no raw payment/activity records.

  Files: authoritative `diaverseapi/app/ops_agent/{api,schemas,user_summary}.py`, router wiring if required, `diaverseapi/tests/test_ops_agent_user_summary.py`, and ops-agent security regression tests.

  Dependencies: Tasks 4-5.

  Logging requirements: DEBUG for signed request entry, request ID, safe target kind, requested step window, donation flag, and latency; INFO for successful sanitized summary; WARN for auth/replay/validation/not-found outcomes using stable reason codes; ERROR for service failure. Never log signature headers, response bodies, PII, raw payment facts, or DB connection data.

  Implementation note (2026-07-17): `POST /v1/internal/ops-agent/user-summary` is mounted on the authoritative router and reuses the deployed body-digest/HMAC, timestamp, request-ID, and replay checks. The payload request ID is bound to the signed header, `include_donations=false` skips contribution loading, and the response is the sanitized typed summary only. Missing production Ops settings were reconciled fail-closed from the deployed baseline and documented in `.env.example`; endpoint/replay/request-ID and service tests pass.

### Phase 3: Ops Agent Routing And Response UX

- [x] **Task 7: Let Ops Agent autonomously invoke the user-summary tool and support exact `@username` resolution.**

  Deliverable: expose the signed user-summary capability to the Ops Agent as a typed read-only tool that the agent may choose from free-form operator text; teach the agent tool contract to resolve UUID, numeric Telegram ID, or exact normalized unique `@username`, infer any requested step period, and treat standalone normalized keyword `донат` as `include_donations=true`. Keep `/userstats <target> --steps <Nd|date-range|all> [--donations]` and the CLI helper as technical fallbacks, not the primary natural-language router. Keep the requested step period independent from the 365-day donation window and render Russian output with Shop/Advent/Crypton/Club breakdown and attribution warnings.

  Expected behavior: `сколько шагов у пользователя @saf донат` is interpreted by the agent, which autonomously invokes the typed tool with all-time steps and 365-day contributions; adding `за последние 30 дней` changes only the step range. The orchestration is not tied to one rigid phrase or pre-Codex regex route. Missing or ambiguous identity produces one concise clarification; unrelated longer words do not accidentally set the donation flag; the response clearly labels Club and excluded/unlinked data.

  Files: `aibot/app/ops_agent/{schemas,diaverse_client,orchestrator,handlers,prompting,user_summary}.py`, the Codex/tool response contract, `aibot/scripts/ops_agent_user_summary.py`, authoritative `diaverseapi/app/ops_agent/{schemas,user_summary}.py`, and focused handler/orchestrator/client/user-summary tests.

  Dependencies: Tasks 2 and 6. The approval-state part of this task also depends on Task 3 where shared state structures overlap.

  Logging requirements: DEBUG for intent match, parser result, step-period kind, donation flag, target kind, client latency, and render path; INFO for deterministic route completion without user metrics; WARN for missing/invalid target, invalid period, attribution warning, or backend rejection; ERROR for signed client failure. Never log operator free text, target IDs, usernames, step totals, donation amounts/counts, payment rows, raw backend bodies, or Telegram tokens.

  Implementation note (2026-07-18): production Codex Operator now receives the typed `user_summary` tool schema and emits validated structured arguments for free-form requests; the pre-Codex parser is used only for `/userstats`. Exact `@username` resolution is normalized case-insensitively and fails closed on ambiguity. A production signed smoke request through `copywriting-ops-agent` reached `api.diaverse.app`, returned HTTP 200, and resolved the synthetic target kind as `telegram_username`.

### Phase 4: Permanent Telegram Comment Restriction

- [x] **Task 8: Register a fail-closed high-risk permanent comment-restriction action.**

  Deliverable: add `telegram.discussion_member.restrict_comments` to both versioned action enums/contracts and the authoritative `diaverseapi` registry; add disabled-by-default moderation target configuration mapping `discussion_key -> discussion_chat_id`; implement preview/execute in a dedicated moderation action service. Require numeric target Telegram ID, bounded reason, exact approval from Task 3, idempotency, enabled flag, allowlisted discussion group, protected-target guards (including the agent bot identity), and an audited permanent effect. Enqueue a distinct transport-only `restrict_member_comments` command that cannot invoke Club membership ACK transitions.

  Expected behavior: absent discussion-group configuration or permission evidence blocks preview/execute; arbitrary input chat IDs are ignored/rejected; the permanent restriction calls `restrictChatMember` with message-sending permissions disabled and no `until_date`; it never calls `banChatMember` or removes membership. The action returns `queued` with command/audit ID, never a false `restricted` result; repeated execution reuses the same command; no route can change Club membership, buddy, payment, or presence state.

  Files: authoritative `diaverseapi/app/ops_agent/{schemas,action_registry,api,telegram_actions}.py`, `diaverseapi/app/core/settings.py`, `diaverseapi/.env.example`, `diaverseapi/app/club/{enums,outbox,service}.py`, optional dedicated moderation target resolver, and `diaverseapi/tests/test_ops_agent_telegram_actions.py` plus focused Club outbox/service regressions.

  Dependencies: Tasks 1 and 3. Final target configuration depends on the later supplied linked discussion-group ID, but code and tests remain fail-closed until then.

  Logging requirements: DEBUG for preview/guard results, discussion alias, hashed target, idempotency lookup, and enqueue latency; INFO for approval-bound enqueue, reused command, ACK/NACK/dead-letter transition, and audit ID; WARN for disabled/unallowlisted discussion, protected/admin/self target, missing permission, approval mismatch, or payload drift; ERROR for persistence/outbox failure. Never log numeric Telegram IDs, bot tokens, raw chat payloads, Telegram response objects, usernames, reason text, secrets, or arbitrary environment values.

- [x] **Task 9: Enforce last-mile moderation safety in the Ops Agent Telegram runtime and expose truthful completion/rollback.**

  Deliverable: add an independent moderation discussion-group allowlist and protected-user list to Ops Agent settings; resolve the live Ops Agent bot ID with `getMe`, add it unconditionally to the protected set, and preflight every configured discussion group for bot administrator status and `can_restrict_members`; expose Ops-Agent-signed claim/ACK/NACK/status endpoints that can access only moderation command types while the Clubbot claim path explicitly excludes them; execute `restrict_member_comments` and `restore_member_comments` with the Ops Agent bot token and last-mile chat/target validation; reject bot self, creator/admin/protected targets; preserve durable retry/NACK/dead-letter behavior; store only sanitized ACK metadata. Define rollback as a separately approved transport-only restoration of the member's allowed/default discussion permissions; rollback must not add/remove chat membership or alter Club domain state.

  Expected behavior: Clubbot cannot claim moderation commands; even a forged/malformed outbox payload cannot make the Ops Agent bot act outside its local allowlist; no `until_date` is sent for the permanent restriction; neither restriction nor rollback calls ban/unban or changes membership; Telegram permission failure is reported as NACK/retry rather than success; bot output says `queued` until ACK and `comments restricted` only after evidence; rollback restores comment permissions without bypassing moderation guards.

  Files: `aibot/app/ops_agent/{settings,telegram_moderation,main,diaverse_client,schemas}.py`, `aibot/core/config.py`, `aibot/.env.example`, focused Ops Agent moderation worker tests, `diaverseapi/app/ops_agent/{api,schemas,telegram_transport}.py`, filtered outbox repository/service code, and backend ACK/status tests.

  Dependencies: Tasks 3, 7, and 8.

  Logging requirements: DEBUG for preflight/command ID, command type, channel alias/hash, hashed target, permission booleans, attempt, and duration; INFO for queued claim, Telegram ACK, backend ACK, confirmed status, and rollback result; WARN for allowlist/protected/admin/self/permission rejection and retry/dead-letter state; ERROR for Telegram/backend transport failure with safe error code/type. Never log numeric Telegram IDs, bot token, raw Telegram response, message text, full reason, signature, or secret-bearing headers.

### Phase 5: Verification, Documentation, And Rollout Gate

- [x] **Task 10: Verify both repositories, update ops documentation, and keep production fail-closed until channel approval.**

  Deliverable: run focused and regression tests for read-only SQL policy, arbitrary/all-time step periods, legacy local-date rows, all four real-money sources including Club, attribution gaps, signed endpoint security, deterministic keyword routing under operator mode, approval binding/persistence, comment-restriction routing, allowlists, protected targets, outbox ACK/NACK/dead-letter, and rollback. Update ops-agent architecture/runbook with the user-summary contract, exact `донат` behavior, permanent comment-restriction approval flow, discussion-group policy, safe configuration, monitoring, disablement, and rollback; document only the queue isolation rule in Club transport docs. Run docs health, diff checks, secret/PII log scans, and targeted GBrain sync after code/docs stabilize.

  Expected behavior: backend and bot suites pass without live payment or Telegram mutation; existing payment actions, manual-link action, Club membership removal, and outbox behavior do not regress; SQL helper write attempts fail locally; no new public route appears; no real discussion-group ID, token, secret, payment payload, or user PII is committed. Production enablement remains blocked until the user supplies the linked discussion-group ID, both allowlists are configured, bot permissions pass read-only preflight, deployment is separately approved, and a real permanent comment-restriction target is explicitly approved.

  Files: all files changed by Tasks 2-9; `docs/architecture/ops-agent.md`, `docs/runbooks/ops-agent.md`, `docs/club.md`; root docs navigation only if needed.

  Dependencies: Tasks 2-9.

  Logging requirements: verification output contains command names, pass/fail counts, stable synthetic IDs, configuration/permission booleans, and high-signal errors only. Documentation defines safe IDs and forbidden fields. Never print secrets, DSNs, bot tokens, full Telegram/API payloads, payment URLs, PII, private infrastructure details, or unrelated dirty diffs.

  Rollout note (2026-07-18): backend commit `3d232080` was pushed to production `main`; aibot commit `576e7bb` was deployed by fast-forwarding the existing production branch and recreating only `copywriting-ops-agent`. The container is healthy, 205 aibot Ops Agent tests and 23 new backend feature tests pass, and the signed production user-summary smoke passed. Candidate Telegram ID `-1001927564724` failed live preflight with `target_not_supergroup`, proving it is the broadcast channel rather than its linked discussion supergroup. Moderation therefore remains disabled and no Telegram member permissions were mutated; enablement now needs the linked discussion-group ID.

## Verification Plan

### `diaverseapi`

- Run focused pytest for `test_ops_agent_user_summary.py`, `test_ops_agent_telegram_actions.py`, existing ops payment/finance action tests, Club service/outbox/internal API tests, and signature/replay security tests.
- Run targeted Ruff/import compilation for changed ops-agent, finance fact, activity-date, and Club files.
- Run `git diff --check` and a focused scan for raw payload/secret/PII logging.
- Verify no Alembic revision is needed unless implementation introduces durable backend approval state or new columns. If a revision becomes necessary, use short explicit PostgreSQL identifiers and run both `alembic heads`, graph tests, and `alembic upgrade <down_revision>:<new_revision> --sql`.

### `aibot`

- Run focused pytest for Ops Agent handler/orchestrator/client/schema/context/CLI tests and Ops Agent Telegram moderation worker tests.
- Run targeted Ruff/import compilation and `git diff --check`.
- Verify the copywriting SQL migration upgrades an existing DB without dropping or rewriting unrelated context rows.
- Assert the SQL helper rejects DML/DDL/multi-statement/locking/unsafe-function inputs and never resolves general/write DSNs.
- Use fake Telegram bot/client responses only; do not call `restrict_chat_member` against a real discussion group in automated tests, and assert that `ban_chat_member` is never called.

### End-to-end contract

- Contract-test the signed user-summary request/response between `aibot` and `diaverseapi`.
- Contract-test the action enum/registry, exact approval binding, pending input replay, outbox command, ACK/status rendering, and comment-permission rollback across both repositories.
- Confirm the discussion-group ID is absent from source control and action preview remains blocked while target config is absent.

### Knowledge and documentation

- Run `scripts/docs-health.ps1`.
- Run targeted GBrain sync for `diaverse-docs`, `diaverse-aif`, `diaverseapi-code`, and `aibot-code` after meaningful implementation/docs changes.

## Definition Of Done

- A known user can be resolved by UUID or numeric Telegram ID and receive correct step totals for any requested inclusive period or all time.
- The standalone keyword `донат` adds a fixed last-365-day real-money total and payment count without changing the step period.
- Donation output includes Shop, Advent, Crypton, and user-linked Club payments, shows Club separately, uses canonical USDT semantics, deduplicates, and discloses excluded/unlinked facts.
- Manual links and unlinked guest/Club payments are never silently attributed to a player.
- Free-form user-summary requests are interpreted by Ops Agent and use the signed typed read-only tool rather than LLM-generated SQL; `/userstats` remains an optional deterministic fallback.
- The Codex SQL helper is technically read-only and product mutations can occur only through registered actions.
- `telegram.discussion_member.restrict_comments` is high-risk, disabled by default, server-allowlisted, approval-bound, idempotent, permanent, durable, auditable, protected-target aware, and truthful about queued versus confirmed state.
- Restriction and rollback use Telegram member permissions only: they never ban/remove the user and cannot mutate Club state.
- The live agent bot identity is always protected from restriction and retains `can_restrict_members` administrator authority over non-protected members in the allowlisted discussion group.
- `/approve` replays the exact previewed input and rejects expiry, actor mismatch, payload drift, replay, or arbitrary approval IDs.
- No real Telegram restriction, deployment, discussion-group configuration, or production restart occurs without the later linked discussion-group ID and separate explicit approval.
