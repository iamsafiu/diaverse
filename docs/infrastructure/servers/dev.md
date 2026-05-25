# Development Server

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

Development backend and web runtime for Diaverse plus self-managed GitLab. Inventory alias: `diaverse-dev`.

Observed OS: Debian 12. Hostname: `msk-1-vm-r93x`.

## Access

Preferred SSH alias: `diaverse-dev`

Do not document private key paths or paste raw SSH commands with identity files in committed docs.

## Paths

| Path | Purpose | Status |
| --- | --- | --- |
| `/home/config` | `diaverse` Docker Compose project, Traefik config, GitLab, backend infrastructure | Verified 2026-05-25 |
| `/home/config/docker-compose.yml` | Active dev backend/infrastructure compose file | Verified 2026-05-25 |
| `/home/config/traefik.toml` | Traefik config file | Verified 2026-05-25 |
| `/home/diaverse` | `diaverseapi` checkout, branch `dev`, deployed commit `377e1bb1` | Verified 2026-05-25 |
| `/home/diaweb` | `diaweb` checkout, branch `dev`, deployed commit `fa88892` | Verified 2026-05-25 |
| `/home/diaweb/docker-compose.dev-traefik.yml` | Active dev frontend compose file | Verified 2026-05-25 |

## Docker / Compose

| Project | Path | Containers | Ports / exposure | Owner repo |
| --- | --- | --- | --- | --- |
| `diaverse` | `/home/config/docker-compose.yml` | `diaverse-api-1`, `diaverse-worker-1`, `diaverse-scheduler-1`, `diaverse-postgresql-1`, `diaverse-redis-1`, `diaverse_traefik`, `gitlab` | Traefik public `80/443`; API host port `8000`; Postgres host port `5432`; GitLab SSH host port `2222` | `diaverseapi` + server config |
| `diaweb-dev` | `/home/diaweb/docker-compose.dev-traefik.yml` | `diaweb-dev` | Container port `3000`, routed by Traefik | `diaweb` |

## Docker Networks

| Network | Members | Purpose |
| --- | --- | --- |
| `diaverse_internal` | backend API, worker, scheduler, Postgres, Redis | backend internal runtime |
| `webproxy` | Traefik, API, `diaweb-dev`, GitLab | public reverse-proxy routing |
| `diaverse_gitlab` | GitLab | GitLab internal runtime |

## Systemd

| Unit | Purpose | Logs | Status |
| --- | --- | --- | --- |
| `docker.service` | Docker runtime for dev containers | `journalctl -u docker` | running |

## Reverse Proxy

| Domain | Config | Upstream | TLS |
| --- | --- | --- | --- |
| `dev.diaverse.app` | Traefik labels on `diaweb-dev` in `/home/diaweb/docker-compose.dev-traefik.yml` | `diaweb-dev:3000` | Traefik cert resolver |
| `api.dev.diaverse.app`, `api2.dev.diaverse.app` | Traefik labels on `diaverse-api-1` in `/home/config/docker-compose.yml` | `diaverse-api-1:8000` | Traefik cert resolver |
| `gitlab.diaverse.app` | Traefik labels on `gitlab` | `gitlab:80` plus SSH on host port `2222` | Traefik cert resolver |

## Data / Volumes / Backups

| Item | Location | Backup expectation | Notes |
| --- | --- | --- | --- |
| Dev database | Docker volume/data under `/home/config` | Useful for dev continuity, not production truth | Do not copy credentials |
| GitLab data | Docker-managed data under `/home/config/gitlab` | Requires separate backup policy if used as source hosting | Large runtime footprint |
| Traefik certificates | Traefik state under `/home/config` | Preserve ACME state and permissions | Do not copy certificate material |

## Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| Dev web health | `curl -fsS https://dev.diaverse.app/api/health` | `diaweb` health JSON |
| Dev API root | `curl -i https://api.dev.diaverse.app/` | backend metadata or expected response |
| Docker status | `docker ps --format ...` | expected containers running; `diaweb-dev`, Postgres, and GitLab healthy |

## Update / Restart

- See [Dev Site Deployment](../../runbooks/dev-site-deployment.md).
- Do not run `--remove-orphans` from unrelated compose projects while dev web is running.

## Open Questions

- Root filesystem is at roughly 83% usage; review Docker images/build cache and GitLab data before large deploys.
- Host ports `8000` and `5432` are publicly bound by Docker on this host; verify whether both are intentional and firewall-restricted.
- `/srv/clubbot` compose files exist on the host but no active Club10000 containers were observed there; confirm whether this is legacy material.
