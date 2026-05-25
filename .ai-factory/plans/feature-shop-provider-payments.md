# Implementation Plan: Shop Provider Payments

Branch: feature/shop-provider-payments
Created: 2026-05-02

## Settings
- Testing: yes
- Logging: verbose
- Docs: yes

## Workspace Mode
- Mode: multi-repo full
- Workspace root: C:\Users\Indigo\Desktop\diaverse
- Shared graph: C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json
- Plan file: C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\feature-shop-provider-payments.md

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes | feature/shop-provider-payments | clean, with global git ignore warning | frontend and BFF |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes | feature/shop-provider-payments | clean, with global git ignore warning | backend payments and shop domain |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | no | unchanged | not checked | copywriting service |

## Research Context
Source: current user request, Graphify report, and source verification.

Goal:
- Move cabinet shop purchases from the active XDV checkout flow to the shared cabinet payment flow used by Advent.
- The shop buy button opens an in-place payment method modal, then the user chooses one of all three provider methods: Pay1Time SBP, Zion Crypto, or Prodamus Hosted.
- The shop must show the canonical item price as USDT.
- Future DCR wallet payment is known but out of scope for this implementation.

Constraints:
- Do not treat the workspace root as a git repository.
- Keep changes inside `diaweb` and `diaverseapi`.
- Use `CabinetPaymentSession(domain_code="shop")` instead of adding a shop-only provider integration.
- Fulfill shop items only after provider-confirmed paid status and domain finalization.
- Remove XDV from the active shop user/admin surface and checkout lifecycle. Legacy DB columns may remain only as deprecated migration residue if dropping them in this release is unsafe; no active code path may use XDV for pricing, balance checks, checkout, fulfillment, or staff editing.
- Do not implement DCR balance, DCR top-up, or DCR checkout in this plan.
- Do not change the finance/revenue module in this plan.

Key source findings:
- `diaverseapi/app/cabinet/payments/types.py` already allows `domain_code="shop"`.
- `diaverseapi/app/cabinet/payments/finalizers.py` currently registers `DeferredCabinetPaymentFinalizer("shop")`.
- `diaverseapi/app/cabinet/payments/registry.py` defaults providers to Advent-only domain support.
- Current quote strategies are Advent/USD/RUB oriented. Shop USDT pricing needs explicit source currency normalization before provider quote creation.
- `diaverseapi/app/cabinet/shop/service.py` currently completes authenticated checkout by deducting XDV and immediately calling `_grant_item`.
- `diaverseapi/app/cabinet/shop/models.py` already has `CabShopOrder`, which is the right business ledger for external provider payments.
- `diaweb/frontend/modules/payments` already has provider capability, quote display, and hosted/crypto payment helper types.
- `diaweb/frontend/modules/shop` currently calls `usePurchase()` directly and defaults storefront prices to XDV.

Open assumptions:
- Initial implementation handles authenticated shop checkout through all three external providers.
- Guest shop checkout must not keep the current mock-paid behavior. If real guest checkout is not explicitly requested during implementation, guests should receive login-required/unavailable behavior instead of a fake completed purchase.
- Existing XDV numeric prices cannot be safely converted to USDT without a product decision. Implementation should use `display_price_amount/display_price_currency` as the source of truth and only allow checkout when the active offer price is explicitly USDT.
- Legacy XDV offers must be hidden, blocked, or marked unavailable until they are migrated to explicit USDT prices.
- Finance dashboards, finance APIs, and revenue reporting are intentionally untouched.

## Acceptance Criteria
- Shop product cards and special offer cards no longer perform direct XDV purchase mutations.
- Buy action opens a shop payment modal that lists all available provider methods returned by backend capabilities.
- Modal displays the item amount as USDT before checkout starts.
- Checkout creates or reuses a `CabinetPaymentSession` with `domain_code="shop"` and a linked `CabShopOrder`.
- Pay1Time, Zion, and Prodamus all support `shop` in capability resolution and generic checkout initialization.
- Provider callback or status reconciliation finalizes paid shop sessions and grants the purchased item exactly once.
- Duplicate callbacks, repeated status polling, and idempotency replays do not double-grant items.
- XDV labels, XDV request/response fields, XDV balance-gated behavior, and XDV staff editing affordances are removed from the active shop storefront and staff shop screens.
- Shop checkout/status reads enforce actor ownership and do not expose another user's public checkout reference.
- Shop checkout rejects providers that are disabled, unsupported for `shop`, or unsupported for the current actor kind.
- Shop payment return/fail/processing URLs are generated server-side from trusted configuration and locale context, not accepted from arbitrary client input.
- Advent payment behavior remains unchanged.
- Finance module behavior remains unchanged.

## Commit Plan
- Commit 1, after tasks 1-5: `feat(api): add shop payment session contracts`
- Commit 2, after tasks 6-10: `feat(api): implement provider-backed shop checkout`
- Commit 3, after tasks 11-17: `feat(web): add shop payment modal and status flow`
- Commit 4, after tasks 18-20: `test: cover shop provider payment migration`

## Tasks

### Phase 1: Backend Payment Contract and Pricing Safety

- [x] Task 1: Add shop payment API contracts and provider selection.
  - Deliverable: `ShopCheckoutRequest` accepts `provider_code`; `ShopCheckoutResponse` carries generic payment fields needed by the frontend: `payment_session_id`, `payment_status`, `finalization_status`, `public_checkout_reference`, `redirect_url`, `return_url`, `fail_url`, `processing_url`, `expires_at`, `payment_payload`, and `payment_quote`.
  - Expected behavior: authenticated checkout returns `action_required` for provider checkout, not `completed`, until provider payment is confirmed.
  - Files: `diaverseapi/app/cabinet/shop/schemas.py`, `diaverseapi/app/cabinet/shop/api.py`, `diaverseapi/app/cabinet/shop/exceptions.py`.
  - Logging requirements: log provider selection, actor kind, offer id, idempotency key, and response status at INFO; log malformed or unsupported provider requests at WARN; do not log raw provider secrets or payer PII.
  - Dependencies: none.

- [x] Task 2: Add shop payment capabilities and status endpoints with ownership hardening.
  - Deliverable: add `GET /v1/cabinet/shop/payment-capabilities` and `GET /v1/cabinet/shop/checkout/{public_checkout_reference}`.
  - Expected behavior: capabilities return all three provider methods subject to feature flags and actor support; status endpoint reconciles in-progress sessions and finalizes paid sessions when possible; status reads are allowed only for the actor that owns the linked shop order/session.
  - Files: `diaverseapi/app/cabinet/shop/api.py`, `diaverseapi/app/cabinet/shop/schemas.py`, `diaverseapi/app/cabinet/payments/contracts.py` if shared read contracts need reuse/export.
  - Logging requirements: log capability resolution by domain, actor, default provider, total methods, selectable methods at DEBUG/INFO; log status reads with public reference, user id, provider, payment status, and finalization status at INFO; log ownership denials at WARN without leaking the owner id to the caller; log reconciliation failures as non-fatal WARN with session id and trigger.
  - Dependencies: Task 1.

- [x] Task 3: Enable the shop domain for all three provider registrations and add USDT quote normalization.
  - Deliverable: Pay1Time SBP, Zion Crypto, and Prodamus Hosted registrations support `domain_codes=("advent", "shop")`; quote creation accepts explicit shop source amounts priced in USDT and normalizes them through a shared quote path before provider-specific quote creation.
  - Expected behavior: backend capabilities show all enabled/visible providers for `domain_code="shop"`; Pay1Time and Prodamus can quote USDT-priced shop offers through the existing USD-to-RUB conversion behavior; Zion can quote USDT-priced shop offers without rejecting the source currency; Advent USD behavior remains unchanged.
  - Implementation notes: preserve the source display currency as USDT in shop payment responses and metadata; if a provider requires USD internally, map USDT to USD-parity for provider quote math in a single helper instead of scattering string checks across strategies.
  - Files: `diaverseapi/app/cabinet/payments/registry.py`, `diaverseapi/app/cabinet/payments/quotes/base.py`, `diaverseapi/app/cabinet/payments/quotes/pay1time.py`, `diaverseapi/app/cabinet/payments/quotes/zion.py`, `diaverseapi/app/cabinet/payments/quotes/prodamus.py`, `diaverseapi/tests/test_cabinet_payment_fx.py`, provider-specific payment tests.
  - Logging requirements: change Advent-only quote log messages to generic cabinet quote messages where the strategy is reused; include `domain_code`, `source_currency`, `provider_currency`, provider code, and quote expiry at DEBUG/INFO; log unsupported currency as WARN with domain and provider.
  - Dependencies: Task 1.

- [x] Task 4: Link shop orders to generic payment sessions with an Alembic migration.
  - Deliverable: `CabShopOrder` can reference its `CabinetPaymentSession` explicitly through a nullable `payment_session_id` FK and indexed lookup; optional denormalized public reference may be added only if it simplifies status lookup.
  - Expected behavior: finalizer and status endpoints can resolve order/session without relying only on JSON metadata.
  - Files: `diaverseapi/app/cabinet/shop/models.py`, `diaverseapi/migrations/versions/<new_shop_payment_revision>.py`, `diaverseapi/tests/test_alembic_graph.py`.
  - Logging requirements: migration itself should not log; service code that writes the link must log order id, session id, source ref, and provider at INFO.
  - Dependencies: Task 1.
  - Migration verification: run `poetry run alembic heads` and `poetry run alembic upgrade <down_revision>:<new_revision> --sql` to catch PostgreSQL DDL/name issues.

- [x] Task 5: Define and enforce the USDT shop pricing source of truth.
  - Deliverable: active shop checkout and storefront contracts resolve purchasable price only from explicit USDT price fields (`display_price_amount/display_price_currency` or a neutral successor), and never from `price_xdv`, `xdv_price_amount`, or user balance data.
  - Expected behavior: offers without an explicit USDT price are hidden, disabled, or returned as unavailable with a clear machine-readable reason; there is no silent XDV-to-USDT conversion or XDV fallback.
  - Files: `diaverseapi/app/cabinet/shop/models.py`, `diaverseapi/app/cabinet/shop/schemas.py`, `diaverseapi/app/cabinet/shop/service.py`, `diaverseapi/app/cabinet/shop/admin_schemas.py`, `diaverseapi/app/cabinet/shop/admin_service.py`.
  - Logging requirements: log price resolution source, skipped legacy offers, missing USDT price decisions, and unavailable checkout reasons at INFO/WARN with item/offer ids.
  - Dependencies: Tasks 1 and 3.

### Phase 2: Backend Shop Checkout Lifecycle

- [x] Task 6: Replace active authenticated XDV checkout with provider-backed shop checkout.
  - Deliverable: `CabShopService.checkout()` validates the offer/item, creates or reuses `CabShopOrder.awaiting_payment`, creates or reuses `CabinetPaymentSession(domain_code="shop")`, and returns provider checkout data.
  - Expected behavior: no XDV balance lookup, XDV deduction, or XDV ledger mutation occurs; ownership and purchase limits are still enforced before starting checkout.
  - Files: `diaverseapi/app/cabinet/shop/service.py`, `diaverseapi/app/cabinet/shop/money.py` only if legacy adapters need isolation, `diaverseapi/app/cabinet/shop/schemas.py`.
  - Logging requirements: log checkout start, offer resolution, price resolution, order reservation, payment session creation/reuse, provider reinitialization, and checkout response at INFO; log validation and lock failures at WARN; log unexpected failures with `exc_info=True`.
  - Dependencies: Tasks 1-5.

- [x] Task 7: Implement shop payment status reconciliation and idempotent reuse.
  - Deliverable: shop status endpoint and checkout replay logic mirror Advent's generic payment session reuse rules for `created`, `awaiting_payment`, `processing`, `paid`, failed, cancelled, and expired sessions.
  - Expected behavior: repeated checkout with the same idempotency key returns the same active session or completed result; paid sessions are finalized on status read if callback has not done it yet.
  - Files: `diaverseapi/app/cabinet/shop/service.py`, `diaverseapi/app/cabinet/shop/api.py`.
  - Logging requirements: log idempotency replay decisions, stale/expired checkout reinitialization, reconciliation trigger, and finalization result at INFO; log duplicate or mismatched idempotency at WARN.
  - Dependencies: Task 6.

- [x] Task 8: Implement and register the shop payment finalizer.
  - Deliverable: add `ShopPaymentFinalizer` and replace `DeferredCabinetPaymentFinalizer("shop")`.
  - Expected behavior: when a shop `CabinetPaymentSession` is paid, the finalizer locks/resolves the linked `CabShopOrder`, validates item/offer, calls `_grant_item(... actor_kind=payment_callback ...)`, stores `fulfillment_payload_json`, marks order `completed`, and marks payment finalization `completed`.
  - Files: `diaverseapi/app/cabinet/shop/payment_finalizer.py`, `diaverseapi/app/cabinet/payments/finalizers.py`, `diaverseapi/app/cabinet/shop/service.py`.
  - Logging requirements: log finalizer start, order resolution, duplicate-completed handling, grant success, and finalization completion at INFO; log missing/mismatched order or broken source refs at ERROR and set finalization failed/review-required with enough context to recover.
  - Dependencies: Tasks 4 and 6-7.

- [x] Task 9: Remove mock guest paid checkout and retire legacy direct purchase paths.
  - Deliverable: current guest shop mock external checkout no longer marks fake provider orders as paid; legacy `/purchase` and direct purchase helpers are removed from the active frontend/API path or return a controlled unavailable response.
  - Expected behavior: guests receive login-required/unavailable behavior for paid shop offers unless a real generic guest provider flow is explicitly added later; there is no fake completed paid purchase and no XDV direct purchase fallback.
  - Files: `diaverseapi/app/cabinet/shop/service.py`, `diaverseapi/app/cabinet/shop/api.py`, `diaverseapi/app/cabinet/guest/service.py` if guest transfer behavior must be updated.
  - Logging requirements: log guest checkout decisions at INFO with actor/session/offer; log blocked mock path at WARN if legacy callers hit it; keep guest transfer failures explicit and non-silent.
  - Dependencies: Tasks 6-8.

- [x] Task 10: Migrate backend admin, seed, bootstrap, and specials away from active XDV terminology.
  - Deliverable: admin contracts, default offer specs, bootstrap logic, and shop specials use neutral or USDT price names; XDV-specific create/update affordances are removed from active admin behavior.
  - Expected behavior: new shop listings and special offers can be priced in USDT; existing XDV offers do not remain user-purchasable unless they are migrated to explicit USDT display offers; special offers without USDT price are not published as payable offers.
  - Files: `diaverseapi/app/cabinet/shop/admin_schemas.py`, `diaverseapi/app/cabinet/shop/admin_service.py`, `diaverseapi/app/cabinet/shop/seed_data.py`, `diaverseapi/app/cabinet/shop/bootstrap.py`, `diaverseapi/app/cabinet/shop/specials/models.py`, `diaverseapi/app/cabinet/shop/specials/schemas.py`, `diaverseapi/app/cabinet/shop/specials/service.py`.
  - Logging requirements: log admin price normalization, hidden/deprecated XDV offer handling, seed/backfill decisions, and special offer price publishing at INFO; log skipped legacy offers at WARN with item/offer ids.
  - Dependencies: Tasks 5-6.

### Phase 3: Frontend Shop Payment Flow

- [x] Task 11: Add shop payment BFF routes and client API/types.
  - Deliverable: frontend BFF proxies shop payment capabilities, checkout, and status endpoints; shop TS types include payment provider code, payment quote, payment payload, payment/finalization statuses, and public checkout reference.
  - Expected behavior: `checkoutShopOffer()` sends `provider_code` and normalizes generic payment contract fields; status polling can read the same contract by public reference.
  - Files: `diaweb/frontend/app/api/cabinet/shop/payment-capabilities/route.ts`, `diaweb/frontend/app/api/cabinet/shop/checkout/route.ts`, `diaweb/frontend/app/api/cabinet/shop/checkout/[publicCheckoutReference]/route.ts`, `diaweb/frontend/modules/shop/api.ts`, `diaweb/frontend/modules/shop/types.ts`, `diaweb/frontend/modules/shop/constants.ts`.
  - Logging requirements: log BFF proxy target, checkout start/result, status polling result, selected provider, public reference, and normalized status at DEBUG/INFO; log malformed payloads at WARN; avoid logging full provider payload if it contains sensitive fields.
  - Dependencies: Tasks 1-2.

- [x] Task 12: Extract reusable payment method chooser and popup utilities.
  - Deliverable: create shared payment UI/helper pieces that Advent and Shop can use without importing Advent-specific components from the shop module.
  - Expected behavior: Advent keeps existing behavior; Shop can render the same provider choice UX with a USDT amount line; this task does not rewrite Advent's whole status page or provider lifecycle.
  - Files: `diaweb/frontend/modules/payments/components/PaymentMethodChooser.tsx`, `diaweb/frontend/modules/payments/index.ts`, `diaweb/frontend/modules/advent/components/AdventCellModal.tsx`, `diaweb/frontend/modules/advent/paymentPopup.ts` or new `diaweb/frontend/modules/payments/paymentPopup.ts`.
  - Logging requirements: client-side logs should record provider selection, unavailable methods, popup prepared/opened/blocked state, and UI fallback decisions at DEBUG/INFO through existing payment logger helpers.
  - Dependencies: Task 11 can proceed in parallel; Advent refactor must be verified with existing Advent tests.

- [x] Task 13: Add shop payment modal and checkout hooks.
  - Deliverable: shop buy actions open a modal with item title/image, canonical price in USDT, and all selectable payment methods; selected provider starts checkout through the BFF and receives a public checkout reference.
  - Expected behavior: modal handles unavailable methods, checkout loading, checkout errors, and popup-blocked preparation states without completing a purchase locally.
  - Files: `diaweb/frontend/modules/shop/hooks/useShopPaymentCapabilities.ts`, `diaweb/frontend/modules/shop/hooks/useShopCheckout.ts`, `diaweb/frontend/modules/shop/components/ShopPaymentModal.tsx`, relevant shared modal/button/card integration helpers.
  - Logging requirements: log modal open/close, selected offer/provider, checkout initialization, hosted checkout popup preparation, and checkout terminal error states at DEBUG/INFO/WARN.
  - Dependencies: Tasks 11-12.

- [x] Task 14: Add shop payment status page and return route contract.
  - Deliverable: add a shop payment page that opens hosted checkout when needed, handles provider return/fail/processing query states, polls checkout status by public reference, and displays finalization status.
  - Expected behavior: route contract is explicit, for example `/{lang}/shop/payment?checkout=<public_reference>&state=return|fail|processing&provider=<provider_code>`; frontend consumes backend-generated `return_url`, `fail_url`, and `processing_url` instead of constructing arbitrary provider callback URLs.
  - Files: `diaweb/frontend/modules/shop/hooks/useShopCheckoutStatus.ts`, `diaweb/frontend/modules/shop/components/ShopPaymentPage.tsx`, `diaweb/frontend/app/[lang]/(cabinet)/shop/payment/page.tsx`, `diaweb/frontend/modules/payments/paymentPopup.ts` if shared popup handling is extracted.
  - Logging requirements: log hosted checkout popup result, polling transitions, terminal statuses, reload/retry decisions, and finalization result at DEBUG/INFO; log popup blocked and status errors at WARN/ERROR.
  - Dependencies: Tasks 11 and 13.

- [x] Task 15: Wire active shop surfaces to the payment modal and remove direct purchase semantics.
  - Deliverable: category pages, shop home specials, live storefront cards, and any still-routed legacy shop page call the payment modal flow instead of direct `usePurchase()` completion semantics.
  - Expected behavior: successful finalization invalidates shop catalog, specials, and notifications; old synchronous feedback such as immediate completed purchase is no longer used for paid offers.
  - Files: `diaweb/frontend/modules/shop/components/ShopCategoryRoutePage.tsx`, `diaweb/frontend/modules/shop/components/ShopHomePage.tsx`, `diaweb/frontend/modules/shop/components/ShopHomeSpecials.tsx`, `diaweb/frontend/modules/shop/components/ShopPage.tsx` if still reachable, `diaweb/frontend/modules/shop/components/StepPassCard.tsx`, `diaweb/frontend/modules/shop/components/shared/ShopItemCard.tsx`, relevant card components under `diaweb/frontend/modules/shop/components`.
  - Logging requirements: log selected offer/item, payment flow start, cache invalidation, and legacy route fallback decisions at DEBUG/INFO.
  - Dependencies: Tasks 13-14.

- [x] Task 16: Remove active XDV labels and fields from shop and staff-shop frontend.
  - Deliverable: storefront, specials, staff listing editor/table, bulk add, and special offer queue display USDT/neutral price fields instead of XDV-specific labels.
  - Expected behavior: user-facing shop no longer shows "XDV" as purchase currency; staff admin can manage USDT-priced offers without provider-specific controls on each offer; remaining XDV mentions are limited to deleted-code history, migrations, or explicitly deprecated compatibility comments.
  - Files: `diaweb/frontend/modules/shop/helpers.ts`, `diaweb/frontend/modules/shop/components/StepPassCard.tsx`, `diaweb/frontend/modules/shop/components/shared/ShopItemCard.tsx`, `diaweb/frontend/modules/shop/components/ShopHomeSpecials.tsx`, `diaweb/frontend/modules/staff-shop/shop-admin-types.ts`, `diaweb/frontend/modules/staff-shop/components/ShopListingEditor.tsx`, `diaweb/frontend/modules/staff-shop/components/ShopListingTable.tsx`, `diaweb/frontend/modules/staff-shop/components/ShopBulkAddDialog.tsx`, `diaweb/frontend/modules/staff-shop/components/ShopSpecialOfferQueue.tsx`, i18n dictionaries/types if labels live there.
  - Logging requirements: keep existing staff-shop API logs for create/update/bulk flows and add price currency/amount context at DEBUG/INFO; log deprecated XDV payload normalization at WARN during transition.
  - Dependencies: Tasks 10 and 13-15.

- [x] Task 17: Update shop payment i18n, copy, and fixtures.
  - Deliverable: shop-specific payment method, amount, pending, processing, paid, failed, expired, review-required, popup-blocked, login-required, and unavailable-price strings are added to dictionaries/types; old "not enough XDV" and balance-driven purchase copy is removed from active fixtures.
  - Expected behavior: UI copy matches provider-backed payment flow and never tells a user they lack XDV for a shop purchase.
  - Files: `diaweb/frontend/modules/i18n/types.ts`, locale dictionaries used by shop/advent payments, `diaweb/frontend/__tests__/modules/shop/shopDictionaryFixture.ts`, shop/staff-shop tests that assert visible strings.
  - Logging requirements: no new runtime logging required.
  - Dependencies: Tasks 13-16.

### Phase 4: Tests and Verification

- [x] Task 18: Add backend tests for shop provider payments.
  - Deliverable: coverage for capabilities, checkout creation, USDT quote normalization, provider support for all three methods, idempotency reuse, ownership denial on status reads, status reconciliation, finalizer idempotency, no double grant, guest mock removal, retired direct purchase behavior, and admin/special USDT pricing.
  - Expected behavior: tests prove shop uses `CabinetPaymentSession(domain_code="shop")`, all providers are available when feature flags allow them, and completed payment grants exactly one fulfillment batch.
  - Files: `diaverseapi/tests/test_cabinet_shop_service.py`, `diaverseapi/tests/test_cabinet_advent_payments.py`, `diaverseapi/tests/test_cabinet_pay1time_callback.py`, `diaverseapi/tests/test_cabinet_zion_payments.py`, `diaverseapi/tests/test_cabinet_prodamus_payments.py`, `diaverseapi/tests/test_cabinet_payment_fx.py`, `diaverseapi/tests/test_cabinet_shop_admin.py`, `diaverseapi/tests/test_cabinet_shop_specials.py` if present or new.
  - Logging requirements: tests should assert important state transitions; do not assert exact log strings unless behavior depends on warning/error classification.
  - Dependencies: Tasks 3-10.

- [x] Task 19: Add frontend and BFF tests for the shop payment flow.
  - Deliverable: coverage for shop API normalization, BFF proxies, payment modal provider selection, checkout route navigation, status page polling, return/fail/processing query states, cache invalidation on completed status, i18n copy, legacy route handling, and removal of active XDV labels.
  - Expected behavior: tests verify all three providers can be displayed/selected and shop success is driven by payment status/finalization, not immediate purchase mutation.
  - Files: `diaweb/frontend/__tests__/modules/shop/shop-api.test.ts`, `diaweb/frontend/__tests__/modules/shop/ShopCategoryRoutePage.test.tsx`, `diaweb/frontend/__tests__/modules/shop/ShopHomePage.test.tsx`, `diaweb/frontend/__tests__/modules/shop/ShopPaymentModal.test.tsx`, `diaweb/frontend/__tests__/modules/shop/ShopPaymentPage.test.tsx`, `diaweb/frontend/__tests__/app/api/cabinet/shop/checkout-route.test.ts`, new BFF route tests for capabilities/status, `diaweb/frontend/__tests__/modules/staff-shop/*.test.tsx`.
  - Logging requirements: tests may mock `console` where noisy, but should preserve production behavior; ensure error/warn paths remain observable for blocked popup and failed status reads.
  - Dependencies: Tasks 11-17.

- [ ] Task 20: Run cross-repo verification and refresh Graphify.
  - Deliverable: both repositories pass targeted tests and type/lint checks; shared graph is refreshed after code changes.
  - Expected behavior: Advent tests still pass, shop provider payment tests pass, no finance module changes are required, remaining XDV matches are audited and limited to migrations/deprecated residue if any, and no workspace-root git operations are performed.
  - Files: no product files expected; this task runs verification commands only.
  - Logging requirements: capture failed command names and the first actionable failure in the implementation notes; do not create a standalone report artifact.
  - Dependencies: Tasks 18-19.

## Verification Plan
- diaverseapi:
  - `poetry run alembic heads`
  - `poetry run alembic upgrade <down_revision>:<new_revision> --sql`
  - `poetry run pytest tests/test_cabinet_shop_service.py tests/test_cabinet_shop_admin.py tests/test_cabinet_shop_specials.py tests/test_cabinet_payment_fx.py`
  - `poetry run pytest tests/test_cabinet_pay1time_callback.py tests/test_cabinet_zion_payments.py tests/test_cabinet_prodamus_payments.py`
  - `poetry run pytest tests/test_cabinet_advent_payments.py`
  - `rg -n "XDV|xdv|price_xdv|balance_xdv" app/cabinet/shop tests/test_cabinet_shop*.py` and classify any remaining matches as migrations/deprecated residue, not active shop behavior.
- diaweb:
  - `npm.cmd test -- __tests__/modules/shop __tests__/app/api/cabinet/shop __tests__/modules/payments __tests__/modules/staff-shop`
  - `npm.cmd test -- __tests__/modules/advent`
  - `npm.cmd run typecheck`
  - `npm.cmd run lint`
  - `rg -n "XDV|xdv|price_xdv|balance_xdv|Not enough XDV" frontend/modules/shop frontend/modules/staff-shop frontend/__tests__/modules/shop frontend/__tests__/modules/staff-shop` and classify any remaining matches as deleted-route/deprecated compatibility, not active UI.
- graph:
  - `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`

## Out of Scope
- DCR wallet, DCR top-up, DCR checkout, or any fourth payment method.
- Automatic XDV-to-USDT business price conversion without product-approved pricing rules.
- Finance dashboards, finance APIs, and revenue reporting.
- Any changes to `aibot`.
