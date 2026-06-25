# AI Cofounder Architecture

## Role

`diaverse-ai-cofounder` is a private operations and content orchestration runtime
for Diaverse. It is not a product backend and is not a source of truth for
business data.

It may:

- read curated workspace context and Diaverse product maps
- read approved aggregate analytics, finance, and content metadata through
  service APIs
- generate content strategy and draft article payloads
- send Telegram reports and human approval requests
- import content as drafts through the content factory

It must not:

- publish content
- write to Diaverse product databases directly
- hold broad production database DSNs
- mount SSH keys, Docker socket, or payment provider credentials
- expose the bridge/admin surface publicly
- run unattended shell/code automation against production repositories

## Integration Map

```text
diaverse-ai-cofounder
  |-- reads curated docs/repo maps
  |-- reads aggregate summaries --> diaverseapi internal AI Cofounder API
  |-- reads catalog/fragments ----> diaverse-content internal content API
  |-- writes draft imports -------> diaverse-content draft-only import API
  |-- sends reports/gates --------> Telegram allowlisted founder channel
  `-- review surface ------------> diaweb /staff/content
```

`diaweb` remains the browser-facing staff review surface. Publishing is a human
staff action. Telegram approval only advances internal AI Cofounder workflows.

## Runtime Boundaries

The foreign-server runtime is containerized:

- unprivileged container user
- named Docker volumes for SQLite, bridge sessions, and generated artifacts
- file-based secrets mounted read-only
- bridge published on host loopback only
- no Docker socket mount
- no production SSH key material inside containers

Schedules stay disabled until secrets, allowlist, read APIs, draft import, and
Telegram dry-run are smoke-tested.

## Observability

Routine execution writes append-only records:

- `event.routine.trigger`
- `audit.routine.start`
- `audit.routine.end`
- `audit.run.journal`
- `audit.budget.deny` when hard caps block calls
- `audit.routine.control_alert` when a budget hit or repeated failure occurs

Run journals store metadata only: routine ids, status, duration, spend estimate,
token count, tool count, artifact record ids, approval state, and error code.
They do not store prompts, full responses, secrets, request bodies, chat ids, or
payment payloads.

## Budget And Failure Controls

LLM hard caps are enforced before network calls through `config/budget.md`:

- per-cycle input tokens
- daily USD
- weekly USD
- monthly USD

External Diaverse API and content-factory calls use retry/backoff and a short
circuit breaker for temporary failures. Permanent authorization/validation
errors fail fast.

## Rollback Model

Application rollback is release-symlink based:

```text
/srv/diaverse-ai-cofounder/current -> releases/<commit>
/srv/diaverse-ai-cofounder/shared  -> private env, config, secrets
```

Rolling back code must not delete Docker named volumes. Volume restore is a
separate operation and requires an explicit backup decision.
