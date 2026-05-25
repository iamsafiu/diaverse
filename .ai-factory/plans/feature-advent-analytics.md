# Implementation Plan: Advent Calendar Analytics Tab

Branch: feature/advent-analytics
Created: 2026-04-21

## Settings
- Testing: yes
- Logging: verbose
- Docs: yes

## Workspace Mode
- Mode: multi-repo full
- Workspace root: C:\Users\Indigo\Desktop\diaverse
- Shared graph: C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes | feature/advent-analytics | clean | frontend analytics UI, hooks, Recharts visuals |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes | feature/advent-analytics | clean | analytics API, aggregation use case, tests |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | no | dev | clean | not affected |

## Roadmap Linkage
Milestone: "none"
Rationale: No workspace roadmap file is present, so this plan is not linked to a milestone.

## Research Context
Source: current planning conversation and verified source reads.

Goal:
Add a new `Адвент` tab to staff analytics showing behavioral analytics for Advent calendars: completion conversion, day-by-day progression, paid-cell friction without revenue metrics, repeated runs, and drop-off insights.

Constraints:
- Exclude revenue, ARPU, and ARPPU. Those belong to a separate future revenue module.
- Use `recharts` for charts because `diaweb/frontend/modules/analytics` already uses it.
- Keep the first release aggregate-based using existing Advent tables where possible.
- Do not add git operations at the top-level `diaverse` workspace.
- Keep the top-level plan as the progress source of truth.

Decisions:
- Add the UI as a tab inside `diaweb/frontend/modules/analytics/components/AnalyticsDashboard.tsx`.
- Add backend aggregation under `diaverseapi/app/analytics`, reusing existing `/v1/analytics` router.
- Treat `CabAdventProgress.completed_runs > 0` as the durable completion signal because `is_completed` is reset when a new run starts.
- Use cohort semantics for conversion: default cohort is actors who started by claiming/pending day 1 within the selected period, with progression measured from their available claims/unlocks as of request time.
- Count paid-cell behavior as behavioral conversion only: reached paid day, checkout started, payment/unlock succeeded, paid day claimed.
- Return explicit empty-state payloads for no calendars, missing selected calendar, and no participants instead of leaving the frontend to infer from partial objects.
- Include a backend performance/index review before implementation is considered complete.

Open questions:
- Whether guest actors and authenticated users should be merged after import in historical analytics. MVP should expose combined totals and keep actor-kind splits where identity cannot be safely merged.

## Scope
In scope:
- Analytics tab navigation: `Общая` and `Адвент`.
- Calendar selector, date range selector, loading/error/empty states.
- KPI cards: started, completed, completion rate, average reached day, active/current participants, repeated runs.
- Recharts visuals: funnel, day progression, repeated runs.
- CSS-grid heatmap for compact 1..N calendar-day overview.
- Paid-cell behavioral table without revenue.
- Backend schemas, route, use case, dependencies, and tests.

Out of scope:
- Revenue by day/currency/provider/cell.
- ARPU/ARPPU.
- Provider financial reconciliation.
- New event-tracking pipeline for page views. Calendar view analytics can be added later as an instrumentation feature.

## Metric Semantics
- Period semantics: `date_from` / `date_to` define the starter cohort window. Progression after the starter event is measured as of request time, not clipped to the period.
- Calendar selection: if `line_id` is supplied, use that calendar. If it is missing or does not exist, return `empty_state.kind = "calendar_not_found"`. If omitted, select the active published calendar first, then the latest available calendar as fallback.
- Actor identity:
  - Authenticated actor key: `user:<uuid>`.
  - Guest actor key: `guest:<guest_session_id>`.
  - Imported guest entitlements with `imported_user_id` should normalize to `user:<imported_user_id>` when this can be done without double counting.
- Started participant: unique actor that claimed or created a pending/imported entitlement for day 1 of the selected calendar in the cohort window.
- Day claimed: unique actor with an authenticated claim or guest pending/imported entitlement for that day.
- Reached paid day: unique actor that reached the paid-day gate, normally by claiming the previous day in the same run; for day 1 paid calendars, day 1 starters count as reached.
- Checkout started: unique actor with an authenticated payment session or guest external order/pending entitlement for the paid day.
- Paid day unlocked: unique actor with `CabAdventPaidUnlock` or a paid/imported guest order for that day.
- Paid day claimed: unique actor with a claim/imported entitlement for the paid day after unlock.
- Completed participant: unique actor with `CabAdventProgress.completed_runs > 0`, or a completed max-day claim/imported entitlement when progress rows are not available.
- `active_now`: actor currently in an unfinished run for the selected calendar. For authenticated users, this means a progress row with `last_claimed_day > 0` and `last_claimed_day < max_day` in the current run; guest actors can be counted only when pending entitlements show a non-final day.
- Repeat runs: distribution by completed run number and current `run_number`, using authenticated progress as the source of truth.
- Rates: percentages are `numerator / started_participants * 100`, rounded to one decimal, unless a row explicitly uses previous-day denominator for drop-off.

## Data Contract Draft
- Endpoint: `GET /v1/analytics/advent`
- Query:
  - `date_from`: YYYY-MM-DD
  - `date_to`: YYYY-MM-DD
  - `line_id`: optional UUID
- Response sections:
  - `empty_state`: optional `{ kind, message }` for no calendars, missing selected calendar, or no cohort
  - `calendar_options`: available Advent calendars for the selector
  - `selected_calendar`: chosen calendar metadata
  - `summary`: participants, completed, completion_rate, average_reached_day, active_now, completed_runs_total
  - `funnel`: ordered steps such as day 1, day 7, paid gates, final
  - `days`: per-day claims, claim_rate, dropoff_from_previous, access_type, checkout_started, unlocks, paid_claims
  - `paid_cells`: paid-day behavioral conversion rows
  - `repeat_runs`: run_number distribution
  - `insights`: strongest drop-offs and notable paid-cell friction

## Commit Plan
- **Commit 1** (after tasks 1-7): `feat: add advent analytics backend aggregates`
- **Commit 2** (after tasks 8-13): `feat: add advent analytics staff dashboard`
- **Commit 3** (after tasks 14-15): `test: cover advent analytics dashboard and API`
- **Commit 4** (after tasks 16-18): `docs: document advent analytics behavior`

## Tasks

### Phase 1: Backend Contract And Aggregation
- [x] Task 1: Define Advent analytics response schemas and empty-state contract in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\schemas.py`.
  - Deliverables:
    - Add Pydantic models for `empty_state`, calendar options, selected calendar, summary KPIs, funnel steps, per-day progression, paid-cell behavior, repeat runs, and insights.
    - Use precise field names that frontend can consume without transformation gymnastics.
    - Represent rates as percentages rounded to one decimal, and counts as integers.
    - Ensure no revenue, amount, currency, ARPU, or ARPPU fields are added.
    - Encode the metric semantics from this plan in OpenAPI descriptions where useful.
  - Logging requirements:
    - No runtime logs required in pure schema definitions.
    - Add clear schema descriptions for OpenAPI where useful so API debugging is easier.
  - Dependencies:
    - None.

- [x] Task 2: Implement Advent calendar selection and empty responses in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`.
  - Deliverables:
    - Resolve calendar options and selected calendar.
    - Default to the active published Advent line when `line_id` is omitted; fall back to latest available line.
    - Return `empty_state.kind = "no_calendars"` when no calendars exist.
    - Return `empty_state.kind = "calendar_not_found"` when a supplied `line_id` is missing.
    - Include enough selected-calendar metadata for the frontend selector and labels.
  - Logging requirements:
    - DEBUG at entry with date range, line_id, and calendar selection mode.
    - DEBUG after calendar option query with option count, not full rows.
    - INFO when a selected calendar is resolved.
    - WARNING if selected line is missing or there are no calendars.
    - ERROR with context if an aggregate query fails.
  - Dependencies:
    - Task 1.

- [x] Task 3: Implement cohort identity and day-progression aggregates in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`.
  - Deliverables:
    - Build started cohort from authenticated day 1 claims and guest day 1 pending/imported entitlements in the requested date range.
    - Normalize actor keys using the rules in `## Metric Semantics`, including imported guest entitlements where safe.
    - Compute summary KPIs: started participants, completed participants, completion rate, average reached day, active_now, completed_runs_total.
    - Compute per-day claim counts, claim rates, and drop-off from previous day.
    - Return `empty_state.kind = "no_participants"` with valid calendar metadata when the selected calendar has no cohort.
  - Logging requirements:
    - DEBUG with aggregate input params and selected line id.
    - DEBUG with row counts for authenticated claims, guest entitlements, and progress rows.
    - INFO with participant count, completed count, completion rate, and max day.
    - WARNING when no day 1 cohort exists for a selected calendar.
    - ERROR with query context on aggregate failure.
  - Dependencies:
    - Task 2.

- [x] Task 4: Implement paid-cell behavior, repeat-run distribution, and insights in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`.
  - Deliverables:
    - Query `CabAdventItem`, `CabAdventPaidUnlock`, `CabAdventPaymentSession`, `CabGuestPendingEntitlement`, and `CabGuestExternalOrder` for paid-cell behavior.
    - Compute paid-cell rows: reached, checkout_started, unlocked, claimed, and their behavioral conversion rates.
    - Compute repeat-run distribution from `CabAdventProgress`.
    - Generate simple insights: strongest day drop-offs and paid-cell friction points.
    - Ensure no revenue, provider amount, currency totals, ARPU, or ARPPU values are returned.
  - Logging requirements:
    - DEBUG with paid-cell count and payment session row counts.
    - DEBUG with repeat-run row counts.
    - INFO with paid-cell summary counts and insight count.
    - WARNING when paid-cell data references a day not present in the selected calendar.
    - ERROR with context on aggregate failure.
  - Dependencies:
    - Task 3.

- [x] Task 5: Wire the backend dependency and route in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\dependencies.py` and `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\api.py`.
  - Deliverables:
    - Add provider for `GetAdventAnalyticsUseCase`.
    - Add `GET /v1/analytics/advent` protected by existing `superadmin` role guard.
    - Validate `date_from <= date_to`.
    - Set default period to the last 30 days, matching the current analytics dashboard rhythm.
    - Return the explicit empty-state responses defined in Task 1.
  - Logging requirements:
    - DEBUG route entry with query params and requesting user id.
    - WARNING for invalid date ranges before returning 422/400.
    - INFO route success with selected calendar id/code and response section counts.
  - Dependencies:
    - Tasks 1-4.

- [x] Task 6: Review Advent analytics query performance and add indexes if needed.
  - Deliverables:
    - Inspect expected aggregate filters over `cab_advent_claimed`, `cab_advent_progress`, `cab_advent_paid_unlocks`, `cab_advent_payment_sessions`, `cab_guest_pending_entitlements`, and `cab_guest_external_orders`.
    - Use existing indexes where adequate.
    - If queries need new support, add an Alembic migration under `C:\Users\Indigo\Desktop\diaverse\diaverseapi\migrations\versions\` with targeted indexes, for example:
      - `cab_advent_claimed(line_id, day_number, claimed_at)`
      - `cab_advent_progress(line_id, completed_runs, run_number, last_claimed_day)`
      - `cab_advent_paid_unlocks(line_id, run_number, day_number, created_at)`
      - `cab_advent_payment_sessions(line_id, day_number, run_number, status, created_at)`
      - `cab_guest_pending_entitlements(advent_line_id, advent_day_number, advent_run_number, entitlement_type, status, created_at)`
    - If no migration is needed, document why in the implementation summary.
  - Logging requirements:
    - No runtime logs required for migration-only changes.
    - If use case code adds defensive slow-path logging, use DEBUG and avoid raw user IDs.
  - Dependencies:
    - Tasks 3-4.

- [x] Task 7: Add backend tests in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\tests\test_analytics_advent.py`.
  - Deliverables:
    - Cover no calendars, selected calendar not found, and no cohort empty-state responses.
    - Cover started/completed/completion-rate calculation.
    - Cover actor de-duplication for imported guest entitlements where practical.
    - Cover paid-cell behavior without revenue fields.
    - Cover repeated run distribution.
    - Cover route authorization and date validation if practical with existing test patterns.
    - Cover performance/index migration smoke checks if a migration is added.
  - Logging requirements:
    - Tests should assert behavior, not log output.
    - Keep test fixtures readable and include comments only for non-obvious cohort setup.
  - Dependencies:
    - Tasks 1-6.

### Phase 2: Frontend Data Layer
- [x] Task 8: Extend analytics types/API/hooks in `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\types.ts`, `api.ts`, and `hooks.ts`.
  - Deliverables:
    - Add TypeScript interfaces matching the backend response.
    - Add `fetchAdventAnalytics(dateFrom, dateTo, lineId?)`.
    - Add `useAdventAnalytics(dateFrom, dateTo, lineId?)` with a stable React Query key.
    - Type `empty_state` explicitly and handle nullable `selected_calendar`.
    - Ensure the API layer does not expose revenue-shaped fields.
  - Logging requirements:
    - Keep production frontend quiet.
    - Use existing dev-only console style only if a malformed payload needs a warning.
    - Errors should flow through React Query and UI error states.
  - Dependencies:
    - Task 5 API contract.

- [x] Task 9: Add Advent analytics formatting helpers in `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\adventAnalyticsUtils.ts`.
  - Deliverables:
    - Add helpers for percentage formatting, count formatting, safe array access, paid/free labels, tooltip labels, and empty-state labels.
    - Keep chart/table components presentation-focused and avoid duplicating formatting logic.
    - Include no revenue/ARPU/ARPPU labels.
  - Logging requirements:
    - No runtime logs.
    - Helpers should be deterministic and easy to unit test.
  - Dependencies:
    - Task 8.

- [x] Task 10: Add analytics tab navigation in `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\AnalyticsDashboard.tsx`.
  - Deliverables:
    - Add tabs `Общая` and `Адвент`.
    - Preserve the existing DAU/WAU/MAU and retention UI under `Общая`.
    - Mount the Advent panel only when selected, or keep query disabled until selected.
    - Maintain responsive staff dashboard layout and existing design variables.
  - Logging requirements:
    - No runtime logs for tab switching.
    - Keep state local and deterministic so UI tests can assert selected tab behavior.
  - Dependencies:
    - Tasks 8-9.

### Phase 3: Frontend Visual Components
- [x] Task 11: Build `AdventAnalyticsPanel` and KPI components under `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\`.
  - Deliverables:
    - Create `AdventAnalyticsPanel.tsx`.
    - Add calendar selector, date range picker reuse, loading/error/empty states.
    - Add KPI cards for started, completed, completion rate, average reached day, active participants, completed runs.
    - Render explicit empty-state messages for `no_calendars`, `calendar_not_found`, and `no_participants`.
    - Make the layout dense and staff-tool-like, not a landing-page layout.
  - Logging requirements:
    - No normal UI logs.
    - Use query error details only in user-facing error text, not console noise.
  - Dependencies:
    - Tasks 8-10.

- [x] Task 12: Build Recharts visuals and calendar heatmap in new analytics components.
  - Deliverables:
    - `AdventFunnelChart.tsx`: horizontal `BarChart` for key progression steps.
    - `AdventDayProgressChart.tsx`: `BarChart` or `ComposedChart` for day-by-day claim rate, with paid days visually distinct.
    - `AdventRunRepeatsChart.tsx`: compact `BarChart` for run_number distribution.
    - `AdventDayHeatmap.tsx`: CSS grid for days 1..N, with paid/free state, claim rate, and drop-off tooltip/title text.
    - `AdventPaidCellsTable.tsx`: reached, checkout started, unlocked, claimed; no revenue columns.
    - `AdventDropoffInsights.tsx`: compact list of strongest drop-offs and paid-cell friction.
  - Logging requirements:
    - No runtime logs.
    - Components should handle missing/empty arrays gracefully and expose visible empty states.
  - Dependencies:
    - Tasks 9-11.

- [x] Task 13: Integrate the Advent panel into the dashboard and refine responsive behavior.
  - Deliverables:
    - Ensure the tab works on desktop and mobile widths.
    - Prevent text overflow in cards, selectors, chart labels, and table cells.
    - Keep chart containers with stable heights so Recharts does not collapse.
    - Use existing staff card/border/text CSS variables and current Recharts tooltip styling conventions.
  - Logging requirements:
    - No normal UI logs.
    - Add temporary dev-only diagnostics only if needed during implementation, then remove before completion.
  - Dependencies:
    - Tasks 10-12.

### Phase 4: Frontend Tests
- [x] Task 14: Add hook/API and formatting utility tests in `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\__tests__\modules\analytics\`.
  - Deliverables:
    - Cover `useAdventAnalytics` query key and URL params.
    - Cover optional `line_id`.
    - Cover `empty_state` typing/handling where practical.
    - Cover `adventAnalyticsUtils.ts` formatting helpers.
    - Keep existing DAU/retention tests passing.
  - Logging requirements:
    - Tests should mock `apiClient.get` and assert calls.
    - No console output expected.
  - Dependencies:
    - Tasks 8-9.

- [x] Task 15: Add component tests under `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\__tests__\modules\analytics\`.
  - Deliverables:
    - Test `AdventAnalyticsPanel` loading, empty, error, and populated states.
    - Test dashboard tab switching.
    - Mock Recharts `ResponsiveContainer` like existing chart tests.
    - Assert paid-cell table does not render revenue/ARPU/ARPPU labels.
    - Assert long calendar titles and empty arrays do not break the visible layout contract.
  - Logging requirements:
    - Silence expected query errors in tests where needed via mocks.
    - Do not assert implementation details of chart internals beyond stable labels and empty states.
  - Dependencies:
    - Tasks 10-13.

### Phase 5: Documentation And Verification
- [x] Task 16: Add or update documentation for Advent analytics behavior.
  - Deliverables:
    - Document metric definitions: starter, completed user, completion rate, paid-cell behavioral conversion, repeat run.
    - Explicitly state that revenue, ARPU, and ARPPU are excluded and belong to a separate revenue module.
    - Prefer an existing repo docs location in `C:\Users\Indigo\Desktop\diaverse\diaweb` or `C:\Users\Indigo\Desktop\diaverse\diaverseapi` if one clearly covers staff analytics/API behavior.
    - If no product docs location exists, add a concise implementation reference under `C:\Users\Indigo\Desktop\diaverse\.ai-factory\references\advent-analytics.md`.
  - Logging requirements:
    - No runtime logs.
    - Keep docs aligned with OpenAPI field names from Task 1.
  - Dependencies:
    - Tasks 1-15.

- [x] Task 17: Perform visual verification for the Advent analytics tab.
  - Deliverables:
    - Run the frontend locally if needed and inspect `/staff/analytics`.
    - Verify desktop and mobile widths.
    - Check that Recharts containers are non-collapsed and labels/tooltips are readable.
    - Check that heatmap cells, calendar selector, KPI cards, and paid-cell table do not overflow with long calendar names or empty data.
    - Capture screenshots or concise observations in the implementation summary.
  - Logging requirements:
    - No persistent code logs.
    - If temporary debug logging is added for layout diagnosis, remove it before completion.
  - Dependencies:
    - Tasks 11-15.

- [x] Task 18: Run automated verification and refresh workspace graph.
  - Deliverables:
    - Run backend tests and lint for analytics/advent changes.
    - Run frontend analytics tests, typecheck, and lint.
    - Run `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1` after code/docs changes.
    - Update this plan's task checkboxes during implementation.
  - Logging requirements:
    - Capture command failures with enough context in the final implementation summary.
    - Do not add persistent code logs solely for verification.
  - Dependencies:
    - Tasks 1-17.

## Verification Plan
- diaverseapi:
  - `cd C:\Users\Indigo\Desktop\diaverse\diaverseapi`
  - `poetry run pytest tests/test_analytics_advent.py tests/test_cabinet_advent.py tests/test_cabinet_advent_payments.py`
  - `poetry run ruff check app/analytics tests/test_analytics_advent.py`
  - If Task 6 adds an Alembic migration, run `poetry run alembic heads` and verify the new revision chain is sane.
- diaweb:
  - `cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend`
  - `npm test -- __tests__/modules/analytics`
  - `npm run typecheck`
  - `npm run lint`
- visual:
  - Run the frontend locally and inspect the Advent tab at desktop and mobile widths before final handoff.
- workspace graph:
  - `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`

## Implementation Notes
- Existing analytics files:
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\AnalyticsDashboard.tsx`
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\api.ts`
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\hooks.ts`
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\types.ts`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\api.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\dependencies.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\schemas.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`
- Existing Advent data sources:
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\offers\advent\models.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\guest\models.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\logging\models.py`
- Recharts is already available in `diaweb/frontend/package.json`.
