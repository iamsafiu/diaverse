---
owner: workspace
status: canonical
domain: pvp
source_of_truth: "diaverseapi/app/pvp + diaweb/frontend/modules/pvp"
last_reviewed: 2026-07-28
review_after: 2026-08-28
---

[← Factory Web](factory.md) · [Back to Documentation](../README.md) · [PvP Combat & Consequences →](pvp-combat-consequences.md)

# PvP World & Recon

> Живой cross-repo контракт первой части PvP: карта мира, публичные профили, маршруты и разведывательное досье. Бои и разрушительные последствия относятся ко второй части.

## Статус

| Область | Состояние |
| --- | --- |
| Backend и схема | Реализованы в изолированном `diaverseapi` worktree, rollout по умолчанию выключен |
| Web и same-origin BFF | Реализованы в изолированном `diaweb` worktree, rollout по умолчанию выключен |
| Backfill | Команда готова; production-запуск требует dry-run и операторского seed |
| Production rollout | Не выполнен |
| PvP Combat & Consequences | Реализованы отдельно; rollout выключен |

Каноничные источники: `КАРТА.doc` и `PvP+Diaverse+2.doc`. Консолидированный research хранится в `/.ai-factory/RESEARCH.md`, план — в `/.ai-factory/plans/feature-pvp-world-recon.md`.

## Владение

```text
browser -> diaweb /api/cabinet/pvp/*
        -> diaverseapi /v1/cabinet/pvp/*
        -> app/pvp services -> narrow domain gateways
```

- `diaverseapi/app/pvp` владеет координатами, публичной PvP-проекцией, геометрией, попытками, досье, идемпотентностью и reconciliation.
- `diaweb/frontend/modules/pvp` владеет web-картой, camera state, публичной карточкой, подтверждением и server-adjusted clock.
- Браузер не вызывает `diaverseapi` напрямую. Same-origin BFF использует закрытый allowlist.
- Factory, Character, Raid и cabinet notification остаются источниками своей истины; PvP обращается к ним через gateway-интерфейсы.

## Мир и размещение

| Правило | Значение |
| --- | --- |
| Координаты | `0..999 × 0..999` |
| Зарезервированный центр | `400..599 × 400..599` |
| Сектор | `100 × 100` |
| Выбор сектора | один из 5 наименее заселённых |
| Версии | `world.v1`, `placement.v1` |

Координата создаётся вместе с новой Factory в одной транзакции. Уникальность гарантирует база; конкурентная коллизия повторяется ограниченное число раз. Существующий профиль повторно не размещается.

```text
distance = sqrt((target.x - origin.x)^2 + (target.y - origin.y)^2)
base_flight_minutes = ceil(5 + distance / 20)
scouting_duration_minutes = max(2, ceil(base_flight_minutes / 4))
```

## Мощь и контуры

Каноничная мощь пэта рассчитывается через `Decimal`, шесть знаков. Для
`pvp_combat.v2` сервер сохраняет полную цепочку:

```text
Rwalk = rarity walk multiplier
Mwalk = mutation walk multiplier
A = 2 / Rwalk
Mpvp = 1 + normalized mutation bonus × mutation level
Ccore = ClevelXdv × Kavatar × KpilotLevel
Cpvp = Ccore × 2 × Mpvp
```

Старые `pvp_combat.v1` snapshots продолжают читаться, но отсутствующие множители
помечаются как legacy-unavailable, а не реконструируются задним числом.

| Контур | Баланс аватаров |
| --- | --- |
| `rare` | `0..375` |
| `epic` | `376..2500` |
| `legendary` | `2501+` |

Клиент не пересчитывает CPVP и не выводит скрытую силу из публичных данных.

## Разведка

- `GET /scouting/attempts/preview` возвращает серверные distance, duration,
  цену, ETA и actor-target eligibility до подтверждения.
- Запуск стоит ровно `100 XDV`.
- Вероятность информации — `65%`, обнаружения — `30%`; броски независимы и сохраняются один раз.
- На actor-target разрешена одна активная попытка.
- Повтор POST с тем же `idempotency_key` возвращает исходную попытку без повторного списания.
- XDV списывается только внутри backend-транзакции после preflight. Клиент баланс оптимистически не меняет.
- Минутный TaskIQ reconciliation завершает просроченные операции; чтение попытки также безопасно подхватывает завершение.
- Повторное открытие поля обновляет snapshot, не создавая вторую карточку.

## Eligibility, фильтры и actor-relative projection

Один pure policy (`pvp_eligibility.v1`) формирует результат отдельно для
разведки и атаки: `allowed`, стабильный `reason_code` и `rules_version`.
Preview и финальный POST повторяют policy под lock; UI никогда не превращает
предварительный `allowed=true` в гарантию принятия команды.

Map, search, nearby и profile read models дополняют публичные факты только
разрешёнными для текущего actor полями:

- собственный активный дрон и армия;
- разрешённая входящая армия;
- время последнего собственного досье;
- scouting/attack availability и reason code.

Поддерживаются semantic filters `potential_targets`, `same_contour`,
`known_intel`, `drone_en_route`, `army_en_route`, один contour и bucket
базового полёта. Эти actor-relative параметры входят в canonical query key и
не смешиваются с публичным shared cache.

Маркеры имеют не только цвет, но и форму/глиф для own, selected, intel, drone,
outbound/returning army, incoming и unavailable.

## Активные маршруты и refresh

`GET /operations/active` отдаёт все авторизованные scouting/attack paths с
phase-specific origin/target, `phase_started_at`, `eta_at`, direction и
progress. Несколько маршрутов рисуются одновременно и связываются с карточкой
операции.

Клиент интерполирует движение через общий server-clock offset. Map и routes
обновляются каждые 10 секунд только в foreground, при возврате focus и после
scout/attack/recall/battle lifecycle transitions. Фоновый polling, SSE и
WebSocket не используются.

## Десять полей досье

| Ключ | Содержимое |
| --- | --- |
| `defensive_power` | оценка оборонительной CPVP с обфускацией ±10% |
| `defending_pet_count` | число защищающих пэтов |
| `defending_pet_roles` | guardian/ranged/assault breakdown |
| `strongest_defending_pets` | до 10 сильнейших защищающих пэтов |
| `active_heavy_heroes` | Rhino, Hippo и Elephant |
| `production_buildings` | работающие и повреждённые здания |
| `vulnerable_resource_stock` | диапазоны уязвимых ресурсов |
| `ready_production_units` | готовые производственные единицы |
| `hospital_waiting` | ожидающие лечения в лазарете |
| `hospital_treatment_started` | уже находящиеся на лечении |

Два поля лазарета независимы. Каждый факт хранит `observed_at` и `source_attempt_id`; неуспешная попытка старые факты не очищает.

## API и privacy

Все ответы используют `schema_version=pvp.public.v1`, `server_time` и private/no-store policy.

| Метод | Backend path | Назначение |
| --- | --- | --- |
| GET | `/v1/cabinet/pvp/catalog` | versioned правила |
| GET | `/v1/cabinet/pvp/state` | capabilities и свой профиль |
| GET | `/v1/cabinet/pvp/map` | bounded viewport: кластеры/маркеры |
| GET | `/v1/cabinet/pvp/search` | имя, UUID или координаты |
| GET | `/v1/cabinet/pvp/nearby` | ближайшие цели, максимум 30 |
| GET | `/v1/cabinet/pvp/profiles/{id}` | публичная карточка |
| GET | `/v1/cabinet/pvp/profiles/{id}/route` | маршрут и ETA |
| GET | `/v1/cabinet/pvp/operations/active` | actor-authorized active routes |
| GET | `/v1/cabinet/pvp/scouting/attempts/preview` | цена, ETA и eligibility |
| POST | `/v1/cabinet/pvp/scouting/attempts` | идемпотентный запуск |
| GET | `/v1/cabinet/pvp/scouting/attempts/{id}` | своя попытка |
| GET | `/v1/cabinet/pvp/scouting/history` | cursor-история |
| GET | `/v1/cabinet/pvp/profiles/{id}/dossier` | собственное досье |

Public allowlist: имя, аватар, координаты, расстояние/время, рейтинг, контур, защита и агрегат собственного досье. User ID, балансы, склад, армия и сырые броски не публикуются.

## Feature flags

Backend — финальная authority:

| Runtime | Флаг | Default |
| --- | --- | --- |
| API | `PVP_WORLD_ENABLED` | `false` |
| API | `PVP_SCOUTING_ENABLED` | `false` |
| API | `PVP_WORLD_ROLLOUT_PERCENT` | `0` |
| API | `PVP_SCOUTING_ROLLOUT_PERCENT` | `0` |
| API | `PVP_ROLLOUT_SALT` | стабильный salt |
| Web | `NEXT_PUBLIC_PVP_WORLD_ENABLED` | `false` |
| Web | `NEXT_PUBLIC_PVP_SCOUTING_ENABLED` | `false` |

Web-флаг скрывает entrypoint, но не выдаёт capability. Cohort — стабильный SHA-256 bucket по user UUID и salt.

## Backfill

Выполнять из `diaverseapi` при выключенных world/scouting:

```powershell
# dry-run
.\.venv\Scripts\python.exe -m app.commands.pvp_backfill_profiles `
  --seed production-placement-v1 --batch-size 250

# запись после аудита
.\.venv\Scripts\python.exe -m app.commands.pvp_backfill_profiles `
  --apply --seed production-placement-v1 --batch-size 250
```

Seed сохраняется в приватном операторском журнале. Прерванный процесс продолжается через `--cursor`; созданные профили не переразмещаются.

## Rollout и rollback

1. Применить миграцию, проверить единственную Alembic head, выполнить dry-run/backfill.
2. Включить мир для staff; проверить privacy, кластеры, поиск, маршруты и query plans.
3. Включить малый стабильный cohort мира.
4. Включить разведку для staff; проверить XDV idempotency, reconciliation и notifications.
5. Включить малый cohort разведки и расширять только при приемлемых error rate/p95.

Начальная инженерная цель viewport/search — p95 `<300 ms` на representative seeded dataset. Это measurement gate, не обещание до production load test.

Rollback: выключить scouting, при необходимости остановить `pvp_scouting-reconcile`, затем выключить world. Координаты, попытки и факты сохраняются для replay/audit; schema downgrade не является обычным rollback.

## Verification

```powershell
# diaverseapi
.\.venv\Scripts\python.exe -m pytest app/pvp/tests tests/test_alembic_graph.py -q
.\.venv\Scripts\python.exe -m ruff check app/pvp app/routers/v1/endpoints.py app/core/features.py app/core/settings.py app/core/broker_app.py
.\.venv\Scripts\python.exe -m compileall -q app/pvp
.\.venv\Scripts\python.exe -m alembic heads

# diaweb/frontend
npm test -- __tests__/modules/pvp __tests__/app/api/cabinet/pvp __tests__/app/cabinet-pvp-page.test.tsx
npm run typecheck
npm run lint
npm run build
```

Real-PostgreSQL concurrency/load tests запускаются только против явно подтверждённой disposable test database.

## Part 2 boundary

Этот документ остаётся authority только для мира, публичных профилей, маршрутов и разведки. Армия, атака, combat locks, бой, Factory damage, loot, Hospital, rewards и recovery описаны в [PvP Combat & Consequences](pvp-combat-consequences.md). Их production rollout по-прежнему выключен по умолчанию.

## See Also

- [Factory Web](factory.md) — источник Factory-профиля и production snapshot.
- [PvP Combat & Consequences](pvp-combat-consequences.md) — Part‑2 combat и последствия.
- [Raids User Guide](raids-user-guide.md) — game UI и pet-проекции.
- [Workspace Architecture](../../.ai-factory/ARCHITECTURE.md) — cross-repo ownership.
