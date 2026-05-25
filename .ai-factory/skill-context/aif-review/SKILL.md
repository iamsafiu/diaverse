# GBrain-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, docs, and impact questions, use local GBrain first when it is available.
- Use source files for final evidence, line references, and correctness judgments.
- If GBrain output conflicts with source code, trust source code and recommend a targeted GBrain sync.

## Diaverse Multi-Repo Review Mode

When `$aif-review` is invoked from `C:\Users\Indigo\Desktop\diaverse`, review child repository changes as one coordinated workspace change set.

Rules:

- Do not review the top-level workspace as if it were one product repository.
- Inspect `git -C diaweb status --short`, `git -C diaverseapi status --short`, `git -C aibot status --short`, and `git -C club10000-bot status --short` when those repos may be affected.
- Group findings by repository.
- Use GBrain to understand cross-repo impact, then cite exact source files and lines for findings.
- Prioritize behavioral regressions, broken contracts between repos, missing verification, security issues, and data-flow mismatches.
- If a frontend change depends on a backend contract, verify both sides before marking it safe.
- If knowledge output looks stale or missing, trust source code and recommend a GBrain sync.
