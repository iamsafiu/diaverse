# Ops Agent Runbook

Status: planned MVP
Last updated: 2026-06-26

## Purpose

This runbook describes how trusted operators should use the internal Telegram Codex Ops Agent after the MVP is deployed. The first supported case type is: a user paid, but the entitlement or credit was not granted.

The bot helps investigate and repair cases, but it is not a free-form production shell. Product mutations happen only through registered `diaverseapi` actions.

## Operating Modes

| Mode | Use when | Command |
| --- | --- | --- |
| Chat mode | Ask questions, explain playbooks, summarize cases, continue a non-operational thread | `/chat`, `/mode chat` |
| Case mode | Investigate or repair a real incident | `/ops`, `/case`, `/mode ops` |

Core commands:

- `/chat <message>` - ask without creating a case or executing actions.
- `/ops <incident>` - create or continue an operational case.
- `/case <case_id>` - continue a known case.
- `/status [case_id]` - show current progress.
- `/close [case_id]` - close the case after summary.
- `/mode chat|ops` - change default mode for the thread.
- `/playbook <query>` - show matching playbook summary.
- `/approve <approval_id>` - approve a pending action.
- `/cancel <approval_id>` - reject a pending action.

Free-form incident messages can route to Case mode when the classifier detects operational intent. If the classifier is unsure, the bot should ask one short clarification instead of starting repairs.

## Start A Payment Case

Operator message:

```text
/ops пользователь <safe identifier> оплатил, но начисление не пришло
```

Expected bot flow:

1. Verify the Telegram user/chat is allowlisted.
2. Create or resume an `ops_agent_cases` record.
3. Sanitize the operator message before storage.
4. Select `payments/paid-not-credited` from the playbook index.
5. Search case memory for the same fingerprint or similar closure.
6. Collect missing safe identifiers if needed.
7. Run signed `diaverseapi` diagnostics and read-only DB checks.
8. Start or resume a Codex investigation thread with playbook, case memory, diagnostics, and code pointers.
9. Preview the registered action, or propose a generated action if no action exists.
10. Apply approval policy.
11. Execute only registered actions.
12. Return closure summary and store the result for next time.

## Payment Case Checklist

Use this checklist for "paid but not credited":

- identify the user by a safe internal id, mapped Telegram id, payment session id, public checkout reference, or allowed provider invoice id;
- confirm the payment session exists;
- confirm payment status and finalization status;
- check `domain_code`, `source_ref`, idempotency key, timestamps, finalizer error category, and related entitlement state;
- detect whether the case is already granted, not paid, paid-not-finalized, finalizer-failed, duplicate, or review-required;
- preview the repair before execution;
- confirm the preview references the expected target and no duplicate grant risk is present;
- execute according to risk policy;
- close with root cause, action result, and follow-up code/config fix.

Forbidden by default:

- direct production write SQL;
- raw provider payload dumps in Telegram;
- manual grant without guards;
- duplicate repair when entitlement already exists;
- action execution from Chat mode;
- action execution without case id and idempotency key.

## Approval Rules

Low-risk actions may auto-execute only when the registry explicitly allows it and every guard passes. Example: retry an idempotent finalizer for a paid session that is not finalized.

Medium-risk actions require Telegram approval. Example: mark review-needed or run a reversible domain repair.

High-risk actions require explicit approval or break-glass handling. Example: manual grant, conflicting evidence, unclear payment state, or an irreversible product mutation.

Blocked actions do not execute. Common reasons:

- missing payment evidence;
- generated action failed safety gates;
- duplicate entitlement risk;
- diagnostics disagree;
- target user cannot be safely identified;
- registry metadata is incomplete.

Approval prompt must contain:

- case id;
- action id;
- target identifier;
- expected effect;
- guards passed and failed;
- risk level;
- rollback notes;
- expiry;
- `/approve <approval_id>` and `/cancel <approval_id>` commands.

No jokes in approval prompts.

## Generated Action Flow

When no existing action can solve the case:

1. Codex writes a generated-action proposal in the configured worktree/path.
2. The proposal records the missing capability, action metadata, tests, rollback notes, and activation plan.
3. Automated gates run.
4. If gates fail, the action remains inactive and the case is marked `review_required` or `blocked`.
5. If gates pass, the action can be activated according to generated-action policy.
6. The bot previews the newly registered action before any execution.
7. Risk policy still decides whether approval is required.

Generated action gates must block dangerous patterns such as direct production write SQL, credential changes, audit bypass, feature flag bypass, or self-changing risk policy.

## Operator Message Style

The bot may be lightly humorous in progress updates, but sensitive states stay factual.

Allowed examples:

```text
Беру лупу, сверяю оплату и playbook. Пока ничего не начисляю.
```

```text
Нашел похожий кейс в памяти. Проверяю, тот ли это сценарий, чтобы не устроить двойное начисление.
```

```text
Финализатор выглядит подозрительно знакомо. Запускаю preview действия, без записи в продуктовые данные.
```

Factual-only messages:

- approval prompts;
- action execution confirmations;
- money-impacting final summaries;
- security/access errors;
- audit notes;
- break-glass instructions.

## Closure Template

```text
Case: <case_id>
Status: <repaired | not_repaired | review_required | duplicate | blocked>
Проблема: <sanitized one-line summary>
Проверено: <diagnostics, playbook id, similar case if any>
Сделано: <action id, result, audit id>
Причина: <root cause or strongest evidence>
Чтобы не повторилось: <code/config follow-up>
Сохранено в память: <fingerprint, playbook id>
```

If repair was not executed, the summary must say exactly why.

## Failure Modes

| Failure | Operator response |
| --- | --- |
| Telegram allowlist rejects user | Do not process. Ask owner to update allowlist through normal deploy/config flow. |
| Codex runner timeout | Keep case open, store timeout artifact, offer retry. |
| `diaverseapi` diagnostics unavailable | Do not execute actions. Mark case `review_required`. |
| Read-only DB unavailable | Continue only with service diagnostics if enough evidence exists. Otherwise pause. |
| Action preview fails | Do not execute. Store failed preview and reason. |
| Approval expires | Cancel execution and require a new preview. |
| Generated action gates fail | Keep proposal inactive and return gate failures. |
| Duplicate grant risk | Block execution and close as duplicate or review-required. |

## Rollback And Disablement

Disable in this order when the agent misbehaves:

1. Disable action execution feature flag.
2. Disable generated-action auto-activation.
3. Disable Codex runner feature flag.
4. Disable Telegram ops-agent runtime.
5. Revoke or rotate read-only DB credentials if investigation access is suspected unsafe.
6. Keep case memory and playbooks for audit unless retention policy says otherwise.

Rollback should not delete case records or audit events.

## Smoke Checks

Run these before production enablement:

- allowlisted operator can use `/chat`;
- non-allowlisted Telegram user is rejected without case creation;
- `/chat` cannot create a repair action or execute anything;
- `/ops пользователь оплатил, начисления нет` creates a case;
- payment playbook is selected from `index.yml`;
- read-only DB inspector rejects write and DDL statements;
- signed `diaverseapi` diagnostics reject invalid HMAC, stale timestamp, and replayed request id;
- Codex runner emits parseable JSONL and persists thread correlation;
- action preview requires case id and idempotency key;
- low-risk auto-execution works only for allowlisted action ids;
- medium/high-risk action requires `/approve`;
- generated action with unsafe code remains inactive;
- final summary stores fingerprint, playbook id, and resolution.

## Documentation Hygiene

Do not put secrets, tokens, raw environment values, private server inventory, private IPs, SSH commands, raw provider payloads, raw Telegram transcripts, or production rows in this runbook.

Use [Telegram Codex Ops Agent](../architecture/ops-agent.md) as the architecture source of truth.

## Deployment Wiring

The MVP runtime lives in `aibot` as Docker Compose service
`copywriting-ops-agent` with role `COPYWRITING_RUNTIME_ROLE=ops-agent-bot`.
It has no public HTTP route and uses Telegram polling, the copywriting
database for sanitized case memory, signed `diaverseapi` endpoints for
diagnostics/actions, and an optional local Codex CLI runner.

Runtime state paths:

- `OPS_AGENT_CODEX_HOME`: `/var/lib/copywriting/ops-agent/codex-home`
- `OPS_AGENT_CODEX_WORKSPACE`: `/var/lib/copywriting/ops-agent/workspace`
- `OPS_AGENT_GENERATED_ACTION_WORKTREE`:
  `/var/lib/copywriting/ops-agent/generated-actions`

Before enabling Codex, verify from the service environment that `codex exec
--json --sandbox read-only` works, that `CODEX_HOME` is already authenticated,
and that no public Codex app-server is exposed. For headless hosts, official
Codex docs describe device-code login and access-token based automation; for
programmatic CLI workflows they recommend API-key auth and explicitly warn not
to expose Codex execution in untrusted or public environments.

Private deploy checklist:

- apply `aibot/migrations/20260626_0001_ops_agent_cases.sql`;
- set Telegram bot token and at least one allowlist env var;
- set `aibot` -> `diaverseapi` HMAC key id/secret on both sides;
- set a dedicated read-only DB URL for investigation;
- keep `OPS_AGENT_CODEX_SANDBOX_MODE=read-only` for MVP investigation;
- start `copywriting-ops-agent`;
- smoke test `/chat`, `/ops`, `/status`, `/playbook`, and an approval dry run
  in a non-production Telegram chat first.
