# Production Server

[Back to Infrastructure](../README.md)

---
owner: workspace
status: canonical
domain: infrastructure
source_of_truth: live server inventory + deployment runbooks
last_reviewed: 2026-05-25
review_after: 2026-06-25
---

## Role

Production application host for the public Diaverse web app, backend API, n8n, Postgres, Redis, and Traefik. Inventory alias: `diaverse-prod`.

Observed OS: Debian 12. Hostname: `Landau`.

## Access

Preferred SSH alias: `diaverse-prod`

Do not document private key paths or paste raw SSH commands with identity files in committed docs.

## Paths

| Path | Purpose | Status |
| --- | --- | --- |
| `/home/config` | `diaverse` Docker Compose project, Traefik config, backend runtime services, Postgres/Redis/n8n runtime data | Verified 2026-05-25 |
| `/home/config/docker-compose.yml` | Active production backend/infrastructure compose file | Verified 2026-05-25 |
| `/home/config/traefik.toml` | Traefik config file | Verified 2026-05-25 |
| `/home/diaverse` | `diaverseapi` checkout, branch `main`, deployed commit `f899974e` | Verified 2026-05-25 |
| `/home/diaweb` | `diaweb` checkout, branch `master`, deployed commit `914e647` | Verified 2026-05-25 |
| `/home/diaweb/docker-compose.traefik.yml` | Active production frontend compose file | Verified 2026-05-25 |

## Docker / Compose

| Project | Path | Containers | Ports / exposure | Owner repo |
| --- | --- | --- | --- | --- |
| `diaverse` | `/home/config/docker-compose.yml` | `diaverse-api-1`, `diaverse-worker-1`, `diaverse-scheduler-1`, `diaverse-postgresql-1`, `diaverse-redis-1`, `diaverse-n8n-1`, `diaverse_traefik` | Traefik public `80/443`; API host port `8000`; Postgres host port `5432`; Redis internal; n8n through Traefik | `diaverseapi` + server config |
| `diaweb` | `/home/diaweb/docker-compose.traefik.yml` | `diaweb` | Container port `3000`, routed by Traefik | `diaweb` |

## Docker Networks

| Network | Members | Purpose |
| --- | --- | --- |
| `diaverse_internal` | backend API, worker, scheduler, Postgres, Redis, n8n | backend internal runtime |
| `webproxy` | Traefik, `diaweb`, API, n8n | public reverse-proxy routing |

## Systemd

| Unit | Purpose | Logs | Status |
| --- | --- | --- | --- |
| `docker.service` | Docker runtime for app containers | `journalctl -u docker` | running |
| `nginx.service` | Host nginx listener; purpose needs review against Traefik setup | `journalctl -u nginx` | running |

## Reverse Proxy

| Domain | Config | Upstream | TLS |
| --- | --- | --- | --- |
| `diaverse.app` | Traefik labels on `diaweb` in `/home/diaweb/docker-compose.traefik.yml` | `diaweb:3000` | Traefik cert resolver |
| `api.diaverse.app`, `api2.diaverse.app`, `api3.diaverse.app` | Traefik labels on `diaverse-api-1` in `/home/config/docker-compose.yml` | `diaverse-api-1:8000` | Traefik cert resolver |
| `n8n.diaverse.app` | Traefik labels on `diaverse-n8n-1` | `diaverse-n8n-1:5678` | Traefik cert resolver |

## Data / Volumes / Backups

| Item | Location | Backup expectation | Notes |
| --- | --- | --- | --- |
| Backend database | Docker volume/data under `/home/config` | Requires production DB backup policy verification | Do not expose credentials in docs |
| Redis | Docker-managed runtime under `/home/config` | Verify persistence needs per feature | Internal runtime dependency |
| Traefik certificates | Traefik state under `/home/config` | Preserve ACME state and permissions | Do not copy certificate material |
| n8n data | Docker-managed runtime under `/home/config` | Requires backup review if workflows are important | Public route exists |

## Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| Docker status | `docker ps --format ...` | expected containers running; `diaweb` healthy |
| Frontend route | `https://diaverse.app/api/health` or equivalent app health | healthy response |
| API route | `https://api.diaverse.app/` | backend metadata or expected API response |
| Traefik | `docker ps` / route-label inspect | `diaverse_traefik` running and route labels present |

## Update / Restart

- Frontend operations: [Copywriting Production Runtime](../../runbooks/copywriting-production-runtime.md) when copywriting-facing web behavior is affected.
- Backend operations: [Backend update](../../runbooks/update-vps-backend.md).
- Do not restart services as part of inventory collection.

## Open Questions

- Host ports `8000` and `5432` are publicly bound by Docker on this host; verify whether both are intentional and firewall-restricted.
- Host nginx is running and listening separately from Traefik; document its owner or remove it from the expected topology after review.
- A nonstandard listener on host port `9999` was observed; identify or close it before marking the production port map clean.
