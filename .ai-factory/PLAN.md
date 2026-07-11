# Implementation Plan: Separate Game, Site, and Overview Analytics

Branch: none (fast mode)
Created: 2026-07-11

## Settings
- Testing: yes
- Logging: standard
- Docs: yes
- Mobile repository: no edits

## Roadmap Linkage
Milestone: "none"
Rationale: No `.ai-factory/ROADMAP.md` file was found; this is a focused staff analytics clarification.

## Workspace Mode
- Mode: fast multi-repo plan
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain was attempted first; exact behavior was verified from source files.
- Affected product repos: `diaweb`
- Affected workspace docs: `docs/research/dau-wau-mau-growth-analysis-2026-07.md`
- Explicitly excluded: `diaverse-mobile`
- Backend default: no backend code changes unless implementation proves an existing frontend-safe API field is missing.

## Research Context
Current confusion:
- `Общая` currently sounds like the whole system, but the DAU/WAU/MAU cards are actually game/app activity from `user_activities` and `user_taps`.
- `Сайт` is already a separate tab and is based on `site_daily_visits`; authenticated web visits can stitch to `users.uuid`, but anonymous web visits are visitor hashes, not users.
- `Новые пользователи по источнику` mixes App Store, Google Play, website, mobile unknown, and legacy unknown in one block, which makes people read backend-account creation as real user acquisition.

Decision:
- Keep headline DAU/WAU/MAU under `Игра / приложение`.
- Keep website analytics under `Сайт`.
- Add `Обзор` as an executive summary that compares system signals side by side without summing app and site DAU into one fake total.
- Split account/source cards by context:
  - app/game tab shows App Store, Google Play, Mobile unknown, Legacy unknown, and total app/backend accounts excluding website;
  - site tab shows website-attributed backend accounts near website visitor metrics.

## Repository Matrix
| Repository | Path | Affected | Current status at planning | Role |
| --- | --- | --- | --- | --- |
| diaweb | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `dev`, only untracked `.worktrees/` visible from status | staff analytics UI and frontend tests |
| diaverseapi | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | no by default | `dev`, dirty with unrelated backend/device/support/payment changes | existing analytics API source of truth |
| diaverse-mobile | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | do not touch | future app-open/session instrumentation only |
| workspace root | `C:\Users\Indigo\Desktop\diaverse` | yes | dirty docs research file | plan and analytics research doc |
| aibot | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | unchanged | not involved |
| diaverse-content | `C:\Users\Indigo\Desktop\diaverse\diaverse-content` | no | unchanged | not involved |
| club10000-bot | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | unchanged | not involved |
| diaverse-auth-bot | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | unchanged | not involved |

## Commit Plan
- **Commit 1** (`diaweb`): `feat(analytics): separate game and site metrics`
- **Commit 2** (`diaweb`): `test(analytics): cover metric grouping labels`
- **Commit 3** (root docs): `docs(analytics): clarify app site overview metrics`

## Tasks

### Phase 1: Information Architecture
- [x] Task 1: Rename the current `Общая` tab to `Игра / приложение` and add a new `Обзор` tab.
  - Deliverable: staff analytics has separate top-level tabs for executive summary, game/app activity, and site analytics.
  - Files to change:
    - `diaweb/frontend/modules/analytics/components/AnalyticsDashboard.tsx`
  - Expected behavior:
    - Default tab becomes `Обзор`.
    - Existing DAU/WAU/MAU, lifecycle chart, activity-quality chart, WAU/MAU bridge, and retention move under `Игра / приложение`.
    - Existing `Сайт`, `Адвент`, `Магазин`, and `Crypton` tabs remain available.
    - No app/game metric is labeled as a website metric.
  - Logging requirements:
    - UI-only task; do not add runtime console logging.
  - Dependency notes:
    - Base task for the UI split.

- [x] Task 2: Create an executive `AnalyticsOverviewPanel`.
  - Deliverable: `Обзор` shows a compact cross-system trend summary without adding app and site DAU together.
  - Files to create/change:
    - `diaweb/frontend/modules/analytics/components/AnalyticsOverviewPanel.tsx`
    - `diaweb/frontend/modules/analytics/components/AnalyticsDashboard.tsx`
  - Expected behavior:
    - Fetch existing data through `useDauWauMau`, `useNewUsersBySource`, and `useSiteAnalytics`.
    - Show side-by-side cards:
      - `Игра: Activity DAU`;
      - `Игра: WAU`;
      - `Игра: MAU`;
      - `Новые app/backend аккаунты`;
      - `Mobile unknown`;
      - `Background-only`;
      - `Сайт: посетители`;
      - `Сайт: web DAU`.
    - Add a clear non-summing note in UI copy: overview compares signals and does not produce a fake total DAU.
    - Use existing date range defaults and avoid nested cards.
  - Logging requirements:
    - UI-only task; no runtime logging.
    - Fetch errors should render through existing React Query error states.
  - Dependency notes:
    - Depends on Task 1 tab structure.

### Phase 2: Game/App Tab
- [x] Task 3: Relabel game/app DAU copy so headline metrics are explicitly app/core activity.
  - Deliverable: the game tab no longer reads as "whole system DAU".
  - Files to change:
    - `diaweb/frontend/modules/analytics/components/DauWauMauCards.tsx`
    - `diaweb/frontend/modules/analytics/components/DauChart.tsx`
    - `diaweb/frontend/modules/analytics/components/WauMauBridgePanel.tsx`
    - `diaweb/frontend/modules/analytics/components/AnalyticsDashboard.tsx`
  - Expected behavior:
    - Section title becomes `Игра / приложение: activity DAU / WAU / MAU`.
    - Cards clarify that values are based on game activity signals, not website visits.
    - Chart labels/tooltips are Russian and include color meaning where needed.
    - `background-only` remains visible as a quality warning, not hidden.
  - Logging requirements:
    - UI-only task; no runtime logging.
  - Dependency notes:
    - Depends on Task 1.

- [x] Task 4: Parameterize `NewUsersSourcePanel` and place app-account source cards inside the game tab.
  - Deliverable: game tab shows new app/backend accounts without the website source card in the same block.
  - Files to change:
    - `diaweb/frontend/modules/analytics/components/NewUsersSourcePanel.tsx`
    - `diaweb/frontend/modules/analytics/components/AnalyticsDashboard.tsx`
  - Expected behavior:
    - Add a presentation mode such as `variant="app"` / `variant="site"` / `variant="all"` or equivalent.
    - In app mode, show:
      - total app/backend accounts = App Store + Google Play + Mobile unknown + Legacy unknown;
      - App Store;
      - Google Play;
      - Mobile unknown;
      - Legacy unknown.
    - In app mode, do not show website as part of app account growth.
    - Labels say `backend-аккаунты`, not plain `новые пользователи`.
  - Logging requirements:
    - UI-only task; no runtime logging.
  - Dependency notes:
    - Depends on Task 3.

### Phase 3: Site Tab
- [x] Task 5: Move website-attributed backend account cards into the site tab.
  - Deliverable: site tab explains both website visitors and website-attributed account creation in one place.
  - Files to change:
    - `diaweb/frontend/modules/analytics/components/SiteAnalyticsPanel.tsx`
    - `diaweb/frontend/modules/analytics/components/NewUsersSourcePanel.tsx`
  - Expected behavior:
    - Site tab keeps existing website visitor DAU/WAU/MAU cards.
    - Add a compact website account block using existing `new-users/sources` data in `variant="site"`.
    - Site tab labels distinguish:
      - `Web visitors` / `посетители сайта`;
      - `Website-attributed backend accounts` / `backend-аккаунты с web evidence`.
    - Do not call anonymous visitors "users".
  - Logging requirements:
    - UI-only task; no runtime logging.
  - Dependency notes:
    - Depends on Task 4.

- [x] Task 6: Tighten site metric labels and selected-period wording.
  - Deliverable: site cards no longer imply they are the same as app DAU.
  - Files to change:
    - `diaweb/frontend/modules/analytics/components/SiteAnalyticsPanel.tsx`
    - `diaweb/frontend/modules/analytics/components/SiteDauChart.tsx`
  - Expected behavior:
    - Use labels such as `Web DAU`, `Web WAU`, `Web MAU`, `Уникальные посетители за период`.
    - Copy explains that site metrics are `site_daily_visits` visitor/user hashes.
    - Keep website tab separate from core game/app DAU.
  - Logging requirements:
    - UI-only task; no runtime logging.
  - Dependency notes:
    - Depends on Task 5.

### Phase 4: Tests And Docs
- [x] Task 7: Add frontend tests for the new tab split and source placement.
  - Deliverable: tests prevent regression back into mixed "Общая" semantics.
  - Files to change/create:
    - `diaweb/frontend/__tests__/modules/analytics/AnalyticsDashboard.test.tsx`
    - `diaweb/frontend/__tests__/modules/analytics/NewUsersSourcePanel.test.tsx`
    - `diaweb/frontend/__tests__/modules/analytics/SiteAnalyticsPanel.test.tsx`
  - Expected behavior:
    - Assert default `Обзор` tab renders executive summary labels.
    - Assert `Игра / приложение` tab renders app activity metrics and app-account source labels.
    - Assert app mode does not present website as part of app-account total.
    - Assert `Сайт` tab renders website visitor labels and website-attributed backend account labels.
  - Logging requirements:
    - Tests should not assert console logs.
    - Mock data must not include real user identifiers.
  - Dependency notes:
    - Depends on Tasks 1-6.

- [x] Task 8: Update analytics research documentation with the final tab model.
  - Deliverable: the research doc tells operators where each metric belongs.
  - Files to change:
    - `docs/research/dau-wau-mau-growth-analysis-2026-07.md`
  - Expected behavior:
    - Add a section that defines:
      - `Обзор` = executive comparison, no fake total DAU;
      - `Игра / приложение` = headline app/core activity metrics;
      - `Сайт` = website visitors and website-attributed accounts;
      - app/backend accounts are not automatically confirmed real users.
    - Preserve existing production analysis numbers and caveats.
    - Do not include SSH commands, server IPs, raw production SQL, tokens, or PII.
  - Logging requirements:
    - Docs-only task; no runtime logging.
  - Dependency notes:
    - Depends on final UI naming from Tasks 1-6.

- [x] Task 9: Run targeted verification.
  - Deliverable: changed UI and docs are checked before handoff.
  - Files/commands:
    - `cd diaweb/frontend && npm run test -- __tests__/modules/analytics/AnalyticsDashboard.test.tsx __tests__/modules/analytics/NewUsersSourcePanel.test.tsx __tests__/modules/analytics/SiteAnalyticsPanel.test.tsx`
    - `cd diaweb/frontend && npm run typecheck`
    - `cd diaweb/frontend && npm run lint`
    - `git diff --check -- docs/research/dau-wau-mau-growth-analysis-2026-07.md`
  - Expected behavior:
    - Targeted tests pass or any environment blocker is reported clearly.
    - Typecheck/lint pass or unrelated existing failures are separated from this change.
  - Logging requirements:
    - Verification task only; no app logging changes.
  - Dependency notes:
    - Depends on Tasks 1-8.

## Verification Plan
- `diaweb/frontend`:
  - `npm run test -- __tests__/modules/analytics/AnalyticsDashboard.test.tsx __tests__/modules/analytics/NewUsersSourcePanel.test.tsx __tests__/modules/analytics/SiteAnalyticsPanel.test.tsx`
  - `npm run typecheck`
  - `npm run lint`
- Workspace docs:
  - `git diff --check -- docs/research/dau-wau-mau-growth-analysis-2026-07.md`
  - Run targeted GBrain sync for `diaverse-docs` after docs changes if implementation completes successfully.

## Rollout Notes
- This plan intentionally avoids mobile changes.
- This plan intentionally avoids backend changes unless implementation discovers a hard API gap.
- Main product DAU should be read from `Игра / приложение`.
- Website metrics should be read from `Сайт`.
- `Обзор` should be used for system-level explanation, not as a new mathematical total.
