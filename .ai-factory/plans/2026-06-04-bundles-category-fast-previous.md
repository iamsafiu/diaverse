# Implementation Plan: Tribute Hosted Payments For Advent

Branch: feature/tribute-advent-payments
Created: 2026-06-03
Mode: fast workspace plan with user-requested product branches

## Settings

- Testing: yes
- Logging: verbose
- Docs: yes
- Branching: product branches were created from `dev` despite fast mode because the user explicitly requested them
- Affected product repositories: `diaverseapi`, `diaweb`
- Not affected for source changes: `aibot`, `club10000-bot`, `diaverse-auth-bot`
- Previous fast plan backup: `.ai-factory/plans/2026-06-03-club10000-broadcasts-fast-completed.md`

## Workspace Mode

- Mode: multi-repo fast/hybrid
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain first through `scripts\gbrain.ps1`, then raw source verification
- Goal: add Tribute as a correctly-architected cabinet payment provider, enabled only for Advent MVP

## Repository Matrix

| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | `feature/tribute-advent-payments` | clean | Tribute client, provider adapter, Advent quote/callback/reconcile |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | `feature/tribute-advent-payments` | clean | Advent payment provider label/UX and tests |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | unchanged | not checked for this plan | unrelated copywriting service |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | unchanged | not checked for this plan | standalone Club10000 bot payments, not generic cabinet payments |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | unchanged | not checked for this plan | Telegram auth transport only |
| root AIF | `C:\Users\Indigo\Desktop\diaverse\.ai-factory` | yes | root branch unchanged | dirty before this plan | planning artifact only |

## Product Decisions

- Provider code: `tribute-hosted`.
- MVP scope: Advent payments only.
- Architecture scope: implement a normal cabinet provider adapter, then restrict rollout through registry/capabilities.
- Actor scope: authenticated Advent users; linked Telegram ID is not required for Tribute.
- Guest checkout: disabled for Tribute in MVP because guest attribution/entitlement transfer should be enabled as a separate rollout.
- Currency policy for MVP: use a configurable Tribute provider currency, default `RUB`, with Prodamus-like USD/USDT to RUB FX quoting and direct RUB support.
- Tribute Digital Product API is out of scope; use Tribute Shop API orders because Advent rewards and finalization remain local Diaverse state.
- Callback trust model: do not trust webhook payload alone; callback must resolve a local session and then reconcile through Tribute `GET /orders/{id}` before marking paid.
- Refund/chargeback policy: map `chargeback`, `refund`, and `partial_refund` to `review_required`; do not auto-revoke Advent rewards in MVP.
- Rollout gate: Tribute MVP should be visible only when generic cabinet payments are enabled; the legacy Advent initializer remains compatible but is not the preferred rollout path.
- Hosted checkout links are sensitive runtime artifacts; do not log raw `webAppUrl`, `link`, `paymentLink`, or `redirect_url` values in backend, frontend, tests, or docs.
- Checkout reuse policy: use an expiry value from Tribute if the response exposes one; otherwise use a configurable local TTL (`TRIBUTE_CHECKOUT_TTL_MINUTES`) or leave expiry empty and rely on explicit status reconciliation.

## Architecture Sketch

```text
Advent UI
  -> payment capabilities for domain=advent actor=authenticated
  -> provider_code=tribute-hosted
  -> diaverseapi CabinetPaymentsService
  -> CabinetTributeService adapter
  -> Tribute POST /api/v2/orders/
  -> hosted checkout URL returned to diaweb
  -> Tribute webhook / cabinet/payments/tribute/callback
  -> Tribute GET /api/v2/orders/{id}/ reconciliation
  -> CabinetPaymentSession status=paid
  -> AdventPaymentFinalizer
```

## Research Context

- Tribute Shop API creates hosted payment orders through `POST https://api.tribute.tg/api/v2/orders/`.
- Tribute API auth uses `Authorization: Api-Key <TOKEN>`.
- Tribute order create accepts `amount`, `currency`, `description`, `payload`, optional `customerId`, `successUrl`, `failUrl`, `cancelUrl`, and `webhookUrl`.
- Tribute order response includes hosted links such as `webAppUrl`, `link`, and `paymentLink`.
- Tribute order statuses include `pending`, `completed`, `failed`, `canceled`, `chargeback`, `refund`, and `partial_refund`.
- Official docs used during exploration:
  - `https://wiki.tribute.tg/ru/for-shops/api-magazina`
  - `https://wiki.tribute.tg/ru/for-shops/api-magazina/metody`
  - `https://wiki.tribute.tg/for-shops/api/webhooks`

## Existing Source Patterns

- Provider enum and method kinds: `diaverseapi/app/cabinet/payments/enums.py`.
- Generic provider protocol and checkout/reconcile flow: `diaverseapi/app/cabinet/payments/service.py`.
- Provider registry and domain/actor capabilities: `diaverseapi/app/cabinet/payments/registry.py`.
- Advent quote provider map: `diaverseapi/app/cabinet/offers/advent/payment_quotes.py`.
- Provider integration shape: `diaverseapi/app/integrations/prodamus/*` and `diaverseapi/app/integrations/zion/*`.
- Provider adapter shape: `diaverseapi/app/cabinet/payments/prodamus/*` and `diaverseapi/app/cabinet/payments/zion/*`.
- Provider error normalization: `diaverseapi/app/cabinet/payments/errors.py`.
- Tribute `customerId` source: local stable `diaverse_user:<user_uuid>`, not Telegram ID.
- Existing Advent hosted URL logging that must be sanitized before adding Tribute: `diaverseapi/app/cabinet/offers/advent/service.py` and `diaweb/frontend/modules/advent/components/AdventPaymentStubPage.tsx`.
- Frontend provider labels and capability helpers: `diaweb/frontend/modules/payments/helpers.ts`.
- Advent payment provider UI/tests: `diaweb/frontend/modules/advent/components/AdventCellModal.tsx`, `diaweb/frontend/__tests__/modules/advent/AdventPagePayments.test.tsx`, `diaweb/frontend/__tests__/modules/advent/AdventPaymentPage.test.tsx`.

## Out Of Scope

- Tribute for shop, Crypton, factory, raids, or club.
- Guest or anonymous Tribute checkout.
- Tribute Digital Product API.
- Recurring subscriptions.
- Automatic reward revocation on refund/chargeback.
- Any changes in `club10000-bot`.
- Browser calls directly to Tribute API.

## Tasks

### Phase 1: Backend Provider Foundation

- [x] Task 1: Add Tribute configuration, feature flags, and integration primitives in `diaverseapi`.

  Deliverable: backend has typed Tribute settings, feature gates, client schemas, exceptions, and a non-leaking API client.

  Expected behavior:
  - Add `CABINET_PAYMENTS_TRIBUTE_ENABLED` and `CABINET_PAYMENTS_TRIBUTE_VISIBLE` feature flags.
  - Add settings for `TRIBUTE_BASE_URL`, `TRIBUTE_API_TOKEN`, `TRIBUTE_CALLBACK_URL`, `TRIBUTE_CALLBACK_RELAY_TOKEN`, `TRIBUTE_PAYMENT_CURRENCY`, `TRIBUTE_TIMEOUT_SECONDS`, and `TRIBUTE_CHECKOUT_TTL_MINUTES`.
  - Create `app/integrations/tribute/client.py`, `schemas.py`, `exceptions.py`, and `security.py`.
  - Client methods: `create_order(...)` and `get_order(order_id)`.
  - API client sends `Authorization: Api-Key <TOKEN>`.
  - Add provider exception classes for configuration, transport, provider rejection, and local callback guard failures.
  - Add redaction helpers for Tribute hosted links, customer ids, callback tokens, API keys, and raw provider bodies.
  - API client must never log tokens, full payloads with PII, raw hosted checkout URLs, or raw callback secrets.

  Files:
  - `diaverseapi/app/core/settings.py`
  - `diaverseapi/app/core/features.py`
  - `diaverseapi/app/integrations/tribute/__init__.py`
  - `diaverseapi/app/integrations/tribute/client.py`
  - `diaverseapi/app/integrations/tribute/schemas.py`
  - `diaverseapi/app/integrations/tribute/exceptions.py`
  - `diaverseapi/app/integrations/tribute/security.py`

  Logging requirements:
  - `INFO` for successful `create_order` and `get_order` with operation, status, order id, and local reference.
  - `WARN` for non-2xx Tribute responses with status code and sanitized error code.
  - `ERROR` for transport failures with operation and error type only.

- [x] Task 2: Register `tribute-hosted` as a cabinet provider but expose it only for authenticated Advent.

  Deliverable: `tribute-hosted` appears in Advent payment capabilities only when enabled and actor is authenticated.

  Expected behavior:
  - Add `CabinetPaymentProviderCode.tribute_hosted = "tribute-hosted"`.
  - Add `CabinetTributeService` to the payment registry.
  - Registration uses `method_kind=bank_transfer` unless a broader method-kind refactor is explicitly chosen later.
  - Registration uses `domain_codes=("advent",)` for MVP.
  - Registration disables guest checkout through `supports_guest_checkout=False`.
  - Capability visibility for Tribute MVP requires `CABINET_GENERIC_PAYMENTS_ENABLED=true` in addition to Tribute feature/config flags.
  - Registration metadata includes `integration="tribute"` and `checkout_kind="hosted"`.

  Files:
  - `diaverseapi/app/cabinet/payments/enums.py`
  - `diaverseapi/app/cabinet/payments/registry.py`
  - `diaverseapi/app/cabinet/payments/errors.py`
  - `diaverseapi/app/cabinet/payments/__init__.py`

  Logging requirements:
  - Keep registry `INFO` capability logs intact.
  - Add no noisy provider-specific logs here beyond existing registry messages.

- [x] Task 3: Add Tribute payment error normalization and redaction safeguards.

  Deliverable: Tribute failures surface through the same cabinet payment error contract as existing providers, without leaking hosted links, local customer ids, tokens, or raw provider payloads.

  Expected behavior:
  - Extend `try_normalize_cabinet_payment_error` to map Tribute configuration, transport, provider rejection, and callback guard errors into existing cabinet payment error categories.
  - Ensure Advent API handlers return controlled provider/configuration/retryable errors instead of generic 500 responses for expected Tribute failures.
  - Redact or omit sensitive fields in normalized provider details, including `paymentLink`, `webAppUrl`, `link`, `customerId`, API keys, callback relay tokens, and full response bodies.
  - Add tests that prove normalized Tribute errors preserve actionable error type/status while hiding sensitive values.

  Files:
  - `diaverseapi/app/cabinet/payments/errors.py`
  - `diaverseapi/app/integrations/tribute/exceptions.py`
  - `diaverseapi/app/integrations/tribute/security.py`
  - `diaverseapi/tests/test_tribute_integration.py`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`

  Logging requirements:
  - No raw hosted checkout URLs, callback tokens, API keys, local customer ids, payer data, or full provider response bodies in normalized errors or test output.

- [x] Task 4: Add the Tribute Advent quote strategy.

  Deliverable: Advent quote creation supports `tribute-hosted` with predictable provider amount/currency metadata.

  Expected behavior:
  - Add `TributeAdventPaymentQuoteStrategy`.
  - Support USD/USDT source prices by converting to configured Tribute currency, default `RUB`, using the existing FX service when target currency is RUB.
  - Support direct RUB source prices when provider currency is RUB.
  - Reject unsupported source/provider currency combinations with `CabinetPaymentQuoteValidationError`.
  - Include `provider_quote_meta` with pricing mode, source currency, provider currency, and FX metadata when applicable.
  - Wire the strategy into `AdventPaymentQuoteService`.
  - Do not wire Tribute into shop/Crypton/factory/raids quote resolvers in MVP.

  Files:
  - `diaverseapi/app/cabinet/payments/quotes/tribute.py`
  - `diaverseapi/app/cabinet/payments/quotes/__init__.py`
  - `diaverseapi/app/cabinet/offers/advent/payment_quotes.py`
  - `diaverseapi/tests/test_cabinet_payment_fx.py`

  Logging requirements:
  - `DEBUG` for quote input normalization.
  - `INFO` for successful Tribute quote creation with provider, domain, source amount/currency, provider currency/amount, and FX date if used.
  - `WARN` for unavailable FX.
  - `ERROR` for unsupported currency combinations.

### Phase 2: Checkout, Callback, And Reconciliation

- [x] Task 5: Implement `CabinetTributeService` as a normal provider adapter.

  Deliverable: Tribute can initialize authenticated Advent hosted checkout and can participate in generic cabinet payment reconciliation patterns.

  Expected behavior:
  - Create `app/cabinet/payments/tribute/service.py`.
  - Implement `build_public_checkout_reference` with a Tribute-specific prefix.
  - Implement `initialize_authenticated_advent_checkout` by creating a Tribute order and storing provider ids, provider status, hosted checkout URL, request payload, response payload, and quote payload.
  - Implement `initialize_checkout` for generic `CabinetPaymentSession`; keep it domain-agnostic internally but rely on registry to expose only Advent for MVP.
  - Implement `initialize_guest_advent_checkout` as an explicit unsupported path with a clear local error until guest Telegram identity flow exists.
  - Resolve `customerId` from the local authenticated user UUID as `diaverse_user:<user_uuid>`; never parse it from `visitor_id`.
  - Reject checkout with a normalized local error when actor is not authenticated or `owner_user_id` is missing.
  - Compose Tribute `webhookUrl` from `TRIBUTE_CALLBACK_URL` and the configured relay token/query token so live callbacks pass the local guard without exposing the token in logs.
  - Set `checkout_expires_at` from a Tribute response expiry field when present; otherwise apply `TRIBUTE_CHECKOUT_TTL_MINUTES` when configured, or leave it empty and rely on reconciliation.
  - Store only the provider data needed for idempotency and reconciliation; avoid duplicating hosted checkout links and PII in verbose provider payload fields when possible.
  - Build Tribute `payload` with enough local references to resolve idempotently: public checkout reference, provider order id, domain code, source ref, and owner user id.
  - Use existing Advent return/fail/processing URL conventions.

  Files:
  - `diaverseapi/app/cabinet/payments/tribute/__init__.py`
  - `diaverseapi/app/cabinet/payments/tribute/service.py`
  - `diaverseapi/app/cabinet/payments/tribute/dependencies.py`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`

  Logging requirements:
  - `INFO` for checkout initialized with local session id, provider order id, public reference, provider status, and local status.
  - `WARN` for missing Telegram user id with user id and session id only.
  - `ERROR` for provider create-order failure with sanitized provider error.

- [x] Task 6: Add Tribute callback router and signed/unguessable callback guard.

  Deliverable: Tribute callbacks enter through a dedicated FastAPI router and are rejected unless they carry the configured local callback token/relay token.

  Expected behavior:
  - Add `POST /v1/cabinet/payments/tribute/callback`.
  - Accept JSON callback payloads for Tribute `shop_order_*` events.
  - Validate a local relay token from query/header until Tribute webhook signature support is confirmed.
  - Validate that generated order requests include a callback URL carrying the relay token/query token expected by this guard.
  - Parse and validate callback payload shape through Tribute schemas.
  - Resolve target local session by Tribute order id and/or embedded payload/public reference.
  - Acknowledge duplicate callbacks idempotently.
  - Return a simple success response after local processing.

  Files:
  - `diaverseapi/app/cabinet/payments/tribute/api.py`
  - `diaverseapi/app/cabinet/payments/tribute/dependencies.py`
  - `diaverseapi/app/routers/v1/endpoints.py`
  - `diaverseapi/app/integrations/tribute/security.py`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`

  Logging requirements:
  - `INFO` for accepted callback with event type, Tribute order id, public reference, local session id, and mapped local status.
  - `WARN` for rejected callback token/signature, target not found, or malformed payload.
  - Do not log raw callback token, raw API key, payer data, or full payload.

- [x] Task 7: Implement Tribute status mapping and provider reconciliation.

  Deliverable: backend never marks a Tribute payment paid from webhook alone; it fetches the authoritative order and maps status safely.

  Expected behavior:
  - Implement `reconcile_payment_session` through `GET /orders/{id}/`.
  - Status mapping:
    - `pending` -> `awaiting_payment`
    - `completed` -> `paid`
    - `failed` -> `failed`
    - `canceled` -> `cancelled`
    - `chargeback`, `refund`, `partial_refund` -> `review_required`
    - unknown statuses -> `review_required`
  - Before `paid`, verify Tribute amount/currency matches local quote and payload matches the local session.
  - Persist provider status, synced timestamp, response payload, finalization flags, and error/review details.
  - Do not downgrade an already `paid` local session to `failed` or `cancelled` from a late callback; refund and chargeback events after payment move the session to review.
  - Trigger `finalize_generic_payment_session_after_provider_update` or authenticated Advent finalization only after paid status is confirmed.

  Files:
  - `diaverseapi/app/cabinet/payments/tribute/service.py`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`
  - `diaverseapi/tests/test_cabinet_payment_sessions.py`

  Logging requirements:
  - `INFO` for reconciliation start/completion with session id, provider order id, provider status, local status, and trigger.
  - `WARN` for amount/currency mismatch, payload mismatch, refund/chargeback, and unknown status.
  - `ERROR` only for unrecoverable provider/client failures.

### Phase 3: Advent Integration And Frontend UX

- [x] Task 8: Ensure Advent checkout routes surface Tribute availability only to eligible users.

  Deliverable: authenticated Advent payment flow can request `tribute-hosted`, while guest Advent flow does not present or accept it.

  Expected behavior:
  - Existing Advent capability endpoint receives enough actor context to keep Tribute limited to authenticated users.
  - Tribute is available for authenticated users when feature flags, generic payments, and config are enabled; `tg_user_id` is not required.
  - Guest actor receives no available Tribute method.
  - Authenticated user without `tg_user_id` can select Tribute and start checkout.
  - Default provider selection and retry/reuse paths must not auto-select disabled Tribute for an ineligible user.
  - Existing Pay1Time/Prodamus/Zion flows remain unchanged.

  Files:
  - `diaverseapi/app/cabinet/offers/advent/api.py`
  - `diaverseapi/app/cabinet/offers/advent/service.py`
  - `diaverseapi/tests/test_cabinet_advent_payments.py`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`

  Logging requirements:
  - `INFO` for successful Advent checkout start with provider and actor kind.
  - `WARN` for ineligible Tribute checkout attempts with actor kind and reason code.

- [x] Task 9: Sanitize hosted checkout URL logging across Advent backend and frontend flows.

  Deliverable: existing Advent hosted checkout logs and new Tribute paths do not expose raw hosted provider URLs or token-bearing redirect links.

  Expected behavior:
  - Remove or redact raw `checkout_url`, `redirect_url`, `paymentLink`, `webAppUrl`, and `link` values from Advent backend logs.
  - Remove or redact raw `checkout.redirect_url` from Advent frontend client logging while keeping non-sensitive diagnostics such as provider code, local reference, and status.
  - Apply the same redaction policy to new Tribute client/service/callback logs.
  - Keep returned API payloads unchanged where the browser needs the redirect URL; only logs, errors, docs, and tests should redact.

  Files:
  - `diaverseapi/app/cabinet/offers/advent/service.py`
  - `diaverseapi/app/cabinet/payments/tribute/service.py`
  - `diaverseapi/app/integrations/tribute/security.py`
  - `diaweb/frontend/modules/advent/components/AdventPaymentStubPage.tsx`
  - `diaweb/frontend/modules/advent/api.ts`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`
  - `diaweb/frontend/__tests__/modules/advent/AdventPaymentPage.test.tsx`

  Logging requirements:
  - Tests and runtime logs may include provider code, local session id, public checkout reference, order id suffix, and status.
  - Tests and runtime logs must not include full hosted checkout URLs or token-bearing query parameters.

- [x] Task 10: Add frontend provider metadata and Advent payment UX handling in `diaweb`.

  Deliverable: Advent users see a clean Tribute payment method label and the existing hosted checkout flow opens the Tribute URL.

  Expected behavior:
  - Extend `PaymentProviderCode` with `"tribute-hosted"`.
  - Add a local fallback label for `tribute-hosted`, for example `Tribute`.
  - Keep capability `public_label` as the preferred backend-controlled label.
  - Ensure `AdventCellModal` does not collapse Tribute into the generic "Other" label intended for Zion.
  - Ensure `AdventPaymentStubPage` return/status flow handles `tribute-hosted` like any other hosted provider.
  - Do not add shop/Crypton UI labels beyond shared provider metadata unless the provider is later enabled for those domains.

  Files:
  - `diaweb/frontend/modules/payments/types.ts`
  - `diaweb/frontend/modules/payments/helpers.ts`
  - `diaweb/frontend/modules/advent/components/AdventCellModal.tsx`
  - `diaweb/frontend/__tests__/modules/advent/AdventPagePayments.test.tsx`
  - `diaweb/frontend/__tests__/modules/advent/AdventPaymentPage.test.tsx`

  Logging requirements:
  - Keep existing `[payments]` and Advent client logs.
  - Add no logs with redirect URLs if they may contain provider/session tokens.
  - Test assertions should cover provider label and selected provider propagation.

### Phase 4: Runtime Configuration, Docs, And Verification

- [x] Task 11: Add environment examples and deployment notes for Tribute.

  Deliverable: runtime operators know which environment variables are required and how to enable Tribute only for Advent testing.

  Expected behavior:
  - Document settings without real tokens or raw production values.
  - Include required feature flags, generic payments dependency, callback URL shape, and checkout URL redaction policy.
  - Include the safe rollout order: backend config -> backend deploy -> frontend deploy -> authenticated Advent smoke.
  - Include rollback: disable `CABINET_PAYMENTS_TRIBUTE_ENABLED` or `CABINET_PAYMENTS_TRIBUTE_VISIBLE`.

  Files:
  - `diaverseapi/.env.example` if present
  - `diaverseapi/docs/cabinet-commerce.md`
  - root docs under `docs/features/` or `docs/runbooks/` for the Advent Tribute rollout note
  - `docs/README.md` if a new root doc is added

  Logging requirements:
  - Docs must explicitly forbid logging Tribute API tokens, relay tokens, full callback payloads, payer PII, and hosted checkout URLs with sensitive parameters.

- [x] Task 12: Add backend unit tests for Tribute client, quote, checkout, callback, and reconciliation.

  Deliverable: Tribute backend behavior is covered without live Tribute API calls.

  Expected behavior:
  - Mock HTTP calls for `create_order` and `get_order`.
  - Test API key header generation without exposing token in assertion failure output.
  - Test quote strategy USD/USDT to RUB and direct RUB behavior.
  - Test authenticated Advent checkout creates a local session with provider order id and redirect URL.
  - Test missing Telegram user id is rejected cleanly.
  - Test authenticated user without `tg_user_id` receives available Tribute capability and can start checkout.
  - Test generated Tribute order request contains a callback URL compatible with the local relay token guard without leaking the token in logs.
  - Test callback accepted, duplicate callback idempotency, rejected token, status mapping, amount mismatch, and refund/chargeback review path.
  - Test normalized Tribute errors and log redaction for hosted URLs, customer id, provider response body, and callback token.
  - Test checkout reuse/expiration behavior for response expiry and `TRIBUTE_CHECKOUT_TTL_MINUTES`.

  Files:
  - `diaverseapi/tests/test_tribute_integration.py`
  - `diaverseapi/tests/test_cabinet_tribute_payments.py`
  - `diaverseapi/tests/test_cabinet_payment_fx.py`
  - `diaverseapi/tests/test_cabinet_advent_payments.py`

  Logging requirements:
  - Tests should assert meaningful warning paths where practical: missing TG id, rejected callback token, amount mismatch, refund/chargeback review.
  - Test output must not contain tokens or full callback payloads.

- [x] Task 13: Add frontend tests for Tribute labels, capabilities, and Advent provider selection.

  Deliverable: frontend regression tests prove the Advent UI can show and select Tribute without breaking existing providers.

  Expected behavior:
  - `tribute-hosted` appears as `Tribute` or backend `public_label`.
  - Clicking the Tribute method calls the Advent payment start path with `provider_code="tribute-hosted"`.
  - Payment return page renders provider label from checkout/capability data.
  - Disabled Tribute capabilities are not selectable and preserve the ineligible reason for UI messaging if rendered.
  - Advent client logs do not include raw `redirect_url` values for Tribute hosted checkout.
  - Existing Pay1Time, Zion, and Prodamus assertions continue to pass.

  Files:
  - `diaweb/frontend/__tests__/modules/advent/AdventPagePayments.test.tsx`
  - `diaweb/frontend/__tests__/modules/advent/AdventPaymentPage.test.tsx`
  - `diaweb/frontend/__tests__/modules/payments/payment-helpers.test.ts` if a helpers test file already exists or is worth adding

  Logging requirements:
  - Tests should not assert noisy console output unless warnings are intentional.

- [x] Task 14: Run targeted verification and record sanitized results.

  Deliverable: implementation is verified in both affected repos, with safe local smoke instructions for a real Tribute order.

  Verification commands:
  ```powershell
  cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
  .venv\Scripts\python.exe -m pytest tests\test_tribute_integration.py tests\test_cabinet_tribute_payments.py tests\test_cabinet_payment_fx.py tests\test_cabinet_advent_payments.py tests\test_cabinet_payment_sessions.py -q
  .venv\Scripts\python.exe -m ruff check app\integrations\tribute app\cabinet\payments\tribute app\cabinet\payments app\cabinet\offers\advent tests\test_tribute_integration.py tests\test_cabinet_tribute_payments.py

  cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
  npm run test -- __tests__/modules/advent/AdventPagePayments.test.tsx __tests__/modules/advent/AdventPaymentPage.test.tsx
  npm run typecheck
  ```

  Safe manual smoke:
  - Enable Tribute only in a non-production/test environment.
  - Use one authenticated test user with a known Telegram user id.
  - Create one paid Advent cell checkout with `provider_code=tribute-hosted`.
  - Confirm the hosted Tribute page opens from the existing Advent payment popup/page.
  - Complete or cancel the order and confirm local status reconciles through the callback/status page.
  - Do not enable Tribute for guests, shop, Crypton, factory, raids, or club in this smoke.

  Logging requirements:
  - Record only sanitized status, order id suffix if needed, local session id, and aggregate result.
  - Do not store Tribute API token, callback relay token, payer PII, raw callback payload, full checkout URL, server IPs, or SSH commands.

## Commit Plan

- Commit 1 (`diaverseapi`): `feat: add tribute advent payment provider`
- Commit 2 (`diaweb`): `feat: support tribute advent checkout`
- Commit 3 (root docs/AIF, if committed): `docs: plan tribute advent payment rollout`

## Risks And Guards

- Tribute Shop API treats `customerId` as optional; Diaverse sends a local stable `diaverse_user:<user_uuid>` value for authenticated Advent users.
- Tribute webhook signature support was not confirmed in the public docs reviewed; protect MVP with a local callback token and server-side order reconciliation.
- Callback `completed` must not mark paid unless amount, currency, and payload match local session data.
- Refund and chargeback events should move to review, not silently change granted Advent rewards.
- `club10000-bot` remains unrelated; do not route cabinet Tribute payments through the standalone Club10000 payment bot.
