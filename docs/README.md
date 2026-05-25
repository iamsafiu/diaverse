# Diaverse Documentation

> Единый вход в документацию workspace `diaverse`.

Этот каталог хранит долгоживущую документацию для связанных репозиториев: `diaweb`, `diaverseapi`, `aibot` и `club10000-bot`. Кодовая истина остается в дочерних репозиториях, а продуктовые контракты, cross-repo runbook'и, исследования, задачи и daily logs собираются здесь.

## Быстрый Старт

```powershell
# Проверить структуру, старые пути и локальные markdown-ссылки
powershell -ExecutionPolicy Bypass -File .\scripts\docs-health.ps1

# Синхронизировать локальный GBrain после существенных правок docs или кода
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1

# Проверить GBrain источники и базовые smoke checks
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-health.ps1
```

## Основные Разделы

| Раздел | Назначение |
| --- | --- |
| [Documentation System](documentation-system.md) | Правила качества, владельцы, статусы, review cadence |
| [Knowledge System](knowledge-system.md) | Локальный GBrain, source IDs, sync/health команды, ограничения безопасности |
| [Infrastructure](infrastructure/README.md) | Server topology, deployment matrix, domains, ports, paths, and safe inventory workflow |
| [Product](product/master-plan.md) | Master plan, фазы, исходные продуктовые спецификации |
| [Architecture](architecture/copywriting-web-architecture.md) | Cross-repo архитектура, file maps, ключевые потоки |
| [Features](features/cabinet/shop-web.md) | Живые документы по auth, RBAC, shop, Advent, pets, analytics |
| [Runbooks](runbooks/copywriting-production-runtime.md) | Deploy, nginx, VPS, production/runtime операции |
| [Research](research/shop/shop-research.md) | Исследования, старые варианты, discovery notes |
| [Logs](logs/shop-network.md) | Исторические технические логи и расследования |
| [Tasks](tasks/) | Task briefs и рабочие заметки |
| [Daily](daily/) | Локальные daily logs по авторам |
| [Assets](assets/) | Скриншоты и другие файлы, на которые ссылаются документы |

## Каноничные Документы

| Документ | Путь | Когда читать |
| --- | --- | --- |
| Documentation System | [documentation-system.md](documentation-system.md) | Перед изменением docs |
| Knowledge System | [knowledge-system.md](knowledge-system.md) | Перед GBrain sync, troubleshooting или изменением knowledge workflow |
| Infrastructure | [infrastructure/README.md](infrastructure/README.md) | Перед server inventory, deploy topology changes или runtime troubleshooting |
| Workspace Architecture | [../.ai-factory/ARCHITECTURE.md](../.ai-factory/ARCHITECTURE.md) | Перед cross-repo решениями |
| Product Master Plan | [product/master-plan.md](product/master-plan.md) | Перед изменением продуктового scope |
| Copywriting Web Architecture | [architecture/copywriting-web-architecture.md](architecture/copywriting-web-architecture.md) | Перед изменением staff copywriting |
| Cabinet Auth Guide | [features/cabinet/auth-guide.md](features/cabinet/auth-guide.md) | Перед изменением auth UI/BFF |
| Cabinet RBAC Guide | [features/cabinet/rbac-guide.md](features/cabinet/rbac-guide.md) | Перед изменением ролей/permissions |
| Cabinet Shop Web | [features/cabinet/shop-web.md](features/cabinet/shop-web.md) | Перед изменением shop frontend/BFF |
| Staff Logging | [architecture/staff-logging.md](architecture/staff-logging.md) | Перед изменением staff logging |
| Advent Calendar | [features/advent-calendar.md](features/advent-calendar.md) | Перед изменением Advent guest/payment flows |
| Diaverse Club Runbook | [club.md](club.md) | Перед изменением club runtime/ops |

## Repo-Local Документация

Не все документы нужно переносить сюда. Узкие документы, которые живут рядом с кодом и обслуживают только один runtime, остаются в своем репозитории:

| Репозиторий | Примеры |
| --- | --- |
| `diaverseapi` | `diaverseapi/docs/*`, `diaverseapi/app/exchange/*.md` |
| `aibot` | `aibot/docs/web-copywriting-service.md`, `aibot/docs/ops-alerts.md` |
| `club10000-bot` | `club10000-bot/docs/referral_system.md` |

Если документ описывает интеграцию двух и более репозиториев, он должен жить в корневом `docs/`.

## See Also

- [Documentation System](documentation-system.md) - правила актуальности и checks.
- [Knowledge System](knowledge-system.md) - локальный GBrain и workflow обновления знаний.
- [Infrastructure](infrastructure/README.md) - server topology and safe inventory workflow.
- [Workspace Map](../AGENTS.md) - правила работы AI agents в workspace.
