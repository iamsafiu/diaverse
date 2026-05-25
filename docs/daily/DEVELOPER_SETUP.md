# Daily Work: настройка для разработчика

## Цель

Каждый разработчик ведет локальный daily-док в `docs/daily`, а в конце дня публикует публичную часть в общий Confluence-док `Daily Work - YYYY-MM-DD`.

Админка Diaverse читает один общий daily-док за день и генерирует один публичный пост о прогрессе команды.

## Как устроено

Локальные файлы остаются раздельными:

```text
docs/daily/2026-05-25-safiu.md
docs/daily/2026-05-25-ivan.md
```

Confluence-страница общая:

```text
Daily Work - 2026-05-25
```

При публикации скрипт обновляет только секцию текущего автора и сохраняет секции остальных разработчиков.

## Что нужно получить

Нужен доступ к Confluence-пространству Diaverse и право редактировать страницы внутри раздела:

```text
Daily docs / Daily Work
```

Также нужен Atlassian API token от аккаунта разработчика.

Для daily-публикации не нужны:

- SSH-доступ к серверу;
- OpenAI API key;
- внутренние JWT;
- доступ к production env сервера.

## Локальный `.env.daily-work`

В корне workspace `diaverse` создать файл `.env.daily-work`.

Файл нельзя коммитить и нельзя отправлять в чат.

```env
DAILY_WORK_CONFLUENCE_BASE_URL=<atlassian-base-url>
DAILY_WORK_CONFLUENCE_EMAIL=<developer-email>
DAILY_WORK_CONFLUENCE_API_TOKEN=<atlassian-api-token>
DAILY_WORK_CONFLUENCE_SPACE_ID=<confluence-space-id>
DAILY_WORK_CONFLUENCE_PARENT_PAGE_ID=<daily-work-parent-page-id>
DAILY_WORK_CONFLUENCE_LABEL_NAME=diaverse-daily-work
DAILY_WORK_CONFLUENCE_TIMEOUT_SECONDS=15
DAILY_WORK_AUTHOR=<author-slug>
```

`DAILY_WORK_AUTHOR` должен быть коротким ASCII slug: буквы, цифры, точка, подчеркивание или дефис.

Пример:

```env
DAILY_WORK_AUTHOR=ivan
```

## Команды

Добавить запись в локальный daily:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Public "Короткая публичная заметка на русском." -Internal "Локальная техническая заметка."
```

Проверить состояние:

```powershell
python scripts\daily_work_publish.py status
```

Проверить публикацию без записи в Confluence:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1 -DryRun
```

Опубликовать `Public digest` в Confluence:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1
```

## Правила daily-дока

Daily-доки пишем на русском языке.

Файл должен содержать две секции:

```md
## Public digest

- Пользовательская или продуктовая формулировка, которую можно использовать в публичном посте.

## Internal log

- Локальные технические детали для команды.
```

В `Public digest` нельзя писать:

- токены;
- значения env;
- SSH-команды;
- пути к ключам;
- внутренние IP;
- приватную инфраструктуру;
- сырые stack trace;
- детали, которые не должны попасть пользователям.

`Internal log` не публикуется в Confluence и не используется для генерации публичного поста.

## Ежедневный процесс

1. После завершения задачи добавить запись через `$daily-work add` или прямую команду `daily-work-add.ps1`.
2. В конце дня запустить `status`.
3. Если `Public digest` заполнен и unsafe-маркеров нет, запустить `publish`.
4. В админке Diaverse открыть Daily Work, выбрать документ за день и сгенерировать один общий пост.
