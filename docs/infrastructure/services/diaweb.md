# Service: diaweb

[Back to Infrastructure](../README.md)

## Ownership

- Owner repository: `diaweb`
- Runtime role: browser-facing frontend and same-origin BFF layer
- Business truth: frontend behavior only; backend state remains in `diaverseapi`
- `last_verified`: 2026-05-25

## Deployments

| Environment | Server | Runtime path | Runtime kind | Container | Public route | Status |
| --- | --- | --- | --- | --- | --- | --- |
| production | `diaverse-prod` | `/home/diaweb` | Docker Compose project `diaweb` using `/home/diaweb/docker-compose.traefik.yml` | `diaweb` | `https://diaverse.app` | running, Docker health healthy |
| development | `diaverse-dev` | `/home/diaweb` | Docker Compose project `diaweb-dev` using `/home/diaweb/docker-compose.dev-traefik.yml` | `diaweb-dev` | `https://dev.diaverse.app` | running, Docker health healthy |

## Network Shape

| Environment | Proxy | Upstream | Notes |
| --- | --- | --- | --- |
| production | Traefik on `diaverse-prod` | `diaweb:3000` on `webproxy` | public app route only observed for `diaverse.app` |
| development | Traefik on `diaverse-dev` | `diaweb-dev:3000` on `webproxy` | dev route uses HTTPS redirect middleware |

## Expected Health Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| container status | `docker ps --format ...` on target server | frontend container running and healthy |
| public app health | public route `/api/health` | status JSON |
| BFF copywriting path | same-origin staff route smoke test | request reaches internal copywriting API through configured server-side URL |

## Logs And Operations

- Prefer linked runbooks for deploy/restart actions.
- Do not expose frontend environment contents in docs.
- If copywriting UI breaks, verify both `diaweb` and `aibot` runtime placement before restarting services.

## Runbooks

- [Dev Site Deployment](../../runbooks/dev-site-deployment.md)
- [Copywriting Production Runtime](../../runbooks/copywriting-production-runtime.md)
