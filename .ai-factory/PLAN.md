# AIF Fast Plan: Магазин, Crypton и бандлы через библиотеку

Дата: 2026-06-13
Режим: `fast`
Тип: multi-repo plan из workspace root
Статус: готов к реализации

## Цель

Довести shop library до единого price-book слоя для трех сценариев:

- публичный магазин продает петов с выбором эволюции в модалке покупки, но не выше 4-й эволюции;
- Crypton продает конечное количество штук, а не количество готовых наборов/офферов, с минимальной суммой заявки от `1 USDT`;
- бандлы собираются из library items, автоматически считают базовую цену по составу и позволяют задать итоговую цену со скидкой.

Ключевое продуктовое решение: продаваемая эволюция питомца является отдельным SKU библиотеки (`variant_key = evolution:N`), но покупательский UI группирует эти SKU как один питомец с выбором эволюции.

## Settings

- Testing: yes
- Logging: verbose
- Docs: yes
- Branch: none in fast mode
- Roadmap Linkage: none; `.ai-factory/ROADMAP.md` отсутствует
- Affected repositories: `diaverseapi`, `diaweb`
- Not affected: `diaverse-mobile`, `aibot`, `club10000-bot`, `diaverse-auth-bot`

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first through `scripts\gbrain.ps1`, then raw source verification
- Note: GBrain search did not find a current canonical page for `shop crypton bundle library`, and GBrain code lookup did not see fresh `CabShopLibraryItem`; source code is the final authority for this plan. Run targeted GBrain sync after implementation.

## Repository Matrix

| Repository | Path | Affected | Current branch | Current status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `main` | clean | library pricing, shop/Crypton/bundle backend contracts, migrations, tests |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `dev` | clean | staff UI, public shop modal, Crypton UI, BFF/types/tests |
| `diaverse-mobile` | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | `main` | clean | not in scope; Crypton/shop web flow is browser-facing |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | `dev` | clean | not in scope |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | `dev` | clean | not in scope |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | `dev` | clean | not in scope |

## Verified Source Context

Existing backend foundation:

- `diaverseapi/app/cabinet/shop/models.py`
  - `CabShopLibraryItem` exists with `source_type`, `source_ref`, `variant_key`, `base_quantity`, `base_price_amount`.
  - `CabShopItem.library_item_id` links storefront items to library rows.
  - `CabShopItemFulfillmentLine` stores bundle/configured reward lines.
- `diaverseapi/app/cabinet/shop/library_pricing.py`
  - `build_evolution_price_chain` already implements `+50%` evolution chain with manual overrides.
  - `derive_storefront_usdt_price` and `minimum_storefront_quantity_for_price` already compute unit price and minimum quantity for `1 USDT`.
  - Current storefront guard rejects below-floor quantity instead of silently raising price to `1 USDT`.
- `diaverseapi/app/cabinet/shop/library_admin_service.py`
  - library create/update/generate-evolution rows exist.
  - current allowed evolution options come from item catalog and may include E5-E7.
- `diaverseapi/app/cabinet/shop/service.py`
  - public storefront already calculates `bundle_savings_percent`.
  - public offer pricing already supports `display_price_amount` as base and `manual_discount_price_amount` as effective discount price.
- `diaverseapi/app/cabinet/offers/crypton/*`
  - current `offer_units_quantity` means number of shop offer copies, not final item quantity.
  - fulfillment multiplies configured lines by `offer_units_quantity`.
  - Crypton already supports pet evolution selection metadata, but price is not library evolution specific.

Existing frontend foundation:

- `diaweb/frontend/modules/staff-shop/components/ShopLibraryEditor.tsx`
  - supports pet evolution rows and manual prices.
- `diaweb/frontend/modules/staff-shop/components/ShopBundleCreateDialog.tsx`
  - currently picks bundle lines from fulfillment catalog/common catalog and asks for bundle price manually.
- `diaweb/frontend/modules/crypton/components/CryptonOfferBuilder.tsx`
  - currently shows quantity as units and sends `offerUnitsQuantity`.
- `diaweb/frontend/modules/staff-shop/components/CryptonRequestsPanel.tsx`
  - currently labels quantities as `наб.`.
- `diaweb/frontend/app/api/cabinet/shop/**/route.ts` and `diaweb/frontend/app/api/cabinet/offers/crypton/**/route.ts`
  - same-origin BFF routes proxy public shop, checkout, purchase, Crypton catalog, requests, and payment capabilities; payload aliases must be forwarded here.
- `diaweb/frontend/modules/shop/*`
  - public cards/payment modal already consume storefront offers and bundle items.
  - separate surfaces exist for `specials`, `category-deals`, `promo-offer`, and showcase offers; they must stay price/variant compatible with the main storefront.

Recent regression context:

- `.ai-factory/patches/2026-06-10-11.38.md`
  - character fulfillment previously ignored `quantity > 1`; this plan must explicitly test multi-quantity character and stackable grants in Crypton/bundles.
- `.ai-factory/patches/2026-06-11-17.58.md`
  - Alembic multiple-head regressions occurred recently; any new migration must be checked with `alembic heads` and a targeted `upgrade ... --sql`.

## Product Decisions

1. Library remains the single source of price truth for new shop, Crypton, and bundle flows.
2. A pet evolution is stored as a separate library SKU with `variant_key = evolution:N`.
3. Commerce sellability cap is E4, even if game/catalog supports E5-E7.
4. In public shop and Crypton, display the first-evolution price on the card and let the user choose E1-E4 in the buy/request modal.
5. Manual override per evolution must survive auto-regeneration; auto chain uses previous effective row price.
6. Crypton quantity means final amount to grant, not number of bundles/shop offers.
7. Crypton minimum quantity is derived from library unit price so total market value is at least `1 USDT`.
8. Bundle contents are selected from library items only for new/edited bundles.
9. Bundle base price is sum of library unit price times quantity for all lines.
10. Bundle discount price is optional; if empty, final price equals base price.
11. Bundle discount percent is calculated from base price and discount price and should be visible in staff UI and public cards.
12. Existing legacy rows remain readable; new UI paths should prefer library-backed flows.
13. Crypton new requests must snapshot quantity semantics, selected library/evolution identity, unit price, market total, and proposed price for audit; historical rows must not be silently reinterpreted.
14. Same-origin BFF route payloads, frontend normalizers, React Query invalidation, and i18n dictionaries are in scope wherever public/admin contracts change.
15. Variant-aware pricing applies to public storefront, authenticated storefront state, specials, category deals, promo offer, showcase cards, checkout, and purchase.
16. Staff bulk edit/listing edit must not let derived bundle base price or library-derived unit price drift; only the explicit discount/final price remains manually editable where allowed.

## Out Of Scope

- Selling pet evolutions above E4.
- Changing game evolution mechanics or max evolution data in `app/evolutions/config.py`.
- Full mobile app implementation.
- New payment providers.
- Reworking Crypton 30-day eligibility, popup timing, or decision lifecycle.
- Repricing historical paid orders or pending checkout sessions.
- Deleting legacy shop/Crypton fields immediately.

## Tasks

### Phase 1: Backend Commerce Evolution Policy

- [x] Task 1: Add a shared commerce sellability policy for pet evolutions.

  Deliverable: backend has one helper that returns sellable evolution options capped at E4 while preserving the full game/catalog options for non-commerce use.

  Expected behavior:
  - Add a commerce constant/helper such as `SHOP_MAX_SELLABLE_PET_EVOLUTION = 4`.
  - Filter library evolution generation and shop/Crypton variant exposure to `1..min(catalog_max, 4)`.
  - Reject create/update/generate requests for E5-E7 with a stable validation error.
  - Keep catalog metadata about full game max evolution unchanged.

  Files:
  - `diaverseapi/app/cabinet/shop/library_pricing.py` or a new `diaverseapi/app/cabinet/shop/evolution_policy.py`
  - `diaverseapi/app/cabinet/shop/library_admin_service.py`
  - `diaverseapi/app/cabinet/shop/admin_schemas.py`
  - `diaverseapi/app/cabinet/offers/crypton/service.py`
  - `diaverseapi/tests/test_cabinet_shop_library_pricing.py`
  - `diaverseapi/tests/test_cabinet_shop_admin.py`
  - `diaverseapi/tests/test_cabinet_crypton.py`

  Logging requirements:
  - DEBUG when full catalog options are reduced to commerce sellable options.
  - WARNING when staff/user requests an evolution above E4.
  - INFO when library evolution generation creates/updates sellable rows.

  Dependencies: none.

- [x] Task 2: Normalize library pet evolution rows as grouped commerce SKUs.

  Deliverable: library admin can create/generate E1-E4 rows as separate SKUs, manual prices remain explicit, and read responses expose enough grouping metadata for UI.

  Expected behavior:
  - Keep `variant_key = evolution:N` as the storage identity.
  - Add/standardize metadata fields: `evolution`, `evolution_group_ref`, `manual_price_override`, `commerce_max_evolution`.
  - Ensure auto price chain is `E(n) = previous effective E(n-1) * 1.5`, with manual overrides participating as the new previous effective price.
  - List/read responses should let frontend group all evolution SKUs for the same `source_ref`.

  Files:
  - `diaverseapi/app/cabinet/shop/library_admin_service.py`
  - `diaverseapi/app/cabinet/shop/admin_schemas.py`
  - `diaweb/frontend/modules/staff-shop/shop-admin-types.ts`
  - `diaverseapi/tests/test_cabinet_shop_admin.py`

  Logging requirements:
  - DEBUG for chain inputs/outputs and override detection.
  - INFO for generated/updated row counts per pet.
  - WARNING for missing catalog metadata or broken source refs.

  Dependencies: Task 1.

### Phase 2: Backend Public Shop Evolution Selection

- [x] Task 3: Extend shop storefront API to expose pet evolution variants from library-backed SKUs.

  Deliverable: public shop can render one pet card using E1 price and carry E1-E4 variant prices/options for the purchase modal.

  Expected behavior:
  - For library-backed character storefront items, group sibling active library/storefront variants by `source_type=character` and `source_ref`.
  - Keep E1 as the card/default variant when available.
  - Expose a compact variant payload such as `evolution_variants[]` with `shop_item_id`, `offer_id`, `evolution`, `price`, `compare_at_price`, `can_purchase`, and lock reason.
  - Apply the same variant-aware payload/price rules to public storefront, authenticated storefront state, specials, category deals, promo offer, and showcase-derived cards.
  - Preserve legacy behavior for non-library or single-variant items.
  - Ensure checkout/purchase uses the selected variant offer/item, not just the displayed E1 card.

  Files:
  - `diaverseapi/app/cabinet/shop/schemas.py`
  - `diaverseapi/app/cabinet/shop/service.py`
  - `diaverseapi/app/cabinet/shop/api.py`
  - `diaverseapi/app/cabinet/shop/specials/service.py`
  - `diaverseapi/app/cabinet/shop/category_deals/service.py`
  - `diaverseapi/app/cabinet/shop/promo_offer/service.py`
  - `diaverseapi/tests/test_cabinet_shop_service.py`
  - `diaverseapi/tests/test_cabinet_shop_api.py`
  - `diaverseapi/tests/test_cabinet_shop_specials.py`
  - `diaverseapi/tests/test_cabinet_shop_category_deals.py`
  - `diaverseapi/tests/test_cabinet_shop_promo_offer.py`

  Logging requirements:
  - DEBUG for grouping decisions and hidden variant reasons.
  - INFO when variant payload is built for a public pet card.
  - WARNING when E1 is missing but higher variants exist, or when selected variant checkout cannot be resolved.

  Dependencies: Tasks 1-2.

- [x] Task 4: Add backend guards for shop checkout with selected evolution variants.

  Deliverable: selected pet evolution purchase remains price-safe and grant-safe.

  Expected behavior:
  - Verify selected variant is active, purchasable, library-backed, and capped at E4.
  - Verify linked offer price matches derived library price before checkout/session creation.
  - Fulfillment line options must include `{"evolution": N}` for selected pet variant.
  - Pending checkout/order snapshots must not be recalculated after library price updates.

  Files:
  - `diaverseapi/app/cabinet/shop/service.py`
  - `diaverseapi/app/cabinet/shop/library_admin_service.py`
  - `diaverseapi/app/cabinet/fulfillment/handlers.py` only if current option propagation has a gap
  - `diaverseapi/tests/test_cabinet_shop_service.py`
  - `diaverseapi/tests/test_cabinet_fulfillment_service.py`

  Logging requirements:
  - INFO for selected evolution checkout initialization.
  - DEBUG for derived price comparison and fulfillment option propagation.
  - WARNING for stale offer drift, invalid selected evolution, or missing library link.

  Dependencies: Task 3.

### Phase 3: Backend Crypton Quantity And Library Pricing

- [x] Task 5: Change Crypton quantity semantics from offer units to final item quantity.

  Deliverable: Crypton request quantity means "сколько штук начислить" for stackable items, not "сколько наборов купить".

  Expected behavior:
  - Introduce API/read aliases such as `requested_quantity` while keeping `offer_units_quantity` as a backward-compatible storage field if avoiding a migration is preferable.
  - Decide explicitly during implementation whether to add new DB columns or store new audit fields in metadata; do not leave semantics implicit in `offer_units_quantity`.
  - Snapshot `quantity_semantics = final_item_quantity` for new requests.
  - Snapshot selected library item id, selected evolution, unit price, min quantity, market total, and source price kind for new requests.
  - For stackable configured lines, grant exactly requested quantity where the selected library item represents one unit.
  - For pets/skins, default min/max quantity remains `1`; if multi-pet purchase is intentionally enabled, fulfillment tests must assert one character is granted per requested unit.
  - Existing historical requests with old semantics remain readable and are labeled as legacy.
  - Admin list/detail, notifications, finance facts, checkout status, and payment session metadata must display/freeze final quantity semantics consistently.

  Files:
  - `diaverseapi/app/cabinet/offers/crypton/models.py`
  - `diaverseapi/app/cabinet/offers/crypton/schemas.py`
  - `diaverseapi/app/cabinet/offers/crypton/catalog_policy.py`
  - `diaverseapi/app/cabinet/offers/crypton/service.py`
  - `diaverseapi/app/cabinet/offers/crypton/fulfillment.py`
  - `diaverseapi/app/cabinet/offers/crypton/payment_facts.py`
  - `diaverseapi/app/cabinet/notifications/service.py`
  - `diaverseapi/tests/test_cabinet_crypton.py`
  - `diaverseapi/tests/test_cabinet_fulfillment_service.py`

  Logging requirements:
  - INFO when a new request is stored with `final_item_quantity` semantics.
  - DEBUG for quantity normalization and fulfillment quantity calculation.
  - WARNING when legacy request semantics are detected or an invalid quantity is rejected.

  Dependencies: Task 1.

- [x] Task 6: Make Crypton catalog and pricing library-backed.

  Deliverable: Crypton market price comes from library unit prices, pet evolution prices come from selected library SKU, and minimum quantity is computed from `1 USDT`.

  Expected behavior:
  - Prefer `CabShopItem.library_item_id` and `CabShopLibraryItem.base_price_amount/base_quantity` over shop offer bundle price for new Crypton catalog rows.
  - Return unit price, minimum quantity, maximum quantity, and market total using final quantity.
  - Include `quantity_input_mode`, unit label, and legacy/current semantics flags in read models so web clients do not infer meaning from old field names.
  - For pet cards, show E1 price by default and expose selectable E1-E4 variants with their library prices.
  - For stackable resources, compute `min_quantity = ceil(1 / unit_price)`.
  - Validate user proposed price against market total using selected evolution/quantity.
  - Keep legacy shop-offer fallback only for old/non-library rows, with warnings and tests.

  Files:
  - `diaverseapi/app/cabinet/offers/crypton/catalog_policy.py`
  - `diaverseapi/app/cabinet/offers/crypton/service.py`
  - `diaverseapi/app/cabinet/offers/crypton/schemas.py`
  - `diaverseapi/app/cabinet/shop/library_pricing.py`
  - `diaverseapi/tests/test_cabinet_crypton.py`

  Logging requirements:
  - DEBUG for selected price source: library, legacy shop offer fallback, or unavailable.
  - INFO for catalog rows with computed min quantity and market total.
  - WARNING for missing library price, non-positive unit price, below-minimum quantity, or requested evolution without library SKU.

  Dependencies: Tasks 2 and 5.

### Phase 4: Backend Library-Backed Bundles

- [x] Task 7: Add library identity to bundle fulfillment lines.

  Deliverable: new bundle lines can reference `CabShopLibraryItem` directly while legacy bundle lines remain readable.

  Expected behavior:
  - Add nullable `library_item_id` to `CabShopItemFulfillmentLine`.
  - Keep existing `item_type`, `item_ref`, `options_json`, and `snapshot_json` for fulfillment compatibility.
  - For new bundle lines, populate `item_type/item_ref/options_json` from the selected library item at save time.
  - Snapshot library title, variant key, unit price, quantity, and line total so existing bundles remain auditable after library edits.
  - Backfill is optional and best-effort; old bundle lines without library refs use legacy price lookup until edited.
  - Alembic revision must use short explicit index/FK names and chain from the current migration head at implementation time.

  Files:
  - `diaverseapi/app/cabinet/shop/models.py`
  - `diaverseapi/app/cabinet/shop/admin_schemas.py`
  - `diaverseapi/app/cabinet/shop/admin_service.py`
  - `diaverseapi/app/cabinet/shop/admin_api.py`
  - `diaverseapi/migrations/versions/*_bundle_lines_library_item.py`
  - `diaverseapi/migrations/env.py` if imports change
  - `diaverseapi/tests/test_alembic_graph.py`
  - `diaverseapi/tests/test_cabinet_shop_admin.py`

  Logging requirements:
  - INFO for bundle line creation/update with library item count.
  - DEBUG for library line hydration into fulfillment payload.
  - WARNING for legacy bundle lines without library refs and missing/broken library refs.

  Dependencies: Tasks 1-2.

- [x] Task 8: Calculate and persist bundle base price, discount price, and discount percent.

  Deliverable: bundle pricing is derived from library contents, with optional final discount price.

  Expected behavior:
  - Compute `base_price = sum(library_unit_price * quantity)` across all bundle lines.
  - Recompute base price on the server from persisted library/line data and ignore any client-supplied base amount except as a debug/audit hint.
  - Set default offer `display_price_amount = base_price`.
  - If staff enters discount price, set `manual_discount_is_active=true` and `manual_discount_price_amount=discount_price`; otherwise disable manual discount.
  - Calculate discount percent from base vs discount and keep public `bundle_savings_percent` aligned.
  - Store enough pricing snapshot metadata on the bundle offer/lines to explain current base, discount, and percent in admin detail screens.
  - Remove legacy pet evolution multipliers as primary source; keep only explicit warning fallback for old lines without library price.
  - Protect derived bundle base price from later generic listing/bulk edit mutations; bundle edits must go through the bundle modal/pricing recalculation path.

  Files:
  - `diaverseapi/app/cabinet/shop/admin_service.py`
  - `diaverseapi/app/cabinet/shop/bundle_savings.py`
  - `diaverseapi/app/cabinet/shop/service.py`
  - `diaverseapi/app/cabinet/shop/admin_schemas.py`
  - `diaverseapi/tests/test_cabinet_shop_admin.py`
  - `diaverseapi/tests/test_cabinet_shop_bundle_savings.py`
  - `diaverseapi/tests/test_cabinet_shop_service.py`

  Logging requirements:
  - DEBUG for each bundle line unit price, quantity, line total, and selected price source.
  - INFO for base price and discount percent recalculation.
  - WARNING for missing library price, discount price below `1 USDT`, discount price greater/equal base price, or legacy multiplier fallback.

  Dependencies: Task 7.

### Phase 5: Frontend Staff UI

- [x] Task 9: Update staff library UI for grouped pet evolution pricing and E4 cap.

  Deliverable: staff sees and edits pet evolution prices as a grouped table capped at E4.

  Expected behavior:
  - `ShopLibraryEditor` shows E1-E4 rows only, even if catalog metadata exposes E5-E7.
  - Manual override fields are clearly shown per evolution.
  - Generated rows use the backend chain and refresh the grouped table.
  - Errors for above-E4 selection are mapped to a clear staff message.

  Files:
  - `diaweb/frontend/modules/staff-shop/components/ShopLibraryEditor.tsx`
  - `diaweb/frontend/modules/staff-shop/components/ShopLibraryTable.tsx`
  - `diaweb/frontend/modules/staff-shop/shop-pet-evolution.ts`
  - `diaweb/frontend/modules/staff-shop/shop-admin-types.ts`
  - `diaweb/frontend/modules/staff-shop/shop-admin-api.ts`
  - `diaweb/frontend/__tests__/modules/staff-shop/ShopLibraryEditor.test.tsx`

  Logging requirements:
  - DEBUG in development for grouped evolution rows and auto-generated price previews.
  - WARNING in development for malformed backend variant payloads.
  - No user IDs, tokens, or payment URLs in logs.

  Dependencies: Tasks 1-2.

- [x] Task 10: Rebuild bundle creation/editing UI around library items.

  Deliverable: staff bundle dialog picks contents from library, shows line prices, computes base price, and accepts optional discount price.

  Expected behavior:
  - Replace fulfillment catalog picker with library picker.
  - For each selected library item show title, evolution if any, unit price, quantity, and line total.
  - Base price is read-only and updates live.
  - Add field `Цена со скидкой`; if empty, final price is base price.
  - Show calculated discount percent next to the discount field.
  - Payload sends `library_item_id` per line and pricing payload according to backend contract.
  - Invalidate staff shop list, library-backed bundle catalog, public shop, specials, category deal, and promo-offer query keys after bundle save.
  - Adjust `ShopListingEditor` and `ShopBulkEditDialog` so derived bundle/library pricing cannot be accidentally overwritten through generic edit paths.

  Files:
  - `diaweb/frontend/modules/staff-shop/components/ShopBundleCreateDialog.tsx`
  - `diaweb/frontend/modules/staff-shop/components/ItemCatalogPicker.tsx` or a new library picker component if needed
  - `diaweb/frontend/modules/staff-shop/components/ShopListingEditor.tsx`
  - `diaweb/frontend/modules/staff-shop/components/ShopBulkEditDialog.tsx`
  - `diaweb/frontend/modules/staff-shop/components/ShopAdminPage.tsx`
  - `diaweb/frontend/modules/staff-shop/shop-admin-types.ts`
  - `diaweb/frontend/modules/staff-shop/shop-admin-api.ts`
  - `diaweb/frontend/__tests__/modules/staff-shop/ShopBundleCreateDialog.test.tsx`

  Logging requirements:
  - DEBUG in development for base price recomputation and line hydration.
  - WARNING in development for missing library price or invalid discount input.
  - No sensitive payment/session data in logs.

  Dependencies: Tasks 7-8.

- [x] Task 11: Update staff Crypton requests/admin UI for final quantity semantics.

  Deliverable: staff no longer sees `наб.` for Crypton requests and can audit quantity, unit price, market total, selected evolution, and proposed price.

  Expected behavior:
  - Replace labels like `наб.` with `шт.` or item-specific unit label.
  - Show `unit_price`, `requested_quantity`, `market_total`, `selected_evolution`.
  - Preserve legacy request display with a clear "старый формат" marker if historical rows use old semantics.
  - Approve/counter decisions continue to work on total USDT price.
  - Ensure request list/detail normalizers read both new aliases and legacy `offer_units_quantity` safely.

  Files:
  - `diaweb/frontend/modules/staff-shop/components/CryptonRequestsPanel.tsx`
  - `diaweb/frontend/modules/staff-shop/crypton-admin-types.ts`
  - `diaweb/frontend/modules/staff-shop/crypton-admin-api.ts`
  - `diaweb/frontend/__tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx`

  Logging requirements:
  - DEBUG in development for request normalization and legacy/current semantics.
  - WARNING in development for malformed quantity or price payload.
  - No user-sensitive payment details in logs.

  Dependencies: Tasks 5-6.

### Phase 6: Frontend Buyer UI

- [x] Task 12: Add pet evolution selection to public shop purchase modal.

  Deliverable: buyer sees E1 price on card and chooses E1-E4 in the buy modal with correct selected price.

  Expected behavior:
  - Extend shop API normalization/types with `evolutionVariants`.
  - Update BFF route tests so public/authenticated storefront and purchase/checkout proxy new fields without stripping them.
  - Render evolution control only for pet items with variants.
  - Update selected offer/item when evolution changes.
  - Payment modal displays selected evolution price and sends selected offer/item to checkout.
  - Legacy single-variant items behave as before.

  Files:
  - `diaweb/frontend/app/api/cabinet/shop/storefront/route.ts`
  - `diaweb/frontend/app/api/cabinet/shop/storefront/public/route.ts`
  - `diaweb/frontend/app/api/cabinet/shop/checkout/route.ts`
  - `diaweb/frontend/app/api/cabinet/shop/purchase/route.ts`
  - `diaweb/frontend/modules/shop/api.ts`
  - `diaweb/frontend/modules/shop/types.ts`
  - `diaweb/frontend/modules/shop/components/ShopPaymentModal.tsx`
  - `diaweb/frontend/modules/shop/components/ShopPetCard.tsx`
  - `diaweb/frontend/modules/shop/components/shared/ShopItemCard.tsx`
  - `diaweb/frontend/__tests__/app/api/cabinet/shop/storefront-route.test.ts`
  - `diaweb/frontend/__tests__/app/api/cabinet/shop/public-storefront-route.test.ts`
  - `diaweb/frontend/__tests__/app/api/cabinet/shop/checkout-route.test.ts`
  - `diaweb/frontend/__tests__/app/api/cabinet/shop/purchase-route.test.ts`
  - `diaweb/frontend/__tests__/modules/shop/ShopPaymentModal.test.tsx`

  Logging requirements:
  - DEBUG in development for variant selection and selected offer changes.
  - WARNING in development for missing selected variant or inconsistent backend payload.
  - No checkout redirect URLs or tokens in logs.

  Dependencies: Tasks 3-4.

- [x] Task 13: Update Crypton buyer UI to request final item quantity and selected evolution price.

  Deliverable: Crypton user inputs the exact amount they want to buy, sees minimum quantity, and pet evolution selection changes market price correctly.

  Expected behavior:
  - Rename UI labels from bundle/offer units to item quantity.
  - Enforce backend-provided `minQuantity` client-side.
  - Show unit price, minimum quantity, market total, and recommended price.
  - For pets, choosing E1-E4 updates market total from selected library variant price.
  - Submit payload uses new quantity alias while keeping compatibility with current BFF until backend is changed.
  - Update ru/en dictionaries and `crypton-i18n` coverage for the new quantity/minimum copy.
  - Update BFF request route tests to forward `requested_quantity` and retain legacy compatibility where needed.

  Files:
  - `diaweb/frontend/app/api/cabinet/offers/crypton/catalog/route.ts`
  - `diaweb/frontend/app/api/cabinet/offers/crypton/requests/route.ts`
  - `diaweb/frontend/modules/crypton/types.ts`
  - `diaweb/frontend/modules/crypton/api.ts`
  - `diaweb/frontend/modules/crypton/shopCatalogAdapter.ts`
  - `diaweb/frontend/modules/crypton/components/CryptonOfferBuilder.tsx`
  - `diaweb/frontend/modules/crypton/components/CryptonOfferModal.tsx`
  - `diaweb/frontend/modules/i18n/dictionaries/ru.json`
  - `diaweb/frontend/modules/i18n/dictionaries/en.json`
  - `diaweb/frontend/__tests__/app/api/cabinet/offers/crypton/route.test.ts`
  - `diaweb/frontend/__tests__/modules/crypton/CryptonOfferBuilder.test.tsx`
  - `diaweb/frontend/__tests__/modules/crypton/crypton-i18n.test.ts`

  Logging requirements:
  - DEBUG in development for quantity validation and selected evolution market price.
  - WARNING in development for backend min quantity conflicts or malformed variant data.
  - No checkout redirect URLs, payment session IDs, or tokens in logs.

  Dependencies: Tasks 5-6.

- [x] Task 14: Ensure public bundle cards display library-derived discount correctly.

  Deliverable: public bundle cards continue to show price and "выгода" percent, but now the percent is based on library-derived base and discount price.

  Expected behavior:
  - Consume backend `discount_percent` and/or `bundle_savings_percent` consistently.
  - Do not show negative savings.
  - Keep existing bundle details/flip behavior intact.
  - Ensure uploaded bundle image behavior remains unchanged.
  - Verify showcase, category deals, specials, and promo-offer cards do not regress when the selected offer has library-derived base/discount pricing.

  Files:
  - `diaweb/frontend/modules/shop/api.ts`
  - `diaweb/frontend/modules/shop/showcase-utils.ts`
  - `diaweb/frontend/modules/shop/hooks/useShowcaseOffers.ts`
  - `diaweb/frontend/modules/shop/components/ShopCategoryBundleCard.tsx`
  - `diaweb/frontend/modules/shop/components/ShowcaseOfferCard.tsx`
  - `diaweb/frontend/modules/shop/components/ShopPromoOfferModal.tsx`
  - `diaweb/frontend/modules/shop/components/shared/bundle-card-helpers.ts`
  - `diaweb/frontend/__tests__/modules/shop/ShopCategoryBundleCard.test.tsx`
  - `diaweb/frontend/__tests__/modules/shop/showcase-utils.test.ts`
  - `diaweb/frontend/__tests__/modules/shop/ShopPromoOfferModal.test.tsx`

  Logging requirements:
  - DEBUG in development only for bundle price/savings normalization.
  - WARNING in development for invalid percent payloads.
  - No sensitive data in logs.

  Dependencies: Tasks 8 and 10.

### Phase 7: Verification, Docs, And Knowledge Sync

- [x] Task 15: Add focused backend regression tests and migration checks.

  Deliverable: pricing, quantity, evolution cap, bundle base/discount, and legacy compatibility are covered by backend tests.

  Expected behavior:
  - Test E5-E7 rejected for commerce sale while catalog can still expose them.
  - Test E1-E4 chain and manual overrides.
  - Test shop modal variant payload and checkout selected evolution guard.
  - Test specials/category-deals/promo-offer/showcase-compatible backend payloads for variant-aware prices.
  - Test Crypton final quantity semantics, min quantity, selected evolution pricing, fulfillment quantities, and legacy read behavior.
  - Test Crypton admin detail/list, notifications, finance facts, and checkout/payment metadata use final quantity semantics.
  - Test bundle library lines, base price calculation, optional discount, percent, and legacy fallback warning.
  - Test `quantity > 1` fulfillment explicitly for stackable rewards and any enabled multi-pet path.
  - Test Alembic graph and SQL DDL for any new migration.

  Verification commands:
  ```powershell
  cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
  .\.venv\Scripts\python.exe -m pytest tests/test_cabinet_shop_library_pricing.py tests/test_cabinet_shop_admin.py tests/test_cabinet_shop_service.py tests/test_cabinet_shop_api.py -q
  .\.venv\Scripts\python.exe -m pytest tests/test_cabinet_shop_specials.py tests/test_cabinet_shop_category_deals.py tests/test_cabinet_shop_promo_offer.py -q
  .\.venv\Scripts\python.exe -m pytest tests/test_cabinet_crypton.py tests/test_cabinet_shop_bundle_savings.py tests/test_cabinet_fulfillment_service.py -q
  .\.venv\Scripts\python.exe -m pytest tests/test_cabinet_payment_sessions.py tests/test_cabinet_prodamus_payments.py -q
  .\.venv\Scripts\python.exe -m pytest tests/test_alembic_graph.py -q
  .\.venv\Scripts\python.exe -m alembic heads
  .\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
  .\.venv\Scripts\python.exe -m ruff check app/cabinet/shop app/cabinet/offers/crypton tests
  ```

  Logging requirements:
  - Tests should assert key warning paths where existing test patterns support it.
  - Test logs must not include tokens, checkout URLs, raw payment provider payloads, or private user data.

  Dependencies: Tasks 1-8.

- [x] Task 16: Add focused frontend tests, typecheck, and browser smoke.

  Deliverable: staff and buyer UI changes are covered and manually smoke-tested in browser.

  Expected behavior:
  - Staff library tests cover E4 cap and manual overrides.
  - Staff bundle dialog tests cover library picker, live base price, discount price, percent.
  - Staff shop admin tests cover bulk/listing guards and cache invalidation after bundle/library changes.
  - Staff Crypton tests cover quantity label and legacy marker.
  - Public shop tests cover pet evolution selection in purchase modal.
  - Shop BFF route tests cover storefront/checkout/purchase proxying of new variant fields.
  - Crypton buyer tests cover min quantity and selected evolution price.
  - Crypton BFF route tests cover `requested_quantity` forwarding and legacy alias fallback.
  - i18n tests cover new Russian/English quantity/minimum strings.
  - Bundle card tests cover percent display with no negative savings.
  - Showcase/promo tests cover library-derived discount percent.

  Verification commands:
  ```powershell
  cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
  npm test -- __tests__/modules/staff-shop/ShopLibraryEditor.test.tsx __tests__/modules/staff-shop/ShopBundleCreateDialog.test.tsx __tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx __tests__/modules/staff-shop/ShopAdminPage.test.tsx
  npm test -- __tests__/app/api/cabinet/shop/storefront-route.test.ts __tests__/app/api/cabinet/shop/public-storefront-route.test.ts __tests__/app/api/cabinet/shop/checkout-route.test.ts __tests__/app/api/cabinet/shop/purchase-route.test.ts
  npm test -- __tests__/app/api/cabinet/offers/crypton/route.test.ts __tests__/modules/crypton/CryptonOfferBuilder.test.tsx __tests__/modules/crypton/CryptonOfferModal.test.tsx __tests__/modules/crypton/crypton-i18n.test.ts
  npm test -- __tests__/modules/shop/ShopPaymentModal.test.tsx __tests__/modules/shop/ShopCategoryBundleCard.test.tsx __tests__/modules/shop/showcase-utils.test.ts __tests__/modules/shop/ShopPromoOfferModal.test.tsx
  npm run typecheck
  ```

  Browser smoke:
  ```text
  Open http://localhost:3000/ru/staff/shop
  Verify library pet E1-E4 rows only
  Create/edit bundle from library rows and see base/discount percent
  Open public shop pet card and select E1-E4 in buy modal
  Open Crypton flow and enter final quantity, not bundle count
  Verify min quantity message when total is below 1 USDT
  ```

  Logging requirements:
  - Frontend dev logs may include item IDs and reason codes.
  - Frontend logs must not include checkout redirect URLs, payment tokens, auth tokens, or raw private payloads.

  Dependencies: Tasks 9-14.

- [x] Task 17: Update docs/daily and run targeted GBrain sync. Skipped by user request on 2026-06-15: no additional daily or GBrain updates.

  Deliverable: workspace knowledge reflects the new commerce source-of-truth decision.

  Expected behavior:
  - Update docs only if implementation changes public/staff behavior in a way operators need to know.
  - Add daily work entry in Russian with safe public digest and internal log.
  - Run targeted/full GBrain sync because current GBrain code lookup missed fresh library symbols.

  Files:
  - `docs/features/cabinet/shop-web.md` or a new commerce note if needed
  - `docs/tasks/crypton.md` only if the task brief needs corrected semantics
  - `docs/tasks/bundle.md` only if the task brief needs corrected source-of-truth notes
  - `docs/daily/YYYY-MM-DD-safiu.md`

  Verification command:
  ```powershell
  cd C:\Users\Indigo\Desktop\diaverse
  powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1
  ```

  Logging requirements:
  - Public digest must avoid secrets, raw provider payloads, internal IPs, SSH commands, tokens, and private infrastructure details.
  - Internal log may include file paths and verification commands, but no secrets.

  Dependencies: Tasks 15-16.

## Commit Plan

Fast mode does not create branches, but the implementation should commit per affected child repository if/when requested.

- **Commit 1 (`diaverseapi`)** after Tasks 1-4: `feat: support library pet evolution variants`
- **Commit 2 (`diaverseapi`)** after Tasks 5-8 and 15: `feat: use library pricing for crypton and bundles`
- **Commit 3 (`diaweb`)** after Tasks 9-14 and 16: `feat: wire library pricing into shop staff flows`
- **Commit 4 (`diaverse`)** after Task 17 if docs/AIF changed: `docs: plan commerce library pricing rollout`

## Risks And Guards

- **Pricing drift:** checkout must verify selected library-derived price before creating new sessions.
- **Historical Crypton requests:** old `offer_units_quantity` rows may mean bundle count; mark/read them as legacy rather than reinterpreting silently.
- **Pet evolution over-sale:** do not rely only on frontend filters; backend must reject E5-E7 commerce selections.
- **Bundle discount abuse:** discount price cannot be below `1 USDT` and cannot be greater/equal to base price if discount is active.
- **Legacy bundle lines:** keep fallback readable, but log warnings and prefer library-backed lines for edited/new bundles.
- **Public API compatibility:** existing shop cards and BFF routes must keep working for non-library and single-variant items.
- **BFF field loss:** diaweb API routes can silently strip/rename request and response fields; add route tests for shop and Crypton aliases.
- **Showcase/promo drift:** specials, category deals, promo offer, and showcase cards are separate price surfaces; they must consume the same variant/base/discount data as storefront cards.
- **Fulfillment quantity regression:** character grants previously ignored `quantity > 1`; regression tests must cover multi-quantity grants where allowed.
- **Alembic head drift:** new migrations must chain from the current head and pass `alembic heads` before implementation is considered done.
- **Generic staff edits:** bulk/listing editors can bypass bundle recalculation unless guarded; bundle base price must remain server-derived.
- **GBrain staleness:** source code currently contains symbols that GBrain did not find; sync after implementation.

## Next Step

Run `/aif-implement` from `C:\Users\Indigo\Desktop\diaverse` to execute this fast plan.
