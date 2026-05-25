# Service: aibot

[Back to Infrastructure](../README.md)

## Ownership

- Owner repository: `aibot`
- Runtime role: internal copywriting API, worker, Telegram ingest/userbot runtimes, club creative assets
- Business truth: copywriting workflows and local service state, not Diaverse membership truth
- `last_verified`: 2026-05-25

## Deployments

| Component | Server | Runtime path | Runtime kind | Container | Exposure | Status |
| --- | --- | --- | --- | --- | --- | --- |
| copywriting API | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | `copywriting-api` | private host interface port `8090`, `copywriting_internal` | healthy |
| copywriting worker | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | `copywriting-worker` | internal only | healthy |
| copywriting userbot | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | `copywriting-userbot` | Telegram/userbot runtime | healthy |
| copywriting clubbot | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | `copywriting-clubbot` | Telegram bot runtime + signed backend calls | healthy |
| copywriting Postgres | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | `copywriting-postgres` | `copywriting_internal` only | healthy |

## Network Shape

| Network | Members | Purpose |
| --- | --- | --- |
| `copywriting_internal` | copywriting API, worker, userbot, clubbot, Postgres | all internal `aibot` service traffic |

## Expected Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| API health | `runtime_probe.py api` | healthy |
| worker heartbeat | `runtime_probe.py heartbeat` | fresh heartbeat |
| userbot heartbeat | `runtime_probe.py heartbeat` | fresh heartbeat |
| clubbot heartbeat | `runtime_probe.py heartbeat` | fresh heartbeat |
| Docker status | `docker ps --format ...` | all `aibot` containers running/healthy |

## Logs And Operations

- Do not commit Telegram API values, bot tokens, session file contents, private chat dumps, generated raw post text, or DB credentials.
- Userbot and bot runtime logs must be sanitized before documentation.
- `aibot` is not the source of truth for club membership; `diaverseapi` owns persisted club state.

## Runbooks

- [Copywriting Production Runtime](../../runbooks/copywriting-production-runtime.md)
- [Diaverse Club Runbook](../../club.md)
