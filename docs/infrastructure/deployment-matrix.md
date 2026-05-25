# Deployment Matrix

[Back to Infrastructure](README.md)

## Status

`last_verified`: 2026-05-25 from read-only inventory snapshots.

This matrix maps runtime placement. It is not the source of truth for product ownership; use [Workspace Architecture](../../.ai-factory/ARCHITECTURE.md) for that.

## Matrix

| Service | Owner repo | Server | Runtime path | Runtime kind | Public route | Internal route | Runbook |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `diaweb` production | `diaweb` | `diaverse-prod` | `/home/diaweb` | Docker Compose project `diaweb` | `https://diaverse.app` | `diaweb:3000` on `webproxy` | [copywriting runtime](../runbooks/copywriting-production-runtime.md) |
| `diaweb` development | `diaweb` | `diaverse-dev` | `/home/diaweb` | Docker Compose project `diaweb-dev` | `https://dev.diaverse.app` | `diaweb-dev:3000` on `webproxy` | [Dev site](../runbooks/dev-site-deployment.md) |
| `diaverseapi` production | `diaverseapi` | `diaverse-prod` | `/home/config` + `/home/diaverse` checkout | Docker Compose project `diaverse` | `https://api.diaverse.app`, `https://api2.diaverse.app`, `https://api3.diaverse.app` | `diaverse-api-1:8000` on `diaverse_internal`/`webproxy` | [backend update](../runbooks/update-vps-backend.md) |
| `diaverseapi` development | `diaverseapi` | `diaverse-dev` | `/home/config` + `/home/diaverse` checkout | Docker Compose project `diaverse` | `https://api.dev.diaverse.app`, `https://api2.dev.diaverse.app` | `diaverse-api-1:8000` on `diaverse_internal`/`webproxy` | [Dev site](../runbooks/dev-site-deployment.md) |
| backend worker/scheduler production | `diaverseapi` | `diaverse-prod` | `/home/config` | Docker Compose project `diaverse` | none | `diaverse-worker-1`, `diaverse-scheduler-1` | [backend update](../runbooks/update-vps-backend.md) |
| backend worker/scheduler development | `diaverseapi` | `diaverse-dev` | `/home/config` | Docker Compose project `diaverse` | none | `diaverse-worker-1`, `diaverse-scheduler-1` | [Dev site](../runbooks/dev-site-deployment.md) |
| `aibot` copywriting API | `aibot` | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | private by default | private host interface port `8090`, `copywriting-api` on `copywriting_internal` | [copywriting runtime](../runbooks/copywriting-production-runtime.md) |
| `aibot` worker | `aibot` | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | none | `copywriting-worker` + copywriting DB/queue | [copywriting runtime](../runbooks/copywriting-production-runtime.md) |
| `aibot` userbot | `aibot` | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | none | Telegram/userbot runtime, `copywriting_internal` | [copywriting runtime](../runbooks/copywriting-production-runtime.md) |
| `aibot` clubbot | `aibot` | `diaverse-bots` | `/srv/aibot` | Docker Compose project `aibot` | none | signed calls to Diaverse API, Telegram runtime | [club runbook](../club.md) |
| `club10000-bot` | `club10000-bot` | `diaverse-bots` | `/srv/club10000-bot` | Docker Compose project `club10000` | `https://iamgradov.ru/payments/prodamus/callback`, `https://iamgradov.ru/webhook/bot` | `club10000_bot:8080`, `club10000_postgres` on `club10000_private` | [club runbook](../club.md) |
| `n8n` | server config | `diaverse-prod` | `/home/config` | Docker Compose project `diaverse` | `https://n8n.diaverse.app` | `diaverse-n8n-1:5678` | server docs |
| GitLab | server config | `diaverse-dev` | `/home/config` | Docker Compose project `diaverse` | `https://gitlab.diaverse.app`, SSH on host port `2222` | `gitlab:80` | server docs |
| `iamgradov` landing | server config | `diaverse-bots` | `/srv/iamgradov-site` | Docker Compose project `iamgradov-site` | `https://iamgradov.ru`, `https://www.iamgradov.ru` | Caddy static files and selected reverse proxies | [club runbook](../club.md) |
| EAS update proxy | server config | `diaverse-bots` | `/srv/iamgradov-site` | Caddy | `https://updates.diaverse.app`, `https://assets.diaverse.app` | external Expo/EAS upstreams | server docs |

## Notes

- Raw inventory snapshots stay under `.tmp/server-inventory/` and are not committed.
- Host-port exposures that need security review are tracked in [Domains And Ports](domains-and-ports.md).
- For live server operations, follow the linked runbooks rather than copying commands from this matrix.
