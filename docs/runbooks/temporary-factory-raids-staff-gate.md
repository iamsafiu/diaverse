# Temporary Factory/Raids Staff Gate

Status: active temporary frontend-only gate
Owner: `diaweb`
Created: 2026-06-01

## Purpose

Factory and Raids are temporarily visible and routable only for staff users:

- `employee`
- `superadmin`

Regular authenticated users should not see the Factory/Raids navigation icons and should be redirected away from direct `/factory` or `/raids` URLs.

This is intentionally a frontend-only product gate. It is not a backend security boundary for `/api/cabinet/factory/*` or `/api/cabinet/raids/*`.

## Active Implementation

The gate is implemented in `diaweb/frontend`:

- `modules/cabinet/components/CabinetTopbar.tsx`
  - Factory/Raids desktop tabs require `hasStaffAccess && !isGuest`.
- `modules/cabinet/components/BottomNav.tsx`
  - Factory/Raids mobile tabs require `hasStaffAccess && !isGuest`.
- `modules/cabinet/routeAccess.ts`
  - `/factory` and `/raids` are listed in `temporaryStaffOnlyGameRouteSuffixes`.
  - `CabinetLayout` treats these paths as staff-only and redirects non-staff users to `/{lang}/offers`.

The proxy still treats `/factory` and `/raids` as authenticated cabinet routes only. Do not add a JWT-role proxy block for this temporary gate unless the product explicitly accepts stale-token behavior.

## How To Disable Later

When Factory and Raids should be public to regular authenticated users again:

1. In `diaweb/frontend/modules/cabinet/routeAccess.ts`, remove `/factory` and `/raids` from `temporaryStaffOnlyGameRouteSuffixes`.
2. Put `/factory` and `/raids` back into `authOnlyRouteSuffixes`.
3. In `CabinetTopbar.tsx`, change:

   ```ts
   const canUseFactoryNav = showFactoryNav && hasStaffAccess && !isGuest;
   const canUseRaidsNav = showRaidsNav && hasStaffAccess && !isGuest;
   ```

   back to:

   ```ts
   const canUseFactoryNav = showFactoryNav && !isGuest;
   const canUseRaidsNav = showRaidsNav && !isGuest;
   ```

4. Make the same change in `BottomNav.tsx`.
5. Update these tests to expect regular authenticated users to see/open Factory and Raids again:

   - `frontend/__tests__/modules/cabinet/routeAccess.test.ts`
   - `frontend/__tests__/modules/cabinet/CabinetTopbar.test.tsx`
   - `frontend/__tests__/modules/cabinet/BottomNav.test.tsx`
   - `frontend/__tests__/modules/cabinet/CabinetLayout.test.tsx`

6. Run:

   ```powershell
   cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
   npm run test -- --run __tests__\modules\cabinet\routeAccess.test.ts __tests__\modules\cabinet\CabinetTopbar.test.tsx __tests__\modules\cabinet\BottomNav.test.tsx __tests__\modules\cabinet\CabinetLayout.test.tsx
   npm run lint -- --file modules\cabinet\routeAccess.ts --file modules\cabinet\components\CabinetTopbar.tsx --file modules\cabinet\components\BottomNav.tsx --file __tests__\modules\cabinet\routeAccess.test.ts --file __tests__\modules\cabinet\CabinetTopbar.test.tsx --file __tests__\modules\cabinet\BottomNav.test.tsx --file __tests__\modules\cabinet\CabinetLayout.test.tsx
   ```

## Verification While Active

Expected active behavior:

- Guest direct `/factory` or `/raids`: redirected to login.
- Regular authenticated user direct `/factory` or `/raids`: no game content is rendered, then redirected to `/offers`.
- `employee` and `superadmin`: Factory/Raids icons are visible when rollout flags are enabled, and direct routes render normally.
