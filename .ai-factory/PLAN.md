# Implementation Plan: Crypton Pet Evolution Selection

**Created:** 2026-06-07  
**Mode:** fast  
**Branch:** none  
**Testing:** yes  
**Logging:** verbose  
**Docs/Roadmap:** warn-only

## Goal

Add pet evolution selection to the Crypton offer builder so a user can choose the desired evolution for a selected pet, submit that choice with a custom desired price, and receive the purchased pet with that evolution after approval and payment.

## Product Decisions

- For pet/character Crypton offers, do not show the recommended price in the user modal because evolution-specific pricing is not defined yet.
- For pet/character Crypton offers, do not block user-entered desired price as "above market"; staff/Crypton can review, approve, reject, or counter the request manually.
- Store the selected evolution in the existing Crypton request metadata/snapshots and fulfillment line options. No database migration is planned.
- Validate evolution server-side against authoritative pet rarity rules. Default legacy submissions to evolution 1 only when no selection exists.
- Show selected evolution in web UI, staff request UI, backend notification payloads, and Telegram notifications.

## Scope

Affected repositories:

- `diaweb` - Crypton modal UI, API payload/types, staff panel display, frontend tests, i18n.
- `diaverseapi` - Crypton request contract, validation, metadata/snapshot, fulfillment options, notification payloads, backend tests.
- `diaverse-auth-bot` - Telegram Crypton status caption rendering and tests.

Not affected:

- `aibot`
- `club10000-bot`
- Root workspace implementation code

## Context Verified

- `diaverseapi/app/cabinet/item_catalog/providers.py` already exposes character metadata with `min_evolution`, `max_evolution`, and `evolution_options`.
- `diaverseapi/app/cabinet/fulfillment/handlers.py` already grants characters using `options_json.evolution`.
- `diaverseapi/app/characters/grants.py` validates requested evolution against character rarity limits.
- `diaweb/frontend/modules/staff-shop/shop-pet-evolution.ts` already has helper functions for character evolution options.
- Crypton currently calculates recommended price from base offer unit price, which is not valid for pet evolution pricing.
- Existing `.ai-factory/RESEARCH.md` content is unrelated to this feature and was not reused as a source of truth.

## Tasks

### Backend Phase

- [x] **1. Backend: Add Evolution Contract, Validation Error, and HTTP Mapping**

Repository: `diaverseapi`

Files:

- `app/cabinet/offers/crypton/schemas.py`
- `app/cabinet/offers/crypton/exceptions.py`
- `app/cabinet/offers/crypton/api.py`
- `app/cabinet/offers/crypton/admin_api.py`
- `app/cabinet/offers/crypton/service.py`
- `tests/test_cabinet_crypton.py`

Work:

- Add optional `selected_evolution` to `CryptonRequestSubmitRequest`.
- Add `selected_evolution`, `selected_evolution_label`, `is_character_offer`, and, where useful, `evolution_options` to `CryptonSelectedOfferSummaryRead` and `CryptonRequestDetailRead`.
- Add a domain error such as `CryptonEvolutionValidationError` and map it to HTTP 422 in public and admin Crypton API error handling.
- Add a focused service helper such as `_resolve_selected_character_evolution(...)` that detects `ShopSourceType.character`, reads allowed options from `shop_item.metadata_json`, and falls back to the authoritative character rarity rules if metadata is incomplete.
- For character offers, normalize missing legacy selections to evolution 1, but reject explicit invalid selections.
- Preserve existing non-character submit behavior unchanged.

Logging requirements:

- Log `INFO` when a Crypton request submit resolves character evolution metadata.
- Log `DEBUG` for resolved allowed evolution options and selected value.
- Log `WARN` for invalid, explicit out-of-range, or metadata-mismatched pet evolution data before raising validation errors.

- [x] **2. Backend: Apply Pet Pricing Rule and Persist Evolution Snapshots**

Repository: `diaverseapi`

Depends on: Task 1

Files:

- `app/cabinet/offers/crypton/service.py`
- `app/cabinet/offers/crypton/catalog_policy.py`
- `tests/test_cabinet_crypton.py`

Work:

- Resolve character-offer status and selected evolution before calling `_validate_proposed_price`.
- For character/pet offers, set `recommended_price_amount=None` and skip the proposed-price-above-market validation.
- Persist selected evolution fields in request `metadata_json`, `item_snapshot_json`, and `pricing_snapshot_json`.
- Keep `market_price_amount` as the original catalog market/reference amount for audit only; do not treat it as a hard cap for pet offers.
- Keep regular non-pet recommended price and market-cap validation unchanged.

Logging requirements:

- Log `INFO` when character pet pricing is switched to manual review mode.
- Log `DEBUG` with request id, offer id, `is_character_offer`, and selected evolution; do not log user-entered price beyond existing safe amount logs.
- Log `WARN` if a character source cannot produce evolution metadata and the service falls back to evolution 1.

- [x] **3. Backend: Apply Evolution to Fulfillment Lines**

Repository: `diaverseapi`

Depends on: Task 2

Files:

- `app/cabinet/offers/crypton/fulfillment.py`
- `app/cabinet/offers/crypton/service.py`
- `tests/test_cabinet_crypton.py`

Work:

- Merge selected evolution into `options_json` only for fulfillment lines where `item_type == "character"`, preferably matching `item_ref` to the selected `shop_item.source_ref`.
- Copy and merge configured `options_json` instead of mutating `CabShopItemFulfillmentLine.options_json`.
- Preserve configured `options_json` for non-character bundle/static fulfillment lines.
- Include selected evolution in batch metadata and request detail payloads where useful.
- Ensure legacy requests without selected evolution still fulfill safely as evolution 1 or an existing configured character line value.

Logging requirements:

- Log `DEBUG` when selected evolution is merged into a fulfillment line.
- Log `INFO` when a character fulfillment is prepared with selected evolution.
- Log `WARN` if a character offer reaches fulfillment without resolvable evolution metadata.

- [x] **4. Backend: Propagate Evolution to Web, Ops, Payment, and Telegram Payloads**

Repository: `diaverseapi`

Depends on: Task 2

Files:

- `app/cabinet/offers/crypton/schemas.py`
- `app/cabinet/offers/crypton/service.py`
- `tests/test_cabinet_crypton.py`

Work:

- Include selected evolution/evolution label in `_selected_offer_summary`, `_request_detail`, admin list/detail responses, and current request state.
- Include selected evolution/evolution label in new-request ops alert metadata and summary.
- Include selected evolution/evolution label in Crypton checkout/payment payload metadata.
- Include selected evolution/evolution label in `_decision_telegram_payload` sent to `diaverse-auth-bot`.
- Keep legacy and non-pet payloads clean by omitting empty evolution fields where the consumer should not show them.

Logging requirements:

- Log `DEBUG` when outgoing Crypton payloads include selected evolution.
- Do not add sensitive user, price, or payment details beyond existing safe payload summaries.

### Frontend Phase

- [x] **5. Frontend: Extend Crypton API Types, Normalizers, and Exports**

Repository: `diaweb`

Depends on: Backend field names from Tasks 1, 2, and 4

Files:

- `frontend/modules/crypton/types.ts`
- `frontend/modules/crypton/api.ts`
- `frontend/modules/crypton/shopCatalogAdapter.ts`
- `frontend/modules/staff-shop/shop-pet-evolution.ts`
- `frontend/modules/crypton/index.ts`

Work:

- Add `selectedEvolution` to `CryptonRequestSubmitInput`.
- Add selected evolution fields to `CryptonSelectedOfferSummary` and `CryptonRequestDetail`.
- Normalize selected evolution fields from backend read models.
- Reuse or extend existing pet-evolution helpers so they can read top-level metadata and nested Crypton metadata from `display`, `item`, and `offer`.
- Export any new helper needed by `CryptonOfferBuilder` without leaking staff-only implementation details.
- Keep non-character offers unchanged.

Logging requirements:

- Emit development-only warnings when character metadata is malformed or has no usable evolution options.
- Avoid logging user-entered prices or sensitive request details.

- [x] **6. Frontend: Forward Evolution Through BFF and API Boundary Tests**

Repository: `diaweb`

Depends on: Task 5

Files:

- `frontend/modules/crypton/api.ts`
- `frontend/app/api/cabinet/offers/crypton/requests/route.ts`
- `frontend/__tests__/app/api/cabinet/offers/crypton/route.test.ts`
- `frontend/__tests__/app/api/cabinet/offers/crypton/proxy-utils.test.ts`

Work:

- Send `selected_evolution` in the submit payload only when a pet/character offer has an evolution selection.
- Include `selected_evolution` in the BFF route's safe development diagnostic summary.
- Add or update BFF tests to assert the submit JSON forwards `selected_evolution` unchanged.
- Add or update API/normalizer test coverage for selected evolution fields if an existing test file is available; otherwise cover the behavior through modal submit and BFF route tests.

Logging requirements:

- Keep BFF diagnostic logging safe: log only boolean/number selection metadata, not raw user-entered prices beyond existing fields.
- Continue warning on malformed JSON via `safeParseCryptonBody`.

- [x] **7. Frontend: Add Evolution Selector to Crypton Offer Modal**

Repository: `diaweb`

Depends on: Task 5 and Task 6

Files:

- `frontend/modules/crypton/components/CryptonOfferBuilder.tsx`
- `frontend/modules/crypton/components/cryptonOfferModal.module.css`
- `frontend/modules/i18n/types.ts`
- `frontend/modules/i18n/dictionaries/ru.json`
- `frontend/modules/i18n/dictionaries/en.json`
- `frontend/__tests__/modules/crypton/CryptonOfferBuilder.test.tsx`
- `frontend/__tests__/modules/crypton/test-helpers.ts`

Work:

- Show an evolution selector when the selected catalog item is a pet/character offer.
- Derive `selectedShopItem` from the same `mapCryptonOfferToShopCatalogItem` adapter output used for catalog cards.
- Populate options from the selected pet's available evolution range.
- Reset selected evolution to the pet-specific default when the selected offer changes.
- Hide recommended price and recommended-price copy for pet/character offers.
- Disable or hide the frontend "above market" validation for pet/character offers.
- Submit selected evolution with the request.
- Display selected evolution in the request status/detail area after submission and in immutable status panels.
- Preserve existing units, price input, validation, and rendering for regular offers.

Logging requirements:

- Log `DEBUG` during local development when a pet offer selection changes.
- Log `WARN` during local development if a selected pet offer lacks evolution options.

- [x] **8. Frontend: Show Evolution in Staff Crypton Requests**

Repository: `diaweb`

Depends on: Task 5

Files:

- `frontend/modules/staff-shop/components/CryptonRequestsPanel.tsx`
- `frontend/modules/staff-shop/crypton-admin-types.ts`
- `frontend/modules/i18n/types.ts`
- `frontend/modules/i18n/dictionaries/ru.json`
- `frontend/modules/i18n/dictionaries/en.json`
- `frontend/__tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx`

Work:

- Add selected evolution fields to staff request types.
- Show selected evolution near selected offer title/quantity in desktop list rows, mobile list cards, and detail view.
- Read list evolution from `selected_offer`; read detail evolution from normalized fields, `metadata`, or `item_snapshot` fallback so list/detail cannot drift.
- Ensure staff can see the requested evolution before approve, reject, or counter actions.
- Avoid showing `"0"` as a counter-price placeholder when pet requests intentionally have no recommended price.
- Keep existing display unchanged when the request is not a pet offer or has no evolution metadata.

Logging requirements:

- Avoid noisy runtime logging in staff UI.
- Emit development-only warnings for character requests missing selected evolution if the backend identifies them as pet/character offers.

### Telegram Phase

- [x] **9. Telegram Auth Bot: Render Evolution in Crypton Captions**

Repository: `diaverse-auth-bot`

Depends on: Task 4

Files:

- `app/services/outbox_delivery.py`
- `tests/test_outbox_delivery.py`

Work:

- Read selected evolution/evolution label from Crypton notification payloads.
- Add an evolution line to Crypton status captions when the payload contains it, e.g. `Эволюция: E5`.
- Do not render an empty evolution line for legacy or non-pet requests.
- Preserve all existing caption fields and formatting.

Logging requirements:

- Do not add sensitive payload logging.
- Preserve existing delivery logs and only add warning-level diagnostics if caption payload shape is invalid.

### Verification Phase

- [x] **10. Backend Verification Tests**

Repository: `diaverseapi`

Files:

- `tests/test_cabinet_crypton.py`

Work:

- Test submit flow for a character offer with selected evolution.
- Test invalid evolution rejection.
- Test pet request has no recommended price and bypasses above-market rejection.
- Test fulfillment line receives `options_json.evolution`.
- Test decision Telegram payload includes selected evolution.
- Test ops alert metadata/summary and payment payload include selected evolution for pet offers.
- Test regular non-pet offers keep the old recommended price and market-cap validation.
- Test public API maps invalid selected evolution to HTTP 422 with a stable reason code.

Commands:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_crypton.py -q
.\.venv\Scripts\python.exe -m ruff check app/cabinet/offers/crypton tests/test_cabinet_crypton.py
```

Logging requirements:

- Assert important log paths with `caplog` where practical, especially invalid evolution validation and fulfillment preparation.

- [x] **11. Frontend and Auth Bot Verification Tests**

Repositories: `diaweb`, `diaverse-auth-bot`

Files:

- `diaweb/frontend/__tests__/modules/crypton/CryptonOfferBuilder.test.tsx`
- `diaweb/frontend/__tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx`
- `diaweb/frontend/__tests__/app/api/cabinet/offers/crypton/route.test.ts`
- `diaweb/frontend/__tests__/app/api/cabinet/offers/crypton/proxy-utils.test.ts`
- `diaverse-auth-bot/tests/test_outbox_delivery.py`

Work:

- Test the modal renders evolution options for pet offers.
- Test selecting an evolution sends it in the submit payload.
- Test recommended price is hidden for pet offers.
- Test non-pet offers still show recommended price and old validation behavior.
- Test staff panel displays selected evolution in list and detail views.
- Test BFF submit route forwards `selected_evolution`.
- Test Telegram caption includes evolution when present and omits it when absent.

Commands:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm test -- __tests__/modules/crypton/CryptonOfferBuilder.test.tsx __tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx __tests__/app/api/cabinet/offers/crypton/route.test.ts __tests__/app/api/cabinet/offers/crypton/proxy-utils.test.ts
npm run typecheck

cd C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot
python -m pytest tests/test_outbox_delivery.py -q
```

Logging requirements:

- Cover development-warning paths only where the existing test setup can do it without brittle console assertions.

## Full Verification Plan

Run after implementation:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_crypton.py -q
.\.venv\Scripts\python.exe -m ruff check app/cabinet/offers/crypton tests/test_cabinet_crypton.py

cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm test -- __tests__/modules/crypton/CryptonOfferBuilder.test.tsx __tests__/modules/staff-shop/CryptonRequestsPanel.test.tsx __tests__/app/api/cabinet/offers/crypton/route.test.ts __tests__/app/api/cabinet/offers/crypton/proxy-utils.test.ts
npm run typecheck

cd C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot
python -m pytest tests/test_outbox_delivery.py -q
```

No Alembic migration is planned. If implementation unexpectedly requires schema changes, add a migration and run the PostgreSQL DDL safety check before verification is considered complete.

After meaningful source changes, run targeted GBrain sync for affected repositories or the full workspace sync.

## Suggested Commit Plan

Commit per affected repository after tests pass:

1. `diaverseapi`: `feat(api): support crypton pet evolution requests`
2. `diaweb`: `feat(web): add crypton pet evolution selection`
3. `diaverse-auth-bot`: `feat(auth-bot): show crypton pet evolution`

Root workspace commit only if this plan or related root documentation is meant to be persisted separately.

## Ready for Implementation

Next command:

```text
$aif-implement
```
