# Architecture: Shared Workspace Over Four Repositories

## Overview

Diaverse uses four separate repositories coordinated through a shared workspace root:

- `diaweb` handles the browser-facing frontend and BFF routes
- `diaverseapi` handles cabinet, auth, staff, and game backend domains
- `aibot` handles internal copywriting workflows consumed by `diaweb`
- `club10000-bot` handles the standalone Club10000 Telegram bot, Prodamus callbacks, and its restored bot-local database

The workspace root adds AI coordination and documentation versioning only. It does not add code dependencies or runtime coupling beyond the integrations that already exist.

## Workspace Layout

```text
diaverse/
|-- .gitignore           # Root repo tracks workspace docs/context only
|-- README.md            # Root repository landing page
|-- .ai-factory/         # Cross-repo context and graph-first rules
|-- .codex/skills/       # Workspace-level skill pack
|-- .mcp.json            # Workspace MCP registry
|-- .graphifyignore      # Shared graph exclusions
|-- .tools/graphify/     # Graphify runtime
|-- graphify-out/        # Shared generated graph outputs, ignored by root git
|-- docs/                # Cross-repo runbooks, task briefs, and daily work logs
|-- scripts/             # Workspace maintenance and daily work scripts
|-- diaweb/              # Frontend repo, ignored by root git
|-- diaverseapi/         # Backend repo, ignored by root git
|-- aibot/               # Copywriting service repo, ignored by root git
`-- club10000-bot/       # Club10000 bot repo, ignored by root git
```

## Dependency Rules

### Cross-Repo

```text
diaweb -> diaverseapi    # REST/BFF integration
diaweb -> aibot          # internal JWT-backed BFF integration for copywriting
diaverseapi -> aibot     # signed club creative asset requests only
aibot -> diaverseapi     # copywriting-clubbot signed club Telegram events/outbox only
club10000-bot -> diaverseapi   # signed normalized Club10000 payment events only
workspace -> repos       # AI context only, no runtime dependency
```

### Club

```text
diaweb/frontend/modules/club -> diaverseapi/app/club admin API
aibot/app/clubbot           -> signed internal HTTP -> diaverseapi/app/club
club10000-bot               -> signed internal payment bridge -> diaverseapi/app/club
diaverseapi/app/club         -> signed HMAC -> aibot club leaderboard image/publish endpoints
aibot worker                 -> idempotent club leaderboard image assets
aibot userbot runtime        -> Telegram userbot publish queue -> configured club topic
aibot                        -> Telegram Bot API using bot_profile=club only for explicit fallback targets
```

The Diaverse club domain state belongs to `diaverseapi`. `aibot` generates and publishes creative assets but never owns membership, roster, payment, pair, or leaderboard truth. `copywriting-clubbot` in `aibot/app/clubbot` owns Telegram system/member lifecycle runtime actions on the foreign bot server, while `diaverseapi/app/club` owns the persisted state and outbox. `club10000-bot` owns the separate Club10000 bot-local state required for funnels, reminders, referrals, historical payment attempts, and Prodamus callback handling; it mirrors only normalized payment status into `diaverseapi`. Leaderboard content can be sent by the existing Premium userbot. Club operational notes live in `docs/club.md`.

### Cabinet Notifications

```text
diaverseapi/app/cabinet/notifications -> notification persistence, read state, user/guest API
diaverseapi/app/cabinet/finance       -> superadmin real-money revenue reports
diaverseapi/app/cabinet/fulfillment    -> emits authenticated reward/purchase notifications
diaverseapi/app/cabinet/guest          -> emits guest pending-auth notifications
diaweb/frontend/modules/notifications  -> notification client hooks and bell UI
diaweb/frontend/modules/finance        -> superadmin finance dashboard and Advent revenue UI
```

Notification creation is a side effect of reward, payment, shop, and guest entitlement flows. It must stay idempotent and non-fatal: failed notification creation is logged, while the underlying grant or purchase continues to use its existing transaction semantics.

### AI Context

```text
workspace .ai-factory -> cross-repo architecture, research, rules
repo .ai-factory -> local implementation context
Graphify -> shared navigation layer over all repos
source code -> final authority when graph and code disagree
```

## Operating Model

### Planning

- Use top-level AIF from `C:\Users\Indigo\Desktop\diaverse` as the primary control plane for Diaverse work
- In the workspace root, normal `full` planning means multi-repo full mode over affected child repositories
- Store cross-repo master plans under `diaverse/.ai-factory/plans/`
- Use repo-level AIF only as an explicit fallback when the user wants to isolate work inside one child repository

### Implementation

- Implement cross-repo plans from the workspace root when the task may touch more than one repository
- Edit product code only inside `diaweb`, `diaverseapi`, `aibot`, or `club10000-bot`
- Keep progress checkboxes in the top-level plan for workspace-run implementations
- Commit product code inside each repository that owns changes
- Commit top-level workspace files in the root repository only when the change is limited to documentation, AI context, shared scripts, or workspace config
- Keep top-level workspace files focused on coordination, AI context, Graphify helpers, documentation, and scripts

### Graphify

- Build the graph from the workspace root
- Keep one canonical shared graph in `graphify-out/`
- Use Graphify summary or MCP queries first for architecture questions
- Refresh the graph after meaningful code or docs changes

### Multi-Repo Full Mode

```text
diaverse/.ai-factory/plans/<branch-slug>.md
        |
        | owns one cross-repo plan
        v
  +-----------+      +--------------+      +--------+      +---------+
  |  diaweb   |      | diaverseapi  |      | aibot  |      | club10000 |
  | git repo  |      | git repo     |      | git    |      | git     |
  +-----------+      +--------------+      +--------+      +---------+
       |                    |                  |                |
       v                    v                  v                v
  branch/status        branch/status       branch/status    branch/status
  commit here          commit here         commit here      commit here
```

Rules:

- The workspace root receives git operations only for root-owned documentation, AI context, scripts, and workspace config.
- A full workspace plan creates or reuses the same branch slug in each affected child repository.
- Unaffected repositories stay on their current branch.
- Dirty child repositories require an explicit pause before branch switching.
- Verification and commit summaries must be grouped by child repository.
