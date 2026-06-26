# Architecture: Shared Workspace Over Eight Repositories

## Overview

Diaverse uses eight separate repositories coordinated through a shared workspace root:

- `diaweb` handles the browser-facing frontend and BFF routes
- `diaverse-mobile` handles the Expo / React Native mobile frontend for iOS and Android
- `diaverseapi` handles cabinet, auth, staff, and game backend domains
- `aibot` handles internal copywriting workflows consumed by `diaweb`
- `diaverse-content` handles the standalone content factory for public learn pages, drafts, revisions, slugs, content search, content SEO fragments, first-party content metrics, and manual Codex-operated draft generation
- `diaverse-ai-cofounder` is an archived/R&D reference repo retained for historical prompts, strategy notes, and rollback context; it is not an active runtime dependency
- `club10000-bot` handles the standalone Club10000 Telegram bot, Prodamus callbacks, and its restored bot-local database
- `diaverse-auth-bot` handles Telegram transport for Diaverse browser login and mobile Telegram linking

The workspace root adds AI coordination and documentation versioning only. It does not add code dependencies or runtime coupling beyond the integrations that already exist.

## Workspace Layout

```text
diaverse/
|-- .gitignore           # Root repo tracks workspace docs/context only
|-- README.md            # Root repository landing page
|-- .ai-factory/         # Cross-repo context and GBrain-first rules
|-- .codex/skills/       # Workspace-level skill pack
|-- .mcp.json            # Workspace MCP registry
|-- .tools/gbrain/       # Local GBrain runtime and project brain state
|-- docs/                # Cross-repo runbooks, task briefs, and daily work logs
|-- scripts/             # Workspace maintenance, GBrain, and daily work scripts
|-- diaweb/              # Web frontend repo, ignored by root git
|-- diaverse-mobile/     # Mobile frontend repo, ignored by root git
|-- diaverseapi/         # Backend repo, ignored by root git
|-- aibot/               # Copywriting service repo, ignored by root git
|-- diaverse-content/    # Content factory repo, ignored by root git
|-- diaverse-ai-cofounder/ # AI Cofounder runtime repo, ignored by root git
|-- club10000-bot/       # Club10000 bot repo, ignored by root git
`-- diaverse-auth-bot/   # Auth bot repo, ignored by root git
```

## Dependency Rules

### Cross-Repo

```text
diaweb -> diaverseapi    # REST/BFF integration
diaweb -> aibot          # internal JWT-backed BFF integration for copywriting
diaverse-mobile -> diaverseapi   # mobile app API integration over shared backend contracts
diaverseapi -> aibot     # signed club creative asset requests only
aibot -> diaverseapi     # copywriting-clubbot signed club Telegram events/outbox only
diaweb -> diaverse-content  # internal JWT-backed BFF integration for content staff workflows
aibot -> diaverse-content   # optional disabled draft import bridge only after content contracts stabilize
local Codex session -> diaverse-content # manual content analysis, metrics export, draft-only imports
diaverse-ai-cofounder -> workspace/docs only # archived historical reference, no active runtime dependency
club10000-bot -> diaverseapi   # signed normalized Club10000 payment events only
diaverse-auth-bot -> diaverseapi   # signed auth login-session and mobile-link approvals only
workspace -> repos       # AI context only, no runtime dependency
```

### Mobile App

```text
diaverse-mobile/app + expo-router screens
        |
        v
diaverse-mobile/api/services/hooks/store
        |
        v
diaverseapi shared auth, cabinet, game, payment, and user APIs
```

`diaverse-mobile` owns the mobile client runtime: Expo / React Native code, committed `ios/` and `android/` project files, EAS build/update configuration, mobile diagnostics, mobile analytics, mobile purchases, localization, and native integration contracts. `diaverseapi` remains the shared backend authority for mobile and web product data. `diaweb` remains the web frontend and same-origin BFF layer; mobile work must not assume `diaweb` is the backend source of truth unless a specific mobile-to-BFF dependency is documented in a feature plan.

### Auth Bot

```text
diaweb auth UI -> diaverseapi/app/security login-session API
diaverseapi    -> login token and browser polling state in Redis
Telegram user  -> diaverse-auth-bot /start login_<token>
diaverse-auth-bot -> signed internal HTTP -> diaverseapi/app/security
diaverseapi    -> user provisioning, Telegram identity persistence, cookies, RBAC, account-linking
```

The auth bot is stateless by design. It must not own a database, Redis state, user provisioning, browser cookies, or broadcast recipient truth. Durable Telegram identity state belongs to `diaverseapi` through `users.tg_user_id` and `bot_users.platform_id`.

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

### Content Factory

```text
public browser -> diaverse.app/ru/learn/* -> diaverse-content public renderer
staff browser  -> diaweb /staff/content -> diaweb BFF -> diaverse-content internal API
diaverseapi    -> staff identity, RBAC, analytics storage
aibot          -> optional draft import bridge, disabled until contract approval
local Codex    -> metrics/context export -> draft-only import -> human review
```

`diaverse-content` owns public learn content state, drafts, revisions, slug history, content search, content SEO fragments, content performance summaries, and the manual Codex operator workflow. It must not own Diaverse product/game/club truth and must not write to the Diaverse backend database. Public routes should stay on the main domain under `/ru/learn/*`; staff browser entrypoints stay in `diaweb`, and staff permission truth stays in `diaverseapi`.

Detailed routing, admin boundary, SEO ownership, analytics, draft import, deployment, and rollback rules live in `docs/architecture/content-factory.md`.

### Archived AI Cofounder

```text
diaverse-ai-cofounder -> historical prompts, org context, strategy notes, and rollback reference
local Codex session   -> diaverse-content content-operator context
diaverse-content      -> draft-only imports and human publication workflow
```

`diaverse-ai-cofounder` is no longer an active operations runtime. The content workflow now uses local Codex sessions as a manual operator over `diaverse-content` metrics, strategy files, and draft import APIs. The archived repo should not run schedules, Telegram reports, autonomous shell/code automation, or production draft orchestration unless a new plan explicitly reactivates it.

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
repo .ai-factory      -> local implementation context
GBrain                -> local navigation layer over docs, AIF context, and repo code
source code           -> final authority when GBrain and code disagree
```

## Operating Model

### Planning

- Use top-level AIF from `C:\Users\Indigo\Desktop\diaverse` as the primary control plane for Diaverse work
- In the workspace root, normal `full` planning means multi-repo full mode over affected child repositories
- Use GBrain first for architecture, ownership, dependency, and docs lookup
- Store cross-repo master plans under `diaverse/.ai-factory/plans/`
- Use repo-level AIF only as an explicit fallback when the user wants to isolate work inside one child repository

### Implementation

- Implement cross-repo plans from the workspace root when the task may touch more than one repository
- Edit product code only inside `diaweb`, `diaverse-mobile`, `diaverseapi`, `aibot`, `diaverse-content`, `club10000-bot`, or `diaverse-auth-bot`
- Keep progress checkboxes in the top-level plan for workspace-run implementations
- Commit product code inside each repository that owns changes
- Commit top-level workspace files in the root repository only when the change is limited to documentation, AI context, shared scripts, or workspace config
- Keep top-level workspace files focused on coordination, AI context, GBrain helpers, documentation, and scripts
- After meaningful code or docs changes, run targeted GBrain sync or `scripts/gbrain-sync.ps1`

### GBrain

- Use project-local GBrain state under `.tools/gbrain/home`
- Keep GBrain source IDs stable so docs, AIF context, and each child repo remain queryable separately
- Use `list` and code-symbol commands as the no-embedding baseline; keyword search may be enabled or tested separately
- Do not expose GBrain through public HTTP/MCP or ChatGPT connector by default
- Do not auto-capture every conversation into GBrain

### Multi-Repo Full Mode

```text
diaverse/.ai-factory/plans/<branch-slug>.md
        |
        | owns one cross-repo plan
        v
  +-----------+      +------------------+      +--------------+
  |  diaweb   |      | diaverse-mobile  |      | diaverseapi  |
  | git repo  |      | git repo         |      | git repo     |
  +-----------+      +------------------+      +--------------+
       |                      |                       |
       v                      v                       v
  branch/status          branch/status           branch/status
  commit here            commit here             commit here

  +--------+      +------------------+      +-----------------------+      +-------------+      +--------------------+
  | aibot  |      | diaverse-content|      | diaverse-ai-cofounder |      | club10000   |      | diaverse-auth-bot  |
  | git    |      | git repo        |      | git repo              |      | git repo    |      | git repo           |
  +--------+      +------------------+      +-----------------------+      +-------------+      +--------------------+
       |                   |                          |                         |                       |
       v                   v                          v                         v                       v
  branch/status       branch/status              branch/status             branch/status           branch/status
  commit here         commit here                commit here               commit here             commit here
```

Rules:

- The workspace root receives git operations only for root-owned documentation, AI context, scripts, and workspace config.
- A full workspace plan creates or reuses the same branch slug in each affected child repository.
- Unaffected repositories stay on their current branch.
- Dirty child repositories require an explicit pause before branch switching.
- Verification and commit summaries must be grouped by child repository.
