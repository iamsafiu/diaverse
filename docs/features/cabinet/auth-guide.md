# Cabinet Auth Guide

## Purpose

This document describes the current web auth model for the Diaverse cabinet after the bot-first rollout and the cabinet browser-session hardening update.

Primary goals:

- keep Telegram out of the browser critical path for the main website;
- keep browser auth seamless for active users through sliding refresh sessions;
- make logout authoritative so an explicit logout cannot silently restore the same browser session;
- preserve guest-friendly cabinet routes without the guest-to-auth flash on reload.

## Current Web Auth Model

Primary login path:

1. Browser opens `/{lang}/login`.
2. Frontend checks `GET /v1/auth/session`.
3. If there is no active or recoverable browser session, frontend pre-creates a short-lived login session with `POST /v1/auth/login-sessions`.
4. The user's first Telegram login click opens the bot via deep link using the already prepared `start_token`.
5. `diaverse-auth-bot` approves the login session through the internal backend contract.
6. Browser polls the public login-session status.
7. Once approved, browser exchanges the session for local `httpOnly` cabinet cookies.
8. Frontend hydrates `/v1/auth/me`, clears guest/public cache, and restores the redirect target.

Legacy fallback:

- Telegram Widget, Telegram Mini App, and Telegram IAB logic still exist in the codebase.
- They are disabled by default in the normal web UI.
- They remain available only as an explicit internal/debug fallback path.

## Runtime Split

`diaweb`

- owns login UI, deep-link launch, polling, exchange, and cache/redirect reconciliation;
- stores pending bot login state in `sessionStorage`;
- stores an explicit "stay guest after logout" marker in `localStorage`;
- derives the recoverable-session hint in the App Router cabinet layout, not in `proxy.ts`.

`diaverseapi`

- owns `GET /v1/auth/session` and `POST /v1/auth/refresh`;
- owns login-session state in Redis;
- owns the persisted cabinet browser session model;
- owns cookie issuance, rotation, revocation, guest bind/transfer, and final user hydration.

`diaverse-auth-bot`

- lives in a separate repo and deploys to the foreign host;
- accepts `/start login_<token>`;
- calls the internal backend approve endpoint;
- never touches the database or Redis directly.

## Browser Session Model

Cabinet browser auth is now stateful.

Each browser session is persisted in `diaverseapi` as a `CabinetAuthSession` record with:

- `session_id`
- `user_id`
- `current_refresh_jti_hash`
- `previous_refresh_jti_hash`
- `previous_refresh_grace_until`
- `expires_at`
- `last_seen_at`
- `revoked_at`
- `revocation_reason`
- `created_via`

Token model:

- access token: short-lived, includes `sid`;
- refresh token: includes `sid` and `jti`;
- refresh token rotation happens on both `/v1/auth/refresh` and refresh-based `/v1/auth/session` recovery.

## Sliding Session Behavior

The browser session uses a sliding refresh window.

- Every successful refresh or refresh-based recovery extends the browser session expiry from "now".
- A user who returns near the end of the window gets a fresh full window again.
- To make the production browser window equal to 14 days, runtime config must set:

```bash
REFRESH_TOKEN_EXPIRE_MINUTES=20160
```

Important:

- this repository does not change tracked `.env` files;
- the code supports sliding sessions already;
- the real expiry window still depends on runtime configuration outside git.

## Transitional Legacy Refresh Upgrade

During rollout, old stateless refresh cookies are still accepted one time.

Behavior:

1. Backend validates the legacy refresh token.
2. Backend creates a persisted `CabinetAuthSession`.
3. Backend issues the new stateful `access_token` and `refresh_token`.

This avoids forced logout for users who still hold an old refresh cookie during the migration window.

## Frontend Flow Details

### Login Page

Main component:

- `frontend/modules/auth/components/LoginPage.tsx`

Key behavior:

- resolves and sanitizes the `redirect` query parameter;
- checks for an already recoverable session on mount;
- restores a pending bot-login session from `sessionStorage` only when explicit guest mode is not active;
- resumes polling on `focus`, `pageshow`, and `visibilitychange`;
- pre-creates the bot login session before the user clicks the Telegram button;
- opens Telegram via `tg://resolve?...start=login_<token>` with `https://t.me/...` fallback only from a direct user click;
- clears the explicit guest marker when the user explicitly starts login again;
- clears pending bot-login state when logout sync arrives from another tab.

### Session Probe

The browser no longer calls `/v1/auth/me` blindly on guest routes.

Instead:

1. `fetchUser()` calls `GET /v1/auth/session` with `skipRefreshRetry`.
2. If explicit guest mode is active, bootstrap is suppressed before any silent recovery attempt.
3. If the probe resolves anonymous, guest routes stay guest and auth-only routes do not hydrate.
4. Only a positive probe can trigger `/v1/auth/me`.

Relevant files:

- `frontend/modules/auth/context.tsx`
- `frontend/modules/auth/lib/browserAuthState.ts`
- `frontend/app/[lang]/(cabinet)/layout.tsx`
- `frontend/modules/cabinet/components/CabinetProviders.tsx`
- `frontend/modules/cabinet/components/CabinetLayout.tsx`
- `frontend/shared/api/client.ts`
- `frontend/proxy.ts`

### Guest-Route Bootstrap

Guest-enabled cabinet routes now distinguish two cases:

- no auth hint: render guest UI immediately;
- recoverable auth hint present: hold a neutral loading shell until auth bootstrap resolves.

The recoverable auth hint is derived from request cookies in the cabinet App Router layout and passed into the client cabinet shell.

`proxy.ts` remains a cheap route gate only. It is not the primary transport for auth bootstrap state.

## Logout Semantics

Logout is now authoritative for cabinet browser sessions.

Behavior:

1. Backend revokes the active `CabinetAuthSession`.
2. Backend clears `access_token` and `refresh_token`.
3. Frontend records explicit guest mode.
4. Frontend clears pending bot-login state.
5. Frontend broadcasts logout to sibling tabs.

Consequences:

- the same browser cannot silently restore auth from the old refresh cookie after logout;
- guest-enabled routes remain guest after explicit logout until the user starts login again;
- a stale bot-login flow cannot resurrect itself in another tab.

## Refresh Rotation and Duplicate Requests

Refresh rotation is concurrency-aware.

Backend strategy:

- state is loaded with row locking;
- the current refresh token is rotated on success;
- the immediately previous refresh token is accepted only inside a very small grace window;
- once that grace window expires, replay of the old refresh token fails.

This protects normal multi-tab or double-request behavior without turning rotated-out refresh tokens into a long-lived bypass.

## Backend Contract

Browser-facing endpoints:

- `GET /v1/auth/session`
- `POST /v1/auth/refresh`
- `POST /v1/auth/login-sessions`
- `GET /v1/auth/login-sessions/{public_id}`
- `POST /v1/auth/login-sessions/{public_id}/exchange`
- `POST /v1/auth/login-sessions/{public_id}/cancel`
- `POST /v1/auth/logout`

Bot-only internal endpoint:

- `POST /v1/auth/internal/login-sessions/approve`

Login-session status model:

- `pending`
- `approved`
- `exchanged`
- `expired`
- `cancelled`
- `failed`

Failure contract:

- `error_code`
- `retryable`
- `user_message_key`

## Environment Variables

### diaweb

Required:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_AUTH_BOT_NAME=diaverse_auth_bot
NEXT_PUBLIC_AUTH_BOT_LOGIN_ENABLED=true
```

Optional legacy override:

```bash
NEXT_PUBLIC_AUTH_LEGACY_FALLBACK_ENABLED=true
```

Legacy-only variables:

```bash
NEXT_PUBLIC_TELEGRAM_BOT_NAME=diaverse_bot
NEXT_PUBLIC_TELEGRAM_APP_NAME=legacy_mini_app_name
```

### diaverseapi

Required for bot-first auth:

```bash
AUTH_BOT_INTERNAL_SECRET=change-me
AUTH_LOGIN_SESSION_TTL_SECONDS=120
AUTH_LOGIN_SESSION_STORE_TTL_SECONDS=900
AUTH_LOGIN_SESSION_POLL_LIMIT=120
AUTH_LOGIN_SESSION_ACTION_LIMIT=30
AUTH_LOGIN_SESSION_ACTION_WINDOW_SECONDS=300
```

Runtime rollout requirement for 14-day sliding browser sessions:

```bash
REFRESH_TOKEN_EXPIRE_MINUTES=20160
```

### diaverse-auth-bot

Required on the foreign host:

```bash
AUTH_BOT_TOKEN=replace-me
AUTH_BOT_NAME=diaverse_auth_bot
BACKEND_INTERNAL_BASE_URL=https://your-diaverse-api.example.com
AUTH_BOT_INTERNAL_SECRET=change-me
AUTH_BOT_MODE=polling
```

## Verification Checklist

Recommended browser validation after deploy:

1. Login through the Telegram bot.
2. Refresh the page on a guest-enabled cabinet route and confirm there is no guest flash before auth resolves.
3. Confirm `GET /v1/auth/session` can return `authenticated=true, recovered=true` only for a valid recoverable session.
4. Confirm `POST /v1/auth/logout` returns `Set-Cookie` clearing both auth cookies.
5. Confirm a follow-up `GET /v1/auth/session` in the same browser resolves anonymous after logout.
6. Confirm logout in one tab propagates to another open cabinet tab.
7. Confirm an old stateless refresh cookie upgrades to the new stateful browser session on first successful touch.

## Operational Notes

- `frontend/proxy.ts` must stay fetch-free.
- `GET /v1/auth/session` must bypass automatic refresh retry in the frontend client.
- Guest/public cache invalidation after login must continue to clear Advent and Shop query keys.
- The foreign server runs only `diaverse-auth-bot`, not the full `diaverseapi` stack.
- The transitional legacy-refresh compatibility path can be removed after the old cookie population has naturally expired.
