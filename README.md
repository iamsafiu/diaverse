# Diaverse Workspace

> Coordination repository for Diaverse documentation, AI context, and shared workspace scripts.

This repository does not contain the product source code. The runtime code stays in four
independent child repositories:

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
| `scripts/` | Workspace maintenance, docs, daily work, and Graphify helper scripts |
| `AGENTS.md` | Workspace map for AI agents |

## What This Repo Does Not Track

The child repositories are ignored here because they have their own remotes,
branches, commits, and release workflows:

```text
diaweb/
diaverseapi/
aibot/
club10000-bot/
```

Generated Graphify outputs, local browser profiles, screenshots, credentials,
environment files, and temporary artifacts are also ignored.

## Common Commands

```powershell
# Check workspace docs for headings, stale paths, and local markdown links
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1

# Check all child repository statuses
powershell -ExecutionPolicy Bypass -File .\scripts\aif-workspace-status.ps1

# Refresh Graphify when you intentionally want to update the shared graph
powershell -ExecutionPolicy Bypass -File .\scripts\graphify-update.ps1
```

## Documentation

Start at [docs/README.md](docs/README.md).

## Repository Boundary

Commit documentation and workspace context changes here. Commit application code
inside the owning child repository.
