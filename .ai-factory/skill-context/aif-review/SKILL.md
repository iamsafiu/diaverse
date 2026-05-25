# Graph-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, and impact questions, first consult `C:\Users\Indigo\Desktop\diaverse\graphify-out\GRAPH_REPORT.md`.
- If Graphify MCP is available, query the graph before broad raw-file search.
- Use source files for final evidence, line references, and correctness judgments.
- If graph output conflicts with source code, trust source code and note that the graph should be refreshed.

## Diaverse Multi-Repo Review Mode

When `$aif-review` is invoked from `C:\Users\Indigo\Desktop\diaverse`, review child repository changes as one coordinated workspace change set.

Rules:

- Do not review the top-level workspace as if it were one git repository.
- Inspect `git -C diaweb status --short`, `git -C diaverseapi status --short`, and `git -C aibot status --short`.
- Group findings by repository.
- Use Graphify to understand cross-repo impact, then cite exact source files and lines for findings.
- Prioritize behavioral regressions, broken contracts between repos, missing verification, security issues, and data-flow mismatches.
- If a frontend change depends on a backend contract, verify both sides before marking it safe.
- If a graph relationship looks stale or missing, trust source code and recommend a graph refresh.
