# Service: diaverseapi

[Back to Infrastructure](../README.md)

## Ownership

- Owner repository: `diaverseapi`
- Runtime role: core backend for auth, cabinet, game, RBAC, payments, staff domains, and club domain state
- Business truth: backend database and service code
- `last_verified`: 2026-05-25

## Deployments

| Environment | Server | Runtime path | Runtime kind | Containers | Public route | Status |
| --- | --- | --- | --- | --- | --- | --- |
| production | `diaverse-prod` | `/home/config` runtime, `/home/diaverse` checkout | Docker Compose project `diaverse` | `diaverse-api-1`, `diaverse-worker-1`, `diaverse-scheduler-1`, `diaverse-postgresql-1`, `diaverse-redis-1` | `api.diaverse.app`, `api2.diaverse.app`, `api3.diaverse.app` | running |
| development | `diaverse-dev` | `/home/config` runtime, `/home/diaverse` checkout | Docker Compose project `diaverse` | `diaverse-api-1`, `diaverse-worker-1`, `diaverse-scheduler-1`, `diaverse-postgresql-1`, `diaverse-redis-1` | `api.dev.diaverse.app`, `api2.dev.diaverse.app` | running; Postgres healthy |

## Network Shape

| Environment | Proxy | Upstream | Internal network |
| --- | --- | --- | --- |
| production | Traefik on `diaverse-prod` | `diaverse-api-1:8000` | `diaverse_internal`, `webproxy` |
| development | Traefik on `diaverse-dev` | `diaverse-api-1:8000` | `diaverse_internal`, `webproxy` |

## Expected Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| API root | `curl -i <api-route>/` | backend metadata or expected response |
| Docker status | `docker ps --format ...` | backend API, worker, scheduler, Postgres, Redis running |
| migration state | Alembic read-only history/current check through backend runbook | expected revision |
| club integration | signed internal event smoke only when planned | no direct DB writes from bot runtimes |

## Logs And Operations

- Keep DB credentials, signing secrets, raw request bodies, and provider callback payloads out of docs.
- Verify Alembic/database operations through backend runbooks, not inventory scripts.
- Host-bound API and Postgres ports are observed on both prod and dev; see [Domains And Ports](../domains-and-ports.md) for security review notes.

## Runbooks

- [Backend update](../../runbooks/update-vps-backend.md)
- [Dev Site Deployment](../../runbooks/dev-site-deployment.md)
- [Diaverse Club Runbook](../../club.md)
