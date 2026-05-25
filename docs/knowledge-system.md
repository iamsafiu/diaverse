# Knowledge System

[Back to Docs](README.md)

## Назначение

Diaverse использует локальный GBrain как навигационный слой по документации, AI Factory context и коду четырех дочерних репозиториев. Он помогает быстро найти связанные документы, кодовые символы и возможные зоны влияния, но не является финальным источником правды.

Финальная проверка всегда делается по:

- source code в `diaweb`, `diaverseapi`, `aibot`, `club10000-bot`;
- canonical docs в `docs/`;
- текущему git status/diff.

## Безопасная Модель

- GBrain запускается локально через CLI wrapper.
- Публичный HTTP MCP, ChatGPT connector, туннель или daemon не включены по умолчанию.
- Raw user/Codex conversations не auto-capture'ятся.
- Embeddings отключены в базовой конфигурации, чтобы не тратить API budget и не отправлять содержимое наружу без отдельного решения.
- Sensitive данные, секреты, raw env values и приватные инфраструктурные детали не должны попадать в публичные docs.

## Source IDs

| Source ID | Path | Назначение |
| --- | --- | --- |
| `diaverse-docs` | `docs/` | Корневая документация workspace |
| `diaverse-aif` | `.ai-factory/` | AI Factory context, rules, plans, research |
| `diaweb-code` | `diaweb/` | Frontend и BFF code lookup |
| `diaverseapi-code` | `diaverseapi/` | Backend code lookup |
| `aibot-code` | `aibot/` | Copywriting service code lookup |
| `club10000-bot-code` | `club10000-bot/` | Standalone bot code lookup |

## Команды

```powershell
# Подготовить локальный runtime, если GBrain еще не установлен
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-bootstrap.ps1

# Инициализировать project-local brain и зарегистрировать sources
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sources.ps1

# Синхронизировать все sources
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1

# Проверить CLI, doctor, sources и smoke checks
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-health.ps1
```

## Примеры Lookup

```powershell
# Посмотреть страницы документации
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 list --source diaverse-docs --limit 10

# Посмотреть AI Factory context
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 list --source diaverse-aif --limit 10

# Найти frontend symbol
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 code-def CopywritingDailyView --json

# Найти backend/service symbol references
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain.ps1 code-refs TelegramService --json
```

## Когда Синхронизировать

Запускай `scripts/gbrain-sync.ps1` после:

- изменения долгоживущих docs;
- изменения кода, которое влияет на архитектуру, контракты, ownership или cross-repo flows;
- обновления `.ai-factory` правил, research или plans, которые должны быть доступны агентам;
- ручной правки GBrain source definitions.

Для быстрых задач можно синхронизировать только нужный source:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaverse-docs
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1 -SourceId diaweb-code
```

## Troubleshooting

| Симптом | Что делать |
| --- | --- |
| `gbrain` не найден | Запустить `scripts/gbrain-bootstrap.ps1`; wrapper использует local clone under `.tools/gbrain` |
| Source отсутствует | Запустить `scripts/gbrain-sources.ps1`, затем `scripts/gbrain-health.ps1` |
| Docs list пустой | Запустить `scripts/gbrain-sync.ps1 -SourceId diaverse-docs -SkipDryRun` |
| Code symbol не находится | Синхронизировать соответствующий `*-code` source и проверить, что файл не исключен gitignore/tools logic |
| Keyword search зависает в no-embedding режиме | Использовать `list`, `code-def`, `code-refs` как baseline; `gbrain-health.ps1` не запускает keyword search без явного `-RunSearchSmoke` |
| Daily файл пропущен import'ом | Daily logs не считаются canonical knowledge; важные решения нужно переносить в canonical docs или `.ai-factory/RESEARCH.md` |

## See Also

- [Documentation System](documentation-system.md)
- [Workspace Map](../AGENTS.md)
- [AI Factory Architecture](../.ai-factory/ARCHITECTURE.md)
