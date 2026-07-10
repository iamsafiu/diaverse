# Site Analytics

## Scope

Site analytics tracks browser-facing `diaweb` visits separately from mobile app activity. Mobile DAU/WAU/MAU stays sourced from the existing backend activity tables; website analytics uses the dedicated `site_daily_visits` table in `diaverseapi`.

The staff analytics dashboard exposes this data in the `Сайт` tab next to `Общая` and `Адвент`.

## Collection

- `diaweb` mounts a silent route tracker under `app/[lang]/layout.tsx`.
- The tracker sends `POST /v1/analytics/site/visit` with `fetch`, `keepalive: true`, and `credentials: "include"`.
- The beacon includes `x-platform: cabinet` so optional backend auth can hydrate the cabinet user from cookies when present.
- The tracker does not use the shared `apiClient`, so analytics collection never triggers auth refreshes or redirects.
- Staff/admin routes are excluded in the frontend and still rejected by the backend.
- `diaverse-content` public learn pages mount a separate consent-gated tracker under `/ru/learn/*`.
- The content tracker sends browser beacons only to its own `/api/analytics/site-visit` proxy; that server route forwards sanitized visits to `diaverseapi /v1/analytics/site/visit` without browser cookies.
- Content staff/admin/internal/import routes are excluded before the beacon is sent and are still rejected by the content proxy.

## Privacy

- Raw browser visitor ids are generated first-party in localStorage and are never stored by the backend.
- `diaverseapi` stores HMAC hashes for `visitor:<id>` and authenticated `user:<uuid>` visitor keys.
- Stored paths and referrers intentionally omit query strings and hashes.
- Cookies, Telegram init data, auth tokens, and raw visitor ids must not be logged.
- `diaverse-content` reuses the browser consent storage key `diaweb:privacy-consent:v1`; no content analytics runs before accepted consent.
- Content attribution uses a separate hash-only ledger. Opaque `dattr` tokens are captured into a short-lived host-only HttpOnly cookie and redeemed after auth; raw tokens and token hashes are not logged or exposed to staff UI.

## Metrics

- Site DAU: distinct site visitor keys with at least one tracked visit on a day.
- Site WAU: distinct site visitor keys over the backend canonical 7-day window.
- Site MAU: distinct site visitor keys over the backend canonical 30-day window.
- Date attribution is owned by the backend. Client timezone is captured only as metadata.
- No historical backfill exists; metrics start from the tracker deployment date.

## Content Attribution Metrics

Content attribution connects consented learn-page touches to later authenticated backend outcomes without exposing per-user facts to the content system.

| Metric | Denominator | Privacy Rule |
| --- | --- | --- |
| Touches | Consented content-attribution touch rows for a bounded date window. | Raw token and visitor key are HMAC-hashed before persistence. |
| Anonymous visitors | Distinct anonymous visitor hashes in the touch ledger. | No raw browser id is stored. |
| Claimed users | Distinct users stitched from valid same/later-day auth claims inside the bounded claim window. | Monotonic stitching; claims are not reassigned to another user. |
| First meaningful activity | Claimed users with positive backend activity within the first eligible activity window. | Returned only when cohort size and maturity thresholds are met. |
| D1 / D7 active | Claimed users active on the D1/D7 UTC calendar-day windows. | Immature or below-threshold cohorts are `insufficient_evidence`, not zero. |
| Approved paid users/outcomes | Authenticated paid outcomes in approved backend payment domains. | Guest/unclaimed outcomes are an explicit `unavailable` gap. |

Unavailable sources are named in the response:

- onboarding conversion: unavailable until an immutable completion timestamp exists;
- guest and unclaimed outcomes: unavailable because no safe stitchable identity exists;
- mobile install attribution: unavailable until a separate mobile deep-link attribution contract exists.

These states must be rendered as `unavailable` or `insufficient_evidence`. Do not coerce them to zero in dashboards, learning scores, or Daily Work summaries.

## Executive KPI Summary

The `Сайт` tab also requests a finance-sensitive executive summary from `GET /v1/analytics/site/executive`.
The endpoint is protected by backend `superadmin` role access, not by ordinary `analytics:view`, because it exposes revenue, payer, ARPPU, and LTV data. The frontend must treat a `403` from this endpoint as a superadmin-only notice while keeping the non-financial site analytics visible.

The response includes metric values, periods, definitions, and warnings in one payload. Backend date attribution is canonical:

- `report_date` defaults to the backend current date.
- `yesterday` is `report_date - 1 day`.
- MTD is the first day of `report_date` month through `report_date`, inclusive.
- MAU is the 30-calendar-day site activity window ending at `report_date`.
- Previous MAU is the immediately preceding 30-calendar-day site activity window.
- Retention and LTV use the selected registration cohort. Defaults are the latest 90-day cohort ending yesterday.
- LTV horizon defaults to 90 days after registration. Partial cohorts are returned with warnings.

### Executive Metric Definitions

| Metric | Definition | Period / Formula |
| --- | --- | --- |
| Active user | Distinct website visitor in `site_daily_visits`, deduplicated by backend visitor/user hash. | Selected site activity period |
| Payer | Distinct `payer_key` from successful real-money Advent, Shop, or Crypton payments. | Selected payment period |
| Gross revenue | Sum of successful real-money payment amounts before fees, refunds, and cost of goods. | Payment confirmation date |
| Net revenue | Revenue after refunds and payment fees. | Not available until a source for refunds/fees exists |
| Revenue Yesterday | Gross revenue from successful real-money payments yesterday. | `sum(successful_payment.amount)` for `yesterday` |
| Revenue MTD | Gross revenue from successful real-money payments from month start through `report_date`. | `sum(successful_payment.amount)` for MTD |
| Net Profit MTD | Profit after fees, refunds, and costs. | Returned as `unavailable` until fee/cost/refund source exists |
| DAU yesterday | Distinct active website visitors yesterday. | `yesterday` |
| MAU | Distinct active website visitors in the current 30-day window. | `mau_from` through `mau_to` |
| Net MAU Growth | Current MAU growth relative to previous MAU. | `(current_mau - previous_mau) / previous_mau * 100` |
| D1 / D7 / D30 / D60 / D90 | Registration-cohort product retention using existing backend activity sources. | Existing retention windows around day N |
| Unique payers | Distinct `payer_key` with successful real-money payment. | MTD |
| Conversion to payer | Share of active site visitors MTD that became payers MTD. | `unique_payers_mtd / active_users_mtd * 100` |
| ARPPU | Average gross revenue per unique payer. | `revenue_mtd / unique_payers_mtd` |
| LTV | Average gross revenue per registered cohort user within the selected horizon after registration. | `cohort_revenue_within_horizon / cohort_size` |

### Payer Identity

Real-money payment facts normalize payer identity into `payer_key`:

- `user:<uuid>` when an authenticated backend user is known.
- `tg:<id>` when only a Telegram user id is available.
- `guest:<id>` for guest payment sessions.
- `payment:<id>` as the final fallback when no stable actor identity is available.

The executive endpoint returns a warning when MTD unique payers include payment-scoped fallback keys, because those can overcount repeat buyers.

## Segments

- Opening context is normalized to `browser`, `telegram`, or `unknown`.
- Telegram context is detected from `window.Telegram.WebApp`, the `X-Telegram-WebApp-Platform` header/body field, Telegram-like user agents, Telegram referrers, or explicit `from=tg` links.
- Device type is normalized independently to `desktop`, `mobile`, `tablet`, or `unknown`.
- Segment counts are unique visitors per segment and can overlap when the same visitor opens the site in multiple contexts or device classes during the selected period.
- `total_unique_visitors` is the distinct total and should not be inferred by summing segment counts.

## Anonymous To Authenticated Stitching

When an authenticated visit arrives with the same first-party browser visitor id, same-day anonymous rows are stitched to the authenticated `user:<uuid>` hash before the daily upsert. This prevents a pre-login and post-login visit from the same browser visitor from double-counting DAU for that day.

Stitching is intentionally same-day only. Cross-day identity repair and historical backfill are out of scope for the first release.
