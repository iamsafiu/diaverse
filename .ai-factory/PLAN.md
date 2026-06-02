# Implementation Plan: Raid Subscription Slot Pool Correction

Created: 2026-06-01
Mode: fast
Branch: none

## Settings

- Testing: yes
- Logging: standard; add or keep compact diagnostics only around slot calculation and stale-client normalization
- Docs: warn-only unless implementation changes public raid rules

## Workspace Mode

- Mode: fast multi-repo workspace plan
- Workspace root: `C:\Users\Indigo\Desktop\diaverse`
- Knowledge: GBrain checked first; exact requirements verified from `docs/tasks/raids/raids-mechanics.md`

## Repository Matrix

| Repository | Path | Affected | Role |
| --- | --- | --- | --- |
| `diaverseapi` | `C:\Users\Indigo\Desktop\diaverse\diaverseapi` | yes | Slot entitlement calculation, raid start validation, cabinet raid state |
| `diaweb` | `C:\Users\Indigo\Desktop\diaverse\diaweb` | yes | Raid slot availability, default mode selection, slot UI/copy |
| `aibot` | `C:\Users\Indigo\Desktop\diaverse\aibot` | no | Not involved |
| `club10000-bot` | `C:\Users\Indigo\Desktop\diaverse\club10000-bot` | no | Not involved |
| `diaverse` | `C:\Users\Indigo\Desktop\diaverse` | plan/daily only | Coordination plan and optional daily/GBrain follow-up |

## Goal

Исправить механику XDV-слотов рейдов: активная подписка должна заменять базовый лимит слотов и делать его выгоднее, а не добавлять отдельную корзину "подписочных" слотов поверх базовых. Токен-слоты остаются постоянным бонусом сверху к активному XDV-лимиту.

## Source Requirements

- `raids-mechanics.md` specifies slots as:
  - without subscription: slots by profile grade;
  - with subscription: slots by profile grade with subscription bonus;
  - USDT raids: unlimited.
- Grade table defines one base value and one subscription value per grade, for example grade `0-10`: `2` without subscription, `4` with subscription.
- Token formula is `XDV slots = slots by profile grade and subscription + unlocked token slots`.
- Token slots do not affect USDT raids.

## Product Decisions

- There is one active XDV slot pool, not separate base and subscription pools.
- Effective XDV capacity:
  - no subscription: `grade_basic_slots + unlocked_token_slots`;
  - active subscription: `grade_subscription_slots + unlocked_token_slots`.
- When subscription is active, new XDV raids should use subscription benefits (`subscription_xdv`) by default.
- Backend should protect stale clients that still submit `basic_xdv` while subscription is active. Recommended behavior: auto-normalize such starts to `subscription_xdv` before pricing/duration/snapshot calculation, then log the normalization.
- Existing active/completed/trapped/rescue-related XDV entries must remain readable and claimable even if they were originally started as `basic_xdv`.
- USDT remains separate and unlimited.

## Tasks

### Phase 1: Backend Slot Entitlement Model

- [x] Task 1: Normalize the slot-domain vocabulary in `diaverseapi`.

  Files:
  - `diaverseapi/app/raids/domain/slots.py`
  - `diaverseapi/app/raids/tests/test_domain_rules.py`

  Deliverable:
  - Add a clear helper for the active XDV capacity, for example `effective_xdv_slot_limit(subscription_active)`.
  - Keep the old basic/subscription grade values available for display and backward compatibility, but make the active limit explicit.
  - Assert with tests:
    - grade `0-10`, no subscription, `0` tokens -> `2`;
    - grade `0-10`, subscription, `0` tokens -> `4`;
    - grade `0-10`, subscription, `1` token -> `5`;
    - token slots never affect USDT.

  Logging:
  - No noisy logs in pure domain helpers.

### Phase 2: Backend State And Start Validation

- [x] Task 2: Make raid state expose one active XDV pool.

  Files:
  - `diaverseapi/app/raids/services/state_service.py`
  - `diaverseapi/app/raids/schemas.py` if schema wording or metadata needs adjustment
  - `diaverseapi/app/raids/tests/test_state_service.py`

  Deliverable:
  - Cabinet state should expose/display the active XDV capacity once.
  - With active subscription, entitlement slots should not be represented as "base slots plus extra subscription slots".
  - Token slots should remain visibly token-derived, but they belong to the same active XDV pool.
  - Existing slot indexes for active, completed, trapped, and rescue states must remain stable.

- [x] Task 3: Align raid start validation with the replacement model.

  Files:
  - `diaverseapi/app/raids/services/command_service.py`
  - `diaverseapi/app/raids/tests/test_command_start.py`
  - `diaverseapi/app/raids/tests/test_raids_flow.py`

  Deliverable:
  - Count occupied XDV slots once across both `basic_xdv` and `subscription_xdv`.
  - If subscription is active and a stale client sends `basic_xdv`, normalize to `subscription_xdv` before calculating duration, trap chance, rewards, and persisted mode.
  - If subscription is inactive, `subscription_xdv` remains unavailable.
  - Keep USDT start behavior unchanged.

  Logging:
  - INFO or DEBUG log stale-client mode normalization with user id, requested mode, effective mode, and subscription state.

### Phase 3: Frontend Availability And Default Mode

- [x] Task 4: Collapse frontend availability into one XDV pool.

  Files:
  - `diaweb/frontend/modules/raids/slotAvailability.ts`
  - affected raid tests under `diaweb/frontend/__tests__/modules/raids/`

  Deliverable:
  - Replace separate behavior based on `basicRemaining` and `subscriptionRemaining` with active fields such as `xdvRemaining`, `xdvTotal`, and `activeXdvMode`.
  - `getDefaultRaidModeForAvailability()` should return:
    - `subscription_xdv` first when subscription is active and XDV slots remain;
    - `basic_xdv` when subscription is inactive and XDV slots remain;
    - `usdt` only when XDV is full or unavailable.
  - Token slots must increase the active XDV pool regardless of subscription state.

- [x] Task 5: Update raid dispatch and slot UI copy.

  Files:
  - `diaweb/frontend/modules/raids/components/RaidDispatchStep.tsx`
  - `diaweb/frontend/modules/raids/components/RaidSlotCard.tsx`
  - `diaweb/frontend/modules/raids/components/RaidSlotGrid.tsx`
  - `diaweb/frontend/modules/raids/components/RaidSlotsSheet.tsx` if present/affected
  - raid i18n dictionaries if copy is centralized

  Deliverable:
  - Stop showing "base slots" and "subscription slots" as independent capacities.
  - Show one active XDV capacity, for example "4 XDV-слота с подпиской" or equivalent existing UI wording.
  - Keep token slots understandable as additional unlocked XDV slots.
  - Keep USDT presentation unchanged.
  - Mobile layout must still avoid overflow when the active capacity grows to subscription + token maximum.

### Phase 4: Verification And Release Prep

- [x] Task 6: Run targeted verification.

  Commands:
  - `cd diaverseapi; pytest app/raids/tests/test_domain_rules.py app/raids/tests/test_command_start.py app/raids/tests/test_state_service.py app/raids/tests/test_raids_flow.py -q`
  - `cd diaverseapi; ruff check app/raids`
  - `cd diaweb; npm test -- --runTestsByPath frontend/__tests__/modules/raids/RaidLocationStack.test.tsx frontend/__tests__/modules/raids/RaidFlows.test.tsx frontend/__tests__/modules/raids/RaidShell.test.tsx`
  - `cd diaweb; npx tsc --noEmit`

  Notes:
  - If `diaweb` still has the unrelated `_auth.ts` `BufferSource` TypeScript issue, record it separately and do not hide raid regressions behind it.
  - After meaningful implementation/docs changes, run targeted GBrain sync for changed sources.

## Risks

- Existing users may have active `basic_xdv` raids while subscription is active; state and claim flows must keep working.
- Silent normalization from `basic_xdv` to `subscription_xdv` changes persisted mode for stale clients. This is intended user-beneficial behavior, but tests must cover duration, price, rewards, trap chance, and idempotency.
- Frontend copy can accidentally keep the old mental model if it still says "base + subscription"; UI must communicate one active XDV pool.
- Slot `source` values may be used by styling/tests, so schema changes should be minimized or made backward-compatible.

## Success Signals

- Grade `0-10` without subscription and no token slots shows `2` XDV slots.
- Grade `0-10` with subscription and no token slots shows `4` XDV slots, not `2 + 2`.
- Grade `0-10` with subscription and one token slot shows `5` XDV slots.
- When subscription is active, default XDV dispatch mode is `subscription_xdv`.
- A token slot can be occupied by a subscription raid when subscription is active.
- USDT raids remain unlimited and unaffected by XDV token slots.

## Commit Plan

- `diaverseapi`: `fix(raids): normalize subscription slot entitlement`
- `diaweb`: `fix(raids): show one active xdv slot pool`
- `diaverse`: commit only if plan/daily/docs updates need to be saved in the workspace repo
