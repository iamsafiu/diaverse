# Bots And Landing Server

[Back to Infrastructure](../README.md)

---
owner: workspace
status: canonical
domain: infrastructure
source_of_truth: live server inventory + bot runbooks
last_reviewed: 2026-05-25
review_after: 2026-06-25
---

## Role

Foreign-hosted server for Telegram bot runtimes, copywriting service runtimes, Club10000 bot callback handling, the `iamgradov.ru` landing site, and EAS update proxy routes. Inventory alias: `diaverse-bots`.

Observed OS: Ubuntu 24.04 LTS. Hostname: `discontent`.

## Access

Preferred SSH alias: `diaverse-bots`

Do not document private key paths or paste raw SSH commands with identity files in committed docs.

## Paths

| Path | Purpose | Status |
| --- | --- | --- |
| `/srv/aibot` | `aibot` checkout, branch `dev`, deployed commit `d1281ee`, production copywriting compose | Verified 2026-05-25 |
| `/srv/aibot/docker-compose.prod.yml` | Active `aibot` copywriting runtime compose file | Verified 2026-05-25 |
| `/srv/club10000-bot` | Club10000 bot runtime and compose files | Verified 2026-05-25 |
| `/srv/club10000-bot/docker-compose.production.yml` | Active Club10000 production compose file | Verified 2026-05-25 |
| `/srv/iamgradov-site` | Caddy static site/proxy project | Verified 2026-05-25 |
| `/srv/iamgradov-site/Caddyfile` | Active Caddy routing config | Verified 2026-05-25 |
| `/srv/iamgradov-watchdog` | Landing watchdog compose project | Verified 2026-05-25 |
| `/opt/bottg` | Separate bot compose project | Verified 2026-05-25 |
| `/srv/diaverse-auth-bot`, `/srv/diaverse-auth-bot-dev` | Auth bot compose projects | Verified 2026-05-25 |

## Docker / Compose

| Project | Path | Containers | Ports / exposure | Owner repo |
| --- | --- | --- | --- | --- |
| `aibot` | `/srv/aibot/docker-compose.prod.yml` | `copywriting-api`, `copywriting-worker`, `copywriting-userbot`, `copywriting-clubbot`, `copywriting-postgres` | `copywriting-api` bound on a private host interface at port `8090`; Postgres internal | `aibot` |
| `club10000` | `/srv/club10000-bot/docker-compose.production.yml` | `club10000_bot`, `club10000_postgres` | bot listens on container port `8080`; routed by Caddy; Postgres internal | `club10000-bot` |
| `iamgradov-site` | `/srv/iamgradov-site/docker-compose.yml` | `iamgradov-caddy` | public `80/443` TCP and `443` UDP | server config |
| `iamgradov-watchdog` | `/srv/iamgradov-watchdog/docker-compose.yml` | `iamgradov-watchdog` | internal monitoring/runtime health | server config |
| `bottg` | `/opt/bottg/docker-compose.yml` + override | `bottg_bot` | Telegram runtime | external bot project |
| `diaverse-auth-bot` | `/srv/diaverse-auth-bot/docker-compose.yml` | `diaverse-auth-bot` | Telegram runtime | auth bot project |
| `diaverse-auth-bot-dev` | `/srv/diaverse-auth-bot-dev/docker-compose.yml` | `diaverse-auth-bot-dev` | Telegram runtime | auth bot project |

## Docker Networks

| Network | Members | Purpose |
| --- | --- | --- |
| `copywriting_internal` | copywriting API, worker, userbot, clubbot, Postgres | internal `aibot` runtime |
| `club10000_private` | Club10000 bot and Postgres | private bot database network |
| `iamgradov-site_default` | Caddy and Club10000 bot | public callback/webhook routing |
| `iamgradov-watchdog_default` | watchdog | landing health monitoring |
| `bottg_default`, `diaverse-auth-bot_default`, `diaverse-auth-bot-dev_default` | respective bot containers | isolated bot runtimes |

## Systemd

| Unit | Purpose | Logs | Status |
| --- | --- | --- | --- |
| `docker.service` | Docker runtime for bot and landing containers | `journalctl -u docker` | running |

## Reverse Proxy

| Domain | Config | Upstream | TLS |
| --- | --- | --- | --- |
| `iamgradov.ru`, `www.iamgradov.ru` | `/srv/iamgradov-site/Caddyfile` | static files under `/srv`; selected routes to `club10000_bot:8080` | Caddy automatic TLS |
| `iamgradov.ru/payments/prodamus/callback` | `/srv/iamgradov-site/Caddyfile` | `club10000_bot:8080` | Caddy automatic TLS |
| `iamgradov.ru/webhook/bot` | `/srv/iamgradov-site/Caddyfile` | `club10000_bot:8080` | Caddy automatic TLS |
| `updates.diaverse.app` | `/srv/iamgradov-site/Caddyfile` | Expo EAS update upstream | Caddy automatic TLS |
| `assets.diaverse.app` | `/srv/iamgradov-site/Caddyfile` | Expo EAS asset upstream | Caddy automatic TLS |

## Data / Volumes / Backups

| Item | Location | Backup expectation | Notes |
| --- | --- | --- | --- |
| Copywriting database | Docker volume for `copywriting-postgres` | Requires backup policy for internal copywriting history | Do not copy credentials |
| Copywriting userbot sessions | Docker volumes under `aibot` compose | Sensitive; backup only through secure operator process | Never commit session contents |
| Copywriting generated/reference assets | Docker volumes under `aibot` compose | Preserve if drafts/assets matter | Can be large |
| Club10000 database | Docker volume for `club10000_postgres` | Requires backup before bot migrations | Credentials and dumps stay out of git |
| Caddy certificates | Docker volume/config under `iamgradov-site` | Preserve automatic TLS state | Do not copy certificate material |

## Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| Docker status | `docker ps --format ...` | expected bot/copywriting containers running |
| Copywriting API | `runtime_probe.py api` from `copywriting-api` | healthy |
| Copywriting worker/userbot/clubbot | `runtime_probe.py heartbeat` | fresh heartbeat |
| Club10000 bot | Docker health state | healthy |
| Caddy routing | public route smoke checks for landing/callback/webhook | expected HTTP statuses |

## Update / Restart

- See [Diaverse Club Runbook](../../club.md).
- See [Clubbot Session Notes](../../tasks/2026-05-20-clubbot-session.md).
- Do not restart bot runtimes as part of inventory collection.

## Open Questions

- Confirm backup cadence for `copywriting-postgres` and `club10000_postgres`.
- Confirm ownership and lifecycle for `bottg`, `diaverse-auth-bot`, and `diaverse-auth-bot-dev`.
- Caddy contains a direct-host HTTP fallback block; it is intentionally omitted from public docs and should be reviewed separately if host-level routing changes.
