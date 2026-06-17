# Implementation Plan: Club Store Banner Payment Modal

Branch: none
Created: 2026-06-17
Mode: fast plan, local workspace update only

## Settings

- Testing: yes, targeted backend and frontend tests are required because this changes paid access.
- Logging: verbose for payment, checkout, finalization, and client state transitions; never log raw activation tokens, full activation URLs, private group invite URLs, callback signatures, or provider secrets.
- Docs: yes, update the club/payment runbook after implementation and run targeted GBrain sync.
- Branching: no branch creation in fast mode.
- Remote actions: none planned.

## Workspace Mode

- Mode: multi-repo fast
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: local GBrain `diaverse-docs` plus raw source verification
- Primary affected repositories: `diaverseapi`, `diaweb`

## Repository Matrix

| Repository | Path | Affected | Branch | Git status | Role |
| --- | --- | --- | --- | --- | --- |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | current | clean | shop banner, BFF routes, club payment UI |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | current | clean | club checkout API, payment finalization, providers |
| `diaverse` root | `C:\Users\Indigo\Desktop\diaverse` | yes | current | dirty with unrelated docs/patches | plan/docs only |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | current | dirty with unrelated referral/env changes | existing paid activation reference only |
| `diaverse-mobile` | `C:\Users\Indigo\Desktop\diaverse\diaverse-mobile` | no | current | clean | out of scope |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | current | dirty unrelated `docker-compose.prod.yml` | out of scope |
| `diaverse-auth-bot` | `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot` | no | current | clean | out of scope |

## Research Context

Source: `.ai-factory/RESEARCH.md` Active Summary.

- Current Active Summary topic is Advent calendar revenue analysis, not this club checkout task.
- Applicability: not used as requirements input for this plan.
- Current-session sources used instead:
  - GBrain `diaverse-docs` page `club`
  - GBrain `diaverse-docs` page `payments/tribute-runbook`
  - `diaweb/frontend/modules/shop/components/ShopClubBanner.tsx`
  - `diaweb/frontend/modules/shop/components/ShopPaymentModal.tsx`
  - `diaverseapi/app/cabinet/payments/registry.py`
  - `diaverseapi/app/cabinet/payments/service.py`
  - `diaverseapi/app/club/payment_finalizer.py`
  - `diaverseapi/app/club/payments.py`
  - `diaverseapi/app/club/service.py`

## Goal

Clicking the club banner buy button in the shop opens a modal with three payment choices:

- Tribute
- Zion
- Pay1Time

Zion and Pay1Time use direct backend checkout and status polling. Tribute remains an external link-only path: no Tribute API, provider adapter, callback, or reconciliation in this slice.

After successful backend-confirmed payment, the web flow must show:

- the existing club onboarding activation URL
- the private closed-group join link

The links must be returned by backend only after a paid and finalized club payment. The frontend must not hardcode the private group invite link or infer payment success from a Tribute external-link click.

## Key Decisions

1. Do not reuse `/v1/cabinet/shop/checkout` for this feature. Shop checkout creates `CabShopOrder` and grants shop items; club access belongs to `diaverseapi/app/club`.
2. Add cabinet club checkout endpoints under the existing authenticated club cabinet API surface.
3. Use generic cabinet payments with `domain_code="club"` and `source_ref="program_code:<active_program_code>"` or `program:<uuid>`.
4. Add `club` support to Zion and Pay1Time provider registrations.
5. Keep Tribute as an external link-only option in the modal. Do not add Tribute backend API integration.
6. Keep `club10000-bot` out of this implementation. Its Prodamus bridge already proves the post-payment activation pattern, but the shop banner web checkout is owned by `diaweb` + `diaverseapi`.

## Confirmed Business Inputs

- Club checkout first month price: `890 RUB`.
- Club checkout renewal/second month price: `1390 RUB`.
- Access period: `1 month`.
- Tribute mode: external link only, no backend Tribute API/callback/reconciliation.

## Open Inputs Before Live Enablement

- Backend-owned private group invite URL setting or program metadata key.
- Exact Tribute external URL source if the existing hardcoded Telegram Tribute URL should move to env/config.

## Commit Plan

- **Commit 1** (`diaverseapi`, after tasks 1-4): `feat: add club checkout payment flow`
- **Commit 2** (`diaverseapi`, after task 5): `test: cover club checkout finalization`
- **Commit 3** (`diaweb`, after tasks 6-8): `feat: add club banner payment modal`
- **Commit 4** (`diaverse` root, after task 9): `docs: update club checkout runbook`

## Tasks

### Phase 1: Backend Checkout Contract

- [x] Task 1: `diaverseapi` - add club checkout configuration and response contracts.

  Deliverable:
  - Add schemas for club payment capabilities, checkout request, checkout status, and post-payment access payload.
  - Define backend-only config for club checkout price, currency, period days, and private group invite URL, preferring explicit settings or active-program metadata over frontend constants.
  - Encode the confirmed pricing model: first month `890 RUB`, renewal/second month `1390 RUB`, access period `1 month`.
  - Ensure response fields for `activation_url`, `activation_token_id`, `activation_expires_at`, and `group_invite_url` are nullable and hidden until paid/finalized.

  Files:
  - `diaverseapi/app/club/payment_schemas.py`
  - `diaverseapi/app/club/checkout.py` (new service module, if cleaner than expanding `service.py`)
  - `diaverseapi/app/core/settings.py`
  - `diaverseapi/.env.example`

  Logging:
  - `INFO` when club checkout config is resolved for a program.
  - `WARN` when price, period, base URL, or group invite config is missing.
  - `DEBUG` for sanitized program ids and source refs only.
  - Do not log private group invite URLs or activation URLs.

  Dependencies:
  - None.

- [x] Task 2: `diaverseapi` - add authenticated club checkout API endpoints.

  Deliverable:
  - Add `GET /v1/cabinet/club/payment-capabilities`.
  - Add `POST /v1/cabinet/club/checkout`.
  - Add `GET /v1/cabinet/club/checkout/{public_checkout_reference}`.
  - Require authenticated cabinet user; no guest club checkout for this iteration.
  - Create generic payment sessions through `CabinetPaymentsService.create_checkout_session` with `domain_code="club"`.
  - On status fetch, reconcile provider status when appropriate and return access links only after `payment_status=paid` and `finalization_status=completed`.

  Files:
  - `diaverseapi/app/club/cabinet_api.py`
  - `diaverseapi/app/club/checkout.py`
  - `diaverseapi/app/club/dependencies.py`
  - `diaverseapi/app/cabinet/payments/contracts.py` only if shared contracts need a small extension

  Logging:
  - `INFO` on capability lookup, checkout creation, and status fetch with user id, program id, provider code, and public checkout reference.
  - `WARN` for unavailable providers, ownership mismatch, missing checkout, and config blockers.
  - `ERROR` for unexpected provider/session reconciliation failures.
  - Never log raw activation token, full activation URL, private group invite URL, callback signatures, or provider payload secrets.

  Dependencies:
  - Depends on Task 1.

- [x] Task 3: `diaverseapi` - register direct backend providers for club.

  Deliverable:
  - Add `club` to Pay1Time and Zion provider `domain_codes`.
  - Keep Tribute out of `CabinetPaymentProviderCode` and generic payment provider registry for this slice.
  - Ensure `GET /v1/cabinet/club/payment-capabilities` returns direct backend methods only: Pay1Time and Zion when configured/enabled.
  - Leave the external Tribute option to frontend modal handling instead of backend payment capabilities.

  Files:
  - `diaverseapi/app/cabinet/payments/enums.py`
  - `diaverseapi/app/cabinet/payments/registry.py`
  - `diaverseapi/app/core/features.py`
  - `diaverseapi/app/core/settings.py`
  - `diaverseapi/.env.example`

  Logging:
  - `INFO` when club provider capabilities are resolved.
  - `WARN` when Pay1Time or Zion is requested but unavailable for `club`.
  - `ERROR` for provider capability/configuration mismatches.
  - Do not log provider secrets or hosted checkout URLs beyond sanitized references.

  Dependencies:
  - Depends on Task 1 for domain-specific pricing metadata.

- [x] Task 4: `diaverseapi` - finalize generic club payments into membership, activation link, and group access payload.

  Deliverable:
  - Update `ClubPaymentFinalizer` so a paid generic club payment creates or reuses the correct `ClubMembership` and `ClubPaymentContract`.
  - Stop hardcoding Prodamus as the provider for generic club sessions; map `payment_session.provider_code` to the club payment provider/event metadata.
  - Generate or reuse an onboarding activation link through `ClubService.create_activation_link`.
  - Persist safe activation metadata on `CabinetPaymentSession.metadata_json`, including token id and membership id, not raw token value.
  - Ensure duplicate callback/status polling does not create duplicate memberships, contracts, or user-visible activation links where reuse is expected.
  - Expose private group link only through the club checkout status response after finalization succeeds.

  Files:
  - `diaverseapi/app/club/payment_finalizer.py`
  - `diaverseapi/app/club/payments.py`
  - `diaverseapi/app/club/service.py`
  - `diaverseapi/app/club/repositories.py` if lookup/reuse helpers are needed
  - `diaverseapi/app/club/payment_schemas.py`

  Logging:
  - `INFO` when payment finalization creates/reuses membership, records contract, and creates/reuses activation token.
  - `WARN` for duplicate finalization, missing program, missing group link after paid status, and activation generation failure.
  - `ERROR` for unexpected finalizer exceptions before marking session failed/review-required.
  - Do not log raw activation URL, raw activation token, private invite URL, or signed provider payloads.

  Dependencies:
  - Depends on Tasks 1-3.

### Phase 2: Backend Tests

- [x] Task 5: `diaverseapi` - add targeted tests for club checkout, providers, and finalization.

  Deliverable:
  - Cover payment capabilities for `club` with Pay1Time and Zion feature-flag states.
  - Cover authenticated checkout creation and status ownership.
  - Cover paid finalization creating membership, contract, activation token id, and gated post-payment links.
  - Cover unpaid/failed/review statuses not exposing onboarding or group links.
  - Cover idempotent duplicate callback/status polling.
  - Assert the flow does not create `CabShopOrder` or shop grants.

  Files:
  - `diaverseapi/tests/test_club_payments.py`
  - `diaverseapi/tests/test_club_cabinet_api.py`
  - `diaverseapi/tests/test_club_checkout.py` (new)
  - `diaverseapi/tests/test_cabinet_payment_registry.py` or equivalent existing provider-registry test
  - no Tribute provider tests in this slice because Tribute is external link-only

  Logging:
  - Use test log capture where useful to ensure raw activation URLs, private invite URLs, and provider secrets are not emitted.
  - Keep provider payload fixtures redacted and synthetic.

  Dependencies:
  - Depends on Tasks 1-4.

### Phase 3: Frontend Integration

- [x] Task 6: `diaweb` - add club checkout BFF routes, API client, and hooks.

  Deliverable:
  - Add same-origin BFF routes for club payment capabilities, checkout creation, and checkout status.
  - Forward cabinet cookies, `Accept-Language`, `X-TimeZone`, and `x-platform: cabinet` following existing club/shop BFF patterns.
  - Add frontend types and normalizers for club checkout result, provider capabilities, access links, and errors.
  - Add hooks for capabilities, checkout mutation, and status polling.
  - Create club checkout idempotency keys client-side.

  Files:
  - `diaweb/frontend/app/api/cabinet/club/_utils.ts`
  - `diaweb/frontend/app/api/cabinet/club/payment-capabilities/route.ts` (new)
  - `diaweb/frontend/app/api/cabinet/club/checkout/route.ts` (new)
  - `diaweb/frontend/app/api/cabinet/club/checkout/[publicCheckoutReference]/route.ts` (new)
  - `diaweb/frontend/modules/club-purchase/api.ts` (new)
  - `diaweb/frontend/modules/club-purchase/types.ts` (new)
  - `diaweb/frontend/modules/club-purchase/hooks/*.ts` (new)

  Logging:
  - `console.debug` in development for request start/success with provider code and public reference only.
  - `console.warn` for controlled API failures with status/code.
  - Never log activation URLs, activation query tokens, private group invite URLs, or full provider redirect URLs.

  Dependencies:
  - Depends on backend contract from Tasks 1-2.

- [x] Task 7: `diaweb` - replace banner CTA with a three-method payment modal and club payment status page.

  Deliverable:
  - Replace the hardcoded Tribute anchor in `ShopClubBanner` with a club purchase modal.
  - Show three choices: external Tribute link, backend Zion checkout, and backend Pay1Time checkout.
  - Initialize backend checkout after Zion/Pay1Time selection and route to a club payment status page.
  - Open the configured Tribute URL directly for the Tribute choice; do not route Tribute through backend payment status.
  - Reuse shared payment helpers for hosted checkout popup/open-link behavior where possible.
  - On successful paid/finalized status, show two actions:
    - `Пройти онбординг` linking to backend `activation_url`
    - `Вступить в закрытую группу` linking to backend `group_invite_url`
  - Enable the shop club banner if product wants this flow live on shop home.
  - Keep modal focus trap, escape close, mobile layout, and no-layout-shift behavior.

  Files:
  - `diaweb/frontend/modules/shop/components/ShopClubBanner.tsx`
  - `diaweb/frontend/modules/shop/components/shopClubBanner.module.css`
  - `diaweb/frontend/modules/shop/components/ShopHomePage.tsx`
  - `diaweb/frontend/modules/club-purchase/components/ClubPurchaseModal.tsx` (new)
  - `diaweb/frontend/modules/club-purchase/components/ClubPaymentPage.tsx` (new)
  - `diaweb/frontend/app/[lang]/(cabinet)/club/payment/page.tsx` (new or nearest existing route convention)
  - `diaweb/frontend/modules/i18n` dictionaries for shop/club payment labels

  Logging:
  - Development-only `console.debug` for modal open, provider selected, checkout initialized, and status view state.
  - `console.warn` for popup blocked, missing checkout reference, or controlled payment error.
  - Do not log onboarding activation URLs, raw activation query tokens, private group invite URLs, or full provider redirect URLs.

  Dependencies:
  - Depends on Task 6 and backend status response from Tasks 2-4.

- [x] Task 8: `diaweb` - add frontend tests for modal, BFF, and success links.

  Deliverable:
  - Cover banner click opening the modal.
  - Cover the three payment choices rendering: external Tribute link plus backend Zion/Pay1Time methods.
  - Cover Zion/Pay1Time selection calling club checkout with idempotency key.
  - Cover Tribute selection opening the configured external URL without calling club checkout.
  - Cover payment status page opening hosted checkout and then showing onboarding/group actions only after paid/finalized status.
  - Cover no activation/group links on pending, failed, expired, or review-required states.
  - Cover focus/escape behavior enough to protect the existing modal UX.

  Files:
  - `diaweb/frontend/__tests__/modules/shop/ShopClubBanner.test.tsx` or existing nearby test convention
  - `diaweb/frontend/__tests__/modules/club-purchase/*.test.tsx` (new)
  - `diaweb/frontend/__tests__/app/api/cabinet/club/*.test.ts` (new if BFF route tests exist)

  Logging:
  - Ensure tests and mocks do not print raw activation tokens, private group invite URLs, or full redirect URLs.
  - Prefer synthetic placeholders such as `https://example.test/club?activation=redacted`.

  Dependencies:
  - Depends on Tasks 6-7.

### Phase 4: Docs And Rollout

- [x] Task 9: root docs - update operator docs and sync local knowledge.

  Deliverable:
  - Update the club runbook with the new web banner checkout flow.
  - Document required env/settings for price, period, provider flags, external Tribute URL, and group invite link.
  - Document support checks for "paid but no onboarding/group links".
  - Document that Tribute is external link-only in this slice and must not be treated as backend-confirmed payment.
  - Run targeted GBrain sync after code/docs changes.

  Files:
  - `docs/club.md`
  - `docs/runbooks/` or `docs/tasks/club/` if a focused rollout note is clearer
  - `.ai-factory/PLAN.md` progress checkboxes during implementation

  Logging:
  - Docs must list safe log keys to inspect: provider code, public checkout reference, payment session id, activation token id, membership id.
  - Docs must explicitly forbid publishing or logging raw activation URL, private invite URL, callback signatures, API keys, bot tokens, and provider payload secrets.

  Dependencies:
  - Depends on Tasks 1-8.

## Verification Plan

- `cd diaverseapi; .\.venv\Scripts\python.exe -m pytest tests/test_club_payments.py tests/test_club_cabinet_api.py tests/test_club_checkout.py tests/test_cabinet_payment_registry.py`
- If any Alembic migration is added: `cd diaverseapi; .\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql`
- `cd diaweb\frontend; npm run lint`
- `cd diaweb\frontend; npm run typecheck`
- `cd diaweb\frontend; npm test -- __tests__/modules/shop __tests__/modules/club-purchase __tests__/app/api/cabinet/club`
- Manual smoke after implementation: open shop, click club banner, select each enabled provider, verify status page states, and confirm paid/finalized response reveals onboarding and group actions only after backend success.
- Knowledge sync after meaningful code/docs changes: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`

## Risks And Mitigations

- Tribute is external link-only and cannot produce backend-confirmed success links. Mitigation: route only Zion/Pay1Time through backend status and do not treat a Tribute click as proof of payment.
- Private group link leakage before payment would expose club access. Mitigation: backend-only setting, returned only after paid/finalized status.
- Generic club finalizer currently records Prodamus-style club events. Mitigation: map generic provider codes explicitly and test Pay1Time/Zion paths.
- Duplicate callbacks/status polling could create duplicate activation links. Mitigation: idempotency keys, session metadata reuse, and duplicate finalization tests.
- Missing price/period config can create inconsistent memberships. Mitigation: hard backend config validation and controlled 503/422 errors before checkout creation.
- Existing dirty work in root, `club10000-bot`, and `aibot` is unrelated. Mitigation: ignore those files unless implementation scope changes.

## Out Of Scope

- Mobile checkout.
- Referral flow.
- Changing Club10000 bot Prodamus callbacks.
- Manual support reconciliation UI beyond docs/log guidance.
- Treating a Tribute link click as proof of payment.
