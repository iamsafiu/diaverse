# Workspace Rules

- Prefer local GBrain for architecture, cross-repo, dependency, ownership, docs, and code navigation before broad raw-file search.
- Preferred GBrain pattern: `list` or `search` -> `get` canonical page -> raw-file/source verification.
- Do not use GBrain `query` as the only source for final answers; use it only for optional broad discovery.
- Treat GBrain as a navigation and synthesis layer, not the final authority; verify exact behavior in source files or canonical docs before editing or reporting.
- If GBrain output disagrees with source code, trust source code and refresh the affected GBrain source with `scripts\gbrain-sync.ps1` or a source-scoped sync command.
- Do not expose GBrain through public HTTP MCP, ChatGPT connector, tunnel, or background daemon without a separate auth/security review.
- Do not auto-capture raw user/Codex conversations into GBrain.
- Use top-level `diaverse\.ai-factory` as the primary operational AIF context for cross-repo plans, implementation, review, and verification.
- In the top-level workspace, AIF `full` mode means multi-repo full mode over affected child repositories for product code, plus root repo operations only for root-owned docs/context/scripts.
- Keep product-code branches, status checks, staging, and commits inside the owning child repositories: `diaweb`, `diaverseapi`, `aibot`, and `club10000-bot`.
- Use the root `diaverse` git repository only for `docs/`, `.ai-factory/`, `.codex/skills/`, `scripts/`, `AGENTS.md`, `README.md`, and workspace config.
- Never add child repository source trees to the root repository.
- For multi-repo full plans, use one branch slug across affected repositories, but do not use `codex/` in branch names. Prefer normal branch prefixes such as `feature/`, `fix/`, `chore/`, `refactor/`, or `test/`.
- Store cross-repo plans in `diaverse\.ai-factory\plans\`; do not store cross-repo plans inside `diaweb` just because the frontend is involved.
- Use `diaweb` as the browser-facing entrypoint, `diaverseapi` as the core backend, `aibot` as the internal copywriting service, and `club10000-bot` as the standalone Club10000 Telegram bot service.
