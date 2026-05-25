# AGENTS.md

> Workspace map for AI agents. Keep this file up-to-date as the Diaverse system evolves.

## Workspace Overview

This folder is the shared Diaverse workspace. It is not a monorepo. The workspace root is a lightweight git repository for cross-repo documentation, AI context, shared scripts, and coordination files only. It groups four related implementation repositories:

- `diaweb` - Next.js web frontend and same-origin BFF layer
- `diaverseapi` - FastAPI backend for auth, cabinet, game, RBAC, payments, and staff domains
- `aibot` - internal copywriting service used by `diaweb` staff tooling
- `club10000-bot` - standalone Club10000 Telegram bot with Prodamus recurring payment callbacks and its own PostgreSQL state

The workspace owns cross-repo AI context, shared scripts, root documentation, and top-level Codex skills. Product implementation commits, branches, and source changes still belong to the individual child repositories.

## Workspace Structure

```text
diaverse/
|-- AGENTS.md
|-- README.md
|-- .gitignore                  # Tracks workspace docs/context only
|-- .ai-factory/                # Cross-repo context only
|-- .ai-factory.json            # Top-level AI Factory bootstrap
|-- .codex/
|   |-- hooks.json              # Workspace hooks
|   `-- skills/                 # Workspace-level skills synced from diaweb
|-- .mcp.json                   # Workspace MCP servers, no public GBrain connector
|-- .tools/
|   `-- gbrain/                 # Local GBrain clone, dependencies, and project brain state
|-- docs/
|   |-- README.md               # Documentation portal and navigation
|   |-- documentation-system.md # Documentation quality and ownership rules
|   |-- knowledge-system.md     # Local GBrain knowledge layer guide
|   |-- architecture/           # Cross-repo architecture and maps
|   |-- product/                # Product contracts and phase docs
|   |-- features/               # Feature-specific living docs
|   |-- runbooks/               # Deploy and operations runbooks
|   |-- research/               # Discovery notes and non-canonical research
|   |-- logs/                   # Historical technical logs
|   |-- assets/                 # Screenshots and doc assets
|   |-- daily/                  # Local daily work logs and template
|   `-- tasks/                  # Task briefs and exploration notes
|-- scripts/
|   |-- aif-workspace-status.ps1
|   |-- aif-workspace-branch.ps1
|   |-- daily-work-add.ps1
|   |-- daily-work-publish.ps1
|   |-- daily_work_publish.py
|   |-- docs-health.ps1
|   |-- gbrain.ps1
|   |-- gbrain-bootstrap.ps1
|   |-- gbrain-sources.ps1
|   |-- gbrain-sync.ps1
|   |-- gbrain-health.ps1
|   `-- sync-aif-skills.ps1
|-- diaweb/                     # Frontend git repo (ignored by root git)
|-- diaverseapi/                # Backend git repo (ignored by root git)
|-- aibot/                      # Copywriting service git repo (ignored by root git)
`-- club10000-bot/              # Club10000 bot git repo (ignored by root git)
```

## Source of Truth

- Cross-repo architecture, ownership, and integration rules live in `diaverse/.ai-factory/*`
- Frontend implementation truth lives in `diaweb`
- Backend implementation truth lives in `diaverseapi`
- Copywriting service truth lives in `aibot`
- Club10000 bot implementation and restored bot DB truth lives in `club10000-bot`
- Cross-repo documentation portal lives in `diaverse/docs/README.md`
- Root git repository truth covers only workspace docs, AI context, and shared scripts
- Local knowledge navigation is provided by GBrain sources registered through `scripts/gbrain-sources.ps1`

## GBrain First

- Before answering architecture, dependency, ownership, docs, or cross-repo impact questions, use local GBrain first when it is available.
- Use `scripts/gbrain.ps1` as the wrapper; do not call a public GBrain HTTP/MCP service unless the user explicitly asks for a separately reviewed security setup.
- Prefer source-scoped lookups:
  - `diaverse-docs` for root documentation
  - `diaverse-aif` for AI Factory context
  - `diaweb-code`, `diaverseapi-code`, `aibot-code`, and `club10000-bot-code` for code repositories
- Use raw-file search and source reads after GBrain for exact verification, code edits, and line-accurate confirmation.
- If GBrain output and source code disagree, trust source code and refresh the relevant GBrain source.

## GBrain Operations

- Bootstrap local runtime: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-bootstrap.ps1`
- Register/update sources: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sources.ps1`
- Sync all sources: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
- Health check: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-health.ps1`
- Example docs lookup: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1 list --source diaverse-docs --limit 10`
- Example code lookup: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1 code-def CopywritingDailyView --json`

## Workspace AIF Helpers

- Multi-repo status: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-status.ps1`
- Create or switch a shared branch in selected repos: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-branch.ps1 -Branch feature/<slug> -Repos diaweb,diaverseapi,club10000-bot -Create`
- These helpers are safety rails for AIF `full` mode; they do not make the top-level folder a deployable application.

## AI Factory Usage

Top-level AI Factory in this workspace is the primary operational control plane for the whole Diaverse system. When Codex is opened in `C:\Users\Indigo\Desktop\diaverse`, AIF may plan, implement, review, and verify cross-repo work across `diaweb`, `diaverseapi`, `aibot`, and `club10000-bot` from this single workspace root.

Repo-local `.ai-factory` folders are local reference context and fallback entrypoints. They are not the default execution surface for cross-repo work.

When running from `C:\Users\Indigo\Desktop\diaverse`, normal AIF `full` mode means multi-repo full mode:

- treat `diaverse` as a separate coordination repository, not as a monorepo
- detect affected child repositories for the requested feature
- create or reuse the same branch name in each affected child repository only
- store the master plan under `diaverse\.ai-factory\plans\`
- implement from the workspace root, editing files under the affected child repositories
- check status, verification, staging, and commits per child repository
- commit root documentation, AI context, or shared script changes in the root repo when those files change

## Agent Rules

- Use top-level skills and top-level `.ai-factory` as the default for Diaverse work, including cross-repo implementation
- Use repo-local skills and repo-local `.ai-factory` only when the user explicitly wants to work inside one repository in isolation
- Create branches, status checks, staging, and commits for product code only inside `diaweb`, `diaverseapi`, `aibot`, or `club10000-bot`
- Use the top-level `diaverse` git repo only for root-owned docs, `.ai-factory`, `.codex`, `scripts`, and workspace config
- Never add `diaweb`, `diaverseapi`, `aibot`, or `club10000-bot` contents to the root repo
- For multi-repo full plans, use one branch slug across affected repositories, but do not use `codex/` in branch names; prefer normal prefixes such as `feature/`, `fix/`, `chore/`, `refactor/`, or `test/`
- Before switching branches in a child repository, check for uncommitted changes and pause if branch switching would mix unrelated work
- During implementation, keep the single top-level plan as the progress source of truth and mark task checkboxes there
- After meaningful docs or code changes, run targeted GBrain sync or `scripts/gbrain-sync.ps1`; do not auto-capture raw conversations
- `diaweb` is the only browser-facing entrypoint for staff copywriting flows
- `diaverseapi` owns auth, RBAC, cabinet APIs, logging, guest flows, and payment integrations
- `aibot` owns internal copywriting workflows, source-backed planning, and draft generation
- `club10000-bot` owns the standalone Club10000 Telegram bot runtime, Prodamus callback handling, bot-local funnels, reminders, referrals, and restored bot DB state
- Do not treat this top-level folder as a deployable application

## Daily Work Capture

- After each meaningful completed task in this workspace, append a concise entry to `docs/daily/YYYY-MM-DD-<author>.md` unless the user explicitly says `bez daily` or `no daily`; use `DAILY_WORK_AUTHOR` when configured, otherwise use `safiu`
- The daily file must have two sections:
  - `Public digest` for short, user-safe progress notes that may be published to Confluence and used to generate a public post
  - `Internal log` for local technical audit notes that must never be published or sent to post generation
- Daily document entries must be written in Russian unless the user explicitly asks for another language; keep the technical section names `Public digest` and `Internal log` unchanged for the publisher
- Only the `Public digest` section may be sent to Confluence or used as source material for generated posts
- Confluence daily pages are shared by date (`Daily Work - YYYY-MM-DD`); the publisher must update only the current author's section and preserve other author sections
- Daily entries must not include secrets, tokens, raw environment values, private SSH commands, SSH key paths, internal IPs, private infrastructure details, raw stack traces with sensitive values, or other internal-only notes in `Public digest`
- Prefer product/user-facing phrasing in `Public digest`; keep implementation details, file names, and debugging context in `Internal log`
- Mention daily-log writes in the final answer when a task updated the current `docs/daily/YYYY-MM-DD-<author>.md`
