# Cabinet Shop Web

Updated: 2026-04-19
Status: implemented for multi-offer storefront rollout with guest external checkout

## Overview

The web cabinet shop now runs as a payment-ready storefront with a unified
catalog model:

`source entity -> shop item -> offer -> order/checkout -> grant/fulfillment`

Flow:

`Browser -> /api/cabinet/shop/* -> /v1/cabinet/shop/* -> diaverseapi/app/cabinet/shop`

The web storefront now supports:
- pets
- pet skins
- pilot skins
- Step Pass Basic
- Step Pass Pro

The storefront is now split by actor context:
- authenticated users keep the existing `XDV` checkout rail
- guest users see only external-capable offers
- guest external checkout is stored as pending state and transferred to the real account after Telegram login

## Current Scope

Included now:
- unified storefront with `items + offers`
- legacy compatibility for `/catalog` and `/purchase`
- offer-based checkout for XDV items
- guest storefront rendering for public cabinet routes
- guest external checkout with pending entitlement transfer on login
- Step Pass section with duration offers:
  - `1 month`
  - `3 months`
  - `6 months`
  - `12 months`
- frontend BFF routes for both legacy and v2 flows

Still deferred:
- YooKassa
- crypto checkout inside Shop runtime
- Shop adoption of the generic payment provider abstraction that Advent now uses
- cleanup/removal of legacy shop endpoints

Important scope note:
- Advent paid cells now use a separate cabinet-only `pay1time` integration in `diaverseapi/app/cabinet/{offers/advent,guest,payments/pay1time}`.
- Advent now also exercises a shared provider-neutral payments seam (`provider_code`, capability discovery, quote/status rendering helpers, provider registry in backend).
- That shared seam currently backs two hosted providers in Advent: `pay1time-sbp` and `zion-crypto`.
- Advent keeps provider-level choice only; for Zion the final coin/network choice happens on the provider-hosted checkout, not in `diaweb`.
- Shop may adopt the same seam later for external providers, yet this branch keeps Shop checkout behavior unchanged: authenticated `XDV` plus existing guest external-order transfer behavior only.

## Storefront Ownership

Source entity data remains in backend domain modules:
- `characters`
- `pet_skins`
- `pilot_skin`
- `market_products` for Step Pass product linkage

Web storefront metadata lives in `diaverseapi/app/cabinet/shop`:
- section placement
- sort order
- visibility
- badge/label metadata
- offer wiring
- offer availability state
- XDV price for XDV-capable offers

This keeps domain tables focused on canonical game/business entities while the
cabinet shop owns storefront presentation and channel-specific commerce rules.

## Data Model

### Shop items

`cab_shop_items` now represents storefront identity and presentation:
- section
- source type and source ref
- slug
- title/description/image overrides
- badge code
- visibility
- ordering

### Shop offers

`cab_shop_item_offers` represents concrete purchase options:
- `payment_kind`
- `offer_code`
- `offer_group`
- duration
- availability state
- display price
- optional XDV amount
- optional `market_product_id` / SKU linkage

Examples:
- a pet can have one XDV offer today and a future external offer later
- Step Pass Basic is one storefront item with four duration offers

### Shop orders

`cab_shop_orders` is the new purchase ledger:
- one row per checkout attempt
- status + idempotency
- payment kind
- balance snapshot for XDV purchases
- fulfillment payload

Legacy `cab_shop_purchases` remains part of the compatibility window. The shop
service dual-reads history so purchase counts and limits do not reset during the
rollout.

## Step Pass Modeling

Step Pass is now part of the same storefront instead of being a separate shop
concept.

Rules:
- section id: `passes`
- storefront items:
  - `basic`
  - `pro`
- offers are built from an allowlisted SKU registry, not from product title
  matching

Supported SKU mapping:
- `sub_fitness_pass_basic_1_month`
- `sub_fitness_pass_basic_3_month`
- `sub_fitness_pass_basic_6_month`
- `sub_fitness_pass_basic_12_month`
- `sub_fitness_pass_pro_1_month`
- `sub_fitness_pass_pro_3_month`
- `sub_fitness_pass_pro_6_month`
- `sub_fitness_pass_pro_12_month`

Active Step Pass state is resolved inside `cabinet/shop` through a normalized
entitlement resolver:
- subscription features are preferred
- personal/mobile-origin pass state is used only as a compatibility signal

This keeps the UI free from legacy subscription/payment ambiguity.

## API Surfaces

### New backend endpoints

- `GET /v1/cabinet/shop/storefront`
- `POST /v1/cabinet/shop/checkout`

### Legacy backend compatibility endpoints

- `GET /v1/cabinet/shop/catalog`
- `POST /v1/cabinet/shop/purchase`

Legacy endpoints are now adapter layers over the new storefront/checkout
service. They no longer own a separate business path.

### Frontend BFF endpoints

New v2 BFF routes:
- `GET /api/cabinet/shop/storefront`
- `POST /api/cabinet/shop/checkout`

Legacy BFF routes kept during compatibility window:
- `GET /api/cabinet/shop/catalog`
- `POST /api/cabinet/shop/purchase`

## Checkout Behavior

### XDV offers

XDV checkout is active now:
1. load selected offer
2. validate ownership / purchase limit / balance
3. create order row with idempotency
4. deduct XDV from canonical `BotUser` balance
5. grant item through internal non-committing grant helpers
6. complete order and refresh storefront state

### External offers

External offers now have two different behaviors depending on actor kind.

Authenticated user:
- external offers can stay modeled but are not the primary rail in the current web cabinet flow

Guest user:
- storefront filters to external-capable offers only
- BFF forwards guest cookies so backend guest-session state survives checkout
- `POST /checkout` creates a guest external order plus pending entitlement
- mock external completion returns a controlled success state that asks the user to sign in
- real grant/import happens only after Telegram login links the guest session to a real account

This keeps `XDV` auth-only while still allowing guest purchase capture without inventing fake users.

## Frontend Rendering Strategy

The frontend storefront still preserves the shop performance work:
- `all` is an overview, not a full render
- section tabs render incrementally in chunks
- chunk growth uses `IntersectionObserver`
- shop images use `next/image`

Current defaults:
- overview preview count: `6`
- section chunk size: `24`
- sentinel root margin: `240px 0px`

Guest UX details:
- guest success feedback in shop is persistent and includes a sign-in CTA
- post-login reconciliation clears cached guest storefront/advent data before redirecting back
- shop item cards and Step Pass cards now treat available external offers as real purchase CTAs instead of unconditional `coming_soon`

Step Pass uses its own section/card UI:
- one card per tier
- duration selector inside the card
- price/CTA update from selected offer

Implementation files:
- `frontend/modules/shop/api.ts`
- `frontend/modules/shop/types.ts`
- `frontend/modules/shop/components/ShopPage.tsx`
- `frontend/modules/shop/components/CatalogSection.tsx`
- `frontend/modules/shop/components/StepPassSection.tsx`
- `frontend/modules/shop/components/StepPassCard.tsx`
- `frontend/modules/shop/components/shared/ShopItemCard.tsx`
- `frontend/app/api/cabinet/shop/storefront/route.ts`
- `frontend/app/api/cabinet/shop/checkout/route.ts`

## Rollout Runbook

### Deployment order

1. Deploy backend schema + service changes in `diaverseapi`
2. Run cabinet shop sync/backfill command for offers and Step Pass rows
3. Smoke-test legacy backend endpoints:
   - `GET /v1/cabinet/shop/catalog`
   - `POST /v1/cabinet/shop/purchase` for an existing XDV item
4. Deploy frontend switch to storefront-v2 / checkout-v2
5. Smoke-test new BFF endpoints:
   - `GET /api/cabinet/shop/storefront`
   - `POST /api/cabinet/shop/checkout`
6. Verify guest storefront visibility on `/shop` without login
7. Verify guest external checkout success state and sign-in CTA
8. Verify authenticated `XDV` checkout still works

### Frontend-only rollback

If the new frontend needs rollback:
- revert frontend to the previous release
- keep backend compatibility window open
- legacy `/catalog` and `/purchase` continue serving old clients

### Backend rollback note

Backend rollback is safest before frontend cutover. After frontend cutover:
- do not remove compatibility endpoints
- keep additive schema in place during the rollback window
- prefer rolling back service behavior, not schema, unless data migration has
  been explicitly reversed

## Smoke Checklist

After rollout, verify:
- storefront loads in `/ru/shop` and `/en/shop`
- `pets`, `pet_skins`, `pilot_skins`, and `passes` tabs all render
- XDV item purchase still succeeds exactly once
- balance refresh still works after XDV purchase
- Step Pass Basic and Pro are visible
- duration selector switches offer/price on Step Pass cards
- guest external offer CTA is enabled when offer availability is `available`
- guest checkout success asks the user to sign in so the purchase can be attached to the account
- legacy `catalog` endpoint still responds
- legacy `purchase` endpoint still works for XDV item compatibility

## Verification Snapshot

Frontend:
- `npm.cmd run test -- --run __tests__/modules/shop/shop-api.test.ts __tests__/modules/shop/usePurchase.test.tsx __tests__/modules/shop/ShopItemCard.test.tsx __tests__/modules/shop/CatalogSection.test.tsx __tests__/modules/shop/ShopPage.test.tsx __tests__/modules/shop/StepPassCard.test.tsx __tests__/app/api/cabinet/shop/storefront-route.test.ts __tests__/app/api/cabinet/shop/checkout-route.test.ts`: passed
- `npm.cmd run lint`: passed with existing unrelated warnings outside shop scope
- `npm.cmd run build`: passed

Backend:
- `py -B -m py_compile` on changed `cabinet/shop` files and tests: passed
- backend tests were added for storefront-v2, compatibility adapters, Step Pass
  registry/resolution, and checkout behavior
- backend `pytest` run could not be executed in the current local Windows
  runtime because `pytest` is not installed there

## Residual Risks

- Backend verification is compile-level only in the current local environment;
  CI or server-side test runtime should execute the added backend tests.
- Shop external checkout remains intentionally unavailable until provider work starts.
- Advent `pay1time` rollout is separate and does not mean shop provider checkout is enabled.
- Legacy compatibility endpoints are still part of the rollout surface and
  should only be removed after production stabilization.
