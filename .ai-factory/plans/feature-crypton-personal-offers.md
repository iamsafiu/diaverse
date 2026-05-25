# Implementation Plan: Crypton Personal Offers

Branch: feature/crypton-personal-offers
Created: 2026-05-18
Refined: 2026-05-18

## Settings
- Testing: yes
- Logging: verbose
- Docs: no
- Assumptions: strict 30-day cooldown, actual popup open counts as shown, currency is USDT, catalog source is public purchasable shop offers, quantity means number of shop offer units.

## Workspace Mode
- Mode: multi-repo full
- Workspace root: C:\Users\Indigo\Desktop\diaverse
- Shared graph: C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json
- Plan source: docs\tasks\crypton.md plus user decisions from this session.

## Repository Matrix
| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| diaweb | C:\Users\Indigo\Desktop\diaverse\diaweb | yes | feature/crypton-personal-offers | clean | frontend, BFF, staff UI |
| diaverseapi | C:\Users\Indigo\Desktop\diaverse\diaverseapi | yes | feature/crypton-personal-offers | clean | backend domain, DB, payments, fulfillment |
| aibot | C:\Users\Indigo\Desktop\diaverse\aibot | no | dev | clean | not needed for MVP |

## Product Decisions
- Crypton is a separate backend domain: `app/cabinet/offers/crypton/`.
- Do not reuse `shop/promo_offer` as source of truth; reuse only UX/API patterns.
- User chooses a public active shop offer. `offer_units_quantity = 2` means two copies of that shop offer, so fulfillment is multiplied.
- Market price is the effective public USDT shop price multiplied by `offer_units_quantity`; snapshot display price and manual discount data for audit.
- First release has no auto approve. Backend computes recommendation, staff decides approve/reject/counter.
- Payment uses generic cabinet payments with `domain_code = "crypton"` and a dedicated finalizer.
- MVP staff access reuses `shop:view/edit`.
- MVP notifications: web popup and inbox notification are required; admin ops/Telegram is best-effort; real push/user Telegram can follow if an existing sender is available.
- Showing is two-step: `GET state` may return an available window, but cooldown starts only after frontend opens the popup and calls `claim-shown`.
- The fullscreen popup is the first-discovery surface; after `claim-shown`, Crypton must also appear in `/offers` as a resumable/status card.
- Closing the fullscreen popup does not cancel the offer. The user can reopen the same Crypton flow from the `/offers` card.
- The `/offers` card uses the same Crypton backend state/request data as the popup, not a separate offer copy.

## Tasks

### Phase 1: Backend Foundation
- [x] Task 1: Create Crypton SQLModel models, enums, Alembic migration, and Alembic model import.
  Deliverables: add `diaverseapi/app/cabinet/offers/crypton/models.py`; import models in `diaverseapi/migrations/env.py`; create `diaverseapi/migrations/versions/*_crypton_personal_offers.py`; define `CabCryptonOfferWindow`, `CabCryptonRequest`, status enums, FK links to users/shop items/shop offers/payment sessions, `shown_at`, `cooldown_until`, `scheduled_at`, `show_claimed_at`, `decision_expires_at`, short explicit indexes and constraints for one active request per user and 30-day history queries. Logging: DEBUG model registration; migration notes must call out short PostgreSQL-safe constraint/index names. Dependencies: none.

- [x] Task 2: Add backend schemas, dependencies, exceptions, and package exports.
  Deliverables: create `schemas.py`, `dependencies.py`, `exceptions.py`, `__init__.py` under `diaverseapi/app/cabinet/offers/crypton/`; define DTOs for state, claim-shown, catalog, submit, request detail, checkout, payment capabilities, admin list/detail, decisions, status errors, and a compact `/offers` card summary for the current discovered/request/payment state. Logging: DEBUG request normalization, WARN invalid timezone/currency/request transition, ERROR unexpected service failures. Dependencies: Task 1.

- [x] Task 3: Wire `crypton` into generic cabinet payment domain support.
  Deliverables: update `diaverseapi/app/cabinet/payments/types.py` so `CabinetPaymentDomainCode` includes `"crypton"`; update `payments/registry.py` provider domain lists; verify quote/capability paths accept authenticated `crypton` sessions; keep guest checkout unsupported for Crypton unless explicitly needed. Logging: DEBUG provider capability resolution for `crypton`, WARN unsupported provider/actor, ERROR missing provider. Dependencies: Task 2.

- [x] Task 4: Define Crypton catalog and pricing policy.
  Deliverables: implement a policy module or service helpers for public active visible purchasable external USDT shop offers; compute effective public unit price from shop offer fields; support `metadata_json.crypton.max_units` override and default `max_units` by shop section; store snapshots for item title, image, section, source type/ref, offer price, manual discount, and provider. Logging: DEBUG catalog filters and excluded reasons, INFO pricing snapshot, WARN invalid quantity/price range. Dependencies: Tasks 1-2.

### Phase 2: Backend User And Admin Contract
- [x] Task 5: Implement eligibility and lazy scheduling without burning the chance.
  Deliverables: in `service.py`, create per-user lazy schedules, enforce authenticated-only access, strict 30-day cooldown from `show_claimed_at`, local-time cutoff before 20:00, no active request, and deterministic handling when a scheduled time has passed; `GET state` must not mark the offer shown. Logging: DEBUG full eligibility decision tree, INFO available window returned, WARN blocked states, ERROR persistence failures. Dependencies: Tasks 1-4.

- [x] Task 6: Implement explicit `claim-shown` lifecycle.
  Deliverables: add `POST /v1/cabinet/offers/crypton/state/claim-shown` or equivalent; atomically mark the window shown after frontend opens the popup; start `cooldown_until = shown_at + 30 days`; make repeated claim idempotent; reject stale/foreign windows; return enough state for `/offers` to render the newly discovered Crypton card immediately. Logging: INFO window claimed shown, DEBUG idempotency path, WARN invalid claim attempts. Dependencies: Task 5.

- [x] Task 7: Implement user catalog, request submission, detail, and anti-abuse APIs.
  Deliverables: add `api.py`; register user router in `diaverseapi/app/routers/v1/endpoints.py`; endpoints: `GET /state`, `POST /state/claim-shown`, `GET /catalog`, `POST /requests`, `GET /requests/{id}`; make `GET /state` return popup eligibility plus the current `/offers` card summary when Crypton is already discovered or has a request; enforce one active request, no edit after submit, no resubmit after reject, shop offer snapshot, total proposed USDT price, min/max validation, recommended price. Logging: INFO submit/detail reads, DEBUG actor/source refs, WARN anti-abuse or validation rejections. Dependencies: Tasks 5-6.

- [x] Task 8: Implement staff admin API and decision workflow.
  Deliverables: add `admin_api.py` and register under `/v1/admin/offers/crypton`; list pending/history, detail view, approve at user price, reject with reason, counter with staff price, staff actor and decision timestamps; protect with `require_staff_module_access("shop", "view/edit")`. Logging: INFO staff decisions, DEBUG decision payload snapshots, WARN invalid transitions or stale requests. Dependencies: Task 7.

- [x] Task 9: Implement expiry and reconciliation behavior.
  Deliverables: expire approved/countered decisions after 12 hours; block checkout after expiry; lazily reconcile expired requests in state/detail/admin list and optionally via a small service method suitable for future worker scheduling; make expiry idempotent. Logging: INFO expired request count, DEBUG expiry checks, WARN checkout blocked by expiry. Dependencies: Task 8.

### Phase 3: Backend Payment, Fulfillment, Notifications
- [x] Task 10: Implement Crypton fulfillment adapter based on shop offer units.
  Deliverables: create helper/service code that converts a selected shop item plus `offer_units_quantity` into fulfillment lines; configured fulfillment lines multiply by units; fallback line uses `shop_item.fulfillment_quantity * units`; step pass, unique, bundle, and broken source cases must be validated explicitly; use `source_domain="crypton"` and idempotency keyed by request/payment. Logging: DEBUG prepared lines and snapshot keys, INFO grant batch submitted, WARN unsupported source/unique conflict, ERROR grant failures. Dependencies: Tasks 4 and 8.

- [x] Task 11: Implement Crypton checkout, status, and payment finalizer.
  Deliverables: add `POST /requests/{id}/checkout`, `GET /checkout/{public_checkout_reference}`, `GET /payment-capabilities`; create `payment_finalizer.py`; register `CryptonPaymentFinalizer` in `payments/finalizers.py`; create `CabinetPaymentSession(domain_code="crypton")`; validate amount/status/expiry; call Crypton fulfillment adapter; set final request status; return compatible checkout/status contract for frontend payment pages. Logging: INFO checkout created/finalized, DEBUG payment/session/source refs, WARN amount/expiry/status mismatch, ERROR finalizer failure. Dependencies: Tasks 3, 9, and 10.

- [x] Task 12: Add Crypton notifications and best-effort ops/Telegram alert.
  Deliverables: extend `cabinet/notifications` formatting for `source_domain="crypton"`; create decision notifications for approved/rejected/countered with action payloads that open `/offers` or the Crypton payment route as appropriate; create payment success notification through fulfillment; if existing logging/ops notification gateway is suitable, enqueue an admin alert after new request with admin URL. Logging: INFO notification created, DEBUG notification payload, WARN skipped/failed delivery as non-fatal. Dependencies: Tasks 8 and 11.

- [x] Task 13: Integrate Crypton into finance and operational monitoring.
  Deliverables: add `CryptonPaymentFactLoader` or equivalent and include Crypton as a source in cabinet finance overview/reporting; add monitoring for stuck Crypton generic payment sessions, either as a dedicated detector or a generalized shop-like detector; use `CabLogModule.shop` with `crypton.*` event codes for MVP unless a dedicated module is implemented cleanly. Logging: INFO finance facts loaded and stuck sessions scanned, DEBUG dedupe/business keys, WARN stuck/review-required sessions. Dependencies: Task 11.

- [x] Task 14: Add backend tests.
  Deliverables: pytest coverage for 30-day eligibility, local 20:00 cutoff, two-step state/claim-shown, `/offers` card summary visibility after claim-shown, one active request, public shop catalog filtering, `metadata_json.crypton.max_units`, quantity-as-shop-units, price validation/recommendation, admin transitions, expiry, checkout capabilities/status, finalizer idempotency, fulfillment multiplication, notifications, finance facts, and Alembic graph. Logging: tests assert key warning/info paths where existing patterns support it. Dependencies: Tasks 1-13.

### Phase 4: Frontend Foundation
- [x] Task 15: Add frontend i18n, dictionary, and Crypton asset handling.
  Deliverables: extend `Dictionary` with `crypton`; update `ru.json` and `en.json`; pass `dictionary.crypton` through cabinet layout/providers and `/offers`; add Crypton image asset path/fallback under `public` or a documented asset location; include short legend copy, `/offers` card labels, status labels, CTA labels, and all popup/request/payment errors. Logging: DEBUG missing asset fallback in development, WARN malformed dictionary-dependent data where applicable. Dependencies: backend contract shape from Tasks 2 and 7.

- [x] Task 16: Add Crypton BFF routes and typed frontend API.
  Deliverables: create `diaweb/frontend/app/api/cabinet/offers/crypton/**/route.ts` for state, claim-shown, catalog, requests, checkout, checkout status, payment capabilities; create `diaweb/frontend/modules/crypton/api.ts`, `types.ts`, hooks, constants, and normalization helpers for popup state and `/offers` card state; forward cookies, `X-TimeZone`, `Accept-Language`, and `X-Telegram-WebApp-Platform`. Logging: DEBUG BFF upstream timing, INFO submit/checkout, WARN malformed responses, ERROR transport failures. Dependencies: Tasks 7 and 11.

### Phase 5: Frontend User Flow
- [x] Task 17: Implement `CryptonOfferGate` with priority over shop promo.
  Deliverables: mount before `ShopPromoOfferGate` in `CabinetProviders`; wait 10 seconds of eligible cabinet route activity; call `GET state`; open modal only when available; immediately call `claim-shown` after actual modal open; invalidate/update Crypton queries so `/offers` shows the resumable card after claim-shown; suppress shop promo while Crypton is pending/open; handle route exclusions and reduced auth/session states. Logging: DEBUG gate timing/state/route checks, INFO popup opened and shown claimed, WARN claim/state failures. Dependencies: Tasks 15-16.

- [x] Task 18: Implement fullscreen Crypton popup and request wizard.
  Deliverables: fullscreen portal with screen shake, background reveal, typewriter text, Crypton image, reduced-motion fallback, focus/escape handling; wizard with public shop offer search/categories, offer-unit quantity, total USDT proposed price input, min/max/recommended context, confirmation, pending state, and no edit after submit; structure the wizard so it can be opened both from the fullscreen discovery popup and from the `/offers` card. Logging: INFO submit attempt/result, DEBUG selection/price state, WARN validation failures or blocked submit. Dependencies: Task 17.

- [x] Task 19: Add Crypton resumable/status card to the `/offers` hub.
  Deliverables: update `diaweb/frontend/modules/offers/components/OffersHub.tsx` and related offer components to render a Crypton card when `GET state` returns a discovered/request/payment summary; show no card before `claim-shown` in MVP; let users reopen the same wizard after closing the fullscreen popup; show status after submit (`pending`, `approved`, `countered`, `rejected`, `expired`, `paid/fulfilled`), selected item, offer-unit quantity, proposed price, market price, decision price, expiry countdown when relevant, and the correct CTA (`open`, `view request`, `pay`, `accepted/closed`). Logging: DEBUG card state mapping, INFO card CTA clicked, WARN inconsistent or stale summary data. Dependencies: Tasks 16 and 18.

- [x] Task 20: Implement decision popup and Crypton payment page.
  Deliverables: show approved/rejected/countered decision at next login/state check; handle inbox notification action payloads; keep `/offers` card in sync with the decision state; add checkout CTA; create route such as `/{lang}/offers/crypton/payment`; reuse shared payment helpers/status UI where practical; invalidate notifications and Crypton queries after payment success. Logging: INFO decision shown and checkout clicked, DEBUG checkout status polling, WARN expired/invalid decision states. Dependencies: Tasks 11, 12, 16, and 19.

### Phase 6: Frontend Staff Flow
- [x] Task 21: Add staff Crypton requests UI.
  Deliverables: add staff API client/types; add a `Crypton` tab inside `/staff/shop` or adjacent shop admin workspace; show pending/history table, detail panel, user, item, units, proposed total, market total, recommended price, status, timestamps, approve/reject/counter actions. Logging: INFO staff action submitted, DEBUG filters/pagination/detail payloads, WARN failed transitions. Dependencies: Task 8 and Task 16.

- [x] Task 22: Add frontend tests.
  Deliverables: Vitest coverage for BFF proxy routes, i18n typing/dictionaries, state -> claim-shown flow, `/offers` card hidden before claim-shown, `/offers` card visible after claim-shown, reopen wizard from card after fullscreen close, status rendering for pending/approved/countered/rejected/expired/paid, gate priority over shop promo, 10-second dwell behavior, reduced-motion fallback, asset fallback, price/quantity validation, decision popup, payment page polling, and staff action panel. Logging: tests cover console warning paths where existing tests mock logging. Dependencies: Tasks 15-21.

### Phase 7: Verification
- [x] Task 23: Run cross-repo verification and refresh graph.
  Deliverables: backend pytest subset plus Alembic checks; frontend Vitest/lint/type checks; manual browser smoke for popup, claim-shown, close popup then reopen from `/offers`, request submit, `/offers` status changes, staff decision, checkout redirect/status; run shared Graphify refresh after code changes. Logging: capture failing command names and exact repo context in implementation notes. Dependencies: Tasks 14 and 22.

## Verification Plan
- diaverseapi: `.\.venv\Scripts\python.exe -m pytest tests/test_alembic_graph.py <new crypton tests>`
- diaverseapi: `.\.venv\Scripts\python.exe -m alembic heads`
- diaverseapi: `.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
- diaweb: `npm test -- --run <crypton tests>`
- diaweb: `npm run lint` and the repo's type/build command if available
- Browser: smoke `CryptonOfferGate`, `claim-shown`, close popup then reopen from `/offers`, request submit, `/offers` status updates, staff decision, checkout redirect/status
- Graph: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`

## Commit Plan
- Commit 1 after Tasks 1-7 in `diaverseapi`: `feat: add crypton offer backend contract`
- Commit 2 after Tasks 8-14 in `diaverseapi`: `feat: wire crypton admin payments and reporting`
- Commit 3 after Tasks 15-20 in `diaweb`: `feat: add crypton user offer flow`
- Commit 4 after Tasks 21-22 in `diaweb`: `feat: add crypton staff review flow`
- Commit 5 after Task 23 per affected repo: `test: verify crypton personal offers`
