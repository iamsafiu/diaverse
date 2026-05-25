# Server Inventory Checklist

[Back to Infrastructure](README.md)

## Purpose

Use this checklist when refreshing Diaverse server documentation from live servers. The inventory helper is read-only and saves sanitized snapshots under `.tmp/server-inventory/`; committed docs must contain only curated topology facts.

## Run Inventory

Run from the workspace root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-prod
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-dev
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-bots
```

For a one-off machine that has no local SSH alias, pass an explicit SSH target and identity file path on the command line. Do not copy that full command into committed docs, daily public digest, chat summaries, or tickets.

## Snapshot Review

For each host snapshot, inspect these files before editing docs:

| File | What to copy into docs | What to keep out of docs |
| --- | --- | --- |
| `metadata.txt` | host alias, generation date | operator machine paths |
| `os.txt` | OS family, hostname role, uptime signal | raw login banners |
| `versions.txt` | Docker, Compose, proxy, runtime versions | full package inventory |
| `docker-ps.txt` | container names, images, health states, public host ports | raw logs or command output blocks |
| `docker-compose.txt` | compose project names and compose file paths | secret values referenced by compose |
| `docker-networks.txt` | network names and service membership | container-internal addresses unless needed |
| `systemd.txt` | service unit names and whether they are running | unit files with credentials |
| `reverse-proxy.txt` | proxy config file names, proxy container names, labels after review | certificate material, provider credentials |
| `ports.txt` | intentionally public ports and localhost-only ports | process args that expose credentials |
| `disk.txt` | broad disk capacity and Docker usage risk | unrelated filesystem details |
| `repos.txt` | repo checkout paths, current branch, commit, remotes | credential-bearing remote URLs |
| `env-paths.txt` | existence and location category of env files | env file contents |

## Redaction Rules

Never copy these into committed docs:

- secret values, provider credentials, session cookies, bot tokens, API keys, JWT signing material, database URLs, Redis URLs, DSNs, or webhooks with embedded credentials;
- private SSH key material, local private-key paths, raw long-form SSH commands, or operator-specific machine paths;
- raw `.env` contents, raw container logs, stack traces with credentials, request headers, cookies, or authorization headers;
- exact private infrastructure details in `Public digest` daily entries or public posts;
- unreviewed output copied directly from `.tmp/server-inventory/`.

If a fact is useful but sensitive, document the safe shape instead. Example: write "PostgreSQL is Docker-network-only" instead of copying a credential-bearing connection string.

## Curate Docs

After review, update only the relevant canonical docs:

- server facts: [servers/prod.md](servers/prod.md), [servers/dev.md](servers/dev.md), [servers/bots-landing.md](servers/bots-landing.md);
- service placement: [deployment-matrix.md](deployment-matrix.md);
- domains and routes: [domains-and-ports.md](domains-and-ports.md);
- service-specific runtime notes: files under [services/](services/);
- action procedures remain in [runbooks](../runbooks/copywriting-production-runtime.md).

Every updated server or service page must include:

- `last_verified` date;
- inventory source alias;
- service owner repo;
- runtime path;
- runtime kind;
- expected health check;
- linked runbook for deploy/restart/update;
- known gaps if the inventory could not verify something safely.

## Verify Before Commit

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-dev -DryRun
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverse-docs
```

Then run a targeted sensitive-data scan over `docs/infrastructure` and `scripts/server-inventory.ps1`. The scan must return no committed secrets or raw access details.
