# Implementation Plan: Server Infrastructure Documentation Inventory

Created: 2026-05-25
Mode: AIF fast plan, workspace root, no branch changes
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: yes - include docs health, script dry-run/help checks, sanitized output review, and GBrain sync/health.
- Logging: standard - PowerShell helpers must print `INFO`, `WARN`, `ERROR`; use `DEBUG` only for non-secret diagnostics.
- Docs: yes - this task is documentation-first and must update the docs portal.
- Roadmap Linkage: none, no `.ai-factory\ROADMAP.md` found.
- GBrain: use local GBrain first for docs/navigation context, then verify with raw files and live read-only server inventory.
- Safety: do not commit secrets, tokens, raw env values, private key contents, raw SSH key paths, private infrastructure-only logs, or destructive commands. Inventory must be read-only.

## Goal

Create a maintainable server documentation system for Diaverse infrastructure:

- production server;
- development server;
- foreign server used for bots and landing/runtime workloads;
- the services, paths, Docker/Compose projects, reverse proxies, ports, data volumes, logs, backups, and health checks that live on those servers.

The end state should let an AI agent quickly answer operational questions like:

- which server runs `diaweb`, `diaverseapi`, `aibot`, or `club10000-bot`;
- where compose files and repo checkouts live;
- which containers and reverse-proxy routes are expected;
- how to inspect, restart, update, or rollback a service safely;
- when the infrastructure docs were last verified.

## Non-Goals

- Do not change server configuration or restart services during inventory.
- Do not deploy code.
- Do not edit product repositories.
- Do not copy `.env` contents or secrets into documentation.
- Do not store raw inventory dumps in git.
- Do not rely on GBrain as the final authority for live server state; live read-only inventory and source files remain the authority.

## Research Context

Existing documentation already has operational runbooks:

- `docs\runbooks\copywriting-production-runtime.md`
- `docs\runbooks\deploy-vps.md`
- `docs\runbooks\dev-site-deployment.md`
- `docs\runbooks\install-vps.md`
- `docs\runbooks\update-vps.md`
- `docs\runbooks\update-vps-backend.md`
- `docs\runbooks\nginx\diaweb-copywriting.conf`

These should remain action-oriented runbooks. New infrastructure docs should describe current topology and live server inventory:

```text
docs/infrastructure/
|-- README.md
|-- deployment-matrix.md
|-- domains-and-ports.md
|-- servers/
|   |-- prod.md
|   |-- dev.md
|   `-- bots-landing.md
`-- services/
    |-- diaweb.md
    |-- diaverseapi.md
    |-- aibot.md
    |-- club10000-bot.md
    `-- reverse-proxy.md
```

## Server Access Model

Use local SSH aliases in operator machines rather than documenting long SSH commands everywhere:

```text
diaverse-prod
diaverse-dev
diaverse-bots
```

The implementation may use the SSH details supplied by the user to perform read-only inventory, but committed docs should prefer aliases and sanitized facts. If IP addresses are included, they must be treated as operational infrastructure data and must not be copied into public daily digests or public posts.

## Target Model

```text
live servers
   |
   | read-only SSH inventory
   v
.tmp/server-inventory/        # raw/sanitized snapshots, ignored by git
   |
   | curated human review
   v
docs/infrastructure/          # canonical committed docs
   |
   | docs-health + GBrain sync
   v
local GBrain source diaverse-docs
```

## Repository Matrix

| Repository / Area | Path | Affected | Branch changes | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` repo | `C:\Users\Indigo\Desktop\diaverse` | yes | none in fast mode | Owns docs, scripts, AI context, GBrain sync |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | read-only reference | none | Service docs source; no product edits |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | read-only reference | none | Service docs source; no product edits |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | read-only reference | none | Service docs source; no product edits |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | read-only reference | none | Service docs source; no product edits |
| live servers | SSH aliases listed above | read-only inventory | none | Runtime truth for deployed topology |

## Tasks

### Phase 1 - Define Infrastructure Documentation Shape

- [x] Task 1: Create the infrastructure documentation skeleton and templates.
  - Files/paths:
    - `docs\infrastructure\README.md`
    - `docs\infrastructure\servers\prod.md`
    - `docs\infrastructure\servers\dev.md`
    - `docs\infrastructure\servers\bots-landing.md`
    - `docs\infrastructure\services\*.md`
  - Deliverable:
    - Canonical sections for role, access alias, paths, Docker/Compose, systemd, reverse proxy, domains, data/volumes, backups, health checks, update/restart links, and `last_verified`.
    - Clear separation between topology docs and action runbooks.
    - Explicit safety note that secrets/raw env/private keys are never committed.
  - Logging:
    - No runtime logging required for docs-only edits.
  - Dependencies:
    - None.

- [x] Task 2: Update documentation navigation for infrastructure docs.
  - Files/paths:
    - `docs\README.md`
    - `docs\documentation-system.md`
    - optionally `AGENTS.md` if workspace structure map needs the new folder.
  - Deliverable:
    - Docs portal links to the new infrastructure section.
    - Documentation rules describe infrastructure docs ownership and server-sensitive data handling.
  - Logging:
    - No runtime logging required.
  - Dependencies:
    - Depends on Task 1.

### Phase 2 - Add Read-Only Server Inventory Helper

- [x] Task 3: Create a sanitized read-only inventory script.
  - Files/paths:
    - `scripts\server-inventory.ps1`
    - `.gitignore` only if an explicit inventory output ignore is needed beyond existing `.tmp/`
  - Deliverable:
    - Script accepts SSH host aliases and writes sanitized inventory under `.tmp\server-inventory\YYYY-MM-DD\<alias>\`.
    - Commands are read-only only: OS info, Docker version, `docker ps`, `docker compose ls`, Docker networks, selected systemd units, nginx/Traefik config names, listening ports, disk usage summary, repo checkout paths, git remotes/branches, and service health probes where safe.
    - Script must not run restart/deploy/stop/down/prune/package install commands.
    - Script must not print or save raw `.env` values; env-like output must be redacted by key pattern.
  - Logging:
    - `INFO [inventory]` for host alias, command category, and output path.
    - `WARN [inventory]` for missing commands, permission-denied noncritical checks, or unavailable services.
    - `ERROR [inventory]` for SSH connection failure or sanitizer failure.
    - Never log secrets, token values, raw env values, or private key contents.
  - Dependencies:
    - Depends on Task 1.

- [x] Task 4: Add inventory usage documentation and safety review checklist.
  - Files/paths:
    - `docs\infrastructure\README.md`
    - `docs\infrastructure\inventory-checklist.md`
  - Deliverable:
    - Commands for running inventory against `diaverse-prod`, `diaverse-dev`, and `diaverse-bots`.
    - Checklist for reviewing snapshots before copying facts into committed docs.
    - Redaction rules for env-like data, IPs in public output, provider tokens, DB URLs, SSH material, Telegram/session details, and raw logs.
  - Logging:
    - No runtime logging required.
  - Dependencies:
    - Depends on Task 3.

### Phase 3 - Collect And Curate Server Facts

- [x] Task 5: Run read-only inventory for all three servers and review sanitized snapshots.
  - Files/paths:
    - `.tmp\server-inventory\...` ignored output only
    - implementation notes in `docs\daily\YYYY-MM-DD-safiu.md`
  - Deliverable:
    - Sanitized snapshots exist for prod, dev, and bots/landing servers.
    - Review notes identify expected service names, compose projects, ports, domains, repo paths, and gaps.
    - Any sensitive output found by sanitizer is removed before docs are updated.
  - Logging:
    - `INFO [inventory]` for each completed host snapshot.
    - `WARN [inventory]` for inaccessible checks or unknown service ownership.
    - `ERROR [inventory]` only if a required server cannot be inventoried.
  - Dependencies:
    - Depends on Tasks 3-4.

- [x] Task 6: Populate server-level docs from reviewed inventory.
  - Files/paths:
    - `docs\infrastructure\servers\prod.md`
    - `docs\infrastructure\servers\dev.md`
    - `docs\infrastructure\servers\bots-landing.md`
  - Deliverable:
    - Each server doc lists role, SSH alias, expected service groups, repo paths, compose paths, containers, reverse proxy, domains, ports, data/volumes, backup notes, health checks, and last verified date.
    - Use links to runbooks for actions instead of duplicating long operational procedures.
  - Logging:
    - No runtime logging required.
  - Dependencies:
    - Depends on Task 5.

- [x] Task 7: Populate service-level infrastructure docs and matrix files.
  - Files/paths:
    - `docs\infrastructure\deployment-matrix.md`
    - `docs\infrastructure\domains-and-ports.md`
    - `docs\infrastructure\services\diaweb.md`
    - `docs\infrastructure\services\diaverseapi.md`
    - `docs\infrastructure\services\aibot.md`
    - `docs\infrastructure\services\club10000-bot.md`
    - `docs\infrastructure\services\reverse-proxy.md`
  - Deliverable:
    - One matrix shows service -> server -> path -> compose/systemd -> public/private endpoints -> owner repo -> runbook.
    - Domain/port doc distinguishes public ports, localhost-only ports, internal Docker ports, and reverse proxy routes.
    - Service docs identify health checks, logs, restart/update runbooks, persistent data, and owner repository.
  - Logging:
    - No runtime logging required.
  - Dependencies:
    - Depends on Tasks 5-6.

### Phase 4 - Verification And Knowledge Sync

- [x] Task 8: Verify docs and inventory script quality.
  - Files/paths:
    - `scripts\docs-health.ps1`
    - `scripts\server-inventory.ps1`
    - `docs\infrastructure\**`
  - Deliverable:
    - `docs-health.ps1` passes.
    - `server-inventory.ps1` help/dry-run syntax works without SSH side effects.
    - `rg` audit finds no committed raw secrets, private key paths, raw env values, or obviously sensitive tokens in `docs\infrastructure` and script output examples.
  - Logging:
    - `INFO [verify]` for passed checks.
    - `WARN [verify]` for known gaps that need manual server access later.
    - `ERROR [verify]` for docs-health failures or detected sensitive data.
  - Dependencies:
    - Depends on Tasks 6-7.

- [x] Task 9: Sync GBrain and update daily work log.
  - Files/paths:
    - `docs\daily\YYYY-MM-DD-safiu.md`
    - local GBrain state under `.tools\gbrain\home`
  - Deliverable:
    - Run `scripts\gbrain-sync.ps1 -SourceId diaverse-docs`.
    - Run `scripts\gbrain-health.ps1`.
    - Add a sanitized daily entry describing the new infrastructure docs and verification status without IPs, key paths, raw env, or server-private details in `Public digest`.
  - Logging:
    - Use existing GBrain script logging.
  - Dependencies:
    - Depends on Task 8.

- [x] Task 10: Commit and push root workspace changes.
  - Files/paths:
    - root git repo only.
  - Deliverable:
    - Root repo commit with suggested message `docs: add server infrastructure inventory`.
    - Push to `git@github.com:iamsafiu/diaverse.git` `main`.
    - No child repo commits.
  - Logging:
    - Include commit hash and push result in final implementation notes.
  - Dependencies:
    - Depends on Task 9.

## Verification Plan

Run from `C:\Users\Indigo\Desktop\diaverse`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -Help
powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-dev -DryRun
powershell -Command "Write-Host 'Run targeted sensitive-data scan over docs\infrastructure and scripts\server-inventory.ps1'"
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverse-docs
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-health.ps1
git status --short --branch
```

Expected:

- docs-health passes with 0 errors;
- dry-run prints planned read-only categories only;
- sensitive audit returns no committed secrets/private key paths/raw env values;
- GBrain health passes after sync;
- root git status is clean after commit.

## Rollback Plan

- Use root git to revert the infrastructure documentation commit.
- Delete ignored `.tmp\server-inventory\...` snapshots if they are no longer needed.
- Do not delete or change any server state during rollback.

## Commit Plan

Because this plan has 10 tasks, use commit checkpoints:

1. `docs: add infrastructure documentation skeleton`
   - Tasks 1-2.
2. `chore: add sanitized server inventory helper`
   - Tasks 3-4.
3. `docs: document deployed server topology`
   - Tasks 5-7.
4. `chore: verify infrastructure docs`
   - Tasks 8-10.

## Next Step

Run `/aif-implement` from `C:\Users\Indigo\Desktop\diaverse` when ready to execute this plan.
