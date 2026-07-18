# Telegram Codex Ops Agent

Status: internal runtime
Last updated: 2026-07-17

## Purpose

Telegram Codex Ops Agent is an internal operations assistant for trusted Diaverse operators. It receives Telegram messages, separates ordinary conversation from operational cases, reads playbooks and past case memory, runs safe diagnostics, asks Codex to investigate code and runtime evidence, then executes only registered repair actions through Diaverse services.

The MVP problem class is: a user paid, but the entitlement or credit was not granted.

The agent must help the operator move faster without turning Telegram or Codex into an unrestricted production console.

## Ownership

| Area | Owner | Notes |
| --- | --- | --- |
| Telegram runtime | `aibot` | Bot entrypoint, allowlist, routing, voice layer, case orchestration, and Ops Agent-owned moderation delivery |
| Case memory | `aibot` | Sanitized case lifecycle, action results, artifacts, generated-action proposals |
| Playbooks | `aibot` | Markdown knowledge base and YAML index |
| Codex runner | `aibot` | Controlled server-side runner abstraction around Codex CLI/SDK |
| Product diagnostics | `diaverseapi` | Signed internal ops endpoints for payment and cabinet diagnostics |
| Product mutations | `diaverseapi` | Registered actions only, with audit and idempotency |
| Cross-repo docs | root `diaverse` | Architecture, runbooks, plans, GBrain sync |
| Staff UI | `diaweb` | Staff support board, per-ticket Ops Agent dispatch, future case dashboard |

`club10000-bot`, `diaverse-auth-bot`, `diaverse-mobile`, and `diaverse-content` have no MVP ownership unless a future case type explicitly touches them.

## Runtime Flow

```text
Telegram operator
  -> aibot ops-agent
  -> allowlist and mode router
     -> Chat mode
        -> lightweight Codex/LLM response or existing thread resume
        -> optional pending developer-task handoff
        -> Telegram response
     -> Case mode
        -> case memory
        -> playbook lookup
        -> similar-case lookup
        -> read-only DB inspector
        -> signed diaverseapi diagnostics
        -> Codex investigation
        -> action preview
        -> approval policy
        -> registered action execution
        -> optional pending developer-task handoff
        -> Telegram closure summary
     -> Support dispatch
        -> signed manual claim from diaverseapi
        -> ticket analysis and safe registered repair attempts
        -> optional pending developer-task handoff
     -> Agent-selected user-summary tool
        -> Codex Operator interprets free-form request and emits typed arguments
        -> signed diaverseapi user-summary endpoint
        -> arbitrary/all-time step aggregation
        -> optional fixed last-365-day contribution aggregation
     -> Approved Telegram moderation
        -> registered diaverseapi action and durable transport queue
        -> Ops Agent bot live permission/target preflight
        -> permanent comment permission restriction without membership change
```

Telegram is the operator UI. Product state authority stays in `diaverseapi`.

## Codex Integration

The MVP Codex integration should use a server-side runner abstraction so the Telegram bot is not tied to one CLI command shape forever.

Preferred MVP path:

- run `codex exec --json` in a controlled workspace;
- parse JSONL events such as thread start, turn completion, assistant output, and errors;
- persist the Codex thread id or runner correlation id on the ops case;
- use `codex exec resume` when a follow-up message belongs to the same active case or chat thread;
- set explicit timeout, concurrency, sandbox, and workspace settings from config;
- store only sanitized prompts, summaries, artifacts, and code pointers in case memory.

Hooks and notify scripts are useful for outbound Telegram notifications when Codex completes a turn. They are not the inbound Telegram control plane.

MCP servers may later expose structured tools to Codex, but they are optional for MVP. A public Codex web UI or exposed app-server is out of scope.

## Telegram Modes

The bot has two explicit modes and an intent classifier for free-form messages.

| Mode | Purpose | May create case | May execute actions |
| --- | --- | --- | --- |
| Chat mode | Ordinary conversation, playbook explanations, status summaries, low-risk analysis | No, unless user explicitly switches or message is classified as incident | No |
| Case mode | Operational incident handling with diagnostics, Codex investigation, previews, approvals, execution | Yes | Yes, through registered actions and risk policy |

Explicit commands override classifier inference:

- `/chat <message>` - answer in Chat mode.
- `/ops <incident>` - create or continue an operational case.
- `/case <case_id>` - attach the current thread to an existing case.
- `/status [case_id]` - return current case or thread status.
- `/close [case_id]` - close a case with resolution summary.
- `/mode chat|ops` - set default mode for the current operator thread.
- `/playbook <query>` - show the matching playbook summary.
- `/userstats <tg_id|uuid|@username> --steps <Nd|YYYY-MM-DD..YYYY-MM-DD|all> [--donations]` - technical fallback for user steps and optional contribution summary.
- `/approve <approval_id>` and `/cancel <approval_id>` - resolve action approval prompts.

Free-form examples:

- "привет, что умеешь?" routes to Chat mode.
- "объясни playbook по оплатам" routes to Chat mode.
- "пользователь 123 оплатил, но скин не пришел" routes to Case mode.
- "продолжай" resumes the active Codex thread or ops case when one exists.

## User Steps And Contributions

Codex Operator interprets free-form user-summary requests and may choose the
typed read-only `user_summary` tool. The orchestrator validates its structured
arguments and calls the signed `diaverseapi` contract; the agent does not write
ad-hoc SQL for this capability. `/userstats` remains a deterministic technical
fallback. Targets may be a UUID, numeric Telegram ID, or an exact normalized
unique `@username`; ambiguous usernames fail closed. Step ranges are inclusive
and may be an arbitrary date range, the last `N` days, or all time. If omitted,
the step range is all time. Legacy activity rows use the canonical user-local
date compatibility expression.

The exact standalone keyword `донат` adds contributions without changing the
requested step range. Contributions always use the fixed inclusive UTC window
`today-364..today`, include successful user-linked Shop, Advent, Crypton, and
Club payments, normalize supported USD/USDT facts to USDT, deduplicate business
keys, and report attribution gaps. Manual links, unimported guest orders, and
unlinked payments are not silently attributed to the user.

## Telegram Comment Moderation

`telegram.discussion_member.restrict_comments` is a high-risk registered
action. It is disabled by default, requires exact payload-bound approval, and
accepts only a server-side `discussion_key`; operators cannot inject a chat id.
Execution queues a transport command and reports `queued` until Telegram ACK is
stored.

The last mile belongs to the existing `copywriting-ops-agent` Telegram bot and
uses its own bot token. The ordinary `copywriting-clubbot` claim path explicitly
excludes moderation command types. The Ops Agent moderation worker can claim
only `restrict_member_comments` and `restore_member_comments`.

Before every Telegram mutation, the Ops Agent resolves its live identity with
`getMe`, protects that identity unconditionally, verifies the configured target
is a linked discussion supergroup, verifies its own administrator status and
`can_restrict_members`, and rejects creators, administrators, and configured
protected users. Restriction calls `restrictChatMember` with message-sending
permissions disabled and no `until_date`; it never calls `banChatMember` and
does not remove or change Club membership. Restoration is a separate approved
command and restores discussion permissions without adding or removing the
member.

The candidate ID `-1001927564724` was verified on 2026-07-18 as a broadcast
channel, not a supergroup. It is intentionally not enabled for moderation; the
linked discussion-supergroup ID is still required.

## Developer Task Handoff

Codex and deterministic analysis may recommend developer work, but Ops Agent
must not directly tag the tracker bot from ordinary chat, case, or support
analysis output.

The Telegram response flow is:

1. Store a pending developer-task handoff in `aibot` with source kind, safe
   callback id, sanitized task text, optional case/support context, recommended
   owner, expiry, and status.
2. Send the operator-facing text beginning with `Нужно создать задачу для этой
   проблемы`.
3. Attach inline buttons `Создать на Ильгизара` and `Создать на Дениса`.
4. Accept `callback_query` updates from Telegram.
5. On a valid, authorized, unexpired callback, emit exactly one final tracker
   command with the selected assignee.
6. Mark duplicate, stale, malformed, or unauthorized callbacks as rejected
   without sending a tracker command.

Legacy `@Jirabro_bot создай задачу...` paragraphs from Codex output are captured
as pending handoffs rather than sent directly.

## Support Dispatch

Support dispatch starts in `diaweb` on a single open support ticket card. Staff
choose `Ильгизар` or `Денис`, and `diaweb` calls
`POST /v1/admin/support/tickets/agent-dispatch` with `{ ticket_ids, owner }`.
`diaverseapi` records `ops_dispatch_requested`, the requesting staff user, and
the owner preference on the selected tickets.

`aibot` claims manually dispatched tickets through the signed Ops support API.
With `OPS_AGENT_SUPPORT_AUTO_CLAIM_ENABLED=false`, the claim flow ignores
ordinary accumulated `new` tickets and only processes manual dispatches. The
older "claim five accumulated tickets" behavior is behind that explicit flag
and should remain disabled until a reviewed rollout re-enables it.

The selected owner is a routing preference for developer-task handoff. The
support analysis may still conclude that no developer work is needed; in that
case no tracker command or pending handoff is created.

## Playbook Knowledge Base

The knowledge base stays simple and file-based:

```text
aibot/app/ops_agent/playbooks/index.yml
aibot/app/ops_agent/playbooks/payments/paid-not-credited.md
```

`index.yml` contains ids, titles, tags, symptoms, fingerprints, supported domains, risk notes, and the Markdown path. Each Markdown playbook contains:

- symptoms and examples;
- required identifiers;
- investigation checklist;
- allowed diagnostics;
- allowed actions;
- forbidden actions;
- approval rules;
- rollback notes;
- Telegram response templates;
- code pointers and related tests.

The database stores playbook ids, file paths, versions or content hashes, and case links. It does not duplicate full playbook bodies.

## Case Memory

Case memory stores concrete incidents, not general instructions. It should include:

- case id, status, actor id, Telegram chat id, and safe target identifiers;
- case type, target domain, fingerprint, playbook id, playbook version/hash;
- sanitized problem summary and operator messages;
- diagnostics summary and safe observations;
- Codex thread id, runner artifacts, and code pointers;
- action previews, approvals, execution results, idempotency keys, and audit ids;
- generated-action proposals and gate results;
- root cause, resolution, follow-up tasks, and closure summary.

Similar-case lookup order:

1. Match the playbook index by tags, symptoms, and known fingerprints.
2. Search exact or normalized fingerprints in case memory.
3. Use safe full-text/trigram search over sanitized summaries.

Embeddings can be added later only after an explicit privacy and retention decision.

## Read-Only Database Investigation

The agent may have a dedicated read-only database role for investigation. This role is for evidence gathering only.

Rules:

- no `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, DDL, advisory locks, or transaction-level mutation;
- no arbitrary raw SQL from Telegram;
- use query templates or validated readonly statements;
- enforce statement timeout and row limit;
- log query template id, duration, row count, and case id;
- do not log result payloads, secrets, raw provider callbacks, contact data, auth data, or full Telegram text;
- use application services or signed diagnostics for final interpretation when possible.

Production writes always go through registered `diaverseapi` actions.

## Action Registry

Every repair action is a typed registry entry in `diaverseapi`. Required metadata:

- action id and owner;
- risk level;
- preview support;
- idempotency scope;
- required guards and invariants;
- allowed service methods;
- required tests;
- rollback notes;
- audit fields;
- approval policy;
- safe log fields.

MVP payment actions:

- retry an existing finalizer for a paid session;
- mark a session as review-needed with an ops note;
- perform a narrow manual repair only through domain service methods when every guard passes.

Additional high-risk action:

- permanently restrict a non-protected member's ability to write in one allowlisted linked Telegram discussion group, using the Ops Agent bot as the executor.

The agent must preview before execution. Execution requires case id, actor id, idempotency key, and risk-policy result.

## Generated Actions

If no registered action can safely solve a repeated problem, Codex may author a new action as code without manual code review. The generated action still receives no authority until automated gates pass.

Required gates:

- generated patch lives in a dedicated worktree/path;
- action metadata is complete;
- static denylist blocks dangerous production access patterns;
- unit tests and relevant domain tests pass;
- migration checks pass if schema changes are present;
- action supports preview or explicitly explains why preview is impossible;
- feature flag or activation record enables the action;
- risk level and approval policy are set before use.

Generated actions cannot grant themselves arbitrary credentials, bypass registry metadata, disable audit, write production SQL directly, or change risk policy for their own execution.

## Approval And Risk Policy

| Risk | Example | Execution |
| --- | --- | --- |
| Low | retry idempotent finalizer after guards confirm paid-not-finalized | May auto-execute if registry allows |
| Medium | mark review-needed, rerun a domain repair with reversible effects | Requires Telegram approval |
| High | manual grant, conflicting state, unclear payment evidence | Requires explicit approval or break-glass process |
| Blocked | missing evidence, unsafe generated action, duplicate repair risk | Do not execute |

Approval messages must be factual and contain action id, case id, target, expected effect, guards, rollback notes, and expiry. They must not contain jokes, secrets, raw payloads, or ambiguous wording.

## Closure Format

Each case closes with a Telegram summary:

```text
Case: <case_id>
Status: repaired | not_repaired | review_required | duplicate | blocked
What happened: <short sanitized cause>
What was checked: <diagnostics and code areas>
What was done: <action ids and safe outcome>
Why it should not repeat: <code/config fix or follow-up>
Stored for next time: <playbook id, fingerprint, case-memory link>
Next owner: <repo/team/person if needed>
```

The same fields are stored in case memory.

## Tone Policy

The Telegram rendering layer may use a light internal humorous tone for progress updates and non-sensitive explanations. The tone must never reduce clarity or hide risk.

Allowed:

- "Беру лупу, открываю playbook и проверяю платежный след."
- "Похоже, финализатор споткнулся на известном месте. Сейчас сверю guards."
- "Нашел похожий кейс, достаю короткую инструкцию из памяти."

Disallowed:

- jokes in approval prompts;
- jokes around money loss, access, security, personal data, or irreversible actions;
- jokes that blame the user or operator;
- jokes in audit records, logs, or final money-impacting confirmations;
- invented confidence when evidence is incomplete.

## Security And Logging

The bot is internal-only and disabled by default. Required controls:

- allowlisted Telegram users/chats;
- feature flags for bot runtime, Codex runner, signed API, read-only DB, generated actions, and auto-activation;
- HMAC-signed `aibot` -> `diaverseapi` calls with timestamp, key id, body digest, replay window, and request id;
- separate read-only DB credentials;
- no public app-server or public Codex web endpoint;
- live Ops Agent bot identity is always protected from moderation targets;
- structured logs with request id, case id, action id, result code, and duration;
- developer-task and support-dispatch logs use safe ids, source kind, selected
  owner, counters, and text lengths only;
- no tokens, HMAC secrets, database URLs, raw Telegram text, raw support bodies,
  attachment metadata, raw provider payloads, auth headers, contact data, or raw
  production rows in logs.

## See Also

- [Ops Agent Runbook](../runbooks/ops-agent.md)
- [Staff Logging](staff-logging.md)
- [Copywriting Production Runtime](../runbooks/copywriting-production-runtime.md)
- [Workspace Architecture](../../.ai-factory/ARCHITECTURE.md)
