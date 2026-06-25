# Infrastructure Documentation

[Back to Docs](../README.md)

## Purpose

This section documents the current Diaverse server topology: which workloads run on which host, where their repositories and compose files live, which reverse proxy routes expose them, and how to verify runtime health.

Use this section for stable topology facts. Use [runbooks](../runbooks/copywriting-production-runtime.md) for action procedures such as deploy, restart, rollback, and incident handling.

## Servers

| Server | Role | Inventory status |
| --- | --- | --- |
| [Production](servers/prod.md) | Production application workloads | Verified 2026-05-25 |
| [Development](servers/dev.md) | Development web, backend, and GitLab workloads | Verified 2026-05-25 |
| [Bots and Landing](servers/bots-landing.md) | Foreign-hosted bot, copywriting, landing, and EAS proxy workloads | Verified 2026-05-25 |

## Service Views

| Service | Documentation |
| --- | --- |
| `diaweb` | [services/diaweb.md](services/diaweb.md) |
| `diaverseapi` | [services/diaverseapi.md](services/diaverseapi.md) |
| `aibot` | [services/aibot.md](services/aibot.md) |
| `diaverse-content` | [Content Factory Architecture](../architecture/content-factory.md), [foreign server runbook](../runbooks/content-factory-foreign-server.md) |
| `club10000-bot` | [services/club10000-bot.md](services/club10000-bot.md) |
| Reverse proxies | [services/reverse-proxy.md](services/reverse-proxy.md) |

## Cross-Cutting Maps

- [Deployment Matrix](deployment-matrix.md) - service to server, path, runtime, endpoint, and runbook mapping.
- [Domains And Ports](domains-and-ports.md) - public ports, internal ports, domains, and proxy routes.
- [Inventory Checklist](inventory-checklist.md) - safe workflow for collecting and curating live server facts.

## Safety Rules

- Do not commit secrets, tokens, raw `.env` values, database URLs, provider credentials, SSH private key material, or raw logs.
- Prefer SSH host aliases in documentation: `diaverse-prod`, `diaverse-dev`, `diaverse-bots`.
- Raw inventory snapshots belong under `.tmp/server-inventory/` and must stay ignored by git.
- Curated docs may include operational facts such as service names, paths, domains, ports, compose project names, and health checks after review.
- Public daily digests must not include IPs, SSH details, private paths, raw command output, or sensitive infrastructure details.
- Unknown listeners, direct DB exposure, and host-specific firewall assumptions must stay as review items until verified by an operator.

## Update Workflow

1. Run the read-only inventory helper for the target host.
2. Review sanitized snapshots under `.tmp/server-inventory/`.
3. Follow the [Inventory Checklist](inventory-checklist.md) and copy only curated, non-secret facts into this section.
4. Run docs health and sensitive-data audits.
5. Sync `diaverse-docs` in GBrain.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-prod
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-dev
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-bots
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverse-docs
```
