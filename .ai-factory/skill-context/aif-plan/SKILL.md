# GBrain-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, docs, and impact questions, use local GBrain first when it is available.
- Use `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1` and source-scoped lookups before broad raw-file search.
- Preferred lookup pattern: GBrain `list` or `search` -> GBrain `get` canonical page -> raw-file/source verification.
- Do not use GBrain `query` as the only source for final answers; treat it as optional broad discovery.
- Use raw-file reads after GBrain for verification, exact edits, and line-accurate confirmation.
- If GBrain output conflicts with source code, trust source code and plan a targeted GBrain sync.

## Diaverse Multi-Repo Full Mode

When `$aif-plan full` is invoked from `C:\Users\Indigo\Desktop\diaverse`, override the normal single-product-repo meaning of `full`. The workspace root is a lightweight coordination repository only. Treat `full` as a multi-repo workspace plan over these child repositories:

- `diaweb` at `C:\Users\Indigo\Desktop\diaverse\diaweb`
- `diaverse-mobile` at `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile`
- `diaverseapi` at `C:\Users\Indigo\Desktop\diaverse\diaverseapi`
- `aibot` at `C:\Users\Indigo\Desktop\diaverse\aibot`
- `club10000-bot` at `C:\Users\Indigo\Desktop\diaverse\club10000-bot`

Planning rules:

- Use the top-level `.ai-factory` as the source of truth for the plan.
- Use GBrain first for cross-repo navigation, then verify affected files with source reads.
- Detect affected repositories from the requested feature and from source verification.
- Do not create branches in unaffected repositories.
- Use one branch slug across affected repositories. Do not use `codex/` in branch names. Prefer normal branch prefixes such as `feature/`, `fix/`, `chore/`, `refactor/`, or `test/`.
- Before branch creation or switching, check each affected child repo with `git -C <repo> status --short` and `git -C <repo> branch --show-current`.
- If a child repository has unrelated uncommitted changes, pause and ask before switching branches.
- Store the master plan under `C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\<branch-slug>.md`.
- If a fast plan is requested, store it in `C:\Users\Indigo\Desktop\diaverse\.ai-factory\PLAN.md` and do not create branches.
- Never run `git checkout`, `git switch`, `git branch`, `git commit`, or `git merge` against the top-level `diaverse` folder for product code.

Multi-repo full plan format:

```markdown
## Workspace Mode
- Mode: multi-repo full
- Workspace root: C:\Users\Indigo\Desktop\diaverse
- Knowledge: local GBrain sources via scripts\gbrain.ps1

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes/no | feature/<slug> | clean/dirty | frontend |
| diaverse-mobile | C:\Users\Indigo\Desktop\diaverse\diaverse-mobile | yes/no | feature/<slug> | clean/dirty | mobile frontend |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes/no | feature/<slug> | clean/dirty | backend |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | yes/no | feature/<slug> | clean/dirty | copywriting service |
| club10000-bot | C:\Users\Indigo\Desktop\diaverse\club10000-bot | yes/no | feature/<slug> | clean/dirty | Club10000 bot |

## Tasks
- [ ] [diaverseapi] Implement backend contract
- [ ] [diaweb] Wire frontend/BFF integration
- [ ] [diaverse-mobile] Wire mobile frontend integration, if affected
- [ ] [aibot] Update internal service behavior, if affected
- [ ] [club10000-bot] Update standalone bot behavior, if affected
- [ ] [cross-repo] Verify the end-to-end flow

## Verification Plan
- diaweb: <lint/test/build commands if applicable>
- diaverse-mobile: <Expo/React Native lint/test/type/release checks if applicable>
- diaverseapi: <pytest/alembic/type/lint commands if applicable>
- aibot: <pytest/lint commands if applicable>
- club10000-bot: <pytest/lint/docker commands if applicable>
- knowledge: run targeted GBrain sync after meaningful code/docs changes

## Commit Plan
- diaweb: <conventional commit suggestion>
- diaverse-mobile: <conventional commit suggestion>
- diaverseapi: <conventional commit suggestion>
- aibot: <conventional commit suggestion>
- club10000-bot: <conventional commit suggestion>
```

Helper commands available from the workspace root:

- `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-status.ps1`
- `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-branch.ps1 -Branch feature/<slug> -Repos diaweb,diaverse-mobile,diaverseapi,club10000-bot -Create`

## PostgreSQL Migration Planning Guard

**Source**: `.ai-factory/patches/2026-04-21-23.31-postgresql-identifier-limit.md`

When a plan includes Alembic migrations for `diaverseapi`, add an explicit verification step for PostgreSQL DDL compilation, not only `alembic heads`. PostgreSQL identifiers are limited to 63 bytes, so planned index/constraint names for long composite objects must be short, explicit, and meaningful. For new revisions, include a check shaped like:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```
