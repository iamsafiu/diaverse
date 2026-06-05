# Temporary Factory Staff Gate

Status: active temporary frontend-only factory gate; raids opened to authenticated users on 2026-06-04
Owner: `diaweb`
Created: 2026-06-01

## Purpose

Factory is temporarily visible and routable only for:

- `employee`
- `superadmin`
- Telegram IDs listed in `NEXT_PUBLIC_CABINET_GAME_TESTER_TG_IDS`

Regular authenticated users outside those groups should not see the Factory navigation icon and should be redirected away from direct `/factory` URLs.

Raids are no longer part of this temporary gate. Regular authenticated users can see and open `/raids` when the raids rollout flag is enabled. Guests still cannot access raids.

This is intentionally a frontend-only product gate. It is not a backend security boundary for `/api/cabinet/factory/*` or `/api/cabinet/raids/*`.

## Active Implementation

The gate is implemented in `diaweb/frontend`:

- `modules/cabinet/components/CabinetTopbar.tsx`
  - Factory desktop tab requires `hasGameAccess && !isGuest`.
  - Raids desktop tab requires only `!isGuest`.
  - Staff navigation still requires `hasStaffAccess && !isGuest`.
- `modules/cabinet/components/BottomNav.tsx`
  - Factory mobile tab requires `hasGameAccess && !isGuest`.
  - Raids mobile tab requires only `!isGuest`.
  - Staff navigation still requires `hasStaffAccess && !isGuest`.
- `modules/cabinet/gameAccess.ts`
  - Staff users get game access through `employee` or `superadmin`.
  - Non-staff testers get factory preview access only when their `/v1/auth/me` Telegram ID is in `NEXT_PUBLIC_CABINET_GAME_TESTER_TG_IDS`.
- `modules/cabinet/routeAccess.ts`
  - `/factory` is listed in `temporaryStaffOnlyGameRouteSuffixes`.
  - `/raids` is listed in `authOnlyRouteSuffixes`.
  - `CabinetLayout` treats `/factory` as a temporary game route and redirects users without game access to `/{lang}/offers`.
  - Other staff-only routes, such as `/shop2`, still require staff access and do not use the tester allowlist.

The proxy still treats `/factory` and `/raids` as authenticated cabinet routes only. Do not add a JWT-role proxy block for this temporary gate unless the product explicitly accepts stale-token behavior.

## How To Disable Later

When Factory should be public to regular authenticated users again:

1. In `diaweb/frontend/modules/cabinet/routeAccess.ts`, remove `/factory` from `temporaryStaffOnlyGameRouteSuffixes`.
2. Put `/factory` into `authOnlyRouteSuffixes`.
3. In `CabinetTopbar.tsx`, change:

   ```ts
   const canUseFactoryNav = showFactoryNav && hasGameAccess && !isGuest;
   ```

   back to:

   ```ts
   const canUseFactoryNav = showFactoryNav && !isGuest;
   ```

4. Remove any `NEXT_PUBLIC_CABINET_GAME_TESTER_TG_IDS` deployment value.
5. Make the same factory nav change in `BottomNav.tsx`.
6. Update these tests to expect regular authenticated users to see/open Factory and Raids again:

   - `frontend/__tests__/modules/cabinet/gameAccess.test.ts`
   - `frontend/__tests__/modules/cabinet/routeAccess.test.ts`
   - `frontend/__tests__/modules/cabinet/CabinetTopbar.test.tsx`
   - `frontend/__tests__/modules/cabinet/BottomNav.test.tsx`
   - `frontend/__tests__/modules/cabinet/CabinetLayout.test.tsx`

7. Run:

   ```powershell
   cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
   npm run test -- --run __tests__\modules\cabinet\gameAccess.test.ts __tests__\modules\cabinet\routeAccess.test.ts __tests__\modules\cabinet\CabinetTopbar.test.tsx __tests__\modules\cabinet\BottomNav.test.tsx __tests__\modules\cabinet\CabinetLayout.test.tsx
   npm run lint -- --file modules\cabinet\gameAccess.ts --file modules\cabinet\routeAccess.ts --file modules\cabinet\components\CabinetTopbar.tsx --file modules\cabinet\components\BottomNav.tsx --file __tests__\modules\cabinet\gameAccess.test.ts --file __tests__\modules\cabinet\routeAccess.test.ts --file __tests__\modules\cabinet\CabinetTopbar.test.tsx --file __tests__\modules\cabinet\BottomNav.test.tsx --file __tests__\modules\cabinet\CabinetLayout.test.tsx
   ```

## Verification While Active

Expected active behavior:

- Guest direct `/factory` or `/raids`: redirected to login.
- Regular authenticated user outside staff/tester access direct `/factory`: no factory content is rendered, then redirected to `/offers`.
- Regular authenticated user direct `/raids`: raids route renders normally when the raids rollout flag is enabled.
- Allowlisted game tester: Factory icon is visible when rollout flags are enabled, and direct factory routes render normally; staff navigation remains hidden.
- `employee` and `superadmin`: Factory/Raids icons are visible when rollout flags are enabled, and direct routes render normally.
