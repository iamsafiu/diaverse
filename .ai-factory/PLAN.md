# Implementation Plan: Replace Graphify With Local GBrain Knowledge Layer

Created: 2026-05-25
Mode: AIF fast plan, workspace root, no branch changes
Workspace: `C:\Users\Indigo\Desktop\diaverse`

## Settings

- Testing: yes - include health checks, dry-runs, docs checks, and GBrain smoke queries.
- Logging: standard - PowerShell helpers must print `INFO`, `WARN`, `ERROR`; use `DEBUG` only for non-secret diagnostic details.
- Docs: yes - this migration changes the workspace operating model, so documentation updates are mandatory.
- Roadmap Linkage: none, no `.ai-factory\ROADMAP.md` found.
- Graphify: remove operationally. Do not run `graphify-build.ps1`, `graphify-update.ps1`, or any Graphify MCP query during implementation.
- GBrain mode: local CLI first. No public HTTP MCP, no ChatGPT connector, no ngrok/tunnel, no auto-capture of every user message.
- Safety: the user has a backup copy of `diaverse`, but implementation should still use git status/diff checks and avoid touching child repo source code unless explicitly needed.

## Goal

Replace the current Graphify-first workspace knowledge layer with a local GBrain-based knowledge layer that can answer questions over:

- root workspace docs and AI context;
- child repository codebases as separate GBrain sources;
- documentation quality and freshness checks.

The end state should make GBrain the default local lookup path for Diaverse architecture, ownership, dependency, and documentation questions, while source code remains the final authority.

## Non-Goals

- Do not expose GBrain over public HTTP MCP.
- Do not connect GBrain to ChatGPT web connector in this migration.
- Do not enable background auto-capture of every Codex/user message.
- Do not merge child repositories into the root repository.
- Do not rewrite historical daily logs just to remove old Graphify mentions; remove active operational references and leave immutable history unless the user later asks for a history scrub.

## Research Context

The current workspace still has Graphify embedded in active rules and tooling:

- `.mcp.json` exposes a `graphify` MCP server.
- `AGENTS.md`, `.ai-factory\RULES.md`, `.ai-factory\ARCHITECTURE.md`, `.ai-factory\DESCRIPTION.md`, and skill-context files are Graphify-first.
- `.codex\hooks.json` injects a Graphify reminder before shell usage.
- `.codex\skills\graphify` exists and `scripts\sync-aif-skills.ps1` can re-overlay it from `C:\Users\Indigo\.agents\skills\graphify`.
- `scripts\graphify-build.ps1`, `scripts\graphify-update.ps1`, and `scripts\graphify-rebuild.py` are active workspace helpers.
- `graphify-out\` and `graphify-out.rar` are local generated artifacts ignored by root git.

GBrain research from `garrytan/gbrain` shows:

- Local CLI is sufficient for the first phase: `gbrain search`, `gbrain query`, `gbrain code-def`, `gbrain code-refs`, `gbrain code-callers`, `gbrain code-callees`.
- GBrain supports multi-source brains, so each Diaverse repo can remain separate.
- GBrain supports code indexing with `sync --strategy code`, tree-sitter chunking, and symbol/call graph commands.
- GBrain docs require an operator checkpoint after `gbrain init` when it prints the search-mode cost matrix; implementation must pause and relay that choice instead of silently accepting expensive defaults.

## Target Model

```text
Codex / shell
     |
     v
local GBrain CLI
     |
     +-- source: diaverse-docs        -> C:\Users\Indigo\Desktop\diaverse\docs
     +-- source: diaverse-aif         -> C:\Users\Indigo\Desktop\diaverse\.ai-factory
     +-- source: diaweb-code          -> C:\Users\Indigo\Desktop\diaverse\diaweb
     +-- source: diaverseapi-code     -> C:\Users\Indigo\Desktop\diaverse\diaverseapi
     +-- source: aibot-code           -> C:\Users\Indigo\Desktop\diaverse\aibot
     +-- source: club10000-bot-code   -> C:\Users\Indigo\Desktop\diaverse\club10000-bot
```

Root docs and `.ai-factory` should be indexed as markdown knowledge. Child repos should be indexed as code sources first. If repo-local docs are not covered well by `strategy=code`, add repo-docs sources later instead of indexing the whole workspace root recursively.

## Repository Matrix

| Repository / Area | Path | Affected | Branch changes | Role |
| --- | --- | --- | --- | --- |
| root `diaverse` repo | `C:\Users\Indigo\Desktop\diaverse` | yes | none in fast mode | Owns docs, AIF context, scripts, MCP config, hooks, root README/AGENTS |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | read/index only | none | GBrain code source; no product edits planned |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | read/index only | none | GBrain code source; no product edits planned |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | read/index only | none | GBrain code source; no product edits planned |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | read/index only | none | GBrain code source; no product edits planned |

## Tasks

### Phase 1 - Bootstrap Local GBrain

- [x] Task 1: Install or wire GBrain in a reversible local way.
  - Files/paths:
    - `.tools\gbrain\` for local clone/runtime if global `gbrain` is unavailable.
    - `scripts\gbrain-bootstrap.ps1`
    - `scripts\gbrain.ps1`
  - Deliverable:
    - A repeatable bootstrap script that checks `bun`, checks whether `gbrain` is available, and either uses the existing CLI or prepares a local deterministic clone under `.tools\gbrain`.
    - The script must not install public HTTP services or background daemons.
    - If `gbrain init` prints an `[AGENT]` search-mode cost matrix, stop and ask the user which mode to use before continuing.
  - Logging:
    - `INFO [gbrain]` for detected Bun/GBrain paths and selected install mode.
    - `WARN [gbrain]` for missing CLI, missing API keys, or fallback-to-local-clone.
    - `ERROR [gbrain]` for failed install/init.
    - Never print API keys, tokens, DB URLs, or full environment values.
  - Dependencies:
    - None.

- [x] Task 2: Initialize the local GBrain brain and register Diaverse sources.
  - Files/paths:
    - `scripts\gbrain-sources.ps1`
    - optional local-only state in `~\.gbrain` and `.tools\gbrain\`
  - Deliverable:
    - Local PGLite/default GBrain initialized.
    - Sources registered with stable IDs:
      - `diaverse-docs` -> `docs`, markdown strategy.
      - `diaverse-aif` -> `.ai-factory`, markdown strategy.
      - `diaweb-code` -> `diaweb`, code strategy.
      - `diaverseapi-code` -> `diaverseapi`, code strategy.
      - `aibot-code` -> `aibot`, code strategy.
      - `club10000-bot-code` -> `club10000-bot`, code strategy.
    - Use explicit `--source` arguments in scripts; do not add `.gbrain-source` files inside child repos unless we intentionally decide to track them.
  - Logging:
    - `INFO [gbrain]` for each source add/update.
    - `WARN [gbrain]` when a source already exists with a different path or strategy.
    - `DEBUG [gbrain]` may print source IDs and paths, but no credentials.
  - Dependencies:
    - Depends on Task 1.

- [x] Task 3: Sync and smoke-test GBrain without embeddings first.
  - Files/paths:
    - `scripts\gbrain-sync.ps1`
    - `scripts\gbrain-health.ps1`
  - Deliverable:
    - Dry-run sync before real sync for every source.
    - Initial sync can use no-embed/keyword/code metadata mode first, so the migration proves basic lookup without API spend.
    - Smoke queries:
      - `gbrain search "cabinet auth"` against docs/AIF.
      - `gbrain search "club payment"` against docs/AIF.
      - `gbrain code-def CopywritingDailyView` against `diaweb-code`.
      - `gbrain code-def TelegramService` against `aibot-code`.
      - one `code-callers` or `code-refs` check on a symbol that exists after indexing.
    - Capture failed/missing symbols as implementation notes and adjust source strategy only if needed.
  - Logging:
    - `INFO [gbrain]` for dry-run counts, sync counts, and smoke-query pass/fail.
    - `WARN [gbrain]` for empty sources, skipped embeddings, missing expected symbols, or unsupported file types.
    - `ERROR [gbrain]` for failed sync.
  - Dependencies:
    - Depends on Task 2.

### Phase 2 - Remove Graphify Operational Surface

- [x] Task 4: Remove Graphify runtime, generated artifacts, MCP entry, and scripts.
  - Files/paths:
    - `.mcp.json`
    - `.gitignore`
    - `.graphifyignore`
    - `.tools\graphify\`
    - `graphify-out\`
    - `graphify-out.rar`
    - `scripts\graphify-build.ps1`
    - `scripts\graphify-update.ps1`
    - `scripts\graphify-rebuild.py`
  - Deliverable:
    - `.mcp.json` no longer exposes Graphify.
    - Graphify runtime/generated artifacts removed from the workspace.
    - Root `.gitignore` removes Graphify-specific tracking/ignore exceptions and keeps `.tools\` ignored for local runtime state.
    - No Graphify command remains as an active workspace helper.
  - Logging:
    - `INFO [cleanup]` for every removed path category.
    - `WARN [cleanup]` for already-missing paths.
    - `ERROR [cleanup]` only if deletion fails after path validation.
  - Dependencies:
    - Depends on successful GBrain smoke tests from Task 3.

- [x] Task 5: Remove Graphify from Codex skills/hooks and prevent reintroduction.
  - Files/paths:
    - `.codex\hooks.json`
    - `.codex\skills\graphify\`
    - `scripts\sync-aif-skills.ps1`
  - Deliverable:
    - PreToolUse hook stops injecting Graphify instructions.
    - Graphify skill directory removed from top-level `.codex\skills`.
    - `sync-aif-skills.ps1` no longer overlays `C:\Users\Indigo\.agents\skills\graphify`.
    - Optional replacement hook may remind agents that GBrain is local CLI only, but it must not run GBrain automatically before every shell command.
  - Logging:
    - `INFO [skills]` for sync behavior changes.
    - `WARN [skills]` if legacy Graphify skill is found outside the workspace but intentionally ignored.
  - Dependencies:
    - Depends on Task 4.

### Phase 3 - Switch Workspace Rules And Documentation To GBrain

- [x] Task 6: Update active AI Factory and agent rules from Graphify-first to GBrain-first.
  - Files/paths:
    - `AGENTS.md`
    - `.ai-factory\DESCRIPTION.md`
    - `.ai-factory\ARCHITECTURE.md`
    - `.ai-factory\RULES.md`
    - `.ai-factory\RESEARCH.md`
    - `.ai-factory\skill-context\aif-plan\SKILL.md`
    - `.ai-factory\skill-context\aif-implement\SKILL.md`
    - `.ai-factory\skill-context\aif-verify\SKILL.md`
    - `.ai-factory\skill-context\aif-review\SKILL.md`
    - `.ai-factory\skill-context\aif-fix\SKILL.md`
    - `.ai-factory\skill-context\aif-explore\SKILL.md`
  - Deliverable:
    - Replace Graphify-first guidance with:
      - GBrain-first for architecture, ownership, dependency, docs, and code lookup.
      - `rg`/raw source reads remain required for exact verification and line-accurate code edits.
      - Source code remains final authority if GBrain output disagrees.
      - No Graphify refresh step after code/docs changes.
    - Active `.ai-factory\RESEARCH.md` summary should describe the new GBrain decision. Historical sessions may remain as history.
  - Logging:
    - No runtime logging required, but implementation notes should list every updated context file.
  - Dependencies:
    - Depends on Tasks 3-5.

- [x] Task 7: Update documentation system around GBrain.
  - Files/paths:
    - `README.md`
    - `docs\README.md`
    - `docs\documentation-system.md`
    - new `docs\knowledge-system.md` or `docs\gbrain.md`
  - Deliverable:
    - Root README and docs portal describe GBrain as the local knowledge layer.
    - Documentation workflow explains:
      - docs health check remains mandatory;
      - GBrain sync replaces Graphify update;
      - GBrain answers are navigation/synthesis, not final source truth;
      - no auto-capture of raw conversations;
      - no public HTTP MCP by default.
    - New GBrain/knowledge-system doc includes source IDs, bootstrap/sync/health commands, safe query examples, and troubleshooting.
  - Logging:
    - No runtime logging required.
  - Dependencies:
    - Depends on Task 6.

### Phase 4 - Verification, Cleanup, And Commit

- [x] Task 8: Add migration verification scripts and run them.
  - Files/paths:
    - `scripts\gbrain-health.ps1`
    - `scripts\docs-health.ps1` if docs exclusions or wording need adjustment.
  - Deliverable:
    - `gbrain-health.ps1` verifies:
      - `gbrain doctor` or equivalent local health command.
      - expected source IDs exist.
      - sample docs/code queries work.
      - no Graphify MCP entry exists.
      - no active Graphify scripts remain.
    - `docs-health.ps1` still passes after docs updates.
  - Logging:
    - `INFO [gbrain-health]` for each passed check.
    - `WARN [gbrain-health]` for optional embeddings or query quality gaps.
    - `ERROR [gbrain-health]` for missing required CLI/source/smoke checks.
  - Dependencies:
    - Depends on Tasks 3-7.

- [x] Task 9: Run final Graphify removal audit.
  - Files/paths:
    - whole workspace root, excluding child repo internals unless needed.
  - Deliverable:
    - `rg -n "Graphify|graphify|graphify-out|\\.graphifyignore"` should show no active operational references in:
      - `AGENTS.md`
      - `README.md`
      - `docs\README.md`
      - `docs\documentation-system.md`
      - `.mcp.json`
      - `.codex\hooks.json`
      - `.ai-factory\DESCRIPTION.md`
      - `.ai-factory\ARCHITECTURE.md`
      - `.ai-factory\RULES.md`
      - `.ai-factory\skill-context\*`
      - `scripts\*`
    - Historical mentions in `docs\daily`, `.ai-factory\patches`, and old completed plan files may remain unless the user requests a history scrub.
  - Logging:
    - Record the audit command and result in implementation notes.
  - Dependencies:
    - Depends on Tasks 4-8.

- [x] Task 10: Commit and push root workspace changes.
  - Files/paths:
    - root git repo only.
  - Deliverable:
    - Root repo commit with conventional message, suggested: `chore: replace graphify with gbrain knowledge layer`.
    - Push to `git@github.com:iamsafiu/diaverse.git` `main`.
    - No child repo commits unless implementation unexpectedly changes child repo files.
  - Logging:
    - Include commit hash and push result in final implementation notes.
  - Dependencies:
    - Depends on Tasks 8-9.

## Verification Plan

Run from `C:\Users\Indigo\Desktop\diaverse`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-health.ps1
git status --short --branch
```

GBrain smoke commands should be executed through the wrapper chosen in Task 1, for example:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 doctor
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 sources list
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 search "cabinet auth"
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 code-def CopywritingDailyView
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 code-def TelegramService
```

Graphify removal audit:

```powershell
rg -n "Graphify|graphify|graphify-out|\.graphifyignore" AGENTS.md README.md docs .ai-factory .codex scripts .mcp.json .gitignore
```

Expected: no active operational references outside historical logs/patches/old completed plans.

## Rollback Plan

- Use the user's backup copy if the workspace needs a full restore.
- For normal rollback, use root git:
  - revert the migration commit;
  - restore `.mcp.json`, Graphify scripts, `.graphifyignore`, `.codex\skills\graphify`, and Graphify rules from the previous commit.
- Do not delete the user's `~\.gbrain` data during rollback unless explicitly requested.

## Commit Plan

Because this plan has 10 tasks, use commit checkpoints:

1. `chore: add local gbrain workspace helpers`
   - Tasks 1-3.
2. `chore: remove graphify workspace tooling`
   - Tasks 4-5.
3. `docs: switch workspace knowledge system to gbrain`
   - Tasks 6-7.
4. `chore: verify gbrain migration`
   - Tasks 8-10.

## Next Step

Run `/aif-implement` from `C:\Users\Indigo\Desktop\diaverse` when ready to execute this plan.
