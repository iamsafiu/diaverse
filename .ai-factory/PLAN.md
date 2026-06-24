# Implementation Plan: Manual Provider Payment Link Generator

Branch: none
Created: 2026-06-24

## Settings

- Testing: yes
- Logging: standard
- Docs: no

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Branch operations: none

## Goal

Add a staff-only manual payment link generator in the admin finance area for:

- Pay1Time: one-time RUB payment links, amount entered in rubles.
- Zion: one-time crypto checkout links, amount entered in dollars/USDT terms, using the configured Zion payment currency.
- Prodamus: one-time signed hosted RUB payment links, amount entered in rubles.

The generator must not create product checkout sessions, payment finalizers, callbacks that mutate Diaverse state, credits, subscriptions, entitlements, shop orders, advent orders, or club orders. It only creates a provider-hosted payment URL and returns it to the admin.

Out of scope: Tribute, recurring payments, automatic reconciliation, user balance crediting, and product-domain checkout flows.

## Workspace Context

This is a multi-repo workspace plan from `C:\Users\Indigo\Desktop\diaverse`.

Local GBrain lookup was attempted for relevant payment-link/admin context and returned no useful canonical page, so the plan is based on verified source files.

## Affected Repositories

| Repository | Affected | Current branch observed | Notes |
| --- | --- | --- | --- |
| `diaverseapi` | Yes | `main` | Backend staff finance API and provider calls. Worktree has unrelated dirty changes; implementation must avoid mixing them. |
| `diaweb` | Yes | `master` | Admin finance UI and frontend API client. Worktree has unrelated dirty changes; implementation must avoid mixing them. |
| `diaverse-mobile` | No | Not checked | Mobile app is not part of staff finance admin. |
| `aibot` | No | Not checked | Copywriting service is unrelated. |
| `club10000-bot` | No | Not checked | Bot-local Prodamus subscription flow remains out of scope. |
| `diaverse-auth-bot` | No | Not checked | Auth transport is unrelated. |
| Root `diaverse` | Yes | Current workspace | Plan file only. |

## Source Facts

- `diaverseapi/app/cabinet/finance/api.py` already exposes `/v1/admin/finance/*` routes protected by `require_role("superadmin")`.
- `diaweb/frontend/modules/finance/components/FinanceDashboard.tsx` already owns the staff finance tabs.
- `diaweb/frontend/modules/finance/api.ts` already calls `/v1/admin/finance/*` through `apiClient`.
- Pay1Time integration exists in `diaverseapi/app/integrations/pay1time/client.py` and schemas in `diaverseapi/app/integrations/pay1time/schemas.py`.
- Pay1Time invoice creation requires `amount` in kopecks and technically requires `callback_url`.
- Zion integration exists in `diaverseapi/app/integrations/zion/client.py` and schemas in `diaverseapi/app/integrations/zion/schemas.py`.
- Zion `order_id` is limited to 20 characters and must match `^[a-zA-Z0-9-]{1,20}$`.
- Existing Zion checkout redirect format can be reused from `_resolve_checkout_redirect_url` in `diaverseapi/app/cabinet/payments/zion/service.py`.
- Prodamus integration exists in `diaverseapi/app/integrations/prodamus/client.py` and schemas in `diaverseapi/app/integrations/prodamus/schemas.py`.
- Prodamus checkout links are signed hosted URLs built locally by `ProdamusClient.build_checkout_link`.
- Prodamus product cabinet flow exists in `diaverseapi/app/cabinet/payments/prodamus/service.py`; manual links must not call that product/session service.

## Architecture Decision

Create a separate manual-link path under staff finance:

- Backend endpoint: `POST /v1/admin/finance/manual-payment-links`
- Frontend location: `/staff/finance`, new tab `Payment links` / `Ссылки на оплату`
- Backend implementation calls provider clients directly.
- Backend must not call `CabinetPaymentsService.create_checkout_session`.
- Backend must not create `CabinetPaymentSession` records.
- Backend should log/audit manual link creation with staff identity, provider, amount, currency, generated manual order id, and provider ids, but never provider tokens.
- No database migration is expected. Prefer existing structured logs or cabinet audit/logging utilities if available. If implementation discovers an existing admin audit table/event mechanism, use it without changing business payment tables.

## API Contract

Request:

```json
{
  "provider": "pay1time" | "zion" | "prodamus",
  "amount": "33525",
  "payer_name": "optional",
  "payer_email": "optional",
  "payer_phone": "optional",
  "description": "optional"
}
```

Provider-specific behavior:

- `pay1time`
  - Treat `amount` as RUB.
  - Convert to integer kopecks.
  - Currency: `RUB`.
  - Generate order id like `ml-rub-<short>` within provider-safe limits.
  - Use a non-mutating callback URL. Do not point it at the product payment callback.
- `zion`
  - Treat `amount` as dollars/USDT terms, not rubles.
  - Send provider amount as decimal string, quantized to the precision accepted by current Zion schemas.
  - Currency: configured `settings.zion_payment_currency` unless the implementation adds an explicit backend whitelist for supported Zion currencies.
  - Generate order id like `ml-<stamp>-<rand>` with max length 20.
  - Success/cancel URLs can be existing frontend safe return URLs, but they must not finalize anything.
- `prodamus`
  - Treat `amount` as RUB.
  - Currency: `rub` for the provider payload and `RUB` for the API response.
  - Generate a manual `order_id` and `order_num` that cannot collide with cabinet product sessions.
  - Build one simple `ProdamusProduct` such as `Manual payment`.
  - Use safe `urlReturn` / `urlSuccess`.
  - Use a non-mutating `urlNotification` or omit notification only if Prodamus accepts that in the current account. Do not point notification at the product Prodamus callback unless that callback explicitly ignores manual order ids.
  - Include `sys` only from existing safe settings.

Response:

```json
{
  "provider": "pay1time",
  "amount": "33525.00",
  "currency": "RUB",
  "order_id": "ml-rub-abc123",
  "payment_url": "https://...",
  "provider_payment_id": "optional",
  "provider_invoice_id": "optional",
  "expires_at": null,
  "raw_status": "optional"
}
```

The frontend must display the link, copy action, provider metadata, amount, currency, and order id.

## Tasks

### 1. [x] Backend schemas and validation

Files:

- `diaverseapi/app/cabinet/finance/api.py`
- Prefer a new local module if the file is getting large, for example `diaverseapi/app/cabinet/finance/manual_payment_links.py`
- Tests under `diaverseapi/tests/`

Deliverable:

- Add typed request/response schemas for manual payment link creation.
- Validate provider is only `pay1time`, `zion`, or `prodamus`.
- Validate positive amount with provider-specific currency semantics:
  - Pay1Time: RUB, two decimal places max, converted to kopecks.
  - Zion: dollar/USDT amount, decimal-safe, no RUB conversion.
  - Prodamus: RUB, two decimal places max.
- Normalize optional payer fields.

Logging:

- Log validation failures at normal API validation level only.
- Do not log full request bodies if they may contain payer contact data.

Dependencies:

- Must be completed before provider service implementation and frontend contract finalization.

### 2. [x] Backend Pay1Time manual provider path

Files:

- `diaverseapi/app/cabinet/finance/manual_payment_links.py`
- `diaverseapi/app/integrations/pay1time/*` only if a small reusable helper is needed
- Tests under `diaverseapi/tests/`

Deliverable:

- Use `Pay1TimeClient.create_qr_invoice`.
- Build `Pay1TimeCreateQrInvoiceRequest` with:
  - integer kopeck amount
  - `currency = "RUB"`
  - safe manual `order_id`
  - configured merchant values
  - safe `return_url` / `fail_url`
  - non-mutating callback URL
- Return the best hosted URL in priority order:
  - response `url`
  - response `invoice.url`
  - response `invoice.payment_url`

Logging:

- Info log on successful manual link creation: provider, order id, amount, currency, provider payment id/guid, staff id.
- Warning log if provider returns no usable payment URL.
- Never log `PAY1TIME_TOKEN`.

Dependencies:

- Requires Task 1 schemas.

### 3. [x] Backend Zion manual provider path

Files:

- `diaverseapi/app/cabinet/finance/manual_payment_links.py`
- `diaverseapi/app/cabinet/payments/zion/service.py` only if a tiny redirect helper should be extracted/reused
- Tests under `diaverseapi/tests/`

Deliverable:

- Use `ZionClient.create_invoice` directly.
- Treat input amount as dollar/USDT terms.
- Use `settings.zion_payment_currency` for the provider currency by default.
- Generate a Zion-safe `order_id` with max length 20 and allowed characters only.
- Build `ZionCreateInvoiceRequest` with safe description, fixed-rate and fee settings aligned with existing Zion configuration.
- Resolve hosted checkout URL from the returned invoice id using the existing checkout base URL convention.

Logging:

- Info log on successful manual link creation: provider, order id, amount, currency, invoice id/reference, staff id.
- Warning log on provider errors or missing hosted URL.
- Never log `ZION_API_TOKEN`.

Dependencies:

- Requires Task 1 schemas.

### 4. [x] Backend Prodamus manual provider path

Files:

- `diaverseapi/app/cabinet/finance/manual_payment_links.py`
- `diaverseapi/app/integrations/prodamus/*` only if a small reusable helper is needed
- Tests under `diaverseapi/tests/`

Deliverable:

- Use `ProdamusClient.build_checkout_link` directly.
- Build `ProdamusCheckoutRequest` with:
  - `currency = "rub"`
  - manual `order_id` and `order_num`
  - one `ProdamusProduct` with RUB price and quantity `1`
  - optional customer phone/email only when provided
  - safe `customer_extra` that marks this as a manual admin link without sensitive data
  - safe `urlReturn` / `urlSuccess`
  - non-mutating `urlNotification` or no notification if supported
  - `sys = settings.prodamus_sys` when configured
- Return `ProdamusCheckoutLink.redirect_url` as `payment_url`.
- Ensure generated links do not create `CabinetPaymentSession`, guest order, club membership, or product-domain rows.

Logging:

- Info log on successful manual link creation: provider, order id, amount, currency, staff id.
- Warning log on configuration/signature/build failure.
- Never log `PRODAMUS_SECRET_KEY` or the generated signature.

Dependencies:

- Requires Task 1 schemas.

### 5. [x] Backend admin route and audit behavior

Files:

- `diaverseapi/app/cabinet/finance/api.py`
- `diaverseapi/app/cabinet/finance/manual_payment_links.py`
- Existing audit/logging utilities if present

Deliverable:

- Add `POST /v1/admin/finance/manual-payment-links`.
- Protect route with existing superadmin requirement.
- Connect route to provider-specific manual service.
- Add structured audit/log entry for every successful generated link.
- Confirm the route does not create or mutate any product payment/session/order records.
- If existing global provider callbacks could see manual order ids, add a small ignore/hardening path for `ml-` order ids only if needed to avoid alert noise. It must not credit or finalize anything.

Logging:

- One structured info/audit event per generated link.
- One structured warning per provider failure.
- Include staff id/email when available.
- Exclude secrets and raw provider payloads.

Dependencies:

- Requires Tasks 2, 3, and 4.

### 6. [x] Backend tests

Files:

- New focused tests, for example `diaverseapi/tests/test_cabinet_finance_manual_payment_links.py`
- Existing finance API test helpers if available

Deliverable:

- Test superadmin access is required.
- Test Pay1Time request converts RUB to kopecks and returns hosted URL.
- Test Pay1Time does not call product checkout/session services.
- Test Zion sends dollar/USDT amount without RUB conversion.
- Test Zion generated order id satisfies max length 20 and allowed characters.
- Test Prodamus request builds a signed hosted URL from RUB amount without calling cabinet product/session service.
- Test Prodamus does not expose the generated signature or secret in logs/API payloads beyond the hosted URL itself.
- Test invalid provider and invalid amount responses.
- Test provider failure maps to a clean API error.

Logging:

- Tests should assert no token appears in logged output if existing log capture helpers make this practical.

Dependencies:

- Requires Tasks 1-5.

### 7. [x] Frontend API types and client

Files:

- `diaweb/frontend/modules/finance/types.ts`
- `diaweb/frontend/modules/finance/api.ts`

Deliverable:

- Add request and response types matching backend contract.
- Add `createManualPaymentLink(payload)` API helper calling `POST /v1/admin/finance/manual-payment-links`.
- Keep provider union limited to `pay1time | zion | prodamus`.
- Make amount/currency semantics explicit in type comments or labels:
  - Pay1Time amount: RUB.
  - Zion amount: USD/USDT terms.
  - Prodamus amount: RUB.

Logging:

- No frontend console logging of generated links or payer contact fields.

Dependencies:

- Can start after Task 1 contract is stable.

### 8. [x] Frontend finance UI

Files:

- `diaweb/frontend/modules/finance/components/FinanceDashboard.tsx`
- New component, for example `diaweb/frontend/modules/finance/components/ManualPaymentLinksPanel.tsx`
- Frontend tests if existing pattern supports them

Deliverable:

- Add a new finance tab: `Ссылки на оплату`.
- Build a compact admin form:
  - Provider segmented control: Pay1Time / Zion / Prodamus.
  - Amount input.
  - Dynamic currency label:
    - Pay1Time: `RUB`
    - Zion: `USD / USDT`
    - Prodamus: `RUB`
  - Optional payer name/email/phone fields for Pay1Time/Prodamus compatibility.
  - Optional description.
  - Generate button with loading and disabled states.
- Show generated result:
  - payment URL
  - copy button
  - provider
  - amount/currency
  - order id
  - provider invoice/payment id if present
- Do not show Tribute.
- Do not imply automatic crediting, subscription creation, or balance changes.

Logging:

- No `console.log` for payment URLs or payer contact fields.

Dependencies:

- Requires Task 7 API helper.

### 9. [x] Frontend tests and UX verification

Files:

- Existing finance tests or new focused tests under `diaweb/frontend`

Deliverable:

- Test provider switching changes currency/help labels.
- Test Pay1Time submits RUB amount.
- Test Zion submits dollar/USDT amount.
- Test Prodamus submits RUB amount.
- Test generated URL result and copy control render.
- Test API error state is readable and does not clear the form unexpectedly.
- Verify layout at desktop and narrow viewport if the local app can run.

Logging:

- Ensure no test snapshots or debug output contain real provider URLs from production.

Dependencies:

- Requires Tasks 7 and 8.

## Verification Plan

Backend:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests\test_cabinet_finance_manual_payment_links.py -q
.\.venv\Scripts\python.exe -m ruff check app\cabinet\finance app\integrations\pay1time app\integrations\zion app\integrations\prodamus tests\test_cabinet_finance_manual_payment_links.py
```

Frontend:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
pnpm vitest run modules/finance
pnpm lint
```

Manual smoke:

- Open staff finance page.
- Confirm new `Ссылки на оплату` tab exists.
- Generate a mocked or staging Pay1Time RUB link.
- Generate a mocked or staging Zion dollar/USDT link.
- Generate a mocked or staging Prodamus RUB link.
- Confirm no cabinet payment session/order/finalizer records are created.
- Confirm logs contain audit metadata and no provider tokens.

Database:

- No Alembic migration is expected.
- If implementation later adds a migration despite this plan, run:

```powershell
alembic upgrade <down_revision>:<new_revision> --sql
```

## Commit Plan

Because the plan has more than five tasks, split implementation commits by repository:

1. `diaverseapi`: after Tasks 1-6 pass targeted tests.
   - Suggested commit: `feat(finance): add manual provider payment links`
2. `diaweb`: after Tasks 7-9 pass targeted tests.
   - Suggested commit: `feat(finance): add manual payment link generator`
3. Root `diaverse`: commit `.ai-factory/PLAN.md` only if the plan file should be kept in coordination history.

Do not stage unrelated dirty files from existing worktrees.

## Guardrails

- Do not implement Tribute in this generator.
- Do not reuse product checkout/session/finalizer flows.
- Do not credit balances, grant access, or create subscriptions.
- Do not expose provider tokens to the frontend.
- Do not log full provider responses if they can contain sensitive details.
- Pay1Time needs a `callback_url`; use a non-mutating/noop URL, not a business callback that finalizes payments.
- Zion manual links use dollars/USDT terms, not rubles.
- Zion order ids must stay within the 20-character provider limit.
- Prodamus manual links use RUB and must be built through the integration client, not the cabinet product Prodamus service.
- Prodamus signatures are required for hosted links but must not be separately exposed or logged.
- Existing child repos are dirty from unrelated work; inspect diffs before editing and keep changes tightly scoped.
