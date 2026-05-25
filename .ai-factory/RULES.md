# Workspace Rules

- Always prefer the shared Graphify report or Graphify MCP for architecture and cross-repo questions before broad raw-file search.
- Trust source code over graph output when they disagree, then refresh the graph.
- Refresh the shared graph with `scripts\graphify-build.ps1` or `scripts\graphify-update.ps1` instead of calling raw `graphify update .` directly from the workspace.
- Use top-level `diaverse\.ai-factory` as the primary operational AIF context for cross-repo plans, implementation, review, and verification.
- In the top-level workspace, AIF `full` mode means multi-repo full mode over affected child repositories for product code, plus root repo operations only for root-owned docs/context/scripts.
- Keep product-code branches, status checks, staging, and commits inside the owning child repositories: `diaweb`, `diaverseapi`, `aibot`, and `club10000-bot`.
- Use the root `diaverse` git repository only for `docs/`, `.ai-factory/`, `.codex/skills/`, `scripts/`, `AGENTS.md`, `README.md`, and workspace config.
- Never add child repository source trees to the root repository.
- For multi-repo full plans, use one branch slug across affected repositories, but do not use `codex/` in branch names. Prefer normal branch prefixes such as `feature/`, `fix/`, `chore/`, `refactor/`, or `test/`.
- Store cross-repo plans in `diaverse\.ai-factory\plans\`; do not store cross-repo plans inside `diaweb` just because the frontend is involved.
- Use `diaweb` as the browser-facing entrypoint, `diaverseapi` as the core backend, `aibot` as the internal copywriting service, and `club10000-bot` as the standalone Club10000 Telegram bot service.
