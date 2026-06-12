# GBrain-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, docs, and impact questions, use local GBrain first when it is available.
- Use `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1` with source-scoped lookups before broad raw-file search.
- Preferred lookup pattern: GBrain `list` or `search` -> GBrain `get` canonical page -> raw-file/source verification.
- Do not use GBrain `query` as the only source for final answers; treat it as optional broad discovery.
- Before changing code, verify the exact implementation in the owning repository source files.
- If GBrain output conflicts with source code, trust source code and run targeted GBrain sync after the change.

## Diaverse Multi-Repo Implementation Mode

When `$aif-implement` is invoked from `C:\Users\Indigo\Desktop\diaverse`, implement from the workspace root and allow code changes in the affected child repositories named by the active top-level plan.

Implementation rules:

- The top-level plan in `diaverse\.ai-factory\PLAN.md` or `diaverse\.ai-factory\plans\*.md` is the progress source of truth.
- Do not search for branch-named plans inside child repositories unless the user explicitly passes an `@plan-file` path there.
- Before editing code, run or mentally follow the workspace status check for affected repositories.
- Read the owning repository `AGENTS.md` before editing files in that repository.
- Use GBrain first for cross-repo navigation, then verify exact source files before edits.
- Execute one task at a time and keep task checkboxes in the top-level plan synchronized.
- Tasks should be tagged with repository ownership such as `[diaweb]`, `[diaverse-mobile]`, `[diaverseapi]`, `[aibot]`, `[club10000-bot]`, `[diaverse-auth-bot]`, or `[cross-repo]`.
- A `[cross-repo]` task may edit multiple child repositories, but the final summary must list changes grouped per repository.
- Run top-level `diaverse` git operations only for root-owned documentation, AI context, shared scripts, and workspace config. Never stage or commit child repository source trees from the root repo.
- If the plan requires branch checks, use child-repo commands such as `git -C diaweb status --short` or `git -C diaverse-mobile status --short`.
- After meaningful code or docs changes, run targeted GBrain sync or `scripts\gbrain-sync.ps1`.
- If source code and GBrain disagree, trust source code and refresh the affected source.

Do not redirect the user to run `$aif-implement` inside each child repository. The preferred workflow is one top-level implementation pass from `C:\Users\Indigo\Desktop\diaverse`.

## Daily Work Capture Hook

When `$aif-implement` completes a meaningful plan task in this workspace, update `docs/daily/YYYY-MM-DD-<author>.md` before marking the task fully done unless the user explicitly says `bez daily` or `no daily`. Use `DAILY_WORK_AUTHOR` when configured, otherwise use `safiu`.

Daily work requirements:

- Keep two sections in every daily file: `Public digest` and `Internal log`.
- Write daily document entries in Russian unless the user explicitly asks for another language. Keep the technical section headings `Public digest` and `Internal log` unchanged because the publisher parses them.
- Append product/user-facing progress notes to `Public digest`; this is the only section that may be published to Confluence or used for public post generation.
- Append implementation details, changed-file context, verification notes, and resume context to `Internal log`; this section stays local and must never be sent to Confluence or post generation.
- Do not write secrets, tokens, raw environment values, private SSH commands, SSH key paths, internal IPs, private infrastructure details, or sensitive stack traces into `Public digest`.
- If a note is useful but sensitive or too technical for users, put a sanitized summary in `Public digest` and the technical detail in `Internal log`.
- Mention the daily-log update in the final answer for the task or implementation session.

## PostgreSQL Migration Identifier Guard

**Source**: `.ai-factory/patches/2026-04-21-23.31-postgresql-identifier-limit.md`

When implementing Alembic migrations in `diaverseapi`, validate every explicit PostgreSQL object name before marking the task complete. PostgreSQL identifiers are limited to 63 bytes, and long composite index names produced from table/column names can fail only during DDL compilation. Use short, explicit, meaningful names for indexes and constraints, mirror those names in SQLModel metadata when applicable, and run an offline SQL compilation check for new migration revisions:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

Do not treat `alembic heads`, Python compilation, Ruff, or unit tests as sufficient validation for a migration that creates indexes or constraints.
