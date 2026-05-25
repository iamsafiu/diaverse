# File Map — Diaverse Website (diaweb)

All paths relative to project root.

## Root

- `AGENTS.md` — project overview, architecture decisions, build commands
- `docker-compose.prod.yml` — production Docker Compose config
- `docker-compose.traefik.yml` — Traefik reverse proxy config
- `index.html` — root HTML fallback

## frontend/ — Next.js Application

### App Router (Pages & Layouts)

- `frontend/app/favicon.ico` — site favicon
- `frontend/app/globals.css` — global CSS styles
- `frontend/app/layout.tsx` — root layout
- `frontend/app/[lang]/layout.tsx` — i18n layout wrapper
- `frontend/app/[lang]/(landing)/layout.tsx` — landing page group layout
- `frontend/app/[lang]/(landing)/page.tsx` — landing/home page
- `frontend/app/[lang]/(landing)/privacy-policy/page.tsx` — privacy policy page
- `frontend/app/[lang]/(landing)/terms/page.tsx` — terms of service page
- `frontend/app/[lang]/login/page.tsx` — Telegram WebApp login page

### Cabinet Pages

- `frontend/app/[lang]/(cabinet)/layout.tsx` — cabinet layout (auth required)
- `frontend/app/[lang]/(cabinet)/dashboard/page.tsx` — user dashboard
- `frontend/app/[lang]/(cabinet)/offers/page.tsx` — offers listing
- `frontend/app/[lang]/(cabinet)/offers/advent/page.tsx` — advent calendar offers
- `frontend/app/[lang]/(cabinet)/offers/advent/payment/page.tsx` — advent payment page
- `frontend/app/[lang]/(cabinet)/partners/page.tsx` — partner/referral page
- `frontend/app/[lang]/(cabinet)/profile/page.tsx` — user profile page
- `frontend/app/[lang]/(cabinet)/shop/page.tsx` — shop v1 page
- `frontend/app/[lang]/(cabinet)/shop/[category]/page.tsx` — shop v1 category page
- `frontend/app/[lang]/(cabinet)/shop2/page.tsx` — shop v2 home page
- `frontend/app/[lang]/(cabinet)/shop2/[category]/page.tsx` — shop v2 dynamic category page
- `frontend/app/[lang]/(cabinet)/shop2/pets2/page.tsx` — pets category (static)
- `frontend/app/[lang]/(cabinet)/shop2/pet-skins2/page.tsx` — pet skins category (static)
- `frontend/app/[lang]/(cabinet)/shop2/pilot-skins2/page.tsx` — pilot skins category (static)

### Staff Pages

- `frontend/app/[lang]/staff/layout.tsx` — staff panel layout with RBAC
- `frontend/app/[lang]/staff/admin/page.tsx` — admin panel
- `frontend/app/[lang]/staff/admin/advent-calendars/page.tsx` — advent calendar list (admin)
- `frontend/app/[lang]/staff/admin/advent-calendars/[id]/page.tsx` — advent calendar editor (admin)
- `frontend/app/[lang]/staff/advent-calendars/page.tsx` — advent calendar list
- `frontend/app/[lang]/staff/advent-calendars/[id]/page.tsx` — advent calendar editor
- `frontend/app/[lang]/staff/analytics/page.tsx` — analytics page
- `frontend/app/[lang]/staff/copywriting/layout.tsx` — copywriting sub-layout
- `frontend/app/[lang]/staff/copywriting/page.tsx` — copywriting dashboard
- `frontend/app/[lang]/staff/copywriting/content-plan/page.tsx` — content plan
- `frontend/app/[lang]/staff/copywriting/drafts/page.tsx` — drafts list
- `frontend/app/[lang]/staff/copywriting/drafts/[id]/page.tsx` — draft editor
- `frontend/app/[lang]/staff/copywriting/images/page.tsx` — image settings
- `frontend/app/[lang]/staff/copywriting/plans/page.tsx` — plans list
- `frontend/app/[lang]/staff/copywriting/posts/page.tsx` — posts list
- `frontend/app/[lang]/staff/copywriting/settings/page.tsx` — copywriting settings
- `frontend/app/[lang]/staff/copywriting/styles/page.tsx` — style management
- `frontend/app/[lang]/staff/exchange/page.tsx` — exchange management
- `frontend/app/[lang]/staff/finance/page.tsx` — finance page
- `frontend/app/[lang]/staff/logging/page.tsx` — logging dashboard
- `frontend/app/[lang]/staff/metrics/page.tsx` — metrics page
- `frontend/app/[lang]/staff/profile/page.tsx` — staff profile
- `frontend/app/[lang]/staff/shop/page.tsx` — shop admin page
- `frontend/app/[lang]/staff/support/page.tsx` — support/grant page
- `frontend/app/[lang]/staff/users/page.tsx` — users management

### API Routes

- `frontend/app/api/health/route.ts` — health check endpoint
- `frontend/app/api/cabinet/shop/_utils.ts` — shop API shared utilities
- `frontend/app/api/cabinet/shop/catalog/route.ts` — catalog listing endpoint
- `frontend/app/api/cabinet/shop/checkout/route.ts` — checkout endpoint
- `frontend/app/api/cabinet/shop/pets/route.ts` — pets listing endpoint
- `frontend/app/api/cabinet/shop/purchase/route.ts` — purchase endpoint
- `frontend/app/api/cabinet/shop/specials/route.ts` — specials listing endpoint
- `frontend/app/api/cabinet/shop/specials/free-reward/claim/route.ts` — free reward claim
- `frontend/app/api/cabinet/shop/storefront/route.ts` — storefront data endpoint
- `frontend/app/api/staff/copywriting/_auth.ts` — copywriting auth middleware
- `frontend/app/api/staff/copywriting/_utils.ts` — copywriting shared utilities
- `frontend/app/api/staff/copywriting/briefs/route.ts` — briefs CRUD
- `frontend/app/api/staff/copywriting/content-plan/route.ts` — content plan CRUD
- `frontend/app/api/staff/copywriting/drafts/route.ts` — drafts list/create
- `frontend/app/api/staff/copywriting/drafts/[id]/route.ts` — draft read/update/delete
- `frontend/app/api/staff/copywriting/drafts/[id]/generate-image/route.ts` — image generation trigger
- `frontend/app/api/staff/copywriting/drafts/[id]/generated-image/route.ts` — generated image serve
- `frontend/app/api/staff/copywriting/image-settings/route.ts` — image settings CRUD
- `frontend/app/api/staff/copywriting/image-settings/[id]/route.ts` — single image setting
- `frontend/app/api/staff/copywriting/image-settings/active/route.ts` — active image setting
- `frontend/app/api/staff/copywriting/image-settings/reference/route.ts` — reference image serve
- `frontend/app/api/staff/copywriting/image-settings/upload-reference/route.ts` — reference image upload
- `frontend/app/api/staff/copywriting/jobs/[id]/route.ts` — job status polling
- `frontend/app/api/staff/copywriting/plans/route.ts` — plans list/create
- `frontend/app/api/staff/copywriting/plans/[id]/items/route.ts` — plan items list/create
- `frontend/app/api/staff/copywriting/plans/[id]/items/[itemId]/route.ts` — plan item CRUD
- `frontend/app/api/staff/copywriting/publish/route.ts` — publish endpoint
- `frontend/app/api/staff/copywriting/publish-targets/route.ts` — publish targets list
- `frontend/app/api/staff/copywriting/publish-targets/[id]/route.ts` — single publish target
- `frontend/app/api/staff/copywriting/reference-posts/route.ts` — reference posts list
- `frontend/app/api/staff/copywriting/reference-posts/[id]/route.ts` — single reference post
- `frontend/app/api/staff/copywriting/reference-posts/import/route.ts` — import reference post
- `frontend/app/api/staff/copywriting/sources/route.ts` — sources list/create
- `frontend/app/api/staff/copywriting/sources/[id]/route.ts` — source CRUD
- `frontend/app/api/staff/copywriting/styles/route.ts` — styles list/create
- `frontend/app/api/staff/copywriting/styles/[id]/route.ts` — style CRUD
- `frontend/app/api/staff/copywriting/styles/active/route.ts` — active style

### Static File Serving

- `frontend/app/var/lib/copywriting/generated_images/[filename]/route.ts` — serves generated images
- `frontend/app/var/lib/copywriting/reference_images/[filename]/route.ts` — serves reference images

## frontend/modules/ — Feature Modules

### shop/ — Shop Module

Core files:
- `frontend/modules/shop/index.ts` — public exports barrel file
- `frontend/modules/shop/types.ts` — TypeScript type definitions for shop
- `frontend/modules/shop/api.ts` — shop API client functions
- `frontend/modules/shop/constants.ts` — shop constants
- `frontend/modules/shop/helpers.ts` — shop helper/utility functions
- `frontend/modules/shop/shop-home-data.ts` — shop home page category definitions and data
- `frontend/modules/shop/shop-mock-catalog.ts` — mock catalog data for development
- `frontend/modules/shop/shopScrollRestoration.ts` — scroll position restoration utility
- `frontend/modules/shop/showcase-utils.ts` — showcase utility functions (hashing, conditions, filtering)

Components:
- `frontend/modules/shop/components/ShopPage.tsx` — shop v1 main page
- `frontend/modules/shop/components/ShopHomePage.tsx` — shop v2 home page
- `frontend/modules/shop/components/ShopCategoryRoutePage.tsx` — dynamic category route handler
- `frontend/modules/shop/components/ShopCategoryContent.tsx` — category page content layout
- `frontend/modules/shop/components/ShopCategoryGrid.tsx` — catalog items grid
- `frontend/modules/shop/components/ShopCategorySearch.tsx` — search within category
- `frontend/modules/shop/components/ShopCategoryEmptyState.tsx` — empty category state
- `frontend/modules/shop/components/ShopCategoryPlaceholderPage.tsx` — placeholder for undefined categories
- `frontend/modules/shop/components/ShopDesktopCategoryModal.tsx` — desktop category navigation modal
- `frontend/modules/shop/components/ShopMobileCategoryMenu.tsx` — mobile category navigation menu
- `frontend/modules/shop/components/ShopMenu.tsx` — shop navigation menu
- `frontend/modules/shop/components/ShopSkeleton.tsx` — loading skeleton
- `frontend/modules/shop/components/ShopFeedback.tsx` — purchase feedback toast
- `frontend/modules/shop/components/ShopPetCard.tsx` — pet item card
- `frontend/modules/shop/components/ShopSkinCard.tsx` — skin item card
- `frontend/modules/shop/components/ShopProductDealCard.tsx` — product deal card
- `frontend/modules/shop/components/ShopStepPassCard.tsx` — step pass card
- `frontend/modules/shop/components/StepPassCard.tsx` — step pass card (alternate)
- `frontend/modules/shop/components/StepPassSection.tsx` — step pass section
- `frontend/modules/shop/components/ShopHomeSpecials.tsx` — home page specials section
- `frontend/modules/shop/components/CatalogSection.tsx` — catalog section container

Showcase components:
- `frontend/modules/shop/components/ShowcaseSection.tsx` — showcase section container (special offers)
- `frontend/modules/shop/components/ShowcaseOfferCard.tsx` — individual showcase offer card
- `frontend/modules/shop/components/ShowcaseHomePreview.tsx` — home page showcase preview (3 offers)
- `frontend/modules/shop/components/NewItemsSection.tsx` — new items section with NEW badges
- `frontend/modules/shop/components/CountdownTimer.tsx` — countdown timer component

Shared shop components:
- `frontend/modules/shop/components/shared/PriceTag.tsx` — price display tag
- `frontend/modules/shop/components/shared/PurchaseButton.tsx` — purchase action button
- `frontend/modules/shop/components/shared/SectionHeader.tsx` — section header component
- `frontend/modules/shop/components/shared/ShopItemCard.tsx` — generic shop item card

Styles:
- `frontend/modules/shop/components/shopHome.module.css` — shop home page styles
- `frontend/modules/shop/components/shopSections.module.css` — shop sections styles
- `frontend/modules/shop/components/showcase.module.css` — showcase section + card styles
- `frontend/modules/shop/components/showcaseHome.module.css` — home preview styles
- `frontend/modules/shop/components/newItems.module.css` — new items section styles
- `frontend/modules/shop/components/countdown.module.css` — countdown timer styles

Hooks:
- `frontend/modules/shop/hooks/useShopCatalog.ts` — catalog data fetching hook
- `frontend/modules/shop/hooks/useShopSpecials.ts` — specials/offers fetching hook
- `frontend/modules/shop/hooks/useShopTab.ts` — shop tab navigation hook
- `frontend/modules/shop/hooks/usePurchase.ts` — purchase flow hook
- `frontend/modules/shop/hooks/useSectionItemWindow.ts` — section item windowing hook
- `frontend/modules/shop/hooks/useShowcaseOffers.ts` — showcase offers rotation hook
- `frontend/modules/shop/hooks/useNewItems.ts` — new items detection hook
- `frontend/modules/shop/hooks/useCountdown.ts` — countdown timer hook

### i18n/ — Internationalization

- `frontend/modules/i18n/index.ts` — i18n exports
- `frontend/modules/i18n/types.ts` — i18n type definitions

### landing/ — Landing Page

- `frontend/modules/landing/index.ts` — landing exports
- `frontend/modules/landing/components/HeroSection.tsx` — hero section
- `frontend/modules/landing/components/CTASection.tsx` — call-to-action section
- `frontend/modules/landing/components/GamificationSection.tsx` — gamification section
- `frontend/modules/landing/components/GrowthSection.tsx` — growth section
- `frontend/modules/landing/components/InsightsSection.tsx` — insights section
- `frontend/modules/landing/components/LevelsSection.tsx` — levels section
- `frontend/modules/landing/components/ProductSection.tsx` — product section
- `frontend/modules/landing/components/QuoteSection.tsx` — quote section
- `frontend/modules/landing/components/ValuesSection.tsx` — values section

### layout/ — Shared Layout

- `frontend/modules/layout/index.ts` — layout exports
- `frontend/modules/layout/components/Header.tsx` — site header
- `frontend/modules/layout/components/Footer.tsx` — site footer

### logging/ — Logging Module

- `frontend/modules/logging/index.ts` — logging exports
- `frontend/modules/logging/api.ts` — logging API client
- `frontend/modules/logging/hooks.ts` — logging hooks
- `frontend/modules/logging/types.ts` — logging type definitions
- `frontend/modules/logging/components/LoggingDashboard.tsx` — main logging dashboard
- `frontend/modules/logging/components/LoggingFilters.tsx` — log filters
- `frontend/modules/logging/components/LoggingModuleTabs.tsx` — module tab navigation
- `frontend/modules/logging/components/LogEventsList.tsx` — events list
- `frontend/modules/logging/components/LogEventDetailPanel.tsx` — event detail panel
- `frontend/modules/logging/components/LogAlertsBell.tsx` — alerts bell icon
- `frontend/modules/logging/components/LogCountersSummary.tsx` — counters summary
- `frontend/modules/logging/components/LoggingCountersHost.tsx` — counters host component

### staff-shop/ — Staff Shop Admin

- `frontend/modules/staff-shop/index.ts` — staff shop exports
- `frontend/modules/staff-shop/shop-admin-api.ts` — shop admin API client
- `frontend/modules/staff-shop/shop-admin-types.ts` — shop admin type definitions
- `frontend/modules/staff-shop/components/ShopAdminPage.tsx` — shop admin page
- `frontend/modules/staff-shop/components/ShopListingEditor.tsx` — listing editor
- `frontend/modules/staff-shop/components/ShopListingTable.tsx` — listings table
- `frontend/modules/staff-shop/components/ShopBulkAddDialog.tsx` — bulk add dialog
- `frontend/modules/staff-shop/components/ShopHelpTooltip.tsx` — help tooltip
- `frontend/modules/staff-shop/components/ItemCatalogPicker.tsx` — item catalog picker
- `frontend/modules/staff-shop/components/ShopSpecialOfferQueue.tsx` — special offer queue
- `frontend/modules/staff-shop/components/ShopSpecialRewardPoolEditor.tsx` — reward pool editor

### staff-advent/ — Staff Advent Calendar Admin

- `frontend/modules/staff-advent/index.ts` — staff advent exports
- `frontend/modules/staff-advent/payment.ts` — advent payment utilities

### staff-item-catalog/ — Staff Item Catalog

- `frontend/modules/staff-item-catalog/index.ts` — catalog exports
- `frontend/modules/staff-item-catalog/catalog-api-types.ts` — catalog API types
- `frontend/modules/staff-item-catalog/catalog-api.ts` — catalog API client
- `frontend/modules/staff-item-catalog/catalog-types.ts` — catalog type definitions
- `frontend/modules/staff-item-catalog/catalog-utils.ts` — catalog utilities
- `frontend/modules/staff-item-catalog/components/StaffItemCatalogPicker.tsx` — item picker

### staff-support/ — Staff Support Module

- `frontend/modules/staff-support/index.ts` — support exports
- `frontend/modules/staff-support/support-api.ts` — support API client
- `frontend/modules/staff-support/support-types.ts` — support type definitions
- `frontend/modules/staff-support/components/SupportGrantPage.tsx` — grant page
- `frontend/modules/staff-support/components/SupportCatalogPicker.tsx` — catalog picker
- `frontend/modules/staff-support/components/SupportFulfillmentHistoryPanel.tsx` — fulfillment history

### staff-profile/ — Staff Profile

- `frontend/modules/staff-profile/index.ts` — staff profile exports

### users/ — User Management

- `frontend/modules/users/index.ts` — users exports
- `frontend/modules/users/components/UserDetail.tsx` — user detail view
- `frontend/modules/users/components/UsersTable.tsx` — users table
- `frontend/modules/users/components/RoleAssignDialog.tsx` — role assignment dialog

### terms/ — Terms & Policies

- `frontend/modules/terms/index.ts` — terms exports
- `frontend/modules/terms/components/TermsContent.tsx` — terms content renderer

### site-analytics/ — Site Analytics

- `frontend/modules/site-analytics/index.ts` — analytics exports

## Tests

- `frontend/__tests__/setup.ts` — vitest test setup
- `frontend/__tests__/proxy.test.ts` — proxy configuration tests
- `frontend/__tests__/modules/shop/` — shop module tests
  - `ShopCategoryRoutePage.test.tsx` — category route page tests
  - `ShopCategorySearch.test.tsx` — category search tests
  - `ShopDesktopCategoryModal.test.tsx` — desktop modal tests
  - `ShopHomePage.test.tsx` — home page tests
  - `ShopItemCard.test.tsx` — item card tests
  - `ShopMobileCategoryMenu.test.tsx` — mobile menu tests
  - `ShopPage.test.tsx` — shop page tests
  - `showcase-utils.test.ts` — showcase utility tests
  - `ShowcaseOfferCard.test.tsx` — showcase card tests
  - `ShowcaseSection.test.tsx` — showcase section tests
  - `StepPassCard.test.tsx` — step pass card tests
  - `useCountdown.test.ts` — countdown hook tests
  - `useNewItems.test.ts` — new items hook tests
  - `usePurchase.test.tsx` — purchase hook tests
  - `shopDictionaryFixture.ts` — test fixture for shop dictionary
- `frontend/__tests__/modules/staff/` — staff module tests
- `frontend/__tests__/modules/staff-advent/` — staff advent tests
- `frontend/__tests__/modules/staff-item-catalog/` — item catalog tests
- `frontend/__tests__/modules/staff-shop/` — staff shop tests
- `frontend/__tests__/modules/staff-support/` — staff support tests
- `frontend/__tests__/modules/users/` — user management tests
- `frontend/__tests__/modules/site-analytics/` — analytics tests
- `frontend/__tests__/shared/` — shared utility tests
