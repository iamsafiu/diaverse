# Documentation System

[Back to Docs](README.md)

## Цель

Документация должна отвечать на два вопроса:

- где находится источник правды по домену;
- что нужно обновить, когда меняется код, контракт или операция.

Корневой `docs/` является порталом для cross-repo знаний. Repo-local документы остаются рядом с кодом, если они полезны только одному сервису.

## Статусы Документов

| Статус | Значение | Правило обновления |
| --- | --- | --- |
| `canonical` | Живой источник правды | Обновлять в том же PR/задаче, что и код |
| `runbook` | Операционная инструкция | Проверять после deploy/runtime изменений |
| `research` | Исследование или discovery | Не считать контрактом без ссылки из canonical doc |
| `log` | Исторический лог/расследование | Не редактировать без причины, можно архивировать |
| `daily` | Локальный daily log | Ведется по правилам Daily Work |

Новые живые документы должны начинаться с короткого metadata-блока:

```yaml
---
owner: workspace
status: canonical
domain: cabinet
source_of_truth: diaweb + diaverseapi
last_reviewed: YYYY-MM-DD
review_after: YYYY-MM-DD
---
```

Для старых документов metadata можно добавлять постепенно при следующем существенном изменении.

## Владение

| Тип документа | Где хранить |
| --- | --- |
| Cross-repo архитектура, продуктовый контракт, интеграционный runbook | `docs/` |
| Server topology, deploy matrix, domains, ports, runtime paths, and safe inventory notes | `docs/infrastructure/` |
| Узкий frontend guide | `diaweb/` рядом с кодом или ссылка из `docs/` |
| Узкий backend/API/runtime guide | `diaverseapi/docs/` или рядом с backend module |
| Узкий copywriting runtime guide | `aibot/docs/` |
| Club10000 bot-specific guide | `club10000-bot/docs/` |
| Daily work | `docs/daily/YYYY-MM-DD-<author>.md` |

## Изменение Документов

Перед изменением:

1. Найти canonical doc через [README](README.md).
2. Проверить source code, если документ описывает текущее поведение.
3. Не переносить секреты, raw env values, private IP, SSH key paths и чувствительные логи в публичные разделы.

После изменения:

1. Запустить docs health check.
2. Если менялся код или долгоживущие docs, синхронизировать GBrain.
3. Для meaningful task добавить daily entry, если пользователь не сказал `bez daily` или `no daily`.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1
```

## Связь С GBrain

GBrain помогает быстро находить документы, связи и символы, но не заменяет source of truth. Ответы GBrain нужно подтверждать:

- canonical docs для продуктовых и операционных контрактов;
- source code для фактического поведения;
- git status/diff для текущего незакоммиченного состояния.

Сырые переписки и внутренние sensitive детали не должны автоматически попадать в GBrain. `docs/daily` используется для локального аудита, а публичной частью daily считается только `Public digest`.

## Infrastructure Docs Safety

Infrastructure docs may include curated operational facts such as service names, domains, ports, compose project names, repo checkout paths, volume names, and health-check commands. They must not include secrets, raw `.env` values, private key paths, SSH identity filenames, database URLs, provider tokens, raw logs, Telegram session data, or unreviewed inventory dumps.

Raw inventory snapshots belong under `.tmp/server-inventory/` and must stay ignored by git. Before copying facts into `docs/infrastructure/`, review the snapshot and keep only stable, non-secret topology information.

## Критерии Качества

| Проверка | Минимум |
| --- | --- |
| Навигация | Документ найден из [README](README.md) или связан из canonical doc |
| H1 | У активных docs есть один понятный заголовок |
| Актуальность | Нет ссылок на старые локальные пути из прежнего workspace или отдельного checkout |
| Ссылки | Локальные markdown-ссылки ведут на существующие файлы |
| Читаемость | Короткие секции, таблицы для структурированных данных, без длинных стен текста |
| Безопасность | Нет секретов, токенов, raw env values или приватных инфраструктурных деталей в публичных разделах |

## See Also

- [Docs README](README.md) - карта разделов документации.
- [Knowledge System](knowledge-system.md) - GBrain source IDs, команды и troubleshooting.
- [Infrastructure](infrastructure/README.md) - server topology and safe inventory workflow.
- [Workspace Map](../AGENTS.md) - правила workspace и Daily Work.
- [Product Master Plan](product/master-plan.md) - продуктовый источник правды.
