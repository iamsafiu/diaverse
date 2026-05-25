# Graph-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, and impact questions, first consult `C:\Users\Indigo\Desktop\diaverse\graphify-out\GRAPH_REPORT.md`.
- If Graphify MCP is available, query the graph before broad raw-file search.
- Use raw-file reads after that for verification, exact edits, and line-accurate confirmation.
- If graph output conflicts with source code, trust source code and note that the graph should be refreshed.

## Diaverse Multi-Repo Fix Mode

When `$aif-fix` is invoked from `C:\Users\Indigo\Desktop\diaverse`, diagnose and fix from the workspace root.

Rules:

- Use Graphify first to identify likely affected repositories.
- Verify the exact bug path in source files before editing.
- The fix may touch `diaweb`, `diaverseapi`, and `aibot` in one pass when the bug crosses repo boundaries.
- Read the owning repository `AGENTS.md` before editing files there.
- Keep git operations per child repository and never against the top-level workspace.
- If the fix requires a plan, store the fix plan under top-level `diaverse\.ai-factory\FIX_PLAN.md`.
- After code changes, refresh Graphify with the shared update script unless the user asks to skip it.
