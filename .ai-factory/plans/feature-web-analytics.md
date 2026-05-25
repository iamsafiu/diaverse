# Implementation Plan: Site Analytics Dashboard

Branch: feature/web-analytics
Created: 2026-04-26

## Settings
- Testing: yes
- Logging: verbose
- Docs: yes

## Workspace Mode
- Mode: multi-repo full
- Workspace root: C:\Users\Indigo\Desktop\diaverse
- Shared graph: C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json
- Plan owner: C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\feature-web-analytics.md

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes | feature/web-analytics | clean | frontend tracker, staff analytics UI |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes | feature/web-analytics | clean | analytics storage, aggregation API, tests |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | no | dev | clean | not affected |

## Goal
Add a new `Сайт` tab to the staff analytics dashboard, next to `Общая` and `Адвент`, showing site DAU/WAU/MAU and breakdowns by:
- opening context: normal browser vs Telegram embedded browser
- device type: desktop vs mobile, with tablet/unknown fallback where classification is uncertain

The feature must not change the existing mobile-app DAU/WAU/MAU semantics, which currently come from `UserTaps` and `UserActivity`.

## Decisions
- Keep website analytics in a new site-specific storage path, not in `user_activities`.
- Use `diaweb` as the only browser-facing instrumentation point.
- Use `diaverseapi` as the source of truth for event normalization, aggregation, staff authorization, and persistence.
- Track user-facing site visits and exclude staff/admin routes from visitor analytics.
- Enforce route exclusion on both sides: frontend should skip internal routes, and backend must return an explicit skipped response for excluded paths.
- Use a stable first-party visitor id for unauthenticated visits and authenticated `user_id` when available.
- Hash visitor identifiers server-side before persistence so raw browser ids are not stored as analytics keys.
- Store both `anonymous_visitor_key_hash` and canonical `visitor_key_hash` so same-day anonymous rows can be stitched to `user:<uuid>` after login from the same browser visitor id.
- Derive `visit_date` on the backend using the backend's canonical analytics date. Client timezone is captured only as metadata/future context and must not decide the aggregate date.
- Store daily deduplicated visit rows rather than raw clickstream by default. This supports DAU/WAU/MAU and keeps storage volume controlled.
- Category breakdowns count unique visitors per category. A visitor who opens both normal browser and Telegram in the same day can appear in both category counts; total DAU remains distinct across all site visits.
- No historical backfill is possible for browser/Telegram/device splits before the new tracker is deployed.
- Avoid new parser dependencies for the first release; use conservative local classifiers and tests instead.

## Refinement Notes
Applied after deeper codebase review:
- Alembic `env.py` imports every SQLModel domain explicitly, so a new `app.analytics.models` module must be added there if model metadata is expected to stay complete.
- The tracker will be mounted under `app\[lang]\layout.tsx`, which also wraps staff routes, so `/[lang]/staff...` exclusion must be tested and duplicated on the backend.
- The beacon should not use `apiClient` because `apiClient` performs auth refresh/redirect behavior; the tracker needs a tiny silent fetch helper with `credentials: "include"`.
- Path storage must strip query strings and hashes to avoid preserving auth/payment tokens or other accidental PII in analytics rows.

## Existing Context
- Current staff analytics tab navigation lives in `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\AnalyticsDashboard.tsx`.
- Current analytics frontend API, hooks, and types live in:
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\api.ts`
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\hooks.ts`
  - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\types.ts`
- Current analytics backend route, schemas, dependencies, and use cases live in:
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\api.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\schemas.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\dependencies.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`
- `diaweb` already sends `X-Telegram-WebApp-Platform` from `window.Telegram.WebApp.platform` in `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\shared\api\client.ts`.
- `diaverseapi` already has optional auth via `get_current_user_optional` in `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\security\dependecies.py`.

## Data Contract Draft
### POST /v1/analytics/site/visit
Purpose: public/optional-auth endpoint used by `diaweb` to record a deduplicated site visit.

Request body:
```json
{
  "visitor_id": "client-generated-uuid",
  "path": "/ru/offers/advent",
  "referrer": "https://example.com",
  "screen_width": 390,
  "screen_height": 844,
  "timezone": "Asia/Yekaterinburg",
  "client_device_type": "mobile",
  "client_open_context": "telegram",
  "telegram_webapp_platform": "ios"
}
```

Response:
```json
{
  "recorded": true,
  "reason": null
}
```

For skipped internal routes the endpoint should return:
```json
{
  "recorded": false,
  "reason": "excluded_path"
}
```

### GET /v1/analytics/site
Purpose: staff-only analytics endpoint protected by existing `analytics:view` access.

Query:
- `date_from`: YYYY-MM-DD, default today - 30 days
- `date_to`: YYYY-MM-DD, default today

Response sections:
- `summary`: `dau_today`, `dau_yesterday`, `wau`, `mau`
- `dau_by_day`: unique site visitors by day
- `open_context`: browser/telegram/unknown counts and rates
- `device_type`: desktop/mobile/tablet/unknown counts and rates
- `context_device_matrix`: compact split by context and device

## Metric Semantics
- Site visitor key: authenticated `user:<uuid>` when optional auth succeeds; otherwise `visitor:<visitor_id>` from first-party storage.
- Site DAU: distinct visitor keys with at least one tracked site visit on the day.
- Site WAU: distinct visitor keys over the last 7 days ending today.
- Site MAU: distinct visitor keys over the last 30 days ending today.
- Browser context: no Telegram WebApp signal in frontend headers/body and no Telegram-like server fallback.
- Telegram context: `window.Telegram.WebApp` or `X-Telegram-WebApp-Platform`/body signal is present.
- Device type: classify independently from opening context using client hints/screen width on the frontend and a conservative server fallback from headers/body.

## Commit Plan
- **Commit 1** (after tasks 1-5): `feat: add site analytics backend aggregates`
- **Commit 2** (after tasks 6-9): `feat: track site visits from diaweb`
- **Commit 3** (after tasks 10-13): `feat: add site analytics staff dashboard`
- **Commit 4** (after tasks 14-16): `test: cover site analytics collection and dashboard`
- **Commit 5** (after tasks 17-18): `docs: document site analytics semantics`

## Tasks

### Phase 1: Backend Storage And Contract
- [x] Task 1: Add site analytics persistence models and migration in `C:\Users\Indigo\Desktop\diaverse\diaverseapi`.
  - Files:
    - Create or extend `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\models.py`.
    - Update `C:\Users\Indigo\Desktop\diaverse\diaverseapi\migrations\env.py` to import the new analytics model module for complete SQLModel metadata.
    - Add Alembic revision under `C:\Users\Indigo\Desktop\diaverse\diaverseapi\migrations\versions\`.
  - Deliverables:
    - Add a daily deduplicated table, for example `site_daily_visits`.
    - Include fields: `uuid`, `visit_date`, `visitor_key_hash`, `anonymous_visitor_key_hash`, `user_id`, `open_context`, `device_type`, `first_seen_at`, `last_seen_at`, `visits_count`, `last_path`, `last_referrer`, `client_timezone`, `created_at`, `updated_at`.
    - Add short explicit index/constraint names that stay under PostgreSQL's 63-byte identifier limit.
    - Add uniqueness for the dedupe grain, for example `(visit_date, visitor_key_hash, open_context, device_type)`.
    - Add indexes for total DAU/WAU/MAU, date range breakdowns, and anonymous-to-authenticated stitching by `anonymous_visitor_key_hash`.
  - Logging requirements:
    - No model-level runtime logging.
    - Migration should be deterministic and avoid noisy print output.
    - Any migration safety notes should be documented in the revision comments.
  - Dependencies:
    - None.

- [x] Task 2: Define backend request and response schemas for site analytics.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\schemas.py`
  - Deliverables:
    - Add `SiteVisitCreate`, `SiteVisitResponse`, `SiteAnalyticsSummary`, `SiteDauByDay`, `SiteAnalyticsBreakdownItem`, `SiteAnalyticsMatrixItem`, and `SiteAnalyticsResponse`.
    - Use strict literals for `open_context`: `browser`, `telegram`, `unknown`.
    - Use strict literals for `device_type`: `desktop`, `mobile`, `tablet`, `unknown`.
    - Validate reasonable path/referrer/screen lengths.
    - Add a nullable `reason` field to `SiteVisitResponse` so skipped internal paths can return `{ recorded: false, reason: "excluded_path" }`.
    - Add a total unique visitor field to the staff response so the UI does not infer totals by summing overlapping categories.
  - Logging requirements:
    - No schema runtime logging.
    - Validation errors rely on FastAPI/Pydantic standard error output.
  - Dependencies:
    - Task 1 can proceed in parallel, but final field names must match the model.

- [x] Task 3: Implement site visit recording use case.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\dependencies.py`
  - Deliverables:
    - Add `RecordSiteVisitUseCase`.
    - Create small private helpers for path sanitization, path exclusion, canonical visit date, visitor hashing, context normalization, and device normalization.
    - Strip query strings and hashes from stored paths/referrers before persistence.
    - Skip internal paths server-side, including localized staff paths such as `/ru/staff/...` and `/en/staff/...`.
    - Normalize `open_context` from body and headers, with Telegram WebApp signal taking precedence over user-agent heuristics.
    - Normalize `device_type` from client signal and conservative fallback.
    - Build `anonymous_visitor_key_hash` from the first-party visitor id and canonical `visitor_key_hash` from authenticated user id when present, otherwise anonymous hash.
    - When an authenticated visit arrives with a known `anonymous_visitor_key_hash`, stitch same-day anonymous rows for that browser visitor to the authenticated canonical hash before or during upsert.
    - Upsert into the daily table and increment `visits_count`, updating `last_seen_at`, `last_path`, and `last_referrer`.
    - Return a stable `{ recorded: true, reason: null }` response for recorded visits and `{ recorded: false, reason: "excluded_path" }` for skipped routes.
  - Logging requirements:
    - DEBUG on entry with path, supplied context/device, auth presence, and sanitized visitor source.
    - INFO when a new daily visitor category row is inserted.
    - DEBUG when an existing daily row is updated.
    - WARNING for invalid/missing visitor identifiers that must fall back to a request-scoped id.
    - INFO when anonymous same-day rows are stitched to an authenticated visitor key.
    - DEBUG when a visit is skipped by server-side path policy.
    - ERROR with full exception context on persistence failure.
    - Never log raw visitor ids, auth tokens, cookies, or full Telegram init data.
  - Dependencies:
    - Tasks 1 and 2.

- [x] Task 4: Implement site analytics aggregation use case.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\dependencies.py`
  - Deliverables:
    - Add `GetSiteAnalyticsUseCase`.
    - Compute `dau_today`, `dau_yesterday`, `wau`, `mau` from distinct `visitor_key_hash`.
    - Compute `dau_by_day` for the requested date range.
    - Compute context and device breakdowns for the requested date range.
    - Compute context/device matrix for compact dashboard visualization.
    - Keep total distinct visitors separate from category sums because category counts can overlap.
    - Use the same backend canonical date rules as visit recording when computing today/yesterday windows.
  - Logging requirements:
    - DEBUG on entry with date range.
    - DEBUG for row counts returned by each aggregate query.
    - INFO on successful response with total rows and period.
    - WARNING for invalid ranges before raising HTTP 400 at the route layer.
    - ERROR with exception context if aggregate queries fail.
  - Dependencies:
    - Tasks 1 and 2.

- [x] Task 5: Wire backend routes and access control.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\api.py`
    - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\dependencies.py`
  - Deliverables:
    - Add `POST /v1/analytics/site/visit` with optional auth and rate limiting appropriate for browser beacons.
    - Add `GET /v1/analytics/site` protected by existing `require_staff_module_access("analytics", "view")`.
    - Validate `date_from <= date_to` for staff queries.
    - Accept `X-Telegram-WebApp-Platform`, `User-Agent`, and other needed headers without requiring them.
    - Include `x_platform` handling so authenticated cabinet cookies can hydrate optional users without making anonymous visits fail.
    - Keep the visit endpoint non-blocking for UX: expected validation/skipped-path responses should be lightweight and deterministic.
  - Logging requirements:
    - DEBUG on visit route entry with sanitized path/context/device and auth presence.
    - INFO on successful staff analytics retrieval.
    - WARNING on invalid date ranges.
    - WARNING on malformed visit payloads only when not already covered by validation.
    - ERROR on unexpected route failure with request context but no secrets.
  - Dependencies:
    - Tasks 2, 3, and 4.

### Phase 2: Frontend Site Visit Tracking
- [x] Task 6: Add frontend visitor identity and classification helpers.
  - Files:
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\site-analytics\visitor.ts`
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\site-analytics\classify.ts`
  - Deliverables:
    - Generate and persist a stable first-party visitor UUID in localStorage.
    - Reuse the local storage defensive style from auth helpers: gracefully handle SSR, disabled storage, and exceptions.
    - Use `crypto.randomUUID()` when available and a clearly marked fallback only when necessary.
    - Classify Telegram embedded browser from `window.Telegram.WebApp`.
    - Classify device type independently from Telegram/browser using `navigator.userAgentData` when available, then screen/media fallback, then user-agent fallback.
    - Keep helper APIs deterministic and unit-testable.
  - Logging requirements:
    - DEBUG only in development for visitor id creation and classification decisions.
    - WARNING only if localStorage is unavailable and a session-only visitor id is used.
    - Never log the raw persisted visitor id in production.
  - Dependencies:
    - Backend contract from Task 2.

- [x] Task 7: Add a low-noise site visit beacon client.
  - Files:
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\site-analytics\api.ts`
  - Deliverables:
    - Send `POST /v1/analytics/site/visit` with `fetch`, `keepalive`, `credentials: "include"`, and required headers.
    - Build the backend URL from the same `NEXT_PUBLIC_API_URL || http://localhost:8000` convention used by `shared/api/client.ts`.
    - Include `x-platform: cabinet` so backend optional cookie auth can identify authenticated cabinet users.
    - Avoid auth redirects or refresh loops for analytics collection.
    - Include visitor id, sanitized route path without query/hash, sanitized referrer, timezone, screen size, open context, device type, and Telegram platform signal when present.
    - Consider `navigator.sendBeacon` only if it can include credentials reliably in the target browsers; otherwise prefer `fetch(..., { keepalive: true, credentials: "include" })`.
    - Return silently on non-critical failures so site UX is not blocked.
  - Logging requirements:
    - DEBUG in development for successful beacon sends.
    - WARNING in development for failed beacon sends.
    - No production console noise for routine beacon failures.
    - Never log cookies, tokens, raw visitor ids, or Telegram init data.
  - Dependencies:
    - Tasks 5 and 6.

- [x] Task 8: Mount a route-aware site visit tracker in the user-facing `diaweb` app.
  - Files:
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\site-analytics\components\SiteVisitTracker.tsx`
    - Update `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\app\[lang]\layout.tsx`
  - Deliverables:
    - Track visits on first page load and client-side pathname changes.
    - Exclude `/staff`, localized staff paths such as `/ru/staff` and `/en/staff`, and other internal/admin routes from site analytics.
    - Include landing, login, offers, cabinet, and other user-facing routes.
    - Use `usePathname` rather than full URL so query strings are not tracked.
    - Throttle duplicate sends per route/tab session while leaving backend upsert as the final dedupe authority.
  - Logging requirements:
    - DEBUG in development when a route is skipped by exclusion rules.
    - DEBUG in development when a duplicate route send is throttled.
    - No production logs during normal route changes.
  - Dependencies:
    - Tasks 6 and 7.

- [x] Task 9: Export frontend site analytics module APIs.
  - Files:
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\site-analytics\index.ts`
  - Deliverables:
    - Export the tracker component and helper functions needed by tests.
    - Keep public exports small so analytics collection details stay encapsulated.
  - Logging requirements:
    - No runtime logging.
  - Dependencies:
    - Tasks 6, 7, and 8.

### Phase 3: Staff Dashboard UI
- [x] Task 10: Extend analytics frontend types, API, and hook.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\types.ts`
    - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\api.ts`
    - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\hooks.ts`
  - Deliverables:
    - Add TypeScript interfaces for `SiteAnalyticsResponse`.
    - Include `total_unique_visitors` or equivalent total field in the response type, separate from overlapping breakdown totals.
    - Add `fetchSiteAnalytics(dateFrom, dateTo)`.
    - Add `useSiteAnalytics(dateFrom, dateTo, enabled?)` with a stable React Query key.
  - Logging requirements:
    - No normal runtime logs in hooks/API wrappers.
    - Rely on existing API client error handling for request failures.
  - Dependencies:
    - Task 5.

- [x] Task 11: Add `Сайт` tab to analytics dashboard navigation.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\AnalyticsDashboard.tsx`
  - Deliverables:
    - Extend active tab state from `overview | advent` to `overview | advent | site`.
    - Add button label `Сайт` to the top-right analytics tab control.
    - Preserve existing `Общая` and `Адвент` behavior.
    - Mount the site panel only when selected or keep its query disabled until selected.
  - Logging requirements:
    - No runtime logs for tab switching.
  - Dependencies:
    - Task 10.

- [x] Task 12: Build site analytics visual components.
  - Files:
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\SiteAnalyticsPanel.tsx`
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\SiteDauChart.tsx`
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\SiteBreakdownCards.tsx`
    - Create `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\SiteContextDeviceMatrix.tsx`
  - Deliverables:
    - Reuse `DateRangePicker`.
    - Show site DAU today, DAU yesterday, WAU, and MAU.
    - Show daily trend chart for site DAU.
    - Show browser vs Telegram unique visitor counts and rates.
    - Show desktop/mobile/tablet/unknown unique visitor counts and rates.
    - Show compact context/device matrix.
    - Render total unique visitors separately from the sum of context/device categories.
    - Keep layout dense, staff-tool-like, and consistent with existing analytics/advent styling.
  - Logging requirements:
    - No normal UI logs.
    - Surface loading/error/empty states in UI instead of console logging.
  - Dependencies:
    - Tasks 10 and 11.

- [x] Task 13: Refine responsive behavior and empty states for the site tab.
  - Files:
    - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\modules\analytics\components\SiteAnalyticsPanel.tsx`
    - Any site analytics child components created in Task 12.
  - Deliverables:
    - Ensure cards, labels, charts, and matrix cells do not overflow on mobile or desktop.
    - Add explicit copy for no-data period.
    - Make chart containers stable so Recharts does not collapse.
    - Clearly note in UI copy only where necessary that category counts can overlap if a visitor used multiple contexts/devices.
  - Logging requirements:
    - No runtime logs.
  - Dependencies:
    - Task 12.

### Phase 4: Tests
- [x] Task 14: Add backend tests for visit recording and aggregation.
  - Files:
    - Create `C:\Users\Indigo\Desktop\diaverse\diaverseapi\tests\test_analytics_site.py`
  - Deliverables:
    - Cover visitor-id recording for anonymous users.
    - Cover authenticated user recording via optional auth where practical with route dependency overrides.
    - Cover Telegram vs browser classification.
    - Cover desktop vs mobile classification.
    - Cover upsert dedupe and `visits_count` updates.
    - Cover server-side exclusion for `/staff`, `/ru/staff`, and `/en/staff`.
    - Cover anonymous-to-authenticated same-day stitching so a pre-login and post-login visit from the same browser visitor id does not double count total DAU.
    - Cover that query strings and hashes are stripped before storage.
    - Cover staff analytics response, DAU/WAU/MAU, daily trend, breakdowns, and matrix.
    - Cover invalid `date_from > date_to`.
  - Logging requirements:
    - Tests should assert behavior, not log output by default.
    - Use captured logs only for critical warning/error scenarios if useful.
  - Dependencies:
    - Tasks 1-5.

- [x] Task 15: Add frontend tests for visitor helpers and tracker.
  - Files:
    - Create tests under `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\__tests__\modules\site-analytics\`
  - Deliverables:
    - Cover stable visitor id creation/restoration.
    - Cover localStorage unavailable fallback.
    - Cover Telegram embedded detection.
    - Cover device classification.
    - Cover route exclusion for `/staff`, `/ru/staff`, and `/en/staff`.
    - Cover query/hash stripping before beacon payload creation.
    - Cover beacon payload and duplicate throttling with mocked fetch.
    - Cover that the beacon helper sends `credentials: "include"` and `x-platform: cabinet`.
  - Logging requirements:
    - Tests may assert development warnings for storage fallback.
    - Avoid noisy console output in test runs.
  - Dependencies:
    - Tasks 6-9.

- [x] Task 16: Add frontend tests for site analytics staff dashboard.
  - Files:
    - Extend `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\__tests__\modules\analytics\hooks.test.ts`
    - Extend or add `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\__tests__\modules\analytics\SiteAnalyticsPanel.test.tsx`
  - Deliverables:
    - Cover `useSiteAnalytics` query key and URL params.
    - Cover dashboard tab switching to `Сайт`.
    - Cover loading, error, empty, and populated site analytics states.
    - Cover browser/Telegram and device breakdown rendering.
  - Logging requirements:
    - Tests should mock API calls and avoid normal console output.
  - Dependencies:
    - Tasks 10-13.

### Phase 5: Documentation And Verification
- [x] Task 17: Document site analytics behavior and privacy constraints.
  - Files:
    - Prefer an existing docs location in `C:\Users\Indigo\Desktop\diaverse\diaverseapi` or `C:\Users\Indigo\Desktop\diaverse\diaweb`.
    - If no product docs location fits, create `C:\Users\Indigo\Desktop\diaverse\.ai-factory\references\site-analytics.md`.
  - Deliverables:
    - Document metric definitions for site DAU/WAU/MAU.
    - Document browser vs Telegram and device classification semantics.
    - Document that raw visitor ids are not stored and category counts can overlap.
    - Document anonymous-to-authenticated same-day stitching behavior and its limits.
    - Document that staff/admin routes are excluded by both frontend and backend safeguards.
    - Document that stored paths intentionally omit query strings and hashes.
    - Document that metrics start from deployment date and are not backfilled.
  - Logging requirements:
    - No runtime logging.
  - Dependencies:
    - Tasks 1-16.

- [x] Task 18: Run automated verification and refresh the shared graph.
  - Files:
    - No product files expected unless verification reveals fixes.
  - Deliverables:
    - Run backend tests for site analytics.
    - Run frontend analytics and site-analytics tests.
    - Run backend lint for changed analytics files.
    - Run frontend typecheck and lint.
    - Verify Alembic heads and compile the new migration SQL.
    - Refresh Graphify after code/docs changes.
  - Logging requirements:
    - Preserve command outputs for final implementation summary.
    - Do not add runtime logs as part of verification unless a bug fix requires it.
  - Dependencies:
    - Tasks 1-17.

## Verification Plan
- diaverseapi:
  - `cd C:\Users\Indigo\Desktop\diaverse\diaverseapi`
  - `poetry run pytest tests/test_analytics_site.py tests/test_analytics_advent.py`
  - `poetry run ruff check app/analytics tests/test_analytics_site.py`
  - `poetry run alembic heads`
  - `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
  - Verify `migrations/env.py` imports `app.analytics.models` so SQLModel metadata remains complete for future autogenerate checks.
- diaweb:
  - `cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend`
  - `npm test -- __tests__/modules/analytics __tests__/modules/site-analytics`
  - `npm run typecheck`
  - `npm run lint`
- visual:
  - Run `diaweb` locally.
  - Inspect `/ru/staff/analytics` and switch to `Сайт`.
  - Verify desktop and mobile widths.
  - Verify no text overlap in cards, charts, and matrix.
- workspace graph:
  - `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`

## Open Questions For Implementation
- Should staff/admin visits be completely excluded, or should we later add a separate internal analytics view?
- Should the first release show page-level top paths, or should it stay focused on DAU/WAU/MAU and requested breakdowns only? Current plan keeps top paths out of scope.
- Should category counts be shown as overlapping unique visitor segments, or should we enforce a primary context/device per visitor per day? Current plan uses overlapping segments and distinct total.
- Which exact backend canonical analytics date should be used if product wants a business timezone instead of the process/server date? Current plan requires backend-owned date derivation and forbids trusting client timezone for `visit_date`.
