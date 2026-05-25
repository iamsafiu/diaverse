# Domains And Ports

[Back to Infrastructure](README.md)

## Status

`last_verified`: 2026-05-25 from read-only inventory snapshots.

## Public Entry Points

| Domain | Server | Reverse proxy | Upstream | Notes |
| --- | --- | --- | --- | --- |
| `diaverse.app` | `diaverse-prod` | Traefik | `diaweb:3000` | production frontend |
| `api.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-api-1:8000` | production API |
| `api2.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-api-1:8000` | production API alternate route |
| `api3.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-api-1:8000` | production API alternate route |
| `n8n.diaverse.app` | `diaverse-prod` | Traefik | `diaverse-n8n-1:5678` | workflow automation |
| `dev.diaverse.app` | `diaverse-dev` | Traefik | `diaweb-dev:3000` | development frontend |
| `api.dev.diaverse.app` | `diaverse-dev` | Traefik | `diaverse-api-1:8000` | development API |
| `api2.dev.diaverse.app` | `diaverse-dev` | Traefik | `diaverse-api-1:8000` | development API alternate route |
| `gitlab.diaverse.app` | `diaverse-dev` | Traefik | `gitlab:80` | self-managed GitLab web UI |
| `iamgradov.ru` | `diaverse-bots` | Caddy | static site, Club10000 callback/webhook routes | production landing and bot callbacks |
| `www.iamgradov.ru` | `diaverse-bots` | Caddy | redirects/canonical site handling | landing alias |
| `updates.diaverse.app` | `diaverse-bots` | Caddy | Expo EAS update upstream | mobile update proxy |
| `assets.diaverse.app` | `diaverse-bots` | Caddy | Expo EAS asset upstream | mobile asset proxy |

## Public / Host Ports

| Server | Port | Exposure | Expected owner | Notes |
| --- | --- | --- | --- | --- |
| `diaverse-prod` | `80`, `443` | public | Traefik | HTTP/HTTPS entrypoints |
| `diaverse-prod` | `8000` | host-bound | `diaverse-api-1` | review whether direct host exposure is intentional |
| `diaverse-prod` | `5432` | host-bound | `diaverse-postgresql-1` | review whether direct host exposure is intentional |
| `diaverse-prod` | `8443` | host-bound | host nginx | owner/purpose needs confirmation |
| `diaverse-prod` | `9999` | host-bound | unknown listener | investigate before marking production port map clean |
| `diaverse-dev` | `80`, `443` | public | Traefik | HTTP/HTTPS entrypoints |
| `diaverse-dev` | `2222` | public | GitLab SSH | self-managed GitLab SSH entrypoint |
| `diaverse-dev` | `8000` | host-bound | `diaverse-api-1` | review whether direct host exposure is intentional |
| `diaverse-dev` | `5432` | host-bound | `diaverse-postgresql-1` | review whether direct host exposure is intentional |
| `diaverse-dev` | `10050` | host-bound | Zabbix agent | monitoring |
| `diaverse-bots` | `80`, `443` | public | Caddy | HTTP/HTTPS entrypoints; Caddy also exposes HTTP/3 over UDP `443` |
| `diaverse-bots` | `8090` | private host interface | `copywriting-api` | internal copywriting API; not a public route |
| `diaverse-bots` | `10050` | host-bound | Zabbix agent | monitoring |
| `diaverse-bots` | `51820/udp` | host-bound | unknown VPN/listener | confirm owner before relying on it |

## Docker/Internal Ports

| Port | Service | Network | Host exposure |
| --- | --- | --- | --- |
| `3000` | `diaweb`, `diaweb-dev` | `webproxy` | routed by Traefik |
| `8000` | `diaverse-api-1` | `diaverse_internal`, `webproxy` | also host-bound on prod/dev as observed |
| `5432` | Diaverse Postgres | `diaverse_internal` | also host-bound on prod/dev as observed |
| `6379` | Redis | `diaverse_internal` | internal only in Docker inventory |
| `5678` | n8n | `diaverse_internal`, `webproxy` | routed by Traefik |
| `8090` | `copywriting-api` | `copywriting_internal` | bound to private host interface on bots server |
| `8080` | `club10000_bot` | `club10000_private`, `iamgradov-site_default` | routed by Caddy |

## Rules

- Do not expose databases directly to the public internet.
- Treat host ports other than `80/443` and documented SSH/GitLab/monitoring ports as exceptions that require explicit documentation.
- Record whether a route is public, localhost-only, Docker-network-only, private-host-interface, or service-to-service.
- Public daily digests must not include raw listener output, private IPs, SSH details, or investigation notes about unknown ports.
