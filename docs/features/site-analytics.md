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

## Privacy

- Raw browser visitor ids are generated first-party in localStorage and are never stored by the backend.
- `diaverseapi` stores HMAC hashes for `visitor:<id>` and authenticated `user:<uuid>` visitor keys.
- Stored paths and referrers intentionally omit query strings and hashes.
- Cookies, Telegram init data, auth tokens, and raw visitor ids must not be logged.

## Metrics

- Site DAU: distinct site visitor keys with at least one tracked visit on a day.
- Site WAU: distinct site visitor keys over the backend canonical 7-day window.
- Site MAU: distinct site visitor keys over the backend canonical 30-day window.
- Date attribution is owned by the backend. Client timezone is captured only as metadata.
- No historical backfill exists; metrics start from the tracker deployment date.

## Segments

- Opening context is normalized to `browser`, `telegram`, or `unknown`.
- Telegram context is detected from `window.Telegram.WebApp`, the `X-Telegram-WebApp-Platform` header/body field, Telegram-like user agents, Telegram referrers, or explicit `from=tg` links.
- Device type is normalized independently to `desktop`, `mobile`, `tablet`, or `unknown`.
- Segment counts are unique visitors per segment and can overlap when the same visitor opens the site in multiple contexts or device classes during the selected period.
- `total_unique_visitors` is the distinct total and should not be inferred by summing segment counts.

## Anonymous To Authenticated Stitching

When an authenticated visit arrives with the same first-party browser visitor id, same-day anonymous rows are stitched to the authenticated `user:<uuid>` hash before the daily upsert. This prevents a pre-login and post-login visit from the same browser visitor from double-counting DAU for that day.

Stitching is intentionally same-day only. Cross-day identity repair and historical backfill are out of scope for the first release.
