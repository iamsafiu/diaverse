# Autonomous Editorial System Runbook

## Operating Principle

The autonomous editor is promotion-gated. Passing local tests does not authorize deployment, scheduler activation, canary publish, or autopublish.

Default safe state:

```text
draft_only mode
global cycle kill switch enabled or scheduler disabled
publish kill switch enabled
learning activation disabled
syndication disabled
provider credentials absent unless explicitly needed
```

## Promotion Stages

| Stage | Allowed Behavior | Promotion Gate |
| --- | --- | --- |
| 0. Coherent baseline | Pain-first content baseline and draft-only imports. | Existing content tests, health, and docs pass. |
| 1. Ingest-only | Search/manual/product evidence import with no generation. | No prompt-injection, privacy, or credential leakage findings. |
| 2. Evaluator shadow | Mature outcome snapshots and lesson proposals in shadow. | Samples are mature; sparse data remains `insufficient_evidence`. |
| 3. Planner shadow | Rank actions against current/human choices without executing. | Planner decisions are explainable and do not chase immature SEO lag. |
| 4. Autonomous draft-only | Generate or revise drafts only. | Human acceptance rate and safety pass thresholds. |
| 5. Visual candidates | Generate/review visual variants; human still publishes. | Pixel review and mobile/card crop quality are acceptable. |
| 6. Low-risk canary | Trusted publisher may canary approved low-risk content. | Rollback tested; zero unresolved safety/privacy incidents. |
| 7. Low-risk autopublish | Limited `auto_low_risk` only for approved categories. | Explicit owner authorization, budget limits, health, and rollback readiness. |

Health/high-risk content remains manual even after Stage 7.

## Preflight

1. Confirm repository status and branch in every affected child repo.
2. Confirm `.env` points at safe local/test databases before broad test runs.
3. Confirm provider credentials are present only in the runtime that needs them.
4. Confirm no raw search exports, prompts, article bodies, cookies, JWTs, or attribution tokens are staged.
5. Run docs health after changing workspace docs:

```powershell
cd C:\Users\Indigo\Desktop\diaverse
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
```

## Local Verification Commands

### `diaverse-content`

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverse-content
npm run typecheck
npm run lint
npm run prisma:validate
npx tsx --test tests/content-autopilot/cycle.test.ts tests/content-autopilot/revision-pipeline.test.ts tests/content-autopilot/hero-image-review.test.ts tests/content-autopilot/publish.test.ts tests/content-autopilot/editorial-pipeline.test.ts tests/security/content-source-injection.test.ts tests/security/artifact-redaction.test.ts
npx tsx scripts/content-autopilot-backtest.ts --fixture tests/fixtures/content-autopilot/shadow-cycle.json --json
```

### `diaverseapi`

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests/test_content_attribution.py tests/test_content_attribution_auth.py tests/test_alembic_graph.py tests/test_analytics_site.py -q
.\.venv\Scripts\python.exe -m alembic upgrade support_tickets_20260708:content_attr_touch_20260710 --sql
.\.venv\Scripts\python.exe -m alembic downgrade content_attr_touch_20260710:support_tickets_20260708 --sql
```

Do not run real migration upgrades against a non-disposable database from this runbook. Use offline SQL compile or a confirmed disposable database.

### `diaweb`

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm run typecheck
npx eslint modules/content/components/EditorialStudioWorkspace.tsx __tests__/app/api/analytics/content-attribution-route.test.ts __tests__/app/api/staff/content/proxy-utils.test.ts __tests__/app/api/staff/content/auth.test.ts __tests__/proxy.test.ts __tests__/modules/content/EditorialStudioWorkspace.test.tsx __tests__/modules/content/EditorialStudioPolling.test.ts
npx vitest run __tests__/app/api/analytics/content-attribution-route.test.ts __tests__/app/api/staff/content/proxy-utils.test.ts __tests__/app/api/staff/content/auth.test.ts __tests__/proxy.test.ts __tests__/modules/cabinet/routeAccess.test.ts __tests__/modules/auth/loginCompletion.test.ts __tests__/modules/content/EditorialStudioWorkspace.test.tsx __tests__/modules/content/EditorialStudioPolling.test.ts
```

If full `npm run lint` fails on unrelated legacy modules, record the exact path and rule separately; do not fold unrelated repairs into an autonomous-editor rollout.

## Runtime Flags

Keep flags disabled until a stage explicitly permits them:

| Flag Category | Safe Default | Incident Action |
| --- | --- | --- |
| Search sync/import | disabled or dry-run | Disable provider sync; keep manual CSV fallback. |
| Product outcomes | unavailable | Stop signed aggregate reads; UI must show `unavailable`. |
| Learning activation | disabled/shadow | Roll back to previous active policy version. |
| Generation | disabled | Stop new drafts; preserve existing run artifacts for audit. |
| Revision pipeline | disabled | Prevent candidate revisions from being created. |
| Visual generation | disabled | Stop image jobs; keep selected/manual fallback images. |
| Publish/canary | draft-only | Enable publish kill switch. |
| Syndication | disabled | Stop external feed/draft jobs. |
| Global cycle | disabled | Stop scheduler/systemd timer. |

## Provider Credentials

Provider credentials must live only in the trusted runtime:

- Search providers: sync job runtime only.
- Product attribution signing secret: server-to-server content runtime only.
- Image/LLM providers: worker runtime only.
- Internal JWT secret: `diaweb` BFF and `diaverse-content` validator only.

Never place provider secrets in public `NEXT_PUBLIC_*`, browser bundles, committed fixtures, screenshots, logs, or Daily Work public digest.

## Codex Runtime Boundary

Automated Codex subprocesses must not inherit the full application environment.
Only OS process essentials, isolated Codex home paths, `NODE_ENV`, and `NO_COLOR`
may be forwarded. Database URLs, S3 credentials, search/provider secrets,
attribution signing secrets, publish credentials, cookies, JWTs, and raw exports
must stay outside the model process.

Text/editorial stages run in a read-only sandbox rooted at the private stage
artifact directory. Image generation may use `workspace-write` only inside that
same private artifact directory to save the bitmap. Production must not run
Codex with `--dangerously-bypass-approvals-and-sandbox`.

## Incident Response

1. Trigger the narrowest kill switch first; if uncertain, use the global cycle kill switch.
2. Stop scheduler/timer for repeated failures.
3. Preserve run manifests, hashes, audit ids, and safe summaries.
4. Do not publish raw prompts, source bodies, cookies, JWTs, attribution tokens, IPs, or credential values in incident notes.
5. If a guide was published or canaried incorrectly, use Studio rollback or remove the `/ru/learn/*` edge route as appropriate.
6. Mark product attribution as `unavailable` rather than zero if the backend aggregate contract fails.
7. Re-enable only after targeted tests and health pass on the exact revision.

## Rollback

Rollback order:

1. Disable publish/canary and global cycle flags.
2. Revert active content policy to the previous policy version.
3. Revert affected guide to a known base revision.
4. Disable visual/generated assets only if the selected asset itself is unsafe.
5. If runtime is unhealthy, disable `/ru/learn/*` and `/_diaverse-content/_next/*` edge routes without touching `diaweb`, `diaverseapi`, mobile, club, auth, or payments.

## Owner Checklist Before Any Promotion

- Evidence states are not collapsed into zeros.
- Privacy suppression threshold is active and tested.
- RBAC matrix is live through `diaverseapi`, not hardcoded browser roles.
- BFF does not forward browser cookies to `diaverse-content`.
- Approval, canary, and rollback mutations require explicit operator action and reason code.
- Visual review is independent from generation.
- Hard-policy gates are code-owned and immutable by learning proposals.
- `diaverse-ai-cofounder` is not in the content publish path.
