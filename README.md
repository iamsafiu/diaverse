# Diaverse Workspace

> Coordination repository for Diaverse documentation, AI context, local knowledge tooling, and shared workspace scripts.

This repository does not contain the product source code. The runtime code stays in four independent child repositories:

- `diaweb` - Next.js web frontend and same-origin BFF layer.
- `diaverseapi` - FastAPI backend for auth, cabinet, payments, RBAC, and staff domains.
- `aibot` - internal copywriting service used by `diaweb` staff tooling.
- `club10000-bot` - standalone Club10000 Telegram bot.

## What This Repo Tracks

| Path | Purpose |
| --- | --- |
| `docs/` | Cross-repo documentation, runbooks, research, tasks, and daily logs |
| `.ai-factory/` | Workspace AI Factory context, plans, rules, and research |
| `.codex/skills/` | Workspace-level Codex skills |
| `scripts/` | Workspace maintenance, docs, daily work, and GBrain helper scripts |
| `AGENTS.md` | Workspace map for AI agents |

## What This Repo Does Not Track

The child repositories are ignored here because they have their own remotes, branches, commits, and release workflows:

```text
diaweb/
diaverseapi/
aibot/
club10000-bot/
```

Local runtime state under `.tools/`, browser profiles, screenshots, credentials, environment files, and temporary artifacts are also ignored.

## Common Commands

```powershell
# Check workspace docs for headings, stale paths, and local markdown links
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1

# Check all child repository statuses
powershell -ExecutionPolicy Bypass -File .\scripts\aif-workspace-status.ps1

# Bootstrap local GBrain if needed
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-bootstrap.ps1

# Register/update GBrain source definitions
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sources.ps1

# Sync GBrain sources after meaningful docs or code changes
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1

# Verify local GBrain health
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-health.ps1
```

## Documentation

Start at [docs/README.md](docs/README.md). The local knowledge layer is documented in [docs/knowledge-system.md](docs/knowledge-system.md).

## Repository Boundary

Commit documentation and workspace context changes here. Commit application code inside the owning child repository.
