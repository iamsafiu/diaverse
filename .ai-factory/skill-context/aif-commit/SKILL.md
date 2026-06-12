# Diaverse Multi-Repo Commit Mode

When `$aif-commit` is invoked from `C:\Users\Indigo\Desktop\diaverse`, commit child repositories independently.

Rules:

- Never stage or commit the top-level `diaverse` folder.
- Inspect `git -C <repo> status --short` for `diaweb`, `diaverse-mobile`, `diaverseapi`, `aibot`, `club10000-bot`, and `diaverse-auth-bot`.
- Only commit repositories that contain changes from the current top-level AIF plan.
- Use separate conventional commits per child repository.
- Scope commit messages by repository or domain, for example `feat(cabinet): ...` in `diaverseapi` and `feat(copywriting): ...` in `diaweb`.
- Do not stage unrelated user changes. If a repository has mixed unrelated changes, pause and ask before staging.
- After successful commits, report branch and commit hash per repository.
- If the user asks for one logical commit across the workspace, explain that the workspace uses separate git repositories and produce one coordinated commit per affected repository.
