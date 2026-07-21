# Diaverse Documentation

> Единый вход в документацию workspace `diaverse`.

Этот каталог хранит долгоживущую документацию для связанных репозиториев: `diaweb`, `diaverse-mobile`, `diaverseapi`, `aibot`, `diaverse-content`, `club10000-bot` и `diaverse-auth-bot`. Кодовая истина остается в дочерних репозиториях, а продуктовые контракты, cross-repo runbook'и, исследования, задачи и daily logs собираются здесь.

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
| [Features](features/factory.md) | Живые документы по factory, auth, RBAC, shop, Advent, pets, analytics |
| [Runbooks](runbooks/copywriting-production-runtime.md) | Deploy, nginx, VPS, production/runtime операции |
| [Content Factory Foreign Server](runbooks/content-factory-foreign-server.md) | Зарубежный runtime `diaverse-content`, S3 media, edge proxy для `/ru/learn/*` |
| [Autonomous Editorial System](features/autonomous-editor.md) | Evidence-first content automation, privacy, attribution, learning, visual review, RBAC and promotion gates |
| [Autonomous Editorial Runbook](runbooks/autonomous-editor.md) | Draft-only operations, rollout stages, kill switches, rollback and verification commands |
| [Referral Structure V1](features/referral-structure.md) | Канонические правила атрибуции, активности, наград, риска и web/staff scope без mobile |
| [Referral Structure Architecture](architecture/referral-structure.md) | Единый граф `team_referral_chains`, additive backend boundary и совместимость без переписывания Teams/Fives |
| [SEO Intelligence](features/seo-intelligence.md) | Search/content strategy analyzer catalog, source credentials, Metrica privacy, read-only baseline, snapshots, outcome learning, rollout gates |
| [Temporary Factory/Raids Staff Gate](runbooks/temporary-factory-raids-staff-gate.md) | Исторический runbook отключенного frontend-only ограничения Factory для staff/tester |
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
| Content Factory Architecture | [architecture/content-factory.md](architecture/content-factory.md) | Перед изменением `diaverse-content`, `/ru/learn/*`, staff content BFF, SEO fragments или зарубежного runtime |
| Autonomous Editorial System | [features/autonomous-editor.md](features/autonomous-editor.md) | Перед изменением autonomous editor, content learning, product attribution, visual candidates, publish modes или Studio UI |
| Autonomous Editorial Runbook | [runbooks/autonomous-editor.md](runbooks/autonomous-editor.md) | Перед promotion, scheduler activation, canary/autopublish, incident response или rollback autonomous editor |
| Referral Structure V1 | [features/referral-structure.md](features/referral-structure.md) | Перед изменением referral attribution, qualification, Mentor, rewards, risk или staff review |
| Referral Structure Architecture | [architecture/referral-structure.md](architecture/referral-structure.md) | Перед изменением графа, схемы, API/BFF, legacy compatibility или rollout referral structure |
| SEO Intelligence | [features/seo-intelligence.md](features/seo-intelligence.md) | Перед изменением SEO analyzer catalog, Search Console/Yandex/Metrica imports, strategy snapshots, candidate influence или outcome strategy learning |
| Copywriting Auth Bot Broadcasts | [features/copywriting/auth-bot-broadcasts.md](features/copywriting/auth-bot-broadcasts.md) | Перед изменением рассылок через auth bot в staff copywriting |
| Copywriting Club10000 Broadcasts | [features/copywriting/club10000-broadcasts.md](features/copywriting/club10000-broadcasts.md) | Перед изменением рассылок через `@club10000_bot` в staff copywriting |
| Cabinet Auth Guide | [features/cabinet/auth-guide.md](features/cabinet/auth-guide.md) | Перед изменением auth UI/BFF |
| Diaverse Auth Bot | [features/cabinet/auth-bot.md](features/cabinet/auth-bot.md) | Перед изменением Telegram auth bot, login-session approve или mobile Telegram link flow |
| Cabinet RBAC Guide | [features/cabinet/rbac-guide.md](features/cabinet/rbac-guide.md) | Перед изменением ролей/permissions |
| Cabinet Shop Web | [features/cabinet/shop-web.md](features/cabinet/shop-web.md) | Перед изменением shop frontend/BFF |
| Support Module | [features/support-module.md](features/support-module.md) | Перед изменением support tickets, attachments, staff board или Ops support digest |
| Редлист | [features/step-cheater-restrictions.md](features/step-cheater-restrictions.md) | Перед изменением step restriction/Redlist, reward eligibility, leagues, clans или Club step rankings |
| DCR Web Commerce Rollout | [tasks/dcr/web-commerce-rollout.md](tasks/dcr/web-commerce-rollout.md) | Перед изменением DCR shop, Advent, admin, support, finance или mobile compatibility contracts |
| Site Analytics | [features/site-analytics.md](features/site-analytics.md) | Перед изменением site tracker, content attribution, staff Site analytics или executive KPI definitions |
| Factory Web | [features/factory.md](features/factory.md) | Перед изменением веб-фабрики, factory API, каталога, ассетов или mobile handoff |
| Raids User Guide | [features/raids-user-guide.md](features/raids-user-guide.md) | Перед изменением рейдового UX, подсказок, баланса, слотов, автоотправки или пользовательских правил |
| Staff Logging | [architecture/staff-logging.md](architecture/staff-logging.md) | Перед изменением staff logging |
| Advent Calendar | [features/advent-calendar.md](features/advent-calendar.md) | Перед изменением Advent guest/payment flows |
| Diaverse Club Runbook | [club.md](club.md) | Перед изменением club runtime/ops |

## Актуальные Исследования

| Документ | Путь | Когда читать |
| --- | --- | --- |
| DAU/WAU/MAU Growth Analysis | [research/dau-wau-mau-growth-analysis-2026-07.md](research/dau-wau-mau-growth-analysis-2026-07.md) | Для технического расчета июльского роста и ограничений source-атрибуции |

## Repo-Local Документация

Не все документы нужно переносить сюда. Узкие документы, которые живут рядом с кодом и обслуживают только один runtime, остаются в своем репозитории:

| Репозиторий | Примеры |
| --- | --- |
| `diaweb` | `diaweb/README.md`, frontend module docs when they only affect the web app |
| `diaverse-mobile` | `diaverse-mobile/MOBILE_RELEASE.md`, `diaverse-mobile/docs/*` |
| `diaverseapi` | `diaverseapi/docs/*`, `diaverseapi/app/exchange/*.md` |
| `aibot` | `aibot/docs/web-copywriting-service.md`, `aibot/docs/ops-alerts.md` |
| `diaverse-content` | `diaverse-content/README.md`, repo-local content factory setup docs |
| `club10000-bot` | `club10000-bot/docs/referral_system.md` |
| `diaverse-auth-bot` | `diaverse-auth-bot/README.md` |

Если документ описывает интеграцию двух и более репозиториев, он должен жить в корневом `docs/`.

## See Also

- [Documentation System](documentation-system.md) - правила актуальности и checks.
- [Knowledge System](knowledge-system.md) - локальный GBrain и workflow обновления знаний.
- [Infrastructure](infrastructure/README.md) - server topology and safe inventory workflow.
- [Workspace Map](../AGENTS.md) - правила работы AI agents в workspace.
