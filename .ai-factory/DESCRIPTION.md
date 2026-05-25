# Project: Diaverse Workspace

## Overview

Shared coordination workspace for the Diaverse system. This folder groups the web frontend, the core backend, the internal copywriting service, and the standalone Club10000 bot so AI agents can reason about the whole system in one place without collapsing the repositories into a monorepo. The workspace root is a lightweight git repository for cross-repo documentation, AI context, and shared scripts only.

## Repositories

- **diaweb** - Next.js 16.2.1 frontend, App Router, React 19, Tailwind v4, same-origin BFF routes
- **diaverseapi** - FastAPI backend, SQLModel/SQLAlchemy, Alembic, PostgreSQL, Redis, task processing
- **aibot** - internal copywriting service, FastAPI + worker + Telegram ingest runtimes, OpenAI/Groq-backed LLM workflows
- **club10000-bot** - standalone Club10000 Telegram bot, aiohttp callbacks, aiogram runtime, Prodamus recurring payments, and bot-local PostgreSQL state

## Current Cross-Repo Integrations

- **Club:** `diaverseapi/app/club` owns the Diaverse club subscription/marathon domain and signed internal club APIs. `diaweb` exposes `/staff/club`. `aibot/app/clubbot` is the thin Telegram adapter runtime for joins, invites, removals, moderation, and other Diaverse system actions, deployed as `copywriting-clubbot` on the foreign bot server. `club10000-bot` owns the legacy Club10000 Telegram bot runtime and its restored bot DB; it should bridge normalized payment events to `diaverseapi` instead of writing to the Diaverse DB directly. `aibot` also generates club benefit posts and leaderboard images through signed service requests; leaderboard content publishes by default through the existing Premium `copywriting-userbot` queue into the configured Telegram topic. Env-backed Bot API targets such as `bot_profile=club` remain explicit fallbacks, not the default club content path.

## Shared AI Layer

- **AI Factory:** project planning, implementation workflow, research, and repo-local execution
- **Graphify:** shared knowledge graph over all four repositories and related docs
- **Codex Skills:** workspace-level skills live in `.codex/skills/` and are synced from `diaweb/.agents/skills`
- **MCP:** top-level `.mcp.json` exposes workspace tools including the shared Graphify server
- **Root repository:** tracks `docs/`, `.ai-factory/`, `.codex/skills/`, `scripts/`, and workspace config; ignores child repository contents and generated artifacts

## Shared Graph

- Graph root: `C:\Users\Indigo\Desktop\diaverse`
- Report: `C:\Users\Indigo\Desktop\diaverse\graphify-out\GRAPH_REPORT.md`
- Data: `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
- Visual graph: `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.html`

## Non-Goals

- This workspace is not a monorepo and does not version child repository source code
- This workspace is not a deployable product
- This workspace does not replace repo-local source of truth
