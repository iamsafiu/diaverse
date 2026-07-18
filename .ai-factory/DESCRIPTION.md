# Project: Diaverse Workspace

## Overview

Shared coordination workspace for the Diaverse system. This folder groups the web frontend, the mobile frontend, the core backend, the internal copywriting service, the standalone content factory, the archived AI Cofounder reference repo, and the standalone Club10000 bot so AI agents can reason about the whole system in one place without collapsing the repositories into a monorepo. The workspace root is a lightweight git repository for cross-repo documentation, AI context, and shared scripts only.

## Repositories

- **diaweb** - Next.js 16.2.1 frontend, App Router, React 19, Tailwind v4, same-origin BFF routes
- **diaverse-mobile** - Expo 53 / React Native 0.79 mobile frontend with iOS/Android native project files, expo-router, EAS build/update config, Sentry, Amplitude, RevenueCat purchases, locize localization, and mobile device integrations
- **diaverseapi** - FastAPI backend, SQLModel/SQLAlchemy, Alembic, PostgreSQL, Redis, task processing
- **aibot** - internal copywriting service, FastAPI + worker + Telegram ingest runtimes, OpenAI/Groq-backed LLM workflows
- **diaverse-content** - standalone Next.js/Prisma content factory for public learn pages, drafts, revisions, slugs, content search, content SEO fragments, manual Codex operator drafts, and content-owned daily Codex autopilot generation with gated publication
- **diaverse-ai-cofounder** - archived/R&D AI Cofounder reference repo. Keep it for historical content strategy, prompts, and rollback context only; it is not an active runtime dependency for content operations.
- **club10000-bot** - standalone Club10000 Telegram bot, aiohttp callbacks, aiogram runtime, Prodamus recurring payments, and bot-local PostgreSQL state
- **diaverse-auth-bot** - stateless Telegram auth transport adapter for Diaverse browser login and mobile Telegram linking

## Current Cross-Repo Integrations

- **Club:** `diaverseapi/app/club` owns the Diaverse club subscription/marathon domain and signed internal club APIs. `diaweb` exposes `/staff/club`. `aibot/app/clubbot` is the thin Telegram adapter runtime for joins, invites, removals, moderation, and other Diaverse system actions, deployed as `copywriting-clubbot` on the foreign bot server. `club10000-bot` owns the legacy Club10000 Telegram bot runtime and its restored bot DB; it should bridge normalized payment events to `diaverseapi` instead of writing to the Diaverse DB directly. `aibot` also generates club benefit posts and leaderboard images through signed service requests; leaderboard content publishes by default through the existing Premium `copywriting-userbot` queue into the configured Telegram topic. Env-backed Bot API targets such as `bot_profile=club` remain explicit fallbacks, not the default club content path.
- **Ops Agent:** `aibot/app/ops_agent` owns the internal Telegram Codex ops-agent runtime deployed as `copywriting-ops-agent`. It stores sanitized case memory and playbooks in the copywriting service, calls signed `diaverseapi/app/ops_agent` diagnostics/actions for product state, and lets Codex Operator select a typed read-only user step/contribution tool from free-form requests (`/userstats` is only a fallback). It can run local `codex exec` in a dedicated `CODEX_HOME`/workspace. Approved comment restrictions are delivered by this same Ops Agent bot through a filtered durable queue; Clubbot cannot claim those commands, and neither restriction nor restoration changes Club membership. Product mutations must go through registered `diaverseapi` actions, not direct write SQL.
- **Auth bot:** `diaverse-auth-bot` owns only the Telegram transport for login and mobile-link deep links. `diaverseapi/app/security` owns login session state, user provisioning, Telegram identity persistence, cookies, RBAC assignment, and account-linking semantics.
- **Mobile app:** `diaverse-mobile` owns the iOS/Android client runtime and release configuration. Its shared backend source of truth is `diaverseapi`; `diaweb` remains the web frontend and same-origin BFF layer, not the default backend authority for mobile contracts.
- **Staff shop skins and pet creation:** `diaverseapi` owns canonical `PilotSkin`/`PetSkinDef` mutations, bounded PNG validation/WebP conversion, atomic creation of canonical pets with all 11 age visuals, and code-owned assignable pet abilities. `diaweb` owns the staff upload/create workflow. Existing and new ability-bearing pets resolve through character assignments; raid participants persist fully resolved start snapshots. `diaverse-mobile` consumes canonical visuals and localized ability presentation through backend APIs, with rendering tracked as a separate mobile task.
- **Content factory:** `diaverse-content` owns content state, public learn rendering, content search, draft/revision lifecycle, slug history, content SEO fragments, first-party content metrics, the manual Codex operator workflow for draft-only articles, and the content-owned daily Codex autopilot that imports drafts first and publishes only after strict local gates. Public content is intended to be mounted on the main domain under `/ru/learn/*`; browser staff entrypoints remain in `diaweb`, while staff identity and RBAC remain in `diaverseapi`.
- **Archived AI Cofounder:** `diaverse-ai-cofounder` is retained as a historical/R&D source for prompts, strategy notes, and rollback context. It is not part of the active content production path, should not run schedules, and should not be required for generating or importing content drafts.

## Shared AI Layer

- **AI Factory:** project planning, implementation workflow, research, and repo-local execution
- **GBrain:** local project knowledge layer over root docs, AI context, and child repository code sources
- **Codex Skills:** workspace-level skills live in `.codex/skills/` and are synced from `diaweb/.agents/skills`
- **MCP:** top-level `.mcp.json` exposes general workspace tools only; GBrain is local CLI-first and not exposed as a public connector by default
- **Root repository:** tracks `docs/`, `.ai-factory/`, `.codex/skills/`, `scripts/`, and workspace config; ignores child repository contents and local runtime state

## Local GBrain

- Wrapper: `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1`
- Bootstrap: `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-bootstrap.ps1`
- Source registration: `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sources.ps1`
- Sync: `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
- Health check: `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-health.ps1`
- Local state: `C:\Users\Indigo\Desktop\diaverse\.tools\gbrain\home`
- Source IDs: `diaverse-docs`, `diaverse-aif`, `diaweb-code`, `diaverse-mobile-code`, `diaverseapi-code`, `aibot-code`, `diaverse-content-code`, `club10000-bot-code`, `diaverse-auth-bot-code`

## Non-Goals

- This workspace is not a monorepo and does not version child repository source code
- This workspace is not a deployable product
- This workspace does not replace repo-local source of truth
- GBrain is not exposed through public HTTP MCP or ChatGPT connector without a separate auth/security review
- Raw conversations are not auto-captured into GBrain
