# Key User Flows — Diaverse Website (diaweb)

## Authentication Flow

1. User opens the web app inside Telegram WebApp
2. Telegram provides `initData` with user identity
3. Frontend sends `initData` to login API endpoint
4. Backend validates Telegram signature
5. Server issues JWT token, sets httpOnly cookie
6. User is redirected to cabinet dashboard
7. All subsequent API requests use httpOnly cookie for auth

**Files involved:**
- `frontend/app/[lang]/login/page.tsx`
- `frontend/modules/auth/` (auth module)

---

## Shop v2 Home Page Flow

1. User navigates to `/[lang]/shop2`
2. `ShopHomePage` component renders
3. Home page displays category cards (pets2, pet-skins2, pilot-skins2, etc.)
4. `ShowcaseHomePreview` shows 3 preview offers (one per showcase-enabled section)
5. `ShopHomeSpecials` displays current special offers
6. `StepPassSection` renders step pass deals if available
7. User clicks a category card to navigate to category page

**Files involved:**
- `frontend/app/[lang]/(cabinet)/shop2/page.tsx`
- `frontend/modules/shop/components/ShopHomePage.tsx`
- `frontend/modules/shop/components/ShowcaseHomePreview.tsx`
- `frontend/modules/shop/components/ShopHomeSpecials.tsx`
- `frontend/modules/shop/components/StepPassSection.tsx`
- `frontend/modules/shop/shop-home-data.ts`

---

## Shop Category Page Flow

1. User navigates to `/[lang]/shop2/[category]` (e.g. pets2, pet-skins2, pilot-skins2)
2. `ShopCategoryRoutePage` resolves the category slug
3. `ShopCategoryContent` renders the full category layout
4. `useShopCatalog` hook fetches catalog data from API
5. `useShopSpecials` hook fetches current special offers
6. Items are rendered in `ShopCategoryGrid`
7. User can search within category via `ShopCategorySearch`
8. User can purchase items via `usePurchase` hook

**Files involved:**
- `frontend/app/[lang]/(cabinet)/shop2/[category]/page.tsx`
- `frontend/modules/shop/components/ShopCategoryRoutePage.tsx`
- `frontend/modules/shop/components/ShopCategoryContent.tsx`
- `frontend/modules/shop/components/ShopCategoryGrid.tsx`
- `frontend/modules/shop/components/ShopCategorySearch.tsx`
- `frontend/modules/shop/hooks/useShopCatalog.ts`
- `frontend/modules/shop/hooks/usePurchase.ts`

---

## Shop Showcase Flow

1. User opens a showcase-enabled category page (pets2, pet-skins2, pilot-skins2)
2. `useShowcaseOffers` hook fetches specials + catalog data
3. `showcase-utils.ts` builds up to 6 showcase offers using hash-based daily rotation
4. `ShowcaseSection` renders above the catalog with discount badges and countdown timers
5. `CountdownTimer` displays time remaining for each offer (using `useCountdown` hook)
6. `useNewItems` hook filters catalog items added within the last 7 days
7. `NewItemsSection` renders below showcase with NEW badges on qualifying items
8. Items appearing in showcase or new-items sections are deduplicated from the main catalog grid
9. On the shop home page, `ShowcaseHomePreview` shows 3 preview offers (one per section)

**Files involved:**
- `frontend/modules/shop/showcase-utils.ts` — hashing, conditions, filtering
- `frontend/modules/shop/hooks/useShowcaseOffers.ts` — showcase offers rotation hook
- `frontend/modules/shop/hooks/useNewItems.ts` — new items detection hook
- `frontend/modules/shop/hooks/useCountdown.ts` — countdown timer hook
- `frontend/modules/shop/components/ShowcaseSection.tsx` — showcase section container
- `frontend/modules/shop/components/ShowcaseOfferCard.tsx` — showcase offer card
- `frontend/modules/shop/components/NewItemsSection.tsx` — new items section
- `frontend/modules/shop/components/ShowcaseHomePreview.tsx` — home page preview
- `frontend/modules/shop/components/CountdownTimer.tsx` — countdown timer component

---

## Shop Purchase Flow

1. User clicks purchase button on a shop item card
2. `usePurchase` hook initiates the purchase
3. If item requires payment, checkout session is created via API
4. `ShopFeedback` component shows success/error toast
5. Catalog is refreshed to reflect updated availability

**Files involved:**
- `frontend/modules/shop/hooks/usePurchase.ts`
- `frontend/modules/shop/components/shared/PurchaseButton.tsx`
- `frontend/modules/shop/components/ShopFeedback.tsx`
- `frontend/app/api/cabinet/shop/purchase/route.ts`
- `frontend/app/api/cabinet/shop/checkout/route.ts`

---

## Staff Shop Admin Flow

1. Staff member navigates to `/staff/shop`
2. `ShopAdminPage` loads current shop listings
3. Staff can add/edit/remove listings via `ShopListingEditor`
4. `ShopBulkAddDialog` allows bulk item creation
5. `ShopSpecialOfferQueue` manages special offer scheduling
6. `ShopSpecialRewardPoolEditor` configures reward pools
7. `ItemCatalogPicker` provides item selection from catalog

**Files involved:**
- `frontend/app/[lang]/staff/shop/page.tsx`
- `frontend/modules/staff-shop/components/ShopAdminPage.tsx`
- `frontend/modules/staff-shop/components/ShopListingEditor.tsx`
- `frontend/modules/staff-shop/components/ShopBulkAddDialog.tsx`
- `frontend/modules/staff-shop/components/ShopSpecialOfferQueue.tsx`
- `frontend/modules/staff-shop/components/ShopSpecialRewardPoolEditor.tsx`
- `frontend/modules/staff-shop/shop-admin-api.ts`

---

## Copywriting Flow

1. Staff member navigates to `/staff/copywriting`
2. Dashboard shows drafts, plans, and posts overview
3. Staff creates/edits drafts with text content
4. Image generation can be triggered for drafts
5. Content plans organize posts by schedule
6. Publishing pushes content to configured targets

**Files involved:**
- `frontend/app/[lang]/staff/copywriting/layout.tsx`
- `frontend/app/[lang]/staff/copywriting/page.tsx`
- `frontend/app/[lang]/staff/copywriting/drafts/page.tsx`
- `frontend/app/[lang]/staff/copywriting/drafts/[id]/page.tsx`
- `frontend/app/api/staff/copywriting/drafts/route.ts`
- `frontend/app/api/staff/copywriting/drafts/[id]/generate-image/route.ts`
- `frontend/app/api/staff/copywriting/publish/route.ts`
