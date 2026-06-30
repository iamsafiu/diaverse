# Factory Web Integration Smoke

Дата: 2026-05-26
Updated: 2026-06-30 for factory level 4 playable evidence.

Цель: зафиксировать smoke-путь веб-фабрики без браузерной проверки. Browser/Playwright smoke намеренно не выполнялся по прямой инструкции пользователя: "в браузере не проверяй".

## Scope

Smoke считается локально подтверждённым через frontend component/BFF tests, backend service/API/payment tests и production build. Live E2E с реальным браузером, backend-сервером и auth-cookie остаётся отдельным pre-release шагом.

## Evidence Map

| Smoke item | Evidence | Status |
| --- | --- | --- |
| Unauthenticated factory deep link redirects to login | `diaweb/frontend/__tests__/proxy.test.ts` covers unauthenticated `/ru/factory` redirect; `routeAccess.test.ts` marks `/factory` auth-only. | Covered |
| Authenticated user opens factory through navigation | `BottomNav.test.tsx` and `CabinetTopbar.test.tsx` cover authenticated factory tab when rollout navigation is enabled and hidden guest state. | Covered |
| Rollout-disabled direct link is controlled | `diaverseapi/app/factory/tests/test_api.py::test_rollout_disabled_returns_503_without_touching_state_service`; `FactoryShell.test.tsx` covers `rollout_enabled=false` controlled unavailable UI. | Covered |
| Onboarding completes | `FactoryOnboardingOverlay.test.tsx` covers four tips and complete/skip; `FactoryShell.test.tsx` covers profile-scoped local dismissal. | Covered |
| Resource workshop builds | `diaverseapi/app/factory/tests/test_building_service.py::test_build_resource_part_debits_catalog_costs_and_activates_level_one`; `FactoryResourceWorkshopScreen.test.tsx` covers ruined resource build submit. | Covered |
| Impulse claim obeys daily cap | `diaverseapi/app/factory/tests/test_impulse_service.py::test_claim_available_caps_daily_impulses_and_replays_without_duplicate_credit`; API route coverage in `test_api.py`. | Covered |
| Warehouse accrues and transfers | `test_warehouse_service.py` covers lazy accrual, ten-hour cap, transfer-to-storage, transfer-to-inventory, and Trademaster autocollect; `FactoryWarehouseScreen.test.tsx` covers UI actions. | Covered |
| Brick craft starts and collects | `test_crafting_service.py` covers selected fragment reservation, brick output, collect, cooldown, explosion/repair; `FactoryCompartmentScreen.test.tsx` covers collect UI. | Covered |
| Active craft has no cancel path | `test_crafting_service.py::test_running_job_cannot_be_cancelled`; `FactoryCompartmentScreen.test.tsx` and `FactoryProductionWorkshopScreen.test.tsx` cover no active cancellation affordance. | Covered |
| Queued item can be removed/refunded | `test_crafting_service.py::test_queued_job_cancel_refunds_reserved_inputs`; frontend compartment/production tests cover queued remove action only for queued jobs. | Covered |
| Slot token blocked/success state works | `test_slot_token_service.py` covers ingredient debit/credit, missing ingredients, replay idempotency; `FactoryDialogs.test.tsx` covers slot-token dialog submit from existing inventory balances. | Covered |
| Subscription state renders | `test_subscriptions.py` covers no-sub, Step Pass Pro, Trademaster, expiry transition; `FactoryDialogs.test.tsx` covers subscription dialog state and existing shop/profile links. | Covered |
| Payment checkout/finalizer path is idempotent | `test_command_service.py::test_upgrade_level_real_money_returns_checkout_without_level_change`, `test_command_service.py::test_paid_level_upgrade_applier_is_idempotent`, `test_payment_service.py`, and `tests/test_cabinet_payment_sessions.py` cover factory payment domain registration and finalizer path. | Covered |
| Factory level 2 -> 3 upgrade is supported | `diaverseapi/app/factory/tests/test_command_service.py::test_upgrade_level_three_game_dollar_debits_and_updates_profile`; `FactoryShell.test.tsx` shows target level 3 upgrade controls when backend exposes `target_level=3`. | Covered |
| Factory level 3 -> 4 upgrade is supported | `diaverseapi/app/factory/tests/test_command_service.py::test_upgrade_level_four_game_dollar_debits_and_updates_profile`; `FactoryShell.test.tsx` shows target level 4 upgrade controls when backend exposes `target_level=4`. | Covered |
| Factory target level 5 remains unavailable | `diaverseapi/app/factory/tests/test_command_service.py::test_upgrade_level_blocks_targets_above_supported_max_level`; `FactoryShell.test.tsx` hides target level 5 controls while supported max level is 4. | Covered |
| Level 4 gameplay surface renders and crafts | Backend state/building/compartment/crafting/inventory tests cover resource level 4, rare/epic pet craft, rare/epic biomass, and common mutagen; `FactoryResourceWorkshopScreen.test.tsx`, `FactoryProductionWorkshopScreen.test.tsx`, and `FactoryCompartmentScreen.test.tsx` cover the web surface. | Covered |
| Level 4 scene and upgrade preview render through manifest | `FactoryScene.test.tsx` covers profile level 4 resolving to the shared playable map and preserving hotspot navigation; `FactoryDialogs.test.tsx` covers `factory.map_preview.level_4` in the level upgrade dialog. | Covered |
| Pet craft selected-shard inputs work across level 3/4 access states | `diaverseapi/app/factory/tests/test_crafting_service.py` covers selected rare/epic shard reserve/collect behavior; `FactoryCompartmentScreen.test.tsx` covers rare pet craft early-access at level 3, normal access at level 4, and epic pet craft early-access at level 4. | Covered |

## Commands

Frontend:

```powershell
npm run lint
npm run typecheck
npm run test -- __tests__/app/api/cabinet/factory __tests__/modules/factory
npm run build
```

Backend targeted smoke set:

```powershell
.\.venv\Scripts\python.exe -m pytest app/factory/tests/test_api.py app/factory/tests/test_building_service.py app/factory/tests/test_impulse_service.py app/factory/tests/test_warehouse_service.py app/factory/tests/test_crafting_service.py app/factory/tests/test_slot_token_service.py app/factory/tests/test_subscriptions.py app/factory/tests/test_payment_service.py tests/test_cabinet_payment_sessions.py -q
```

## Notes

- No new inventory or currency domain is part of this smoke. Web UI consumes existing backend state and inventory excerpts.
- Factory levels intentionally share the same playable map and workshop hotspot geometry through `assetManifest.ts`; mechanics and hotspot wiring are covered, and any future map-layout divergence requires an explicit product decision.
- Read-only mobile verification on 2026-06-22 found no mobile source dependency on an old factory supported max-level constant.
- Browser console cleanliness is not asserted here because browser verification was explicitly skipped.
- Full live E2E should be run later with real auth/backend when the user allows browser verification.
