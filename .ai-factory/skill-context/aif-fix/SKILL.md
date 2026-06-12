# GBrain-First Workspace Rule

- For architecture, cross-repo, dependency, ownership, docs, and impact questions, use local GBrain first when it is available.
- Preferred lookup pattern: GBrain `list` or `search` -> GBrain `get` canonical page -> raw-file/source verification.
- Do not use GBrain `query` as the only source for final answers; treat it as optional broad discovery.
- Use raw-file reads after GBrain for verification, exact edits, and line-accurate confirmation.
- If GBrain output conflicts with source code, trust source code and plan a targeted GBrain sync.

## Diaverse Multi-Repo Fix Mode

When `$aif-fix` is invoked from `C:\Users\Indigo\Desktop\diaverse`, diagnose and fix from the workspace root.

Rules:

- Use GBrain first to identify likely affected repositories.
- Verify the exact bug path in source files before editing.
- The fix may touch `diaweb`, `diaverse-mobile`, `diaverseapi`, `aibot`, `club10000-bot`, and `diaverse-auth-bot` in one pass when the bug crosses repo boundaries.
- Read the owning repository `AGENTS.md` before editing files there.
- Keep git operations per child repository and never against the top-level workspace for product code.
- If the fix requires a plan, store the fix plan under top-level `diaverse\.ai-factory\FIX_PLAN.md`.
- After meaningful code or docs changes, run targeted GBrain sync or `scripts\gbrain-sync.ps1`.
