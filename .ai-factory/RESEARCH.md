# Research

Updated: 2026-05-25 15:45
Status: ready

## Active Summary (input for /aif-plan)
<!-- aif:active-summary:start -->
Topic: Workspace-level GBrain and AI Factory integration for the full Diaverse system
Goal: Use one shared AI workspace over `diaweb`, `diaverseapi`, `aibot`, and `club10000-bot` with local GBrain sources and top-level AIF control plane for cross-repo planning, implementation, review, verification, and commits.
Constraints:
  - Keep the child repositories separate; do not create a monorepo
  - The workspace root is a lightweight git repository for documentation, AI context, shared scripts, and workspace config only
  - Repo-local source code remains the final authority
  - Top-level AIF should coordinate cross-repo work without collapsing the child repositories into a monorepo
  - Repo-local AI context is reference/fallback context unless the user explicitly asks to work inside one repository in isolation
  - Keep GBrain local CLI-first; no public HTTP MCP, no ChatGPT connector, and no automatic raw conversation capture by default
Decisions:
  - Use `C:\Users\Indigo\Desktop\diaverse` as the shared workspace root
  - Keep local GBrain project state under `.tools/gbrain/home`
  - Register stable source IDs for root docs, AI Factory context, and each child code repository
  - Use top-level AIF for cross-repo planning, implementation, review, verification, and commit coordination
  - Keep branches, status checks, staging, and commits inside `diaweb`, `diaverseapi`, `aibot`, and `club10000-bot`
  - Keep the top-level plan as the single progress source of truth for workspace-run implementations
  - Sync top-level Codex skills from `diaweb/.agents/skills`
Open questions:
  - Whether to enable embeddings later after the no-embedding baseline is stable
Success signals:
  - Top-level Codex sessions can plan, implement, review, verify, and coordinate commits naturally from `diaverse`
  - GBrain health checks pass against `diaverse-docs`, `diaverse-aif`, `diaweb-code`, `diaverseapi-code`, `aibot-code`, and `club10000-bot-code`
  - Agents use GBrain first for cross-repo navigation, then verify exact source files and canonical docs
Next step: Use local GBrain as the default cross-repo navigation layer, run AIF from the workspace root by default, and rerun GBrain sync whenever code or long-lived docs change
<!-- aif:active-summary:end -->

## Sessions
<!-- aif:sessions:start -->
### 2026-05-25 - Local GBrain workspace knowledge layer
What changed:
  Switched the active workspace knowledge decision to local GBrain sources over root documentation, AI Factory context, and the four child code repositories.

Key notes:
  - GBrain is local CLI-first through `scripts/gbrain.ps1`
  - Project-local state lives under `.tools/gbrain/home`
  - Stable source IDs are `diaverse-docs`, `diaverse-aif`, `diaweb-code`, `diaverseapi-code`, `aibot-code`, and `club10000-bot-code`
  - No public HTTP MCP, ChatGPT connector, tunnel, daemon, or raw conversation auto-capture is enabled by default
  - Source code and canonical docs remain the final authority

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-health.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\docs\knowledge-system.md`

### 2026-04-28 - Pets and pet skins source of truth
What changed:
  Captured the backend catalog model for Diaverse pets and pet skins after the production audit showed mixed base pets, legacy character variants, default visuals, and item skins.

Key notes:
  - `characters.subkind = default` is the only normal base-pet shape.
  - `characters.subkind != default` is a legacy/event character variant and must not be sold or granted as a new base pet.
  - `pet_skin_defs.is_default = true` is a bundled default age/evolution visual, not a `UserSkinItem`.
  - `pet_skin_defs.is_default = false AND is_acquirable = true` is a real item/equippable pet skin.
  - `pet_skin_defs.is_default = false AND is_acquirable = false` is a legacy/non-acquirable skin definition.
  - User-approved decisions: Красная панда is a skin of Панда; Кенгуру-победитель is a skin of Кенгуру; Единорог is a base pet without approved item skins; Огонёк, Кристаллик, and Лианчик are three different base pets; missing skins must wait for real assets/data.

Links:
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\pets-skins-catalog.md`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\pets-skins-canonical-manifest.md`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\sql\pets_skins_preflight.sql`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\sql\pets_skins_postcheck.sql`

### 2026-04-21 16:40 - Workspace AI coordination bootstrap
What changed:
  Established the decision to keep a shared workspace root with top-level Graphify and AI Factory context while preserving the three separate repositories.

Key notes:
  - `diaweb` already had the richest AI context and skill pack
  - `aibot` had partial AI Factory state
  - `diaverseapi` had no local AI Factory files
  - Top-level Graphify and MCP are the right place to unify architectural context

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\diaweb`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi`
  - `C:\Users\Indigo\Desktop\diaverse\aibot`

### 2026-04-21 16:45 - Shared graph runtime wired and validated
What changed:
  Installed Graphify into `C:\Users\Indigo\Desktop\diaverse\.tools\graphify\.venv`, enabled Codex integration, created a shared Graphify MCP server, and produced the first workspace graph artifacts.

Key notes:
  - `ai-factory init --agents codex --no-skills --mcp filesystem,playwright,postgres,chrome-devtools` was enough to bootstrap top-level AI Factory metadata without moving repo-local contexts
  - `graphify codex install` added always-on Graphify guidance and a Codex pre-tool hook at the workspace root
  - The installed `graphify` CLI exposes `update`, `query`, `path`, `explain`, and `serve`; the slash-command examples in the README map to skill behavior, not a public `graphify .` CLI subcommand
  - The workspace graph is large enough to exceed Graphify's default HTML visualization limit (`MAX_NODES_FOR_VIZ = 5000`), so the workspace scripts now rebuild through a helper that safely raises the cap for this workspace
  - Current shared graph outputs:
    - `C:\Users\Indigo\Desktop\diaverse\graphify-out\GRAPH_REPORT.md`
    - `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
    - `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.html`

Validation:
  - Rebuild command: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-build.ps1`
  - Refresh command: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`
  - Graph query example: `C:\Users\Indigo\Desktop\diaverse\.tools\graphify\.venv\Scripts\python.exe -m graphify query "show the auth flow" --graph C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
  - MCP server command: `C:\Users\Indigo\Desktop\diaverse\.tools\graphify\.venv\Scripts\python.exe -m graphify.serve C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`

Recovery steps:
  - If the graph looks stale, rerun `scripts\graphify-update.ps1`
  - If graph files are missing or corrupted, rerun `scripts\graphify-build.ps1`
  - If graph output conflicts with code, trust the code, then refresh the graph

### 2026-04-21 17:10 - Multi-repo AIF full mode decision
What changed:
  Reframed the top-level `diaverse` workspace as the primary operational AIF center, not just a planning brain. The user's preferred workflow is one AIF session from `C:\Users\Indigo\Desktop\diaverse` that may plan, implement, review, verify, and coordinate changes across `diaweb`, `diaverseapi`, and `aibot`.

Key notes:
  - Do not require the user to enter each child repository and run `$aif-implement` separately
  - In the workspace root, `$aif-plan full` means multi-repo full mode over affected child repositories
  - The top-level folder is a coordination git repository only; child repositories stay independent
  - Branches, status checks, staging, and commits remain per child repository
  - The top-level plan remains the single progress source of truth
  - Helper scripts now support status and branch creation/switching across selected child repositories

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-plan\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-implement\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-verify\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-commit\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-status.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-branch.ps1`

### 2026-04-21 18:01 - Multi-repo AIF housekeeping
What changed:
  Removed stale wording from the active research summary so it consistently treats top-level AIF as the default workspace control plane for planning, implementation, review, verification, and commit coordination.

Key notes:
  - Repo-local AI context remains useful as reference/fallback context
  - Cross-repo progress should stay in the top-level plan under `diaverse\.ai-factory\plans\`
  - `diaverseapi` now has a local `AGENTS.md` map for backend-specific agent guidance

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\RESEARCH.md`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\AGENTS.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\`
<!-- aif:sessions:end -->
