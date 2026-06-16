# Club10000 Paid Activation Flow - Fast Implementation Plan

Created: 2026-06-16
Mode: fast plan, no branch creation
Branch: use existing `dev` branches during implementation

## Settings

- Testing: yes, targeted tests per affected repository
- Logging: verbose internal logs for activation/payment/invite edges, without raw tokens or activation URLs
- Docs: yes, update operator docs for the new activation process
- Daily: no daily entry requested for this planning pass
- GBrain: used for discovery; sync only after implementation/docs changes if not explicitly skipped

## Goal

Implement the new Club10000 access model:

- after payment, `club10000-bot` privately sends the user:
  - a personal activation link to the Diaverse club onboarding
  - the private group link
- the onboarding page is available only through a valid activation link or to a user who already claimed that activation
- the user can authorize through Telegram or email
- the activation code in the URL is the access proof for MVP: first authenticated user who claims a valid unused link becomes the linked club user
- staff can manually create an onboarding invitation with one button, without a long form
- referral flow stays hidden and out of scope

## Source Context

- Canonical architecture: `.ai-factory/DESCRIPTION.md`, `.ai-factory/ARCHITECTURE.md`
- Club runbook from local GBrain: `diaverseapi/app/club` owns club state, `club10000-bot` owns Prodamus/funnel bot state and mirrors payment events to Diaverse through signed internal HTTP
- Current onboarding implementation already exists in:
  - `diaverseapi/app/club/service.py`
  - `diaverseapi/app/club/internal_api.py`
  - `diaverseapi/app/club/admin_api.py`
  - `diaweb/frontend/app/[lang]/(cabinet)/club/page.tsx`
  - `diaweb/frontend/modules/club-onboarding/*`
- Current payment bridge already exists in:
  - `diaverseapi/app/club/payments.py`
  - `diaverseapi/app/club/payment_schemas.py`
  - `club10000-bot/app/services/diaverse_client.py`
  - `club10000-bot/app/services/diaverse_outbox.py`

## Repository Matrix

| Repository | Branch | Status | Role |
| --- | --- | --- | --- |
| `diaverseapi` | `dev` | clean | club state, activation tokens, payment bridge, admin endpoint |
| `club10000-bot` | `dev` | clean | post-payment private Telegram delivery |
| `diaweb` | `dev` | clean | onboarding page and staff admin button |
| `aibot` | not planned | not checked for edits | no direct change unless group welcome template ownership forces it |
| `diaverse` root | `dev` | dirty with unrelated docs/tasks | plan/docs only; do not stage unrelated files |
| `diaverse-mobile` | not planned | not checked | out of scope |
| `diaverse-auth-bot` | not planned | not checked | out of scope |

## Key Design Decisions

## Task Checklist

- [x] Task 1: `diaverseapi` - change activation claim semantics
- [x] Task 2: `diaverseapi` - return activation URL from the Club10000 payment bridge
- [x] Task 3: `diaverseapi` - add one-click staff onboarding invitation endpoint
- [x] Task 4: `diaverseapi` - stop relying on group welcome activation links
- [x] Task 5: `club10000-bot` - send activation link after Diaverse payment bridge success
- [x] Task 6: `club10000-bot` - align legacy local group invite fallback
- [x] Task 7: `diaweb` - add staff one-click invitation UI
- [x] Task 8: `diaweb` - polish member onboarding access behavior
- [x] Task 9: Cross-repo docs and verification

### 1. Activation link is a private bearer invite

For this MVP, the link is not bound to the login method. A paid user may open the link and authorize through Telegram or email.

Rules:

- unused valid activation link + authenticated user = claim succeeds
- the first successful claim binds the membership to that Diaverse user
- the same user can reopen the link and continue onboarding idempotently
- a different authenticated user cannot reuse an already claimed link
- expired, missing, or unknown links return a controlled access error
- raw tokens and full activation URLs must not be written to logs

### 2. Payment bot remains the delivery owner

`club10000-bot` privately receives the paid user context and is the right place to send the activation link. `diaverseapi` should generate and return the activation URL from the signed payment bridge response; the bot then sends the Telegram message after a successful Diaverse delivery.

This avoids generating links in group welcome messages and keeps the site access proof tied to the paid/private funnel.

### 3. Manual invitation is intentionally minimal

Staff should not fill a form. The MVP admin action is:

1. staff clicks `Создать приглашение`
2. backend creates a pending invitation membership/manual access record
3. backend creates an activation link
4. frontend shows the link with a copy action

Optional names, comments, dates, and referral fields are out of scope for this iteration.

## Implementation Tasks

### 1. `diaverseapi` - change activation claim semantics

Files:

- `diaverseapi/app/club/service.py`
- `diaverseapi/app/club/schemas.py`
- `diaverseapi/tests/test_club_onboarding_activation.py`
- `diaverseapi/tests/test_club_cabinet_api.py`

Work:

- Update `claim_activation_for_user` so an unused valid activation token can be claimed by the currently authenticated user even when the original membership only has Telegram/payment metadata and no `user_id`.
- Preserve idempotency for the already linked user.
- Reject reuse by another authenticated user with a clear conflict/access error.
- Persist enough metadata for audit:
  - claimed user id
  - auth method hint if available
  - previous membership Telegram/payment identifiers
  - claimed timestamp
- Keep onboarding inaccessible without a valid token or an already claimed membership.
- Ensure email-login and Telegram-login users both pass the same claim path.

Logging:

- `INFO` on first successful claim and idempotent resume.
- `WARN` on expired/claimed-by-other/unknown activation attempts.
- `DEBUG` only for non-sensitive internal ids.
- Never log raw activation token, full activation URL, signed headers, or email address as a primary identifier.

Tests:

- valid unused token can be claimed by email-authenticated user
- valid unused token can be claimed by Telegram-authenticated user
- same user can resume onboarding with the same claimed activation
- different user cannot reuse claimed activation
- missing/expired/invalid token cannot open onboarding

### 2. `diaverseapi` - return activation URL from the Club10000 payment bridge

Files:

- `diaverseapi/app/club/payment_schemas.py`
- `diaverseapi/app/club/payments.py`
- `diaverseapi/app/club/internal_api.py`
- `diaverseapi/app/club/service.py`
- `diaverseapi/tests/test_club_internal_payment_events.py`
- `diaverseapi/tests/test_club_payment_events.py`

Work:

- Extend the payment bridge result/response with:
  - `activation_url`
  - `activation_token_id`
  - `activation_expires_at`
- Generate an activation link after a successful paid event is accepted and membership is resolved/created.
- Use metadata/reason similar to:
  - `reason = "club10000_payment"`
  - provider event id / order id / subscription id
  - bot user id / Telegram user id when present
- For duplicate payment bridge deliveries, keep financial processing idempotent.
- If the response was lost and the outbox retries, it is acceptable to mint a new activation token for the same membership; the bot-level delivery guard must prevent duplicate Telegram messages for the same outbox event.
- Do not expose activation URLs for unpaid, failed, refunded, or rejected payment events.

Logging:

- `INFO` when a payment event generates an activation link.
- `WARN` when a paid event cannot generate a link because membership resolution failed.
- Do not log full activation URLs.

Tests:

- paid event response includes activation fields
- failed/unpaid event response does not include activation fields
- duplicate/deduped payment event does not create duplicate financial state
- activation link returned by payment bridge can be claimed through normal onboarding claim API

### 3. `diaverseapi` - add one-click staff onboarding invitation endpoint

Files:

- `diaverseapi/app/club/admin_api.py`
- `diaverseapi/app/club/service.py`
- `diaverseapi/app/club/schemas.py`
- `diaverseapi/tests/test_club_admin_api.py`

Endpoint proposal:

- `POST /v1/admin/club/onboarding-invitations`

Request:

- no required body
- optional body can be accepted later, but the frontend MVP sends `{}` or no body

Response:

- `membership_id`
- `manual_access_id` if the existing manual access model is reused
- `activation_url`
- `activation_token_id`
- `activation_expires_at`
- `status`

Work:

- Create a pending invitation membership using existing club/manual access primitives where possible.
- Mark source/reason as `staff_invitation`.
- Generate an activation link for the created membership.
- Avoid adding a long manual form or required recipient fields.
- Keep the endpoint staff/admin protected by the existing RBAC/club admin guard.
- If the existing model requires display fields, use safe defaults such as `Manual invitation` and store real recipient details as optional future metadata, not MVP requirements.

Logging:

- `INFO` when staff creates an invitation.
- `WARN` for permission failures or configuration issues.
- Never log full activation URL.

Tests:

- authorized staff can create one-click invite
- unauthorized user cannot create invite
- returned activation URL can be claimed by an authenticated user
- created membership is visible enough for staff audit/status views

### 4. `diaverseapi` - stop relying on group welcome activation links

Files:

- `diaverseapi/app/club/service.py`
- related club notification/template tests if present

Work:

- Make post-payment/manual invite activation the primary path.
- Avoid generating fresh activation links for group welcome messages by default.
- If a custom legacy template still explicitly contains `{activation_url}`, generate it only for that template path and keep behavior backward-compatible.
- Ensure the default welcome text no longer gives the impression that group entry is the activation mechanism.

Logging:

- `DEBUG` when a legacy template requests activation URL generation.
- No raw token/URL logs.

Tests:

- default group welcome does not generate/send activation URL
- legacy placeholder path still works if intentionally configured

### 5. `club10000-bot` - send activation link after Diaverse payment bridge success

Files:

- `club10000-bot/app/services/diaverse_client.py`
- `club10000-bot/app/services/diaverse_outbox.py`
- `club10000-bot/app/models/diaverse_event_outbox.py`
- `club10000-bot/app/config.py`
- `club10000-bot/tests/test_sync_diaverse_payments.py`
- new focused test if clearer: `club10000-bot/tests/test_diaverse_activation_delivery.py`

Work:

- Parse `activation_url`, `activation_token_id`, and `activation_expires_at` from the Diaverse payment response.
- After a successful outbox delivery with `activation_url`, send the Telegram user a private message with:
  - button/link `Активировать клуб`
  - button/link `Войти в группу`
- Use existing configured group invite link if present; otherwise add a clear config variable for the Club10000 group link.
- Persist a delivery guard so the same outbox event/idempotency key cannot send duplicate activation DMs on worker retry.
  - Prefer fields like `activation_message_sent_at`, `activation_message_id`, or an existing response/result JSON field if already available.
  - If model fields are added, create and verify the migration.
- If Telegram delivery fails after Diaverse accepted the payment event, keep the outbox item retryable or create a dedicated retry state so the message is not silently lost.

Logging:

- `INFO` when activation DM is sent.
- `WARN` when Diaverse response has no activation URL for a paid event, or when group link is not configured.
- `ERROR` when Telegram send fails.
- Never log the full activation URL.

Tests:

- response with activation URL triggers one Telegram DM
- retry does not send duplicate DM after successful send
- missing activation URL does not crash the worker
- Telegram send failure leaves a retryable/auditable state

### 6. `club10000-bot` - align legacy local group invite fallback

Files:

- `club10000-bot/app/handlers/funnel_handler.py`
- `club10000-bot/app/services/diaverse_outbox.py`
- `club10000-bot/app/config.py`
- relevant bot payment/funnel tests

Work:

- Make the new Diaverse activation DM the canonical success message when the bridge is enabled and returns an activation URL.
- Keep the old direct group invite fallback only for explicit recovery mode when Diaverse bridge is disabled/unavailable.
- Prevent the user from receiving two conflicting post-payment messages.
- Keep group URL delivery in the same message as activation when possible.

Logging:

- `INFO` when canonical Diaverse activation delivery is used.
- `WARN` when falling back to local recovery behavior.

Tests:

- bridge success sends activation+group message
- bridge unavailable can still use configured recovery fallback
- bridge success does not also trigger duplicate legacy invite message

### 7. `diaweb` - add staff one-click invitation UI

Files:

- `diaweb/frontend/modules/club/api.ts`
- `diaweb/frontend/modules/club/types.ts`
- likely staff UI files:
  - `diaweb/frontend/modules/club/components/ClubDashboard.tsx`
  - `diaweb/frontend/modules/club/components/ClubMembersPanel.tsx`
  - or a small new component under `diaweb/frontend/modules/club/components/`
- staff BFF route files if this module proxies admin calls through `/api/staff/club/*`

Work:

- Add API client method for `POST /v1/admin/club/onboarding-invitations`.
- Add a simple button labeled `Создать приглашение`.
- On success, show the generated activation link and a copy action.
- Do not add a recipient form in this iteration.
- Do not expose raw backend errors or token internals in the UI.
- Keep existing manual member form untouched unless it shares small reusable API types.

Logging/telemetry:

- client-side debug only for action start/success/failure if this module already has a pattern
- no full activation URL in console logs

Tests:

- component test or existing UI test for successful invite creation
- failure state shows a controlled message
- API helper maps the response correctly

### 8. `diaweb` - polish member onboarding access behavior

Files:

- `diaweb/frontend/modules/club-onboarding/api.ts`
- `diaweb/frontend/modules/club-onboarding/components/ClubOnboardingClient.tsx`
- `diaweb/frontend/app/[lang]/(cabinet)/club/page.tsx`
- existing BFF route for activation claim, if present

Work:

- Ensure `/club?activation=...` works after either email or Telegram authorization.
- Ensure the activation query survives login redirect until claim completes.
- Show a clear locked/access-required state when the user opens onboarding without a valid activation or existing claimed membership.
- Keep referral step hidden.
- Keep notification icon hidden.
- Preserve the previous fixes:
  - WebP onboarding images
  - desktop/mobile scroll
  - non-flickering next/back step animation
  - PDF gifts

Logging:

- no full activation token in browser logs
- controlled warning for failed claim

Tests:

- activation query is sent to claim API
- claim failure does not expose token
- already claimed user can load onboarding without re-claiming

### 9. Cross-repo docs and verification

Files:

- `docs/club.md` or the current canonical club runbook location
- `.ai-factory/PLAN.md`
- optional rollout note under `docs/tasks/club/`

Work:

- Document the new process:
  - payment bot sends activation link and group link privately
  - user activates club by completing onboarding after login
  - staff can create one-click manual onboarding invitations
  - group welcome activation links are no longer the primary path
- Include operator notes for what to check when a user says they cannot access onboarding.
- Keep infrastructure secrets, bot tokens, private SSH details, and raw signed headers out of docs.

Verification commands:

- `cd diaverseapi; pytest tests/test_club_onboarding_activation.py tests/test_club_cabinet_api.py tests/test_club_internal_payment_events.py tests/test_club_payment_events.py tests/test_club_admin_api.py`
- if a `diaverseapi` Alembic migration is added: `cd diaverseapi; alembic upgrade <down_revision>:<new_revision> --sql`
- `cd club10000-bot; pytest tests/test_sync_diaverse_payments.py tests/test_diaverse_activation_delivery.py`
- if a `club10000-bot` DB migration is added, run its migration compile/apply check according to the repo's existing tooling
- `cd diaweb/frontend; npm run lint`
- `cd diaweb/frontend; npm test -- club`
- no browser launch unless explicitly requested

Commit plan:

- `diaverseapi`: `feat: support paid and manual club activation links`
- `club10000-bot`: `feat: send club activation links after payment`
- `diaweb`: `feat: add one-click club onboarding invites`
- root docs/plan only if changed: `docs: update club activation rollout plan`

## Risks And Mitigations

- Link forwarding risk: accepted for MVP by business decision. Mitigation is first-claim binding and claimed-by-other rejection.
- Lost Telegram DM after payment bridge success: bot must persist activation message delivery state and retry or expose an auditable failure.
- Duplicate Prodamus callbacks/outbox retries: payment state remains idempotent; bot delivery guard prevents duplicate activation DMs.
- Email authorization identity mismatch: intentionally allowed for this flow because the activation code is the proof.
- Old group welcome activation path causing duplicate links: disable by default and keep only explicit legacy placeholder support.
- Manual invite without recipient metadata reduces audit detail: acceptable for speed; membership/source/reason/timestamps still provide a minimum audit trail.

## Out Of Scope

- Referral system
- Long manual invitation form
- Payment entitlement hardening beyond first-claim bearer activation
- Browser-based manual QA run
- Mobile app changes
- Public GBrain/MCP setup
