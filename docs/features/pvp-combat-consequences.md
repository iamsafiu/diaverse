---
owner: workspace
status: canonical
domain: pvp
source_of_truth: "diaverseapi/app/pvp + diaweb/frontend/modules/pvp"
last_reviewed: 2026-07-28
review_after: 2026-08-28
---

[← PvP World & Recon](pvp-world-recon.md) · [Back to Documentation](../README.md) · [PvP Combat Operations →](../runbooks/pvp-combat-consequences.md)

# PvP Combat & Consequences

> Живой cross-repo контракт второй части PvP: армия, атака, бой, возврат, Factory damage, лазарет, settlement и безопасное восстановление операций.

## Статус

| Область | Состояние |
| --- | --- |
| Backend, схема и reconciliation | Реализованы в `diaverseapi` worktree |
| Web и same-origin BFF | Реализованы в `diaweb` worktree |
| Feature flags | По умолчанию выключены |
| Migration delta | Не требуется: модели/таблицы не изменены, существующая единственная Alembic head сохранена |
| Production migration/rollout | Не выполнены |
| Mobile parity | Отдельная будущая задача |

Реализация не означает разрешение production rollout. Миграция, internal training, последствия и permanent death включаются отдельными этапами из [операционного runbook](../runbooks/pvp-combat-consequences.md).

## Владение и поток данных

```text
diaweb /[lang]/pvp
       /battles/{battleId}
       /reports/{battleId}
       /hospital
  -> same-origin /api/cabinet/pvp/*
  -> diaverseapi /v1/cabinet/pvp/*
  -> app/pvp services and repositories
       -> Factory / Characters / Pack / Raids / Exchange gateways
       -> XDV, inventory and cabinet notifications
```

- `diaverseapi/app/pvp` — authority для выбора армии, жизненного цикла атаки, снимков, боя, settlement, лазарета, lock-строк и reconciliation.
- `diaweb/frontend/modules/pvp` — web UX, polling, server-adjusted clock, подтверждения и private projections.
- Браузер обращается к backend только через allowlisted same-origin BFF.
- Factory и Characters остаются владельцами production state и canonical pet state. PvP хранит причину и вызывает узкие domain services.
- Клиент не рассчитывает исход боя, награды, ущерб, стоимость лечения или доступность действий.

## Режимы

| Режим | Награды и rating | Factory/loot/Hospital/death |
| --- | --- | --- |
| `training` | Нет | Нет |
| `calibration` | `100/20` tokens, `+20/-20` rating | Нет |
| `standard` | `100/20` tokens, `+20/-20` rating | Да, если включены consequences |

Первые три standard-intent атаки защищённого игрока исполняются как training; третья завершает раннюю защиту для последующих атак. Calibration сопоставляется только с calibration.

## Основные state machines

### Attack

```text
registered
  |-- recall before 50% --> recalling --> completed
  `-- arrival -----------> in_battle --> returning --> completed

retryable failure -> тот же state + next_retry_at
irrecoverable failure -> failed + locks retained
```

- Post-battle return использует принятую effective one-way duration.
- Recall return использует уже пройденное outbound-время.
- 24-часовой same-target cooldown начинается от terminal completion, включая recall.
- `failed` остаётся активным для incoming, Exchange и pet guards до доказуемого recovery.

### Battle

```text
waiting_choices -> resolving_round
  |-- ongoing ----------------> waiting_choices
  `-- terminal result --------> settling -> completed
```

До 12 раундов, выбор production building — 45 секунд. Пропущенный выбор берётся из сохранённой автоматической последовательности или детерминированного fallback. Повтор reconciliation не создаёт второй раунд или settlement.

### Hospital

```text
awaiting_treatment --> treating --> recovered
         |
         `-- seven-day deadline --> dead | blocked_expired
```

`blocked_expired` используется, если permanent-death policy была выключена при intake. Переключение флага позднее не меняет историческую запись.

### Factory damage

```text
damaged --> repairing --> repaired
```

Damage замораживает только production-часть выбранного здания. Reservations, unfinished jobs и ready output сохраняются; после ремонта возобновляется сохранённое remaining time.

## Combat contract

Снимки армии и правил immutable. Mutable health хранится отдельно в battle-local state.

```text
Rwalk = rarity walk multiplier
Mwalk = mutation walk multiplier
A = 2 / Rwalk
Mpvp = 1 + normalized_mutation_bonus × mutation_level
Ccore = ClevelXdv × Kavatar × KpilotLevel
Cpvp = Ccore × 2 × Mpvp
power = round(sqrt(max_health × damage))
```

- Расчёты CPVP используют `Decimal` с шестью знаками.
- Новые операции фиксируют `pvp_catalog.v3`, `pvp_combat.v2` и
  `pvp_rng.v2`; исторические `v1` snapshots остаются читаемыми.
- `pvp_rng.v2` использует deterministic integer roll `0..9999`, поэтому
  chance comparison не зависит от float/Decimal serialization.
- Редкость определяет роль и слой, а evolution не влияет на combat.
- Слои: `front`, `assault`, `ranged`, `command`.
- На каждый вид Rhino/Hippo/Elephant выбирается не более одного command hero:
  active pet, затем меньший Pack slot, затем UUID. Обычная pet-карточка
  показывает capability, но `selected_for_battle=true` только у фактического
  выбранного героя.
- Rhino, Hippo и Elephant применяют versioned hero rules.
- Один engine path работает для малых армий и 500-vs-500 без per-hit persistence.
- Round evidence `pvp_round_evidence.v2` хранит choices/sources, версии,
  integer rolls, hero activations, все modifier stages, equal-share floor,
  remainder, layer overflow/transitions и pet health changes.
- Seed остаётся private server data; участник получает сохранённые rolls и
  evidence только через авторизованный report.

## Working production buildings

Preferences, army registration и battle choice используют один typed option:
`{key, title}`. Сервер выдаёт только активные и не повреждённые production
buildings, а финальный choice снова проверяет live Factory state под lock.

Web использует один ordered picker: add/remove, защита от дублей, доступные с
клавиатуры up/down и явная маркировка stale option. Свободного ввода внутренних
ключей через запятую нет. Сохранённая stale preference не становится
разрешением: runtime пропускает её и берёт следующий working building или
детерминированный fallback.

## Locks и конкурентность

Каноничный порядок захвата:

```text
profiles -> attacks -> battles -> rounds -> pet locks
Factory profile -> buildings -> compartments -> jobs -> balances
Hospital entry -> canonical character
```

Правила:

- одна активная incoming operation на defender;
- permanent idempotency key на attacker;
- attacker/defender pets блокируются живыми `pvp_pet_locks`;
- Hospital переводит lock reason из `battle` в `hospital`;
- Pack, Raids и character mutations проверяют живой PvP lock;
- Exchange блокирует только создание новых buy/sell orders во время incoming operation;
- нет generic force-unlock: lock освобождает terminal return, recovery, Hospital outcome или иной доказуемый domain transition.

## Settlement и последствия

Settlement — одна атомарная транзакция на battle.

При standard attacker victory:

- повреждается production building;
- крадётся `floor(3%)` уязвимых Factory resources;
- общий resource loss ограничен `5%` от первого положительного game-day snapshot;
- при наличии ready production выбирается одна единица детерминированно;
- canonical inventory получает loot;
- token/rating ledgers записывают фактически применённое изменение;
- проигравший defender получает восемь часов защиты.

Hospital принимает pets с нулевым health. Сильнейшие `ceil(30%)` у каждого владельца автоматически получают бесплатное 24-часовое лечение. Стоимость остальных:

```text
max(100, ceil(start_power / 10) × 10) XDV
```

Repair:

```text
cost = 500 × production_level XDV
duration = 60 × production_level minutes
```

## Persistence

| Группа | Назначение |
| --- | --- |
| `pvp_attacks`, `pvp_battles`, `pvp_rounds` | lifecycle, deadlines, retries |
| `pvp_army_snapshots`, `pvp_pet_snapshots` | immutable accepted combat input |
| `pvp_battle_pet_states` | mutable current battle health |
| `pvp_pet_locks` | cross-activity availability |
| `pvp_settlements`, reward/resource ledgers | idempotent economic result |
| `pvp_factory_damage`, output claims | damage, repair and ready-product claim |
| `pvp_hospital_entries` | treatment/death policy snapshot and deadlines |

JSONB используется только для versioned immutable rule/detail snapshots и line items; identities, ownership, status, deadlines и uniqueness остаются relational.

## API

Все private ответы используют no-store policy и owner/participant authorization.

| Метод | Backend path | Назначение |
| --- | --- | --- |
| GET | `/combat/army-options` | server-authoritative army options |
| GET/POST | `/combat/preferences*` | automatic building sequence |
| POST | `/combat/attacks/preview` | composition, power, mode, flight preview |
| POST | `/combat/attacks` | idempotent registration |
| GET | `/operations/active` | все actor-authorized scouting/attack routes |
| GET/POST | `/combat/attacks/{id}*` | state и recall |
| GET/POST | `/combat/battles/{id}*` | battle state, choice и retreat |
| GET | `/combat/battles/{id}/report` | typed `pvp_battle_report.v2` |
| GET/POST | `/hospital*` | owner hospital state и treatment |
| GET/POST | `/factory-damage*` | owner damage state и repair |

Полный prefix: `/v1/cabinet/pvp`. BFF mirror: `/api/cabinet/pvp`.

## Flags

| Backend flag | Default | Назначение |
| --- | --- | --- |
| `PVP_COMBAT_ENABLED` | `false` | новая регистрация и combat API |
| `PVP_CONSEQUENCES_ENABLED` | `false` | destructive standard settlement |
| `PVP_PERMANENT_DEATH_ENABLED` | `false` | death policy для нового Hospital intake |
| `PVP_COMBAT_ROLLOUT_PERCENT` | `0` | stable web cohort |

World и scouting flags из [Part 1](pvp-world-recon.md) также остаются обязательными. Выключение регистрации не должно бросать уже принятые операции: reconciliation доводит их по сохранённому контракту или оператор применяет safe-cancel.

## Reconciliation и диагностика

Минутные каналы:

- `pvp_scouting-reconcile`;
- `pvp_scouting-combat-reconcile`;
- `pvp_scouting-consequence-reconcile`.

Каждая consequence operation исполняется в отдельной транзакции. Poison item исключается до следующего tick и не блокирует последующие элементы текущего batch.

Read-only audit:

```powershell
.\.venv\Scripts\python.exe -m app.commands.pvp_combat_audit
```

Отчёт содержит только aggregate counts, maximum lag и безопасные error-code groups для due, retrying, failed-with-locks, flight, round, return, Hospital, repair и settlement. Snapshot, choice, seed, balance, loot identity, pet names и connection data не выводятся.

## Privacy

Public map/search не получают army, Hospital, inventory, seed, raw rolls, balances или loot. Battle report доступен только участникам и использует сохранённые presentation snapshots. Backend logs содержат безопасные IDs, состояния и error codes, но не private payloads.

## Battle report contract

`pvp_battle_report.v2` возвращает typed summary, обе army snapshots,
independently cursor-paginated pets и rounds, consequences и evidence status.
Pet coefficients показывают Rwalk/Mwalk/A/Mpvp/Ccore/Cpvp только если они
реально были сохранены.

Web сначала рендерит краткий summary, versions, armies и consequences. Pet и
round drilldowns монтируются только после открытия `<details>`; следующие pet
и round pages загружаются независимыми действиями. Legacy snapshots показывают
известные факты и явное “detail unavailable for this version”, без raw JSON и
без выдуманного backfill.

## Rollout и rollback

Порядок rollout: подтвердить единственную Alembic head с flags off →
deterministic replay → internal training → small training cohort → internal
consequences без death → Factory/Hospital/ledger gates → отдельное approval
permanent death → постепенное расширение.

Rollback: permanent death off → consequences off → combat registration off. Workers продолжают завершать принятые операции. История, snapshots, rounds, settlement, damage, Hospital и cooldown не удаляются; schema downgrade не является обычным rollback.

## See Also

- [PvP World & Recon](pvp-world-recon.md) — карта, публичные профили и разведка.
- [PvP Operations Runbook](../runbooks/pvp-combat-consequences.md) — rollout, audit, recovery и rollback.
- [Workspace Architecture](../../.ai-factory/ARCHITECTURE.md) — cross-repo ownership.
