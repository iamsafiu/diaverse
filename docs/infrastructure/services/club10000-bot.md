# Service: club10000-bot

[Back to Infrastructure](../README.md)

## Ownership

- Owner repository: `club10000-bot`
- Runtime role: standalone Club10000 Telegram bot, Prodamus callback handling, reminders, referrals, restored bot-local PostgreSQL state
- Diaverse integration: mirrors normalized payment events into `diaverseapi` through signed internal HTTP
- `last_verified`: 2026-05-25

## Deployments

| Environment | Server | Runtime path | Runtime kind | Containers | Public route | Status |
| --- | --- | --- | --- | --- | --- | --- |
| production bot runtime | `diaverse-bots` | `/srv/club10000-bot` | Docker Compose project `club10000` using `/srv/club10000-bot/docker-compose.production.yml` | `club10000_bot`, `club10000_postgres` | `https://iamgradov.ru/payments/prodamus/callback`, `https://iamgradov.ru/webhook/bot` | bot and Postgres healthy |

## Network Shape

| Network | Members | Purpose |
| --- | --- | --- |
| `club10000_private` | `club10000_bot`, `club10000_postgres` | private bot database traffic |
| `iamgradov-site_default` | `iamgradov-caddy`, `club10000_bot` | public callback/webhook reverse proxy |

## Expected Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| bot container | `docker ps` read-only check | `club10000_bot` running and healthy |
| callback route | empty/safe callback smoke from runbook | expected validation error from bot, proving route reaches service |
| local database | read-only connectivity/status check if safe | `club10000_postgres` healthy |
| Caddy route | Caddy config validate in planned maintenance window | routes to `club10000_bot:8080` |

## Logs And Operations

- Do not commit Prodamus secrets, Telegram tokens, DB passwords, private chat data, or raw callback payloads.
- Local bot database paths can be documented, but credentials and dumps must stay out of git.
- Keep Diaverse payment-event mirroring signed and idempotent; never write directly into Diaverse backend DB from this bot.

## Runbooks

- [Diaverse Club Runbook](../../club.md)
- [Clubbot Session Notes](../../tasks/2026-05-20-clubbot-session.md)
