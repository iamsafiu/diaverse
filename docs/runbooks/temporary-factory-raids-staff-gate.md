# Temporary Factory Staff Gate

Status: disabled on 2026-06-13; historical frontend-only factory gate
Owner: `diaweb`
Created: 2026-06-01

## Purpose

This runbook records the temporary Factory staff/tester gate that was removed on
2026-06-13.

Factory is now visible and routable for every authenticated user when
`NEXT_PUBLIC_FACTORY_WEB_ENABLED=true`. Guests still cannot access Factory.
Raids remain visible and routable for every authenticated user when the raids
rollout flag is enabled.

This is intentionally a frontend-only product gate. It is not a backend security boundary for `/api/cabinet/factory/*` or `/api/cabinet/raids/*`.

## Current Implementation

The active access rules are implemented in `diaweb/frontend`:

- `modules/cabinet/components/CabinetTopbar.tsx`
  - Factory desktop tab requires `showFactoryNav && !isGuest`.
  - Raids desktop tab requires only `!isGuest`.
  - Staff navigation still requires `hasStaffAccess && !isGuest`.
- `modules/cabinet/components/BottomNav.tsx`
  - Factory mobile tab requires `showFactoryNav && !isGuest`.
  - Raids mobile tab requires only `!isGuest`.
  - Staff navigation still requires `hasStaffAccess && !isGuest`.
- `modules/cabinet/routeAccess.ts`
  - `/factory` is listed in `authOnlyRouteSuffixes`.
  - `/raids` is listed in `authOnlyRouteSuffixes`.
  - Other staff-only routes, such as `/shop2`, still require staff access.

The proxy treats `/factory` and `/raids` as authenticated cabinet routes only.

## Former Gate

The removed temporary gate limited Factory to:

- `employee`
- `superadmin`
- Telegram IDs listed in `NEXT_PUBLIC_CABINET_GAME_TESTER_TG_IDS`

## Verification

Expected behavior after the gate was disabled:

- Guest direct `/factory` or `/raids`: redirected to login.
- Regular authenticated user direct `/factory`: factory route renders normally when the factory rollout flag is enabled.
- Regular authenticated user direct `/raids`: raids route renders normally when the raids rollout flag is enabled.
- `employee` and `superadmin`: Factory/Raids icons are visible when rollout flags are enabled, and staff navigation remains available.
