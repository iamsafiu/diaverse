---
owner: workspace
status: runbook
domain: pvp
source_of_truth: "diaverseapi/app/pvp + diaweb/frontend/modules/pvp"
last_reviewed: 2026-07-28
review_after: 2026-08-28
---

[← PvP Combat & Consequences](../features/pvp-combat-consequences.md) · [Back to Documentation](../README.md) · [Raids User Guide →](../features/raids-user-guide.md)

# PvP Combat Operations

## Safety contract

- Начальное состояние всех combat/consequence/death flags — `false`.
- Production migration, deploy и flag changes требуют отдельного операторского разрешения.
- Не останавливать reconciliation, пока существуют принятые non-terminal operations.
- Не менять private PvP rows прямым SQL и не освобождать `pvp_pet_locks` вручную.
- Permanent death включается только отдельным решением после evidence по deadline notifications.

## Preflight

1. Проверить единственную Alembic head. Текущая интеграция не меняет
   SQLModel/schema и не создаёт новую revision; не генерировать пустую миграцию.
   Offline exact-range SQL нужен только если будущий diff действительно добавит
   revision.
2. Убедиться, что combat, consequences и permanent death выключены.
3. Запустить backend/frontend verification из canonical contract.
4. Проверить aggregate audit:

```powershell
.\.venv\Scripts\python.exe -m app.commands.pvp_combat_audit
```

5. Не продолжать rollout при растущем maximum lag, failed-with-locks или неизвестных invariant error codes.

Audit read-only и не выводит snapshots, seeds, choices, balances, loot identities, pet names или database connection data.

## Dev-readiness snapshot

- Code находится в изолированных `diaverseapi`/`diaweb` worktrees и сам по себе
  не означает merge, deploy или rollout.
- Backend defaults: `PVP_WORLD_ENABLED=false`,
  `PVP_SCOUTING_ENABLED=false`, `PVP_COMBAT_ENABLED=false`,
  `PVP_CONSEQUENCES_ENABLED=false`, `PVP_PERMANENT_DEATH_ENABLED=false`;
  rollout percentages остаются `0`.
- Web entrypoint flags также остаются выключенными по умолчанию.
- Перед dev enablement backend flags/capabilities включаются первыми, web flags
  только открывают UI. Web никогда не является authority.
- Принятые операции продолжают исполняться по сохранённым
  `catalog/combat/rng` versions даже после запрета новой регистрации.

## Rollout

1. Подтвердить schema/head с выключенными flags; если schema delta отсутствует,
   ничего не применять.
2. Проверить catalog fixtures, deterministic replay и Part‑1 world/scouting regression.
3. Включить world/scouting/combat только для internal/staff training.
4. Проверить flight, recall, offline rounds, report, pet locks и Exchange guard.
5. Расширить training на малый stable cohort.
6. Включить consequences только internal; permanent death оставить выключенным.
7. Проверить Factory damage/repair, Hospital, daily cap, ledgers и reconciliation.
8. Отдельно одобрить permanent death после deadline-notification evidence.
9. Расширять cohort только при нормальных error rate, latency и stuck-state metrics.

После enablement проверить actor-relative filters и reason codes, preview/POST
race, все active routes и возвраты, foreground polling, canonical hero selection,
typed building options, report v2/legacy fallback и независимую пагинацию.

## Recovery

Сначала выполнить read-only preview:

```powershell
.\.venv\Scripts\python.exe -m app.commands.pvp_combat_recover `
  --action resume --operation-type battle --operation-id 00000000-0000-0000-0000-000000000000
```

После review применить тот же запрос:

```powershell
.\.venv\Scripts\python.exe -m app.commands.pvp_combat_recover `
  --action resume --operation-type battle --operation-id 00000000-0000-0000-0000-000000000000 `
  --apply --confirm APPLY_PVP_RECOVERY
```

Допустимые resume types: `attack`, `battle`, `settlement`, `hospital`, `repair`.

Safe-cancel разрешён только для attack до создания battle:

```powershell
.\.venv\Scripts\python.exe -m app.commands.pvp_combat_recover `
  --action safe-cancel --operation-type attack --operation-id 00000000-0000-0000-0000-000000000000 `
  --apply --confirm APPLY_PVP_RECOVERY
```

Команда повторно захватывает canonical rows, проверяет participants, timeline, snapshot и retained locks. При наличии battle safe-cancel отклоняется. Успешный cancel проходит штатный return/cooldown transition; отдельного unlock action не существует.

## Rollback

1. Выключить `PVP_PERMANENT_DEATH_ENABLED`.
2. Выключить `PVP_CONSEQUENCES_ENABLED`.
3. Выключить `PVP_COMBAT_ENABLED` и public combat cohort.
4. Оставить minute reconcilers активными для уже принятых операций.
5. Для irrecoverable rows выполнить audit и точечный recovery/safe-cancel.
6. Не удалять snapshots, rounds, settlements, damage, Hospital, ledgers или cooldown history.

Schema downgrade не является штатным rollback. Для текущего schema-free delta
откатывается только runtime/code/flags; существующие применённые PvP revisions
не переписываются и не помечаются вручную.

Если runtime workers должны быть остановлены, сначала aggregate audit должен показать ноль non-terminal due/retrying operations либо каждая оставшаяся operation должна иметь reviewed recovery decision.

## See Also

- [PvP Combat & Consequences](../features/pvp-combat-consequences.md) — state machines и технический контракт.
- [PvP World & Recon](../features/pvp-world-recon.md) — Part‑1 flags и public privacy.
- [Documentation System](../documentation-system.md) — требования к living docs.
