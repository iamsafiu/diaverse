# Diaverse Multi-Repo Verification Mode

When `$aif-verify` is invoked from `C:\Users\Indigo\Desktop\diaverse`, verify the active top-level plan across all affected child repositories.

Rules:

- Use the top-level plan in `diaverse\.ai-factory\PLAN.md` or `diaverse\.ai-factory\plans\*.md`.
- Read the plan's repository matrix or infer affected repositories from completed tasks.
- Check git status separately for `diaweb`, `diaverseapi`, and `aibot`; never check or commit at the top-level workspace as if it were a git repository.
- Verify implementation against source files in each affected repository.
- Run only verification commands that are appropriate for the affected repositories and available in their project files.
- Use Graphify to trace cross-repo dependencies, then verify with raw source.
- If verification discovers graph drift, rerun `C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`.
- Report results grouped by repository and include any remaining cross-repo risks.

## PostgreSQL Migration Verification Guard

**Source**: `.ai-factory/patches/2026-04-21-23.31-postgresql-identifier-limit.md`

When verifying `diaverseapi` changes that add or modify Alembic migrations, inspect explicit index/constraint names for PostgreSQL's 63-byte identifier limit and compile the migration DDL offline. `alembic heads` is not enough because it checks revision graph shape but does not compile `op.create_index(...)` statements. For a new revision, run:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

If the migration creates database objects with names near the limit, report the exact identifier lengths and require shorter names before handoff.
