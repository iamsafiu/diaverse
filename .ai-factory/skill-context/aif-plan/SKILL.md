# Graph-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, and impact questions, first consult `C:\Users\Indigo\Desktop\diaverse\graphify-out\GRAPH_REPORT.md`.
- If Graphify MCP is available, query the graph before broad raw-file search.
- Use raw-file reads after that for verification, exact edits, and line-accurate confirmation.
- If graph output conflicts with source code, trust source code and note that the graph should be refreshed.

## Diaverse Multi-Repo Full Mode

When `$aif-plan full` is invoked from `C:\Users\Indigo\Desktop\diaverse`, override the normal single-product-repo meaning of `full`. The workspace root is a lightweight coordination repository only. Treat `full` as a multi-repo workspace plan over these child repositories:

- `diaweb` at `C:\Users\Indigo\Desktop\diaverse\diaweb`
- `diaverseapi` at `C:\Users\Indigo\Desktop\diaverse\diaverseapi`
- `aibot` at `C:\Users\Indigo\Desktop\diaverse\aibot`
- `club10000-bot` at `C:\Users\Indigo\Desktop\diaverse\club10000-bot`

Planning rules:

- Use the top-level `.ai-factory` as the source of truth for the plan.
- Read the shared Graphify report before broad file search.
- Detect affected repositories from the requested feature and from source verification.
- Do not create branches in unaffected repositories.
- Use one branch slug across affected repositories. Do not use `codex/` in branch names. Prefer normal branch prefixes such as `feature/`, `fix/`, `chore/`, `refactor/`, or `test/`.
- Before branch creation or switching, check each affected child repo with `git -C <repo> status --short` and `git -C <repo> branch --show-current`.
- If a child repository has unrelated uncommitted changes, pause and ask before switching branches.
- Store the master plan under `C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\<branch-slug>.md`.
- If a fast plan is requested, store it in `C:\Users\Indigo\Desktop\diaverse\.ai-factory\PLAN.md` and do not create branches.
- Never run `git checkout`, `git switch`, `git branch`, `git commit`, or `git merge` against the top-level `diaverse` folder.

Multi-repo full plan format:

```markdown
## Workspace Mode
- Mode: multi-repo full
- Workspace root: C:\Users\Indigo\Desktop\diaverse
- Shared graph: C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes/no | feature/<slug> | clean/dirty | frontend |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes/no | feature/<slug> | clean/dirty | backend |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | yes/no | feature/<slug> | clean/dirty | copywriting service |
| club10000-bot | C:\Users\Indigo\Desktop\diaverse\club10000-bot | yes/no | feature/<slug> | clean/dirty | Club10000 bot |

## Tasks
- [ ] [diaverseapi] Implement backend contract
- [ ] [diaweb] Wire frontend/BFF integration
- [ ] [aibot] Update internal service behavior, if affected
- [ ] [club10000-bot] Update standalone bot behavior, if affected
- [ ] [cross-repo] Verify the end-to-end flow

## Verification Plan
- diaweb: <lint/test/build commands if applicable>
- diaverseapi: <pytest/alembic/type/lint commands if applicable>
- aibot: <pytest/lint commands if applicable>
- club10000-bot: <pytest/lint/docker commands if applicable>
- graph: refresh Graphify after code changes

## Commit Plan
- diaweb: <conventional commit suggestion>
- diaverseapi: <conventional commit suggestion>
- aibot: <conventional commit suggestion>
- club10000-bot: <conventional commit suggestion>
```

Helper commands available from the workspace root:

- `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-status.ps1`
- `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-branch.ps1 -Branch feature/<slug> -Repos diaweb,diaverseapi,club10000-bot -Create`

## PostgreSQL Migration Planning Guard

**Source**: `.ai-factory/patches/2026-04-21-23.31-postgresql-identifier-limit.md`

When a plan includes Alembic migrations for `diaverseapi`, add an explicit verification step for PostgreSQL DDL compilation, not only `alembic heads`. PostgreSQL identifiers are limited to 63 bytes, so planned index/constraint names for long composite objects must be short, explicit, and meaningful. For new revisions, include a check shaped like:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```
