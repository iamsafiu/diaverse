# Service: Reverse Proxy

[Back to Infrastructure](../README.md)

## Ownership

Reverse proxy ownership is per server. Inventory identifies which proxy owns each route and which config path or container labels describe the route.

`last_verified`: 2026-05-25

## Deployments

| Server | Proxy | Config path | Public ports | Routed domains | Status |
| --- | --- | --- | --- | --- | --- |
| `diaverse-prod` | Traefik `v2.11` container `diaverse_traefik`; host nginx also running | `/home/config/traefik.toml`; labels in `/home/config/docker-compose.yml` and `/home/diaweb/docker-compose.traefik.yml` | `80/443`; host nginx on `8443` needs owner review | `diaverse.app`, `api.diaverse.app`, `api2.diaverse.app`, `api3.diaverse.app`, `n8n.diaverse.app` | running |
| `diaverse-dev` | Traefik `v2.11` container `diaverse_traefik` | `/home/config/traefik.toml`; labels in `/home/config/docker-compose.yml` and `/home/diaweb/docker-compose.dev-traefik.yml` | `80/443`; GitLab SSH `2222` | `dev.diaverse.app`, `api.dev.diaverse.app`, `api2.dev.diaverse.app`, `gitlab.diaverse.app` | running |
| `diaverse-bots` | Caddy `2` container `iamgradov-caddy` | `/srv/iamgradov-site/Caddyfile` | `80/443` TCP, `443` UDP | `iamgradov.ru`, `www.iamgradov.ru`, `updates.diaverse.app`, `assets.diaverse.app` | running |

## Route Summary

| Route | Server | Proxy | Upstream |
| --- | --- | --- | --- |
| `https://diaverse.app` | `diaverse-prod` | Traefik | `diaweb:3000` |
| `https://api.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-api-1:8000` |
| `https://api2.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-api-1:8000` |
| `https://api3.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-api-1:8000` |
| `https://n8n.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-n8n-1:5678` |
| `https://dev.diaverse.app` | `diaverse-dev` | Traefik | `diaweb-dev:3000` |
| `https://api.dev.diaverse.app` | `diaverse-dev` | Traefik | `diaverse-api-1:8000` |
| `https://api2.dev.diaverse.app` | `diaverse-dev` | Traefik | `diaverse-api-1:8000` |
| `https://gitlab.diaverse.app` | `diaverse-dev` | Traefik | `gitlab:80` |
| `https://iamgradov.ru` | `diaverse-bots` | Caddy | static files under `/srv`, selected routes to Club10000 bot |
| `https://iamgradov.ru/payments/prodamus/callback` | `diaverse-bots` | Caddy | `club10000_bot:8080` |
| `https://iamgradov.ru/webhook/bot` | `diaverse-bots` | Caddy | `club10000_bot:8080` |
| `https://updates.diaverse.app` | `diaverse-bots` | Caddy | Expo EAS update upstream |
| `https://assets.diaverse.app` | `diaverse-bots` | Caddy | Expo EAS asset upstream |

## Expected Checks

| Check | Command shape | Expected result |
| --- | --- | --- |
| Traefik container | `docker ps` / labels inspect | running and routes attached |
| Caddy container | `docker ps` / config path review | running and routes attached |
| public TLS | `openssl s_client` or curl headers | valid certificate |
| route smoke | route-specific curl from runbook | expected HTTP status and upstream response |

## Safety

- Do not paste full proxy configs if they contain secrets or internal-only headers.
- Prefer route summaries: domain, upstream, TLS owner, and config path.
- Keep raw certificate material out of docs.
- Host nginx on `diaverse-prod` and unknown/nonstandard listeners must be reviewed separately before treating the port map as clean.

## Runbooks

- [Dev Site Deployment](../../runbooks/dev-site-deployment.md)
- [Copywriting Production Runtime](../../runbooks/copywriting-production-runtime.md)
