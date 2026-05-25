# Daily Work для Дениса

Эта инструкция настраивает локальный daily-процесс для Diaverse.

Идея простая:

- каждый разработчик ведет свой локальный файл `docs/daily/YYYY-MM-DD-<author>.md`;
- в Confluence создается одна общая страница за день `Daily Work - YYYY-MM-DD`;
- при публикации обновляется только секция текущего автора;
- админка Diaverse читает один общий Confluence-док и генерирует один публичный пост о прогрессе команды.

## Что должно получиться

Пример локальных файлов:

```text
docs/daily/2026-05-25-safiu.md
docs/daily/2026-05-25-denis.md
```

Пример общей страницы в Confluence:

```text
Daily Work - 2026-05-25
```

Внутри страницы:

```text
Daily Work - 2026-05-25

safiu
- ...

denis
- ...
```

## Что нужно от Safiu

Safiu передает готовые Confluence-настройки, включая email/token-пару для публикации:

```env
DAILY_WORK_CONFLUENCE_BASE_URL=<выдает Safiu>
DAILY_WORK_CONFLUENCE_EMAIL=<email владельца token, выдает Safiu>
DAILY_WORK_CONFLUENCE_API_TOKEN=<api token, выдает Safiu>
DAILY_WORK_CONFLUENCE_SPACE_ID=<выдает Safiu>
DAILY_WORK_CONFLUENCE_PARENT_PAGE_ID=<выдает Safiu>
DAILY_WORK_CONFLUENCE_LABEL_NAME=diaverse-daily-work
DAILY_WORK_CONFLUENCE_TIMEOUT_SECONDS=15
```

Личный Atlassian API token Денису создавать не нужно.

Важно: `DAILY_WORK_CONFLUENCE_EMAIL` должен соответствовать владельцу token. Если Safiu дает свой token, здесь должен быть Confluence email Safiu, а не email Дениса. Авторство daily задается отдельно через `DAILY_WORK_AUTHOR=denis`.

Для daily-публикации не нужны:

- SSH-доступ к серверу;
- OpenAI API key;
- внутренние JWT;
- production env сервера;
- доступ к базе данных.

## Atlassian API token

Для этой схемы используется API token, который передает Safiu. У владельца token должны быть права смотреть и редактировать страницы в Confluence-разделе:

```text
Daily docs / Daily Work
```

Правила хранения:

1. Сохрани token только локально в `.env.daily-work`.
2. Не отправляй token в чат.
3. Не коммить `.env.daily-work`.
4. Не вставляй token в `Public digest`, задачи, логи или скриншоты.

## Локальный `.env.daily-work`

В корне workspace `diaverse`, где запускается Codex или Claude, создай файл:

```text
.env.daily-work
```

Содержимое:

```env
DAILY_WORK_CONFLUENCE_BASE_URL=<atlassian-base-url>
DAILY_WORK_CONFLUENCE_EMAIL=<email-владельца-token-от-Safiu>
DAILY_WORK_CONFLUENCE_API_TOKEN=<api-token-от-Safiu>
DAILY_WORK_CONFLUENCE_SPACE_ID=<confluence-space-id>
DAILY_WORK_CONFLUENCE_PARENT_PAGE_ID=<daily-work-parent-page-id>
DAILY_WORK_CONFLUENCE_LABEL_NAME=diaverse-daily-work
DAILY_WORK_CONFLUENCE_TIMEOUT_SECONDS=15
DAILY_WORK_AUTHOR=denis
```

`DAILY_WORK_AUTHOR` должен быть коротким ASCII slug:

- можно: `denis`, `denis.k`, `denis-dev`;
- нельзя: пробелы, кириллица, спецсимволы.

## Какие файлы должны быть в workspace

В workspace  должны быть эти файлы:

```text
scripts/daily_work_publish.py
scripts/daily-work-add.ps1
scripts/daily-work-publish.ps1
docs/daily/TEMPLATE.md
.codex/skills/daily-work/SKILL.md
```

Если какого-то файла нет, попроси Safiu передать актуальную версию из workspace.

## Ежедневные команды

Все команды запускать из корня workspace `diaverse`.

Проверить состояние daily:

```powershell
python scripts\daily_work_publish.py status
```

Добавить запись вручную:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Public "Короткая публичная заметка на русском." -Internal "Локальная техническая заметка."
```

Проверить публикацию без записи в Confluence:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1 -DryRun
```

Опубликовать `Public digest` в Confluence:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1
```

Проверить другого автора явно:

```powershell
python scripts\daily_work_publish.py status --author denis
```

Опубликовать другого автора явно:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1 -Author denis
```

## Как пользоваться через Codex skill

Если Codex открыт в workspace `diaverse`, используй команды:

```text
$daily-work status
$daily-work add
$daily-work publish
```

Что они делают:

- `$daily-work status` проверяет локальный daily-файл, Confluence config и unsafe-маркеры;
- `$daily-work add` добавляет запись в `docs/daily/YYYY-MM-DD-denis.md`;
- `$daily-work publish` отправляет только `Public digest` в твою секцию на общей Confluence-странице.

Важно: это не фоновый daemon. Codex дописывает daily по правилу в workspace/skill после завершенных задач, но если запись не появилась, вызови `$daily-work add` вручную.

## Правила daily-дока

Daily-доки пишем на русском языке.

Файл должен содержать две секции:

```md
# Daily Work - YYYY-MM-DD [denis]

## Public digest

- Пользовательская или продуктовая формулировка, которую можно использовать в публичном посте.

## Internal log

- Локальные технические детали для команды.
```

`Public digest` может попасть в публичный пост. Там нельзя писать:

- токены;
- значения env;
- SSH-команды;
- пути к ключам;
- внутренние IP;
- приватную инфраструктуру;
- сырые stack trace;
- детали, которые не должны попасть пользователям.

`Internal log` не публикуется в Confluence и не используется для генерации публичного поста.

Хороший `Public digest`:

```md
- Улучшили ежедневный copywriting-процесс: команда теперь видит общий прогресс за день и может быстрее собирать публичный пост об обновлениях.
```

Плохой `Public digest`:

```md
- Залез на сервер по ssh, поправил env TOKEN=..., перезапустил контейнер на IP ...
```

Технические детали такого уровня нужно писать только в `Internal log`.

## Готовый skill: `.codex/skills/daily-work/SKILL.md`

Создай папку:

```text
.codex/skills/daily-work
```

И файл:

```text
.codex/skills/daily-work/SKILL.md
```

Содержимое:

````md
---
name: daily-work
description: Manage the Diaverse local Daily Work log and Confluence publishing workflow. Use when the user says "$daily-work add", "$daily-work status", "$daily-work publish", asks to append today's completed work to docs/daily, checks daily publish readiness, or wants to publish the safe public digest to Confluence.
---

# Daily Work

Use this skill from the Diaverse workspace root. It is script-driven: run the workspace scripts instead of rewriting Confluence REST logic.

## Model

- Local files are per author: `docs/daily/YYYY-MM-DD-<author>.md`.
- The author comes from `DAILY_WORK_AUTHOR`; if it is missing, the default is `safiu`.
- Confluence pages are shared per day: `Daily Work - YYYY-MM-DD`.
- Publishing updates only the current author's section on the shared Confluence page and preserves other author sections.
- Only `Public digest` is published. `Internal log` stays local.

## Commands

### `$daily-work add`

Append or normalize today's local daily file:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Public "<безопасная публичная заметка>" -Internal "<локальная техническая заметка>"
```

If the user gives no text, synthesize a concise note from the just-completed task. Daily document entries must be written in Russian unless the user explicitly asks for another language. Keep `Public digest` user-safe and put implementation details in `Internal log`.

For another author explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Author "<author-slug>" -Public "<безопасная публичная заметка>"
```

### `$daily-work status`

Show today's file path, author, target Confluence title, section counts, unsafe public markers, and Confluence config presence without printing secret values:

```powershell
python scripts\daily_work_publish.py status
```

Use this as a preflight before publishing or when the user asks whether the daily doc is ready.

### `$daily-work publish`

Publish only `Public digest` to the current author's section on the shared Confluence page:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1
```

For validation without network writes:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1 -DryRun
```

Run `status` first when the user has not already checked readiness. If publish succeeds, include the Confluence page URL in the final answer.

## Safety Rules

- Never publish or prompt-generate from `Internal log`.
- Write daily document content in Russian by default. Keep the technical section names `Public digest` and `Internal log` unchanged because the publisher parses them.
- Never echo Confluence tokens, raw env values, auth headers, private SSH commands, SSH key paths, internal IPs, private infrastructure details, or sensitive stack traces.
- If `Public digest` contains unsafe markers, stop and tell the user what marker classes were detected. Do not include the sensitive text.
- If config is missing, report only missing env key names.
- Keep final answers concise and mention whether the daily file was updated or published.

## Script Logging

Expect script-level `INFO`, `WARN`, and `ERROR` logs. They should include paths, dates, counts, author, page ids, titles, and safe reason codes only. They must not include generated post bodies, Confluence document bodies, tokens, JWTs, or raw environment values.
````

## Готовое правило для `AGENTS.md`

Добавь в `AGENTS.md` workspace такую секцию или проверь, что она уже есть:

```md
## Daily Work Capture

- After each meaningful completed task in this workspace, append a concise entry to `docs/daily/YYYY-MM-DD-<author>.md` unless the user explicitly says `bez daily` or `no daily`; use `DAILY_WORK_AUTHOR` when configured, otherwise use `safiu`.
- The daily file must have two sections:
  - `Public digest` for short, user-safe progress notes that may be published to Confluence and used to generate a public post.
  - `Internal log` for local technical audit notes that must never be published or sent to post generation.
- Daily document entries must be written in Russian unless the user explicitly asks for another language; keep the technical section names `Public digest` and `Internal log` unchanged for the publisher.
- Only the `Public digest` section may be sent to Confluence or used as source material for generated posts.
- Confluence daily pages are shared by date (`Daily Work - YYYY-MM-DD`); the publisher must update only the current author's section and preserve other author sections.
- Daily entries must not include secrets, tokens, raw environment values, private SSH commands, SSH key paths, internal IPs, private infrastructure details, raw stack traces with sensitive values, or other internal-only notes in `Public digest`.
- Prefer product/user-facing phrasing in `Public digest`; keep implementation details, file names, and debugging context in `Internal log`.
- Mention daily-log writes in the final answer when a task updated the current `docs/daily/YYYY-MM-DD-<author>.md`.
```

## Готовый шаблон `docs/daily/TEMPLATE.md`

Создай файл:

```text
docs/daily/TEMPLATE.md
```

Содержимое:

```md
# Daily Work - {{date}} [{{author}}]

## Public digest

<!-- Только безопасные публичные заметки на русском. Этот раздел можно публиковать в Confluence и использовать для генерации постов. -->

## Internal log

<!-- Локальные технические заметки на русском. Этот раздел нельзя публиковать или отправлять в генерацию постов. -->
```

## Первый запуск

1. Создай `.env.daily-work`.
2. Проверь, что `DAILY_WORK_AUTHOR=denis`.
3. Выполни:

```powershell
python scripts\daily_work_publish.py status
```

Если файл за сегодня еще не создан, добавь первую запись:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Public "Подключил локальный Daily Work процесс для командной публикации прогресса." -Internal "Настроен .env.daily-work и проверен daily-work skill."
```

Проверь dry-run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1 -DryRun
```

Если `unsafe_public_markers` пустой и `confluence_configured=true`, публикуй:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1
```

## Ежедневный процесс

1. Работаешь над задачей через Codex.
2. После завершения задачи проверяешь, появилась ли запись в daily.
3. Если запись не появилась, вызываешь `$daily-work add`.
4. В конце дня запускаешь `$daily-work status`.
5. Если все чисто, запускаешь `$daily-work publish`.
6. В админке Diaverse выбирается общий daily-док за день и генерируется один публичный пост.

## Troubleshooting

Если `confluence_configured=false`:

- проверь `.env.daily-work`;
- проверь, что файл лежит в корне workspace `diaverse`;
- проверь имена env-переменных;
- не печатай token в чат.

Если `unsafe_public_markers` не пустой:

- открой `docs/daily/YYYY-MM-DD-denis.md`;
- найди в `Public digest` технические или секретные слова;
- перенеси такие детали в `Internal log`;
- переформулируй публичную часть пользовательским языком.

Если publish создал не тот файл:

- проверь `DAILY_WORK_AUTHOR`;
- проверь, что запускаешь команды из корня `diaverse`;
- запусти `python scripts\daily_work_publish.py status` и посмотри `path` и `target_title`.

Если Confluence вернул ошибку доступа:

- проверь, что `DAILY_WORK_CONFLUENCE_EMAIL` и `DAILY_WORK_CONFLUENCE_API_TOKEN` взяты из одной пары, которую дал Safiu;
- попроси Safiu проверить права на раздел `Daily docs / Daily Work`.
